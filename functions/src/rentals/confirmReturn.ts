import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

export const confirmReturn = onCall(async (req) => {
  const authUid = req.auth?.uid;
  if (!authUid) throw new HttpsError("unauthenticated", "Not authenticated");

  const { requestId, qrToken } = req.data;
  if (!requestId || !qrToken)
    throw new HttpsError("invalid-argument", "Missing parameters");

  const db = getFirestore();
  const ref = db.collection("rentalRequests").doc(requestId);
  const snap = await ref.get();

  if (!snap.exists) throw new HttpsError("not-found", "Rental not found");
  const data = snap.data()!;

  // Only owner scans return QR
  if (data.itemOwnerUid !== authUid)
    throw new HttpsError("permission-denied", "Only owner can confirm return");

  if (data.status !== "active")
    throw new HttpsError("failed-precondition", "Rental is not active");

  if (!data.returnQrToken || data.returnQrToken !== qrToken)
    throw new HttpsError("failed-precondition", "Invalid return QR");

  const renterUid = data.renterUid;
  const insurance = Number(data.insuranceAmount || 0);

  // RETURN DATE VALIDATION
  const endDate = new Date(data.endDate);
  const today = new Date();
  const maxReturnDate = new Date(endDate);
  maxReturnDate.setDate(maxReturnDate.getDate() + 3);

  if (today > maxReturnDate)
    throw new HttpsError(
      "failed-precondition",
      "Return window expired. Rental already handled."
    );

  //  GET WALLETS
  const walletsSnap = await db
    .collection("wallets")
    .where("userId", "==", renterUid)
    .get();

  if (walletsSnap.empty)
    throw new HttpsError("not-found", "Renter wallets not found");

  let holdingRef: FirebaseFirestore.DocumentReference | null = null;
  let mainRef: FirebaseFirestore.DocumentReference | null = null;

  walletsSnap.forEach((doc) => {
    const w = doc.data();
    if (w.type === "HOLDING") holdingRef = doc.ref;
    if (w.type === "USER") mainRef = doc.ref;
  });

  if (!holdingRef || !mainRef)
    throw new HttpsError(
      "failed-precondition",
      "Missing USER or HOLDING wallet"
    );

  await db.runTransaction(async (tx) => {
    const holdingSnap = await tx.get(holdingRef!);
    if (!holdingSnap.exists)
      throw new HttpsError("not-found", "Holding wallet missing");

    const holdingBalance = Number(holdingSnap.data()?.balance || 0);

    if (holdingBalance < insurance)
      throw new HttpsError(
        "failed-precondition",
        "Holding wallet inconsistent"
      );

    const mainSnap = await tx.get(mainRef!);
    const mainBalance = Number(mainSnap.data()?.balance || 0);

    //  BALANCE MOVEMENTS
    tx.update(holdingRef!, {
      balance: holdingBalance - insurance,
      updatedAt: FieldValue.serverTimestamp(),
    });

    tx.update(mainRef!, {
      balance: mainBalance + insurance,
      updatedAt: FieldValue.serverTimestamp(),
    });

    // WALLET TRANSACTIONS
    const walletTx = db.collection("walletTransactions");

    const txRef = walletTx.doc();
    tx.set(txRef, {
      fromWalletId: holdingRef!.id,
      toWalletId: mainRef!.id,
      amount: insurance,
      purpose: "INSURANCE_RELEASE",
      rentalRequestId: requestId,
      userId: data.renterUid,
      status: "confirmed",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    // UPDATE RENTAL status
    tx.update(ref, {
      status: "ended",
      updatedAt: FieldValue.serverTimestamp(),
      returnConfirmedAt: FieldValue.serverTimestamp(),
    });
  });

  return { success: true };
});
