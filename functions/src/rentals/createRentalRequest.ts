import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

export const createRentalRequest = onCall(async (request) => {
  const renterUid = request.auth?.uid;
  if (!renterUid) {
    throw new HttpsError("unauthenticated", "Not authenticated.");
  }

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

  const db = getFirestore();

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

  const newStart = new Date(data.startDate);
  const newEnd = new Date(data.endDate);

  if (newEnd <= newStart) {
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
    const existingStart = new Date(existing.startDate);
    const existingEnd = new Date(existing.endDate);

    if (newStart < existingEnd && newEnd > existingStart) {
      throw new HttpsError(
        "failed-precondition",
        "This item is already rented for the selected time period."
      );
    }
  }

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
    createdAt: FieldValue.serverTimestamp(),
  });

  return { success: true };
});