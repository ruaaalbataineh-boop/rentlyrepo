import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();
const db = getFirestore();

export const createRentalRequest = onCall(async (request) => {
  const renterUid = request.auth?.uid;
  if (!renterUid)
    throw new HttpsError("unauthenticated", "Not authenticated.");

  const data = request.data;

  const required = [
    "itemId",
    "itemTitle",
    "itemOwnerUid",
    "ownerName",
    "rentalType",
    "rentalQuantity",
    "startDate",
    "endDate",
    "pickupTime",
    "rentalPrice",
    "totalPrice",
    "insurance",
    "penalty",
  ];

  for (const k of required) {
      if (data[k] === undefined || data[k] === null) {
        throw new HttpsError(
            "invalid-argument",
            `Missing field: ${k}`);
      }
  }

  // Get user profile
  const userDoc = await db.collection("users").doc(renterUid).get();
  const user = userDoc.exists ? userDoc.data() : null;

  let renterName = "Unknown User";

  if (user) {
    const first = user.firstName ?? user.firstname ?? "";
    const last = user.lastName ?? user.lastname ?? "";

    if (first || last) {
      renterName = `${first} ${last}`.trim();
    }
  }

  const fiveDays = 5 * 24 * 60 * 60 * 1000;
  const startDate = data.startDate.toMillis();
  const endDate = data.endDate.toMillis();

  if (endDate <= startDate) {
    throw new HttpsError(
      "invalid-argument",
      "Invalid rental period."
    );
  }

  const snap = await db
    .collection("rentalRequests")
    .where("itemId", "==", data.itemId)
    .where("status", "in", ["accepted", "active"])
    .where("startDate", "<", data.endDate)
    .get();

  for (const doc of snap.docs) {
    const existing = doc.data();
    const existingStart = existing.startDate.toMillis();
    const existingEnd = existing.endDate.toMillis();

    const noOverlap =
          endDate + fiveDays <= existingStart ||
          startDate - fiveDays >= existingEnd;

    if (!noOverlap) {
      throw new HttpsError(
        "failed-precondition",
        "Conflicts with another accepted rental (buffer rule)."
      )
    }

    //if (startDate < existingEnd && endDate > existingStart) {
    //  throw new HttpsError(
    //    "failed-precondition",
    //    "This item is already rented for the selected time period."
    //  );
    //}
  }

  return await db.runTransaction(async (trx) => {
      // Get wallets
      const walletsRef = db.collection("wallets");

      const userWalletSnap = await trx.get(
        walletsRef.where("userId","==", renterUid).where("type","==","USER").limit(1)
      );

      const holdingWalletSnap = await trx.get(
        walletsRef.where("userId","==", renterUid).where("type","==","HOLDING").limit(1)
      );

      if (userWalletSnap.empty || holdingWalletSnap.empty)
        throw new HttpsError("failed-precondition","Wallets not found");

      const userWallet = userWalletSnap.docs[0];
      const holdingWallet = holdingWalletSnap.docs[0];

      const userBalance = userWallet.data().balance || 0;
      const total = Number(data.totalPrice);

      if (userBalance < total)
        throw new HttpsError("failed-precondition","Insufficient wallet balance");

      // Move Money
      trx.update(userWallet.ref, {
        balance: userBalance - total,
        updatedAt: FieldValue.serverTimestamp(),
      });

      trx.update(holdingWallet.ref, {
        balance: (holdingWallet.data().balance || 0) + total,
        updatedAt: FieldValue.serverTimestamp(),
      });

      const txRef = db.collection("walletTransactions").doc();
      trx.set(txRef, {
        userId: renterUid,
        fromWalletId: userWallet.id,
        toWalletId: holdingWallet.id,
        amount: total,
        purpose: "RENTAL_LOCK",
        status: "confirmed",
        createdAt: FieldValue.serverTimestamp(),
      });

      await db.collection("rentalRequests").add({
          itemId: data.itemId,
          itemTitle: data.itemTitle,

          itemOwnerUid: data.itemOwnerUid,
          ownerName: data.ownerName ?? null,

          renterUid,
          renterName,

          rentalType: data.rentalType,
          rentalQuantity: data.rentalQuantity,

          startDate: data.startDate,
          endDate: data.endDate,
          startTime: data.startTime ?? null,
          endTime: data.endTime ?? null,
          pickupTime: data.pickupTime,

          rentalPrice: data.rentalPrice,
          totalPrice: data.totalPrice,

          insurance: {
              itemOriginalPrice: data.insurance.itemOriginalPrice,
              ratePercentage: data.insurance.ratePercentage,
              amount: data.insurance.amount,
              accepted: data.insurance.accepted,
          },

          penalty: {
              hourlyRate: data.penalty.hourlyRate,
              dailyRate: data.penalty.dailyRate,
              maxHours: data.penalty.maxHours,
              maxDays: data.penalty.maxDays,
          },

          status: "pending",
          paymentStatus: "locked",
          createdAt: FieldValue.serverTimestamp(),
        });

    return { success: true };
  });
});