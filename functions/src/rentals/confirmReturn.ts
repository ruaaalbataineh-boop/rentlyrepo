import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { requireWallets } from "../utils/walletHelpers";

const DEV_MODE = true;

export const confirmReturn = onCall(async (req) => {
  const authUid = req.auth?.uid;
  if (!authUid) throw new HttpsError("unauthenticated","Not authenticated");

  const { requestId, qrToken, force } = req.data;
  if (!requestId) throw new HttpsError("invalid-argument","Missing requestId");

  const db = getFirestore();
  const ref = db.collection("rentalRequests").doc(requestId);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found","Rental not found");

  const r = snap.data()!;

  if (!force && r.itemOwnerUid !== authUid)
    throw new HttpsError("permission-denied","Only owner can confirm return");

  if (r.status !== "active")
    throw new HttpsError("failed-precondition","Rental not active");

  const endDate = new Date(r.endDate);
  const today = new Date();
  const dLate = Math.floor((today.getTime() - endDate.getTime()) / 86400000);

  if (!DEV_MODE && !force) {
    if (!qrToken || qrToken !== r.returnQrToken)
      throw new HttpsError("failed-precondition","Invalid return QR");

    const maxReturn = new Date(endDate);
    maxReturn.setDate(maxReturn.getDate() + 3);

    if (today < endDate)
      throw new HttpsError("failed-precondition","Return not allowed yet");

    if (today > maxReturn)
      throw new HttpsError("failed-precondition","Return window expired");
  }

  const renterUid = r.renterUid;
  const ownerUid = r.itemOwnerUid;
  const insurance = Number(r.insurance?.amount || 0);

  // determine late fee eligibility
  const isShort =
    (r.rentalType === "daily" && r.rentalQuantity <= 30) ||
    (r.rentalType === "weekly" && r.rentalQuantity <= 4);

  const dailyOrWeekly = ["daily","weekly"].includes(r.rentalType);

  let basePerDay = 0;
  if (r.rentalType === "daily")
    basePerDay = r.rentalPrice / r.rentalQuantity;
  if (r.rentalType === "weekly")
    basePerDay = r.rentalPrice / 7;

  const lateFee =
    dailyOrWeekly && isShort && dLate > 0
      ? dLate * basePerDay
      : 0;

  // wallets
  const { user: renterUser, holding: renterHolding } =
      await requireWallets(renterUid);

  const ownerWallets = await db
    .collection("wallets")
    .where("userId", "==", ownerUid)
    .where("type", "==", "USER")
    .limit(1)
    .get();

  if (ownerWallets.empty)
     throw new HttpsError("failed-precondition", "Owner wallet missing");

  const ownerUser = ownerWallets.docs[0].ref;

  await db.runTransaction(async(tx)=>{
    const h = await tx.get(renterHolding);
    const ru = await tx.get(renterUser);
    const ou = await tx.get(ownerUser);

    const hb = Number(h.data()?.balance||0);
    const rub = Number(ru.data()?.balance||0);
    const oub = Number(ou.data()?.balance||0);

    // insurance release
    tx.update(renterHolding,{balance:hb-insurance});
    tx.update(renterUser,{balance:rub+(insurance - lateFee)});

    tx.set(db.collection("walletTransactions").doc(),{
      rentalRequestId:requestId,
      purpose:"RENTAL_INSURANCE_RELEASE",
      fromWalletId:renterHolding.id,
      toWalletId:renterUser.id,
      userId:renterUid,
      amount:insurance,
      status:"confirmed",
      createdAt:FieldValue.serverTimestamp()
    });

    // late fee
    if(lateFee>0){
      tx.update(ownerUser,{balance:oub+lateFee});

      tx.set(db.collection("walletTransactions").doc(),{
        rentalRequestId:requestId,
        purpose:"RENTAL_LATE_FEE",
        fromWalletId:renterUser.id,
        toWalletId:ownerUser.id,
        userId:renterUid,
        amount:lateFee,
        status:"confirmed",
        createdAt:FieldValue.serverTimestamp()
      });

      tx.set(db.collection("walletTransactions").doc(),{
              rentalRequestId:requestId,
              purpose:"RENTAL_LATE_FEE",
              fromWalletId:renterUser.id,
              toWalletId:ownerUser.id,
              userId:ownerUid,
              amount:lateFee,
              status:"confirmed",
              createdAt:FieldValue.serverTimestamp()
            });
    }

    tx.update(ref,{
      status:"ended",
      lateDays:dLate>0?dLate:0,
      endReason:dLate>0?"late":"normal",
      updatedAt:FieldValue.serverTimestamp(),
      returnConfirmedAt:FieldValue.serverTimestamp()
    });
  });

  return {success:true};
});
