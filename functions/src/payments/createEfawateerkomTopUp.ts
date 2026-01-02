import { onCall } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();
const db = getFirestore();

function generateReferenceNumber() {
  // 10-digit reference number
  return Math.floor(1000000000 + Math.random() * 9000000000).toString();
}

export const createEfawateerkomTopUp = onCall(async (req) => {
  const { userId, walletId, amount } = req.data;

  if (!userId || !walletId || !amount) throw new Error("Missing data");
  if (amount <= 0) throw new Error("Amount must be > 0");

  const walletRef = db.collection("wallets").doc(walletId);
  const walletSnap = await walletRef.get();
  if (!walletSnap.exists) throw new Error("Wallet not found");

  if (walletSnap.data()!.type !== "USER")
    throw new Error("Efawateerkom topups allowed only for USER wallets");

  const referenceNumber = generateReferenceNumber();
  const expiresAt = Timestamp.fromMillis(Date.now() + 24 * 60 * 60 * 1000); // 24h

  // create pending wallet transaction
  const txRef = db.collection("walletTransactions").doc();
  await txRef.set({
    fromWalletId: null,
    toWalletId: walletId,
    amount,
    purpose: "TOPUP_EFAWATEERKOM",
    referenceId: referenceNumber,
    status: "pending",
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
    expiresAt,
  });

  // topUp request
  const topRef = db.collection("topUpRequests").doc();
  await topRef.set({
    userId,
    walletId,
    amount,
    referenceNumber,
    status: "pending",
    transactionId: txRef.id,
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
    expiresAt,
  });

  return {
    topUpId: topRef.id,
    transactionId: txRef.id,
    referenceNumber,
    amount,
  };
});
