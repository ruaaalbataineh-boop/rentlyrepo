import { onCall } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();
const db = getFirestore();

export const createTransaction = onCall(async (req) => {
  const { fromWalletId, toWalletId, amount, purpose, referenceId } = req.data;

  if (!amount || amount <= 0) throw new Error("Amount must be > 0");

  const txRef = db.collection("walletTransactions").doc();

  const txData = {
    fromWalletId: fromWalletId ?? null,
    toWalletId: toWalletId ?? null,
    amount,
    purpose,
    referenceId: referenceId ?? null,
    status: "pending",
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  };

  await txRef.set(txData);

  return { transactionId: txRef.id, ...txData };
});
