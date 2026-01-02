import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();
const db = getFirestore();

export const expireWithdrawals = onSchedule("every 5 minutes", async () => {
  const now = Timestamp.now();

  const snap = await db.collection("withdrawalRequests")
    .where("status", "==", "pending")
    .where("expiresAt", "<=", now)
    .get();

  if (snap.empty) return;

  for (const doc of snap.docs) {
    const data = doc.data();

    const userRef = db.collection("wallets").doc(data.userWalletId);
    const holdingRef = db.collection("wallets").doc(data.holdingWalletId);

    await db.runTransaction(async (trx) => {
      const userSnap = await trx.get(userRef);
      const holdingSnap = await trx.get(holdingRef);

      if (!userSnap.exists || !holdingSnap.exists) return;

      const userBal = userSnap.data()!.balance;
      const holdingBal = holdingSnap.data()!.balance;

      if (holdingBal < data.amount) return;

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
        purpose: "WITHDRAWAL_EXPIRED_RETURN",
        status: "confirmed",
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      });

      trx.update(doc.ref, {
        status: "expired",
        updatedAt: Timestamp.now(),
      });
    });
  }
});
