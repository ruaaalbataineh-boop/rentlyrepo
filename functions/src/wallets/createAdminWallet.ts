import { onCall } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();
const db = getFirestore();

export const createAdminWallet = onCall(async () => {
  const existing = await db
    .collection("wallets")
    .where("type", "==", "ADMIN")
    .limit(1)
    .get();

  if (!existing.empty) return { message: "Admin wallet already exists" };

  const walletRef = db.collection("wallets").doc();

  const walletData = {
    userId: null,
    type: "ADMIN",
    balance: 0,
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  };

  await walletRef.set(walletData);

  return { walletId: walletRef.id, ...walletData };
});
