import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

export const rejectItem = onCall(async (request) => {
  const itemId = request.data.itemId;
  if (!itemId) throw new Error("Missing itemId");

  const db = admin.firestore();
  const pendingRef = db.collection("pending_items").doc(itemId);

  const snap = await pendingRef.get();
  if (!snap.exists) throw new Error("Pending item not found");

  const data = snap.data()!;
  const ownerId = data.ownerId;

  await pendingRef.update({
    status: "rejected",
    reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Notification saved 
  await db.collection("notifications").add({
    senderId: "ADMIN",
    receiverId: ownerId,
    type: "ITEM_REJECTED",
    itemId: itemId,
    title: "Item Rejected",
    body: "Your item has been rejected ❌",
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  //   FCM POPUP 
  const userSnap = await db.collection("users").doc(ownerId).get();
  const fcmToken = userSnap.data()?.fcmToken;

  if (fcmToken) {
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: "Item Rejected",
        body: "Your item has been rejected ❌",
      },
      data: {
        type: "ITEM_REJECTED",
        itemId: itemId,
      },
    });
  }

  return { success: true };
});
 
