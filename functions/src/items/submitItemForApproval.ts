import { onCall } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

function buildSearchKeywords(text: string): string[] {
  const cleaned = text
    .toLowerCase()
    .replace(/[^a-z0-9 ]/g, " ");

  const words = cleaned.split(/\s+/);

  const result = new Set<string>();

  for (const word of words) {
    for (let i = 1; i <= word.length; i++) {
      result.add(word.substring(0, i));
    }
  }

  return Array.from(result);
}

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

  const fullText = `${data.name} ${data.description ?? ""} ${data.category} ${data.subCategory} ${ownerName}`;
  const searchKeywords = buildSearchKeywords(fullText);

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

    searchKeywords,

    submittedAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  });

  return { success: true, itemId };
});
