import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

export const createRentalRequest = onCall(async (request) => {
  const customerUid = request.auth?.uid;
  if (!customerUid) {
    throw new HttpsError("unauthenticated", "Not authenticated.");
  }

  const data = request.data;

  const required = [
    "itemId",
    "itemTitle",
    "itemOwnerUid",
    "rentalType",
    "rentalQuantity",
    "startDate",
    "endDate",
    "pickupTime",
    "totalPrice",
  ];

  for (const k of required) {
    if (!data[k]) {
      throw new HttpsError(
        "invalid-argument",
        `Missing field: ${k}`
      );
    }
  }

  const db = getFirestore();

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

    const overlaps =
      newStart < existingEnd && newEnd > existingStart;

    if (overlaps) {
      throw new HttpsError(
        "failed-precondition",
        "This item is already rented for the selected time period."
      );
    }
  }

  await db.collection("rentalRequests").add({
    ...data,
    customerUid,
    status: "pending",
    createdAt: FieldValue.serverTimestamp(),
  });

  return { success: true };
});
