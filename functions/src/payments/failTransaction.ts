import { onCall } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();
const db = getFirestore();

export const failTransaction = onCall(async (req) => {
  const { transactionId } = req.data;

  const txRef = db.collection("walletTransactions").doc(transactionId);

  await txRef.update({
    status: "failed",
    updatedAt: Timestamp.now(),
  });

  return { success: true };
});
