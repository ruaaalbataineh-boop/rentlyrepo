import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import Stripe from "stripe";
import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();

const STRIPE_SECRET_KEY = defineSecret("STRIPE_SECRET_KEY");
const STRIPE_WEBHOOK_SECRET = defineSecret("STRIPE_WEBHOOK_SECRET");

export const stripeWebhook = onRequest(
  {
    region: "us-central1",
    secrets: [STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET],
  },
  async (req, res): Promise<void> => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const stripe = new Stripe(STRIPE_SECRET_KEY.value());
    const signature = req.headers["stripe-signature"];

    if (!signature) {
      res.status(400).send("Missing Stripe signature");
      return;
    }

    let event: Stripe.Event;

    try {
      event = stripe.webhooks.constructEvent(
        req.rawBody,
        signature,
        STRIPE_WEBHOOK_SECRET.value()
      );
    } catch (err: any) {
      console.error("Invalid webhook signature", err.message);
      res.status(400).send(`Webhook Error: ${err.message}`);
      return;
    }

    // SUCCESS
    if (event.type === "payment_intent.succeeded") {
      const pi = event.data.object as Stripe.PaymentIntent;
      const referenceNumber = pi.metadata?.referenceNumber;
      const uid = pi.metadata?.userId;
      const amount = pi.amount_received / 100;

      if (!referenceNumber || !uid) {
        console.error("Missing metadata");
        res.status(200).send("ok");
        return;
      }

      const db = admin.firestore();

      const snap = await db
        .collection("paymentInvoices")
        .where("referenceNumber", "==", referenceNumber)
        .limit(1)
        .get();

      if (snap.empty) {
        console.error("Invoice not found");
        res.status(200).send("ok");
        return;
      }

      const doc = snap.docs[0];

      if (doc.data().status === "PAID") {
        res.status(200).send("ok");
        return;
      }

      const walletRef = db.collection("wallets").doc(uid);

      await db.runTransaction(async (tx) => {
        const walletDoc = await tx.get(walletRef);
        const currentBalance = walletDoc.exists
          ? walletDoc.data()?.balance || 0
          : 0;

        tx.set(
          walletRef,
          {
            uid,
            balance: currentBalance + amount,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

        tx.update(doc.ref, {
          status: "PAID",
          paidAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        tx.set(db.collection("transactions").doc(), {
          uid,
          type: "TOPUP",
          method: "credit_card",
          amount,
          referenceNumber,
          invoiceId: doc.id,
          status: "SUCCESS",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      res.status(200).send("ok");
      return;
    }

    // FAILED
    if (event.type === "payment_intent.payment_failed") {
      const pi = event.data.object as Stripe.PaymentIntent;
      const userId = pi.metadata?.userId;

      if (userId) {
        await admin.firestore().collection("wallet_recharges").add({
          userId,
          status: "failed",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }

    res.status(200).send("ok");
  }
);
