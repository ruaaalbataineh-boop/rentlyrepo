import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

export const confirmPickup = onCall(async (req) => {
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

  // Must be renter scanning
  if (data.renterUid !== authUid)
    throw new HttpsError("permission-denied", "Only renter can confirm pickup");

  if (data.status !== "accepted")
    throw new HttpsError("failed-precondition", "Rental not accepted");

  // Validate QR
  if (!data.pickupQrToken || data.pickupQrToken !== qrToken)
    throw new HttpsError("failed-precondition", "Invalid pickup QR");

  // DATE VALIDATION
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

  // MONEY LOGIC
  const renterUid = data.renterUid;
  const ownerUid = data.itemOwnerUid;
  const rentalPrice = Number(data.rentalPrice || 0);
  const insurance = Number(data.insuranceAmount || 0);

  const commissionRate = 0.07;
  const commissionAmount = rentalPrice * commissionRate;
  const ownerAmount = rentalPrice - commissionAmount;

  if (rentalPrice <= 0)
    throw new HttpsError("failed-precondition", "Invalid rental price");

  // get wallets
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
    throw new HttpsError("failed-precondition", "Renter holding wallet missing");

  const ownerWallet = await db
    .collection("wallets")
    .where("userId", "==", ownerUid)
    .where("type", "==", "USER")
    .limit(1)
    .get();

  if (ownerWallet.empty)
    throw new HttpsError("not-found", "Owner wallet missing");

  const ownerRef = ownerWallet.docs[0].ref;

  const adminWallet = await db
    .collection("wallets")
    .where("type", "==", "ADMIN")
    .limit(1)
    .get();

  if (adminWallet.empty)
    throw new HttpsError("failed-precondition", "Admin wallet missing");

  const adminRef = adminWallet.docs[0].ref;

  // transactions
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

    // UPDATE BALANCES
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

    //  WALLET TRANSACTIONS
    const walletTx = db.collection("walletTransactions");

    // To Owner
    const ownerTxRef = walletTx.doc();
    tx.set(ownerTxRef, {
      fromWalletId: holdingRef!.id,
      toWalletId: ownerRef.id,
      amount: ownerAmount,
      purpose: "RENTAL_PAYOUT",
      rentalRequestId: requestId,
      userId: data.itemOwnerUid,
      status: "confirmed",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    const renterTxRef = walletTx.doc();
        tx.set(renterTxRef, {
          fromWalletId: holdingRef!.id,
          toWalletId: ownerRef.id,
          amount: ownerAmount,
          purpose: "RENTAL_PAYOUT",
          rentalRequestId: requestId,
          userId: data.renterUid,
          status: "confirmed",
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });

    // Commission to Admin
    const adminTxRef = walletTx.doc();
    tx.set(adminTxRef, {
      fromWalletId: holdingRef!.id,
      toWalletId: adminRef.id,
      amount: commissionAmount,
      purpose: "PLATFORM_COMMISSION",
      rentalRequestId: requestId,
      userId: null,
      status: "confirmed",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    // RENTAL status UPDATE
    tx.update(ref, {
      status: "active",
      paymentStatus: "released",
      pickupConfirmedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  return { success: true };
});
