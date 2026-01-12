import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const DEV_MODE = true;   //  TURN OFF IN PRODUCTION

export const confirmPickup = onCall(async (req) => {
  const authUid = req.auth?.uid;
  if (!authUid) throw new HttpsError("unauthenticated", "Not authenticated");

  const { requestId, qrToken, force } = req.data;

  if (!requestId)
    throw new HttpsError("invalid-argument", "Missing requestId");

  const db = getFirestore();
  const ref = db.collection("rentalRequests").doc(requestId);
  const snap = await ref.get();

  if (!snap.exists) throw new HttpsError("not-found", "Rental not found");

  const data = snap.data()!;

  // Must be renter scanning unless force
  if (!force && data.renterUid !== authUid)
    throw new HttpsError("permission-denied", "Only renter can confirm pickup");

  if (data.status !== "accepted")
    throw new HttpsError("failed-precondition", "Rental not accepted");

  //  DEV MODE / FORCE
  if (DEV_MODE || force) {
    console.log("DEV MODE / FORCE → Pickup bypass validation");
  } else {
    //  STRICT QR VALIDATION
    if (!qrToken)
      throw new HttpsError("invalid-argument", "Missing qrToken");

    if (!data.pickupQrToken || data.pickupQrToken !== qrToken)
      throw new HttpsError("failed-precondition", "Invalid pickup QR");

    //  DATE VALIDATION
    const startDate = new Date(data.startDate);
    const today = new Date();

    const sameDay =
      today.getFullYear() === startDate.getFullYear() &&
      today.getMonth() === startDate.getMonth() &&
      today.getDate() === startDate.getDate();

    if (!sameDay)
      throw new HttpsError(
        "failed-precondition",
        "Pickup only allowed on start date"
      );
  }

  //  MONEY LOGIC
  const renterUid = data.renterUid;
  const ownerUid = data.itemOwnerUid;

  const rentalPrice = Number(data.rentalPrice || 0);
  const insurance = Number(data.insuranceAmount || 0);

  if (rentalPrice <= 0)
    throw new HttpsError("failed-precondition", "Invalid rental price");

  const commissionRate = 0.07;
  const commissionAmount = rentalPrice * commissionRate;
  const ownerAmount = rentalPrice - commissionAmount;

  // renter wallets
  const renterWallets = await db
    .collection("wallets")
    .where("userId", "==", renterUid)
    .get();

  if (renterWallets.empty)
    throw new HttpsError("not-found", "Renter wallets not found");

  let holdingRef: FirebaseFirestore.DocumentReference | null = null;

  renterWallets.forEach((doc) => {
    if (doc.data().type === "HOLDING") holdingRef = doc.ref;
  });

  if (!holdingRef)
    throw new HttpsError("failed-precondition", "Holding wallet missing");

  // owner wallet
  const ownerWallet = await db
    .collection("wallets")
    .where("userId", "==", ownerUid)
    .where("type", "==", "USER")
    .limit(1)
    .get();

  if (ownerWallet.empty)
    throw new HttpsError("not-found", "Owner wallet missing");

  const ownerRef = ownerWallet.docs[0].ref;

  // admin wallet
  const adminWallet = await db
    .collection("wallets")
    .where("type", "==", "ADMIN")
    .limit(1)
    .get();

  if (adminWallet.empty)
    throw new HttpsError("failed-precondition", "Admin wallet missing");

  const adminRef = adminWallet.docs[0].ref;

  await db.runTransaction(async (tx) => {
    const holdSnap = await tx.get(holdingRef!);
    const ownerSnap = await tx.get(ownerRef);
    const adminSnap = await tx.get(adminRef);

    const holdingBalance = Number(holdSnap.data()?.balance || 0);
    const ownerBalance = Number(ownerSnap.data()?.balance || 0);
    const adminBalance = Number(adminSnap.data()?.balance || 0);

    const required = rentalPrice + insurance;
    if (holdingBalance < required)
      throw new HttpsError(
        "failed-precondition",
        "Holding wallet has insufficient funds"
      );

    tx.update(holdingRef!, {
      balance: holdingBalance - rentalPrice,
      updatedAt: FieldValue.serverTimestamp(),
    });

    tx.update(ownerRef, {
      balance: ownerBalance + ownerAmount,
      updatedAt: FieldValue.serverTimestamp(),
    });

    tx.update(adminRef, {
      balance: adminBalance + commissionAmount,
      updatedAt: FieldValue.serverTimestamp(),
    });

    const walletTx = db.collection("walletTransactions");

    tx.set(walletTx.doc(), {
      fromWalletId: holdingRef!.id,
      toWalletId: ownerRef.id,
      amount: ownerAmount,
      purpose: "RENTAL_PAYOUT",
      rentalRequestId: requestId,
      userId: ownerUid,
      status: "confirmed",
      createdAt: FieldValue.serverTimestamp(),
    });

    tx.set(walletTx.doc(), {
          fromWalletId: holdingRef!.id,
          toWalletId: ownerRef.id,
          amount: ownerAmount,
          purpose: "RENTAL_PAYOUT",
          rentalRequestId: requestId,
          userId: renterUid,
          status: "confirmed",
          createdAt: FieldValue.serverTimestamp(),
        });

    tx.set(walletTx.doc(), {
      fromWalletId: holdingRef!.id,
      toWalletId: adminRef.id,
      amount: commissionAmount,
      purpose: "PLATFORM_COMMISSION",
      rentalRequestId: requestId,
      status: "confirmed",
      createdAt: FieldValue.serverTimestamp(),
    });

    const endDate = new Date(data.endDate);
    const endPlus3 = new Date(endDate);
    endPlus3.setDate(endPlus3.getDate() + 3);

    tx.update(ref, {
      status: "active",
      paymentStatus: "released",
      endDatePlus3: endPlus3,
      pickupConfirmedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  return { success: true };
});
