/**
 * Firebase Functions v2 entry file
 * --------------------------------
 * Uses v2 onCall / onRequest syntax
 */

import * as admin from "firebase-admin";

admin.initializeApp();

export { submitUserForApproval } from "./users/submitUserForApproval";
export { approveUser } from "./users/approveUser";
export { rejectUser } from "./users/rejectUser";

export { submitItemForApproval } from "./items/submitItemForApproval";
export { approveItem } from "./items/approveItem";
export { rejectItem } from "./items/rejectItem";

export { notifyUserOnRentalDecision } from "./notifications/notifyUserOnRentalDecision";


export { createRentalRequest } from "./rentals/createRentalRequest";
export { updateRentalRequestStatus } from "./rentals/updateRentalRequestStatus";
export { confirmPickup } from "./rentals/confirmPickup";
export { confirmReturn } from "./rentals/confirmReturn";
export { autoExpirePendingRentals } from "./rentals/autoExpirePendingRentals";
export { autoNoShowRentals } from "./rentals/autoNoShowRentals";
export { autoNeverReturned } from "./rentals/autoNeverReturned";

import { onValueCreated } from "firebase-functions/v2/database";
import { onDocumentCreated } from "firebase-functions/v2/firestore";

export { createAdminWallet } from "./wallets/createAdminWallet";
export { getWallet } from "./wallets/getWallet";
export { getUserWallets } from "./wallets/getUserWallets";

export { createTransaction } from "./payments/createTransaction";
export { confirmTransaction } from "./payments/confirmTransaction";
export { failTransaction } from "./payments/failTransaction";

export { createEfawateerkomTopUp } from "./payments/createEfawateerkomTopUp";
export { createStripeTopUp } from "./payments/createStripeTopUp";
export { stripeWebhook } from "./payments/stripeWebhook";
export { expireTopUps } from "./payments/expireTopUps";
export { approveEfawateerkomTopUp } from "./PSPsimulations/approveEfawateerkomTopUp";
export { rejectEfawateerkomTopUp } from "./PSPsimulations/rejectEfawateerkomTopUp";

export { requestWithdrawal } from "./payments/requestWithdrawal";
export { approveWithdrawal } from "./PSPsimulations/approveWithdrawal";
export { rejectWithdrawal } from "./PSPsimulations/rejectWithdrawal";
export { expireWithdrawals } from "./payments/expireWithdrawals";

export { submitIssueReport } from "./issueReports/submitIssueReport";
export { approveIssueReport } from "./issueReports/approveIssueReport";

export { submitReview } from "./reviews/submitReview";



// req notif

export const notifyOwnerOnNewRentalRequest = onDocumentCreated(
  {
    document: "rentalRequests/{requestId}",
    region: "asia-southeast1",
  },
  async (event) => {
    const req = event.data?.data();
    const requestId = event.params.requestId;

    if (!req) return;

    const ownerUid = req.itemOwnerUid;
    const itemTitle = req.itemTitle ?? "Item";

    if (!ownerUid) {
      console.log("Missing itemOwnerUid on request:", requestId);
      return;
    }

    const tokenSnap = await admin
      .database()
      .ref(`users/${ownerUid}/fcmToken`)
      .get();

    if (!tokenSnap.exists()) {
      console.log("No FCM token for owner:", ownerUid);
      return;
    }

    const fcmToken = tokenSnap.val();

    await admin.messaging().send({
      token: fcmToken,
      android: { priority: "high" },
      notification: {
        title: "New Rental Request",
        body: `You have a new request for "${itemTitle}"`,
      },
      data: {
        type: "rental_request",
        title: "New rental request",
        message: `Request for "${itemTitle}"`,
        requestId: requestId,
      },
    });

    console.log("Rental request notification sent to owner:", ownerUid);
  }
);






/*                            CHAT USER to USER                             */


export const testOnNewMessage = onValueCreated(
    {
        ref: "/messages/{chatId}/{messageId}",
        instance: "p22rently-default-rtdb",
        region: "asia-southeast1",
    },
    async (event) => {
        const message = event.data.val();
        const chatId = event.params.chatId;

        if (!message) return;

        const senderId = message.sender;
        // 🔹 get sender name from Realtime Database
const senderSnap = await admin
  .database()
  .ref(`users/${senderId}/name`)
  .get();

const senderName = senderSnap.exists()
  ? senderSnap.val()
  : "";

        const text = message.text ?? "New message";

        // chatId = user1-user2
        const [user1, user2] = chatId.split("-");

        const receiverId = senderId === user1 ? user2 : user1;

        // get receiver fcm token
        const tokenSnap = await admin
            .database()
            .ref(`users/${receiverId}/fcmToken`)
            .get();

        if (!tokenSnap.exists()) {
            console.log(" No FCM token for user:", receiverId);
            return;
        }

        const fcmToken = tokenSnap.val();

       await admin.messaging().send({
        token: fcmToken,
        android: {
         priority: "high",
        },
        data: {
            type: "chat",
            chatId: chatId,
            senderUid: senderId,
            senderName: senderName, // ✅ مهم
            messageText: text,                         // ✅ أهم سطر
        },
        });


        console.log(" Notification sent to:", receiverId);
    }
);


/*                     USER to  ADMIN                   */


export const notifyAdminOnNewItem = onDocumentCreated(
    {
        document: "pending_items/{itemId}",
        region: "asia-southeast1",
    },
    async (event) => {
        const item = event.data?.data();
        const itemId = event.params.itemId;

        if (!item) return;

        const ownerId = item.ownerId;

        const ADMIN_UID = "m3B5iwPzb3N8EffKu0PsLnpb93k2";

        //  Save notification 
        await admin.firestore().collection("notifications").add({
            senderId: ownerId,
            receiverId: ADMIN_UID,
            type: "NEW_ITEM",
            itemId: itemId,
            title: "New item pending approval",
            body: "A new item was submitted and needs review",
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        //  POPUP NOTIFICATION 
        await admin.messaging().send({
            topic: "admin",
            notification: {
                title: "New Item Pending Approval",
                body: item.name
                    ? `Item "${item.name}" needs your review`
                    : "A new item needs your review",
            },
            data: {
                type: "NEW_ITEM",
                itemId: itemId,
            },
        });

        console.log(" Admin notified (Firestore + FCM popup):", itemId);
    }
);
