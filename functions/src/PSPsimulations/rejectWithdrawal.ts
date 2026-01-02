import { onCall } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();
const db = getFirestore();

export const rejectWithdrawal = onCall(async (req) => {
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

    const userRef = db.collection("wallets").doc(data.userWalletId);
    const holdingRef = db.collection("wallets").doc(data.holdingWalletId);

    const userSnap = await trx.get(userRef);
    const holdingSnap = await trx.get(holdingRef);

    const userBal = userSnap.data()!.balance;
    const holdingBal = holdingSnap.data()!.balance;

    if (holdingBal < data.amount)
      throw new Error("Holding wallet inconsistent!");

    trx.update(userRef, {
      balance: userBal + data.amount,
      updatedAt: Timestamp.now(),
    });

    trx.update(holdingRef, {
      balance: holdingBal - data.amount,
      updatedAt: Timestamp.now(),
    });

    const txRef = db.collection("walletTransactions").doc();
    trx.set(txRef, {
      fromWalletId: data.holdingWalletId,
      toWalletId: data.userWalletId,
      amount: data.amount,
      purpose: "WITHDRAWAL_REJECT_RETURN",
      status: "confirmed",
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    });

    trx.update(wRef, {
      status: "rejected",
      updatedAt: Timestamp.now(),
    });
  });

  return { success: true };
});

