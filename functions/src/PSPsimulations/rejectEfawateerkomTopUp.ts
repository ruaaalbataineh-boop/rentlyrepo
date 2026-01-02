import { onCall } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();
const db = getFirestore();

export const rejectEfawateerkomTopUp = onCall(async (req) => {
  const { topUpId } = req.data;
  if (!topUpId) throw new Error("Missing topUpId");

  const topRef = db.collection("topUpRequests").doc(topUpId);
  const topSnap = await topRef.get();
  if (!topSnap.exists) throw new Error("TopUp not found");

  const topUp = topSnap.data()!;

  // already resolved?
  if (topUp.status !== "pending") {
    throw new Error("TopUp already processed. Cannot reject.");
  }

  const txRef = db.collection("walletTransactions").doc(topUp.transactionId);

  await Promise.all([
    topRef.update({
      status: "rejected",
      updatedAt: Timestamp.now(),
    }),
    txRef.update({
      status: "failed",
      updatedAt: Timestamp.now(),
    }),
  ]);

  return { success: true };
});
