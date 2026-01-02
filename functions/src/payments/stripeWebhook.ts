import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import Stripe from "stripe";

import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();
const db = getFirestore();

const STRIPE_SECRET_KEY = defineSecret("STRIPE_SECRET_KEY");
const STRIPE_WEBHOOK_SECRET = defineSecret("STRIPE_WEBHOOK_SECRET");

export const stripeWebhook = onRequest(
  {
    region: "us-central1",
    secrets: [STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET],
  },
  async (req, res) => {
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
      const paymentIntentId = pi.id;

      const snap = await db
        .collection("topUpRequests")
        .where("referenceNumber", "==", paymentIntentId)
        .limit(1)
        .get();

      if (snap.empty) {
        console.error("TopUp request not found");
        res.status(200).send("ok");
        return;
      }

      const topUpDoc = snap.docs[0];
      const topUp = topUpDoc.data();
      if (topUp.status === "approved") {
        res.status(200).send("ok");
        return;
      }

      const txRef = db.collection("walletTransactions").doc(topUp.transactionId);
      const walletRef = db.collection("wallets").doc(topUp.walletId);

      await db.runTransaction(async (t) => {
        const txSnap = await t.get(txRef);
        const walletSnap = await t.get(walletRef);

        if (!walletSnap.exists) throw new Error("Wallet missing");
        if (!txSnap.exists) throw new Error("Transaction missing");

        const walletBalance = walletSnap.data()!.balance;
        const tx = txSnap.data()!;

        if (tx.status === "confirmed") return;

        t.update(walletRef, {
          balance: walletBalance + tx.amount,
          updatedAt: Timestamp.now(),
        });

        t.update(txRef, {
          status: "confirmed",
          updatedAt: Timestamp.now(),
        });

        t.update(topUpDoc.ref, {
          status: "approved",
          updatedAt: Timestamp.now(),
        });
      });

      res.status(200).send("ok");
      return;
    }

    // FAILED
    if (event.type === "payment_intent.payment_failed") {
      const pi = event.data.object as Stripe.PaymentIntent;
      const paymentIntentId = pi.id;

      const snap = await db
        .collection("topUpRequests")
        .where("referenceNumber", "==", paymentIntentId)
        .limit(1)
        .get();

      if (snap.empty) {
        console.error("TopUp request not found for failed payment");
        res.status(200).send("ok");
        return;
      }

      const topUpDoc = snap.docs[0];
      const topUp = topUpDoc.data();

      // already processed?
      if (topUp.status !== "pending") {
        res.status(200).send("ok");
        return;
      }

      const txRef = db.collection("walletTransactions").doc(topUp.transactionId);

      await Promise.all([
        topUpDoc.ref.update({
          status: "rejected",
          updatedAt: Timestamp.now(),
          failureReason: pi.last_payment_error?.message ?? "Unknown failure",
        }),
        txRef.update({
          status: "failed",
          updatedAt: Timestamp.now(),
        }),
      ]);

      console.log("Stripe topup failed & marked correctly");
      res.status(200).send("ok");
      return;
    }

    res.status(200).send("ok");
  }
);
