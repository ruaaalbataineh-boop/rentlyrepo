import { getFirestore, Timestamp } from "firebase-admin/firestore";
import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import Stripe from "stripe";
import { defineSecret } from "firebase-functions/params";

if (!admin.apps.length) admin.initializeApp();
const db = getFirestore();

const STRIPE_SECRET_KEY = defineSecret("STRIPE_SECRET_KEY");

export const expireTopUps = onSchedule(
  "every 5 minutes",
  async () => {
    const now = Timestamp.now();

    const snap = await db.collection("topUpRequests")
      .where("status", "==", "pending")
      .where("expiresAt", "<=", now)
      .get();

    if (snap.empty) return;

    const batch = db.batch();

    const stripe = new Stripe(STRIPE_SECRET_KEY.value());

    for (const doc of snap.docs) {
      const data = doc.data();
      const txRef = db.collection("walletTransactions").doc(data.transactionId);

      // Mark as expired + failed
      batch.update(doc.ref, {
        status: "expired",
        updatedAt: Timestamp.now(),
      });

      batch.update(txRef, {
        status: "failed",
        updatedAt: Timestamp.now(),
      });

      // cancel stripe payment intent
      if (data.method === "stripe") {
        try {
          await stripe.paymentIntents.cancel(data.referenceNumber);
          console.log("Canceled expired Stripe PI:", data.referenceNumber);
        } catch (err) {
          console.error("Stripe cancel failed:", err);
        }
      }
    }

    await batch.commit();
  }
);
