import { onCall } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

export const approveUser = onCall(async (request) => {

  const uid = request.data?.uid;
  if (!uid) {
    throw new Error("Missing uid.");
  }

  const db = getFirestore();

  const pendingRef = db.collection("pending_users").doc(uid);
  const pendingSnap = await pendingRef.get();

  if (!pendingSnap.exists) {
    throw new Error("Pending user not found.");
  }

  const pendingUserData = pendingSnap.data()!;

  await db.collection("users").doc(uid).set({
    uid: uid,
    email: pendingUserData.email,
    firstName: pendingUserData.firstName,
    lastName: pendingUserData.lastName,
    phone: pendingUserData.phone,
    birthDate: pendingUserData.birthDate,
    status: "approved",
    approvedAt: Timestamp.now(),
  });

  await pendingRef.update({
    status: "approved",
    approvedAt: Timestamp.now(),
  });

  const batch = db.batch();

  // Create USER wallet
  const walletsRef = db.collection("wallets");
  const userWalletRef = walletsRef.doc();
  batch.set(userWalletRef, {
    userId: uid,
    type: "USER",
    balance: 0,
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  });

  // Create HOLDING wallet
  const holdingWalletRef = walletsRef.doc();
  batch.set(holdingWalletRef, {
    userId: uid,
    type: "HOLDING",
    balance: 0,
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  });

  await batch.commit();

  return { success: true };
});
