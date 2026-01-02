import { onCall } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();
const db = getFirestore();

export const getWallet = onCall(async (req) => {
  const { walletId } = req.data;

  const doc = await db.collection("wallets").doc(walletId).get();
  if (!doc.exists) throw new Error("Wallet not found");

  return doc.data();
});
