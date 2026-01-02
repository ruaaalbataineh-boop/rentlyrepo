import { onCall } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();
const db = getFirestore();

export const approveWithdrawal = onCall(async (req) => {
  const { withdrawalId } = req.data;
  if (!withdrawalId) throw new Error("Missing withdrawalId");

  const wRef = db.collection("withdrawalRequests").doc(withdrawalId);

  await db.runTransaction(async (trx) => {
    const snap = await trx.get(wRef);
    if (!snap.exists) throw new Error("Withdrawal not found");

    const data = snap.data()!;

    if (data.status !== "pending")
      throw new Error("Already processed");

    if (data.expiresAt && data.expiresAt.toMillis() <= Date.now())
      throw new Error("Withdrawal expired");

    const holdingRef = db.collection("wallets").doc(data.holdingWalletId);
    const holdingSnap = await trx.get(holdingRef);
    if (!holdingSnap.exists) throw new Error("Holding wallet missing");

    const holdingBal = holdingSnap.data()!.balance;
    if (holdingBal < data.amount)
      throw new Error("Holding wallet inconsistent");

    // Deduct from holding
    trx.update(holdingRef, {
      balance: holdingBal - data.amount,
      updatedAt: Timestamp.now(),
    });

    const txRef = db.collection("walletTransactions").doc();
    trx.set(txRef, {
      fromWalletId: data.holdingWalletId,
      toWalletId: null,
      amount: data.amount,
      purpose: data.method === "exchange"
        ? "WITHDRAWAL_PAYOUT_EXCHANGE"
        : "WITHDRAWAL_PAYOUT_BANK",
      status: "confirmed",
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    });

    trx.update(wRef, {
      status: "approved",
      transaction_payout_id: txRef.id,
      updatedAt: Timestamp.now(),
    });
  });

  return { success: true };
});
