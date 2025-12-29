import { onCall } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

export const markInvoicePaid = onCall(async (request) => {
  const data = request.data;

  const referenceNumber = data?.referenceNumber;
  if (!referenceNumber) throw new Error("referenceNumber required");

  const db = getFirestore();

  const snap = await db
    .collection("paymentInvoices")
    .where("referenceNumber", "==", referenceNumber)
    .limit(1)
    .get();

  if (snap.empty) throw new Error("Invoice not found");

  const doc = snap.docs[0];
  const invoice = doc.data();

  if (invoice.status === "PAID") {
    return { message: "Already paid" };
  }

  const walletRef = db.collection("wallets").doc(invoice.uid);

  await db.runTransaction(async (tx) => {
    const walletDoc = await tx.get(walletRef);
    const currentBalance = walletDoc.exists
      ? walletDoc.data()?.balance || 0
      : 0;

    tx.set(
      walletRef,
      {
        uid: invoice.uid,
        balance: currentBalance + invoice.amount,
        updatedAt: Timestamp.now(),
      },
      { merge: true }
    );

    tx.set(db.collection("transactions").doc(), {
      uid: invoice.uid,
      type: "TOPUP",
      method: invoice.method,
      amount: invoice.amount,
      referenceNumber,
      invoiceId: invoice.invoiceId,
      status: "SUCCESS",
      createdAt: Timestamp.now(),
    });

    tx.update(doc.ref, { status: "PAID" });
  });

  return { success: true };
});
