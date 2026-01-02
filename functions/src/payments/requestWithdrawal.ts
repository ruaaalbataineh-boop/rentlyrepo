import { onCall } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();
const db = getFirestore();

export const requestWithdrawal = onCall(async (req) => {
  const {
    userId,
    userWalletId,
    holdingWalletId,
    amount,
    method,

    iban,
    bankName,
    accountHolderName,

    pickupName,
    pickupPhone,
    pickupIdNumber
  } = req.data;

  if (!userId || !userWalletId || !holdingWalletId || !amount || !method)
    throw new Error("Missing required fields");

  if (amount <= 0) throw new Error("Amount must be > 0");
  if (!["bank", "exchange"].includes(method))
    throw new Error("Invalid withdrawal method");

  // BANK VALIDATION
  if (method === "bank") {
    if (!iban || !bankName || !accountHolderName)
      throw new Error("Bank withdrawal requires IBAN, bankName, accountHolderName");
  }

  // EXCHANGE VALIDATION
  let referenceNumber = null;
  if (method === "exchange") {
    if (!pickupName || !pickupPhone || !pickupIdNumber)
      throw new Error("Exchange withdrawal requires pickupName, pickupPhone and pickupIdNumber");

    referenceNumber = Math.floor(1000000000 + Math.random() * 9000000000).toString();
  }

  // Expiry (bank 24h, exchange 48h)
  const expiresAt = Timestamp.fromMillis(
    Date.now() + (method === "exchange" ? 48 : 24) * 60 * 60 * 1000
  );

  const userRef = db.collection("wallets").doc(userWalletId);
  const holdingRef = db.collection("wallets").doc(holdingWalletId);

  const userSnap = await userRef.get();
  if (!userSnap.exists) throw new Error("User wallet not found");

  const balance = userSnap.data()!.balance;
  if (balance < amount) throw new Error("Insufficient balance");

  const wRef = db.collection("withdrawalRequests").doc();
  const txRef = db.collection("walletTransactions").doc();

  await db.runTransaction(async (trx) => {
    const holdingSnap = await trx.get(holdingRef);
    if (!holdingSnap.exists) throw new Error("Holding wallet missing");

    trx.update(userRef, {
      balance: balance - amount,
      updatedAt: Timestamp.now(),
    });

    trx.update(holdingRef, {
      balance: holdingSnap.data()!.balance + amount,
      updatedAt: Timestamp.now(),
    });

    trx.set(txRef, {
      fromWalletId: userWalletId,
      toWalletId: holdingWalletId,
      amount,
      purpose: "WITHDRAWAL_HOLD",
      status: "confirmed",
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    });

    trx.set(wRef, {
      userId,
      userWalletId,
      holdingWalletId,
      amount,
      method,

      iban: iban ?? null,
      bankName: bankName ?? null,
      accountHolderName: accountHolderName ?? null,

      referenceNumber,
      pickupName: pickupName ?? null,
      pickupPhone: pickupPhone ?? null,
      pickupIdNumber: pickupIdNumber ?? null,

      status: "pending",
      transaction_hold_id: txRef.id,
      expiresAt,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    });
  });

  return { success: true, withdrawalId: wRef.id, referenceNumber };
});
