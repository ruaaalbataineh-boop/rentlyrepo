import { onCall } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

export const submitItemForApproval = onCall(async (request) => {
  const ownerId = request.auth?.uid;
  if (!ownerId) throw new Error("Not authenticated");

  const data = request.data;
  const db = getFirestore();

  // Get user profile
  const userDoc = await db.collection("users").doc(ownerId).get();
  const user = userDoc.exists ? userDoc.data() : null;

  let ownerName = "Unknown User";

  if (user) {
    const first = user.firstName ?? user.firstname ?? "";
    const last = user.lastName ?? user.lastname ?? "";

    if (first || last) {
      ownerName = `${first} ${last}`.trim();
    }
  }

  const ref = db.collection("pending_items").doc();
  const itemId = ref.id;

  await ref.set({
    itemId,
    ownerId,
    ownerName,
    name: data.name,
    description: data.description ?? "",
    category: data.category,
    subCategory: data.subCategory,

    images: Array.isArray(data.images) ? data.images : [],
    rentalPeriods: data.rentalPeriods ?? {},

    insurance: data.insurance ?? {},

    // store location
    latitude: data.latitude ?? null,
    longitude: data.longitude ?? null,

    status: "pending",
    submittedAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  });

  return { success: true, itemId };
});
