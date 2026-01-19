import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();
const db = getFirestore();

export const deletePendingRentalRequest = onCall(async (request) => {
  try {
    const renterUid = request.auth?.uid;
    if (!renterUid)
      throw new HttpsError("unauthenticated", "Not authenticated.");

    const { requestId } = request.data;
    if (!requestId)
      throw new HttpsError("invalid-argument", "Missing requestId");

    const ref = db.collection("rentalRequests").doc(requestId);
    const snap = await ref.get();

    if (!snap.exists)
      throw new HttpsError("not-found", "Request not found");

    const data = snap.data()!;

    if (data.renterUid !== renterUid)
      throw new HttpsError("permission-denied", "Not your request");

    if (data.status !== "pending")
      throw new HttpsError(
        "failed-precondition",
        "Only pending requests can be deleted"
      );

    const total = Number(data.totalPrice || 0);

    return await db.runTransaction(async (trx) => {
      const walletsRef = db.collection("wallets");

      const userWalletSnap = await trx.get(
        walletsRef.where("userId","==", renterUid).where("type","==","USER").limit(1)
      );

      const holdingWalletSnap = await trx.get(
        walletsRef.where("userId","==", renterUid).where("type","==","HOLDING").limit(1)
      );

      if (userWalletSnap.empty || holdingWalletSnap.empty)
        throw new HttpsError("failed-precondition","Wallets not found");

      const userWallet = userWalletSnap.docs[0];
      const holdingWallet = holdingWalletSnap.docs[0];

      const holdingBalance = holdingWallet.data().balance || 0;

      if (holdingBalance < total)
        throw new HttpsError("failed-precondition","Holding wallet inconsistent");

      // Move money back
      trx.update(holdingWallet.ref, {
        balance: holdingBalance - total,
        updatedAt: FieldValue.serverTimestamp(),
      });

      trx.update(userWallet.ref, {
        balance: (userWallet.data().balance || 0) + total,
        updatedAt: FieldValue.serverTimestamp(),
      });

      // Record transaction
      const txRef = db.collection("walletTransactions").doc();
      trx.set(txRef, {
        userId: renterUid,
        fromWalletId: holdingWallet.id,
        toWalletId: userWallet.id,
        amount: total,
        purpose: "RENTAL_CANCEL_REFUND",
        status: "confirmed",
        createdAt: FieldValue.serverTimestamp(),
        rentalRequestId: requestId,
      });

      // Delete request
      trx.delete(ref);

      return { success: true };
    });

  } catch (e) {
    console.error("deletePendingRentalRequest ERROR:", e);
    if (e instanceof HttpsError) throw e;
    throw new HttpsError("internal", "Unexpected error");
  }
});
