import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const DEV_MODE = true;   // TURN OFF IN PROD

export const confirmReturn = onCall(async (req) => {
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

  if (!force && data.itemOwnerUid !== authUid)
    throw new HttpsError("permission-denied", "Only owner can confirm return");

  if (data.status !== "active")
    throw new HttpsError("failed-precondition", "Rental not active");

  //  DEV MODE / FORCE
  if (DEV_MODE || force) {
    console.log("DEV MODE / FORCE → Return bypass validation");
  } else {
    //STRICT QR
    if (!qrToken)
      throw new HttpsError("invalid-argument", "Missing qrToken");

    if (!data.returnQrToken || data.returnQrToken !== qrToken)
      throw new HttpsError("failed-precondition", "Invalid return QR");

    // DATE VALIDATION
    const endDate = new Date(data.endDate);
    const today = new Date();

    const maxReturn = new Date(endDate);
    maxReturn.setDate(maxReturn.getDate() + 3);

    if (today < endDate)
      throw new HttpsError(
        "failed-precondition",
        "Return not allowed yet"
      );

    if (today > maxReturn)
      throw new HttpsError(
        "failed-precondition",
        "Return window expired"
      );
  }

  const renterUid = data.renterUid;
  const insurance = Number(data.insurance?.amount || 0);

  const wallets = await db
    .collection("wallets")
    .where("userId", "==", renterUid)
    .get();

  if (wallets.empty)
    throw new HttpsError("not-found", "Wallets missing");

  let holdingRef: FirebaseFirestore.DocumentReference | null = null;
  let mainRef: FirebaseFirestore.DocumentReference | null = null;

  wallets.forEach((doc) => {
    const w = doc.data();
    if (w.type === "HOLDING") holdingRef = doc.ref;
    if (w.type === "USER") mainRef = doc.ref;
  });

  if (!holdingRef || !mainRef)
    throw new HttpsError("failed-precondition", "Wallet missing");

  await db.runTransaction(async (tx) => {
    const holdSnap = await tx.get(holdingRef!);
    const mainSnap = await tx.get(mainRef!);

    const holdBal = Number(holdSnap.data()?.balance || 0);
    const mainBal = Number(mainSnap.data()?.balance || 0);

    if (holdBal < insurance)
      throw new HttpsError(
        "failed-precondition",
        "Holding inconsistency"
      );

    tx.update(holdingRef!, {
      balance: holdBal - insurance,
      updatedAt: FieldValue.serverTimestamp(),
    });

    tx.update(mainRef!, {
      balance: mainBal + insurance,
      updatedAt: FieldValue.serverTimestamp(),
    });

    const walletTx = db.collection("walletTransactions");

    tx.set(walletTx.doc(), {
      fromWalletId: holdingRef!.id,
      toWalletId: mainRef!.id,
      amount: insurance,
      purpose: "INSURANCE_RELEASE",
      rentalRequestId: requestId,
      userId: renterUid,
      status: "confirmed",
      createdAt: FieldValue.serverTimestamp(),
    });

    tx.update(ref, {
      status: "ended",
      updatedAt: FieldValue.serverTimestamp(),
      returnConfirmedAt: FieldValue.serverTimestamp(),
    });
  });

  return { success: true };
});
