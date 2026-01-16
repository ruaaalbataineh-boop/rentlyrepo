import * as admin from "firebase-admin";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";

export const notifyUserOnRentalDecision = onDocumentUpdated(
  {
    document: "rentalRequests/{requestId}",
    region: "asia-southeast1",
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const requestId = event.params.requestId;

    if (!before || !after) return;

    const oldStatus = before.status;
    const newStatus = after.status;

    // نهتم فقط بالتغيير من pending → accepted / rejected
    if (oldStatus === newStatus) return;
    if (oldStatus !== "pending") return;
    if (newStatus !== "accepted" && newStatus !== "rejected") return;

    const userUid = after.renterUid;
    const itemTitle = after.itemTitle ?? "Item";

    if (!userUid) return;

    // get user FCM token
    const tokenSnap = await admin
      .database()
      .ref(`users/${userUid}/fcmToken`)
      .get();

    if (!tokenSnap.exists()) {
      console.log("No FCM token for user:", userUid);
      return;
    }

    const fcmToken = tokenSnap.val();

    const title =
      newStatus === "accepted"
        ? "Rental Approved ✅"
        : "Rental Rejected ❌";

    const body =
      newStatus === "accepted"
        ? `Your rental request for "${itemTitle}" was approved`
        : `Your rental request for "${itemTitle}" was rejected`;

    await admin.messaging().send({
      token: fcmToken,
      android: { priority: "high" },
      notification: { title, body },
    data: {
  type: "rental_decision",
  status: newStatus, // "accepted" | "rejected"
  title:
    newStatus === "accepted"
      ? "Order accepted"
      : "Order rejected",
  message:
    newStatus === "accepted"
      ? `Your rental request for "${itemTitle}" was accepted`
      : `Your rental request for "${itemTitle}" was rejected`,
  requestId: requestId,
      },
    });

    console.log(
      `Rental decision (${newStatus}) notification sent to user:`,
      userUid
    );
  }
);
