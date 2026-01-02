import { onCall } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();
const db = getFirestore();

export const approveEfawateerkomTopUp = onCall(async (req) => {
  const { topUpId } = req.data;
  if (!topUpId) throw new Error("Missing topUpId");

  const topRef = db.collection("topUpRequests").doc(topUpId);

  await db.runTransaction(async (trx) => {
    const topSnap = await trx.get(topRef);
    if (!topSnap.exists) throw new Error("TopUp not found");

    const topUp = topSnap.data()!;

    // Already processed?
    if (topUp.status !== "pending") {
      throw new Error("TopUp already processed or not pending");
    }

    // Expired?
    if (topUp.expiresAt && topUp.expiresAt.toMillis() <= Date.now()) {
      throw new Error("TopUp expired. Cannot approve.");
    }

    const txRef = db.collection("walletTransactions").doc(topUp.transactionId);
    const walletRef = db.collection("wallets").doc(topUp.walletId);

    const txSnap = await trx.get(txRef);
    const walletSnap = await trx.get(walletRef);

    if (!txSnap.exists) throw new Error("Transaction missing");
    if (!walletSnap.exists) throw new Error("Wallet missing");

    const tx = txSnap.data()!;
    const balance = walletSnap.data()!.balance;

    // Transaction already applied?
    if (tx.status !== "pending")
      throw new Error("Transaction already processed");

    // CREDIT MONEY
    trx.update(walletRef, {
      balance: balance + tx.amount,
      updatedAt: Timestamp.now(),
    });

    trx.update(txRef, {
      status: "confirmed",
      updatedAt: Timestamp.now(),
    });

    trx.update(topRef, {
      status: "approved",
      updatedAt: Timestamp.now(),
    });
  });

  return { success: true };
});
