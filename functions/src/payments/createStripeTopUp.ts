import { onCall } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import * as admin from "firebase-admin";
import { defineSecret } from "firebase-functions/params";
import Stripe from "stripe";

if (!admin.apps.length) admin.initializeApp();
const db = getFirestore();

const STRIPE_SECRET_KEY = defineSecret("STRIPE_SECRET_KEY");

export const createStripeTopUp = onCall(
  {
    region: "us-central1",
    secrets: [STRIPE_SECRET_KEY],
  },
  async (req) => {
    const { userId, walletId, amount } = req.data;

    if (!userId || !walletId || !amount)
      throw new Error("Missing data");

    if (amount <= 0) throw new Error("Amount must be > 0");

    const walletRef = db.collection("wallets").doc(walletId);
    const walletSnap = await walletRef.get();

    if (!walletSnap.exists) throw new Error("Wallet not found");
    if (walletSnap.data()!.type !== "USER")
      throw new Error("Stripe topups allowed only to USER wallets");

    const stripe = new Stripe(STRIPE_SECRET_KEY.value());
    const expiresAt = Timestamp.fromMillis(Date.now() + 15 * 60 * 1000); // 15 mins

    // Create Stripe PaymentIntent in JOD (JD)
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // stripe minor units
      currency: "jod",
      metadata: {
        userId,
        walletId,
      },
      automatic_payment_methods: { enabled: true },
    });

    // Create pending wallet transaction
    const txRef = db.collection("walletTransactions").doc();
    await txRef.set({
      fromWalletId: null,
      toWalletId: walletId,
      amount,
      purpose: "TOPUP_STRIPE",
      referenceId: paymentIntent.id,
      status: "pending",
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      expiresAt,
    });

    // Create top-up request
    const topUpRef = db.collection("topUpRequests").doc();
    await topUpRef.set({
      userId,
      walletId,
      amount,
      method: "stripe",
      referenceNumber: paymentIntent.id,
      status: "pending",
      transactionId: txRef.id,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      expiresAt
    });

    return {
      clientSecret: paymentIntent.client_secret,
      topUpId: topUpRef.id,
      transactionId: txRef.id,
    };
  }
);
