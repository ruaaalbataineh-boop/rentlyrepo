import { onCall } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { defineSecret } from "firebase-functions/params";
import Stripe from "stripe";

const STRIPE_SECRET_KEY = defineSecret("STRIPE_SECRET_KEY");

export const createInvoice = onCall(
    {
        region: "us-central1",
        secrets: [STRIPE_SECRET_KEY],
      },
  async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new Error("User must be logged in.");

  const data = request.data;

  const amount = data?.amount;
  const method = data?.method;

  if (!amount || amount <= 0) {
    throw new Error("Invalid amount");
  }

  if (!["credit_card", "efawateercom"].includes(method)) {
    throw new Error("Invalid payment method");
  }

  const db = getFirestore();

  const invoiceRef = db.collection("paymentInvoices").doc();

  const referenceNumber =
    "INV" + Math.floor(10000000 + Math.random() * 90000000);

  const invoice = {
    invoiceId: invoiceRef.id,
    uid,
    amount,
    method,
    referenceNumber,
    status: "PENDING",
    createdAt: Timestamp.now(),
  };

  await invoiceRef.set(invoice);

  if (method === "credit_card") {
        const stripe = new Stripe(STRIPE_SECRET_KEY.value());

        const paymentIntent = await stripe.paymentIntents.create({
          amount: Math.round(amount * 100), // USD cents
          currency: "usd",
          metadata: {
            userId: uid,
            referenceNumber,
          },
          automatic_payment_methods: { enabled: true },
        });

        return {
          ...invoice,
          clientSecret: paymentIntent.client_secret,
        };
      }

  return invoice;
});
