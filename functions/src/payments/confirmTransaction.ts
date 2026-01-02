import { onCall } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();
const db = getFirestore();

type WalletTransactionStatus = "pending" | "confirmed" | "failed";

type WalletTransaction = {
  status: WalletTransactionStatus;
  fromWalletId?: string | null;
  toWalletId?: string | null;
  amount: number;
};

export const confirmTransaction = onCall(async (req) => {
  const { transactionId } = req.data;

  if (!transactionId) throw new Error("Missing transactionId");

  const txRef = db.collection("walletTransactions").doc(transactionId);

  await db.runTransaction(async (trx) => {
    const txSnap = await trx.get(txRef);
    if (!txSnap.exists) throw new Error("Transaction not found");

    const tx = txSnap.data() as WalletTransaction;

    if (!tx) throw new Error("Transaction data missing");
    if (tx.status !== "pending")
      throw new Error("Transaction already processed");

    if (typeof tx.amount !== "number" || tx.amount <= 0)
      throw new Error("Invalid transaction amount");

    const { fromWalletId, toWalletId, amount } = tx;

    // Deduct from source wallet
    if (fromWalletId) {
      const fromRef = db.collection("wallets").doc(fromWalletId);
      const fromSnap = await trx.get(fromRef);

      if (!fromSnap.exists) throw new Error("From wallet not found");

      const fromData = fromSnap.data();
      if (!fromData) throw new Error("From wallet data missing");

      const fromBalance = fromData.balance ?? 0;

      if (fromBalance < amount)
        throw new Error("Insufficient balance in source wallet");

      trx.update(fromRef, {
        balance: fromBalance - amount,
        updatedAt: Timestamp.now(),
      });
    }

    // Credit to destination wallet
    if (toWalletId) {
      const toRef = db.collection("wallets").doc(toWalletId);
      const toSnap = await trx.get(toRef);

      if (!toSnap.exists) throw new Error("To wallet not found");

      const toData = toSnap.data();
      if (!toData) throw new Error("To wallet data missing");

      const toBalance = toData.balance ?? 0;

      trx.update(toRef, {
        balance: toBalance + amount,
        updatedAt: Timestamp.now(),
      });
    }

    // Mark transaction confirmed
    trx.update(txRef, {
      status: "confirmed",
      updatedAt: Timestamp.now(),
    });
  });

  return { success: true };
});
