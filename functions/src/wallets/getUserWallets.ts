import { onCall } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();
const db = getFirestore();

export const getUserWallets = onCall(async (req) => {
  const { userId } = req.data;

  const snap = await db
    .collection("wallets")
    .where("userId", "==", userId)
    .get();

  return snap.docs.map((d) => ({ walletId: d.id, ...d.data() }));
});
