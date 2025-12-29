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

export { createRentalRequest } from "./rentals/createRentalRequest";
export { updateRentalRequestStatus } from "./rentals/updateRentalRequestStatus";

import { onValueCreated } from "firebase-functions/v2/database";
import { onDocumentCreated } from "firebase-functions/v2/firestore";

export { createInvoice } from "./payments/createInvoice";
export { markInvoicePaid } from "./payments/markInvoicePaid";

export { stripeWebhook } from "./payments/stripeWebhook";


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
            notification: {
                title: " New Message",
                body: text,
            },
            data: {
                chatId,
                senderId,
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
