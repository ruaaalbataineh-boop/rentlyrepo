import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

export const approveItem = onCall(async (request) => {
  const itemId = request.data.itemId;
  if (!itemId) throw new Error("Missing itemId");

  const db = admin.firestore();

  const pendingRef = db.collection("pending_items").doc(itemId);
  const itemsRef = db.collection("items").doc(itemId);

  const snap = await pendingRef.get();
  if (!snap.exists) throw new Error("Pending item not found");

  const data = snap.data()!;
  const ownerId = data.ownerId;

  await itemsRef.set({
    ...data,
    status: "approved",
    approvedAt: admin.firestore.FieldValue.serverTimestamp(),
    rating: 0,
    reviews: [],
  });

  await pendingRef.update({
    status: "approved",
    reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  //  Save notification 
  await db.collection("notifications").add({
    senderId: "ADMIN",
    receiverId: ownerId,
    type: "ITEM_APPROVED",
    itemId: itemId,
    title: "Item Approved",
    body: "Your item has been approved ",
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  //   FCM Realtime Database
  const tokenSnap = await admin
    .database()
    .ref(`users/${ownerId}/fcmToken`)
    .get();

  const fcmToken = tokenSnap.val();

  if (fcmToken) {
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: "Item Approved",
        body: "Your item has been approved ",
      },
      data: {
        type: "ITEM_APPROVED",
        itemId: itemId,
      },
    });
  }

  return { success: true };
});
