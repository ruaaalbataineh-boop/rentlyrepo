import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const db = getFirestore();

export const submitReview = onCall(async (req) => {
  const authUid = req.auth?.uid;
  if (!authUid) throw new HttpsError("unauthenticated", "Not logged in");

  const { requestId, rating, comment } = req.data ?? {};
  if (!requestId) throw new HttpsError("invalid-argument", "Missing requestId");

  const r = Number(rating);
  if (!Number.isFinite(r) || r < 1 || r > 5)
    throw new HttpsError("invalid-argument", "Rating must be between 1 and 5");

  const cleanComment =
    typeof comment === "string" ? comment.trim().slice(0, 500) : "";

  const rentalRef = db.collection("rentalRequests").doc(String(requestId));

  // Deterministic review id prevents duplicates without needing queries/indexes
  const reviewId = `${requestId}_${authUid}`;
  const reviewRef = db.collection("reviews").doc(reviewId);

  await db.runTransaction(async (tx) => {
    const rentalSnap = await tx.get(rentalRef);
    const existingReviewSnap = await tx.get(reviewRef);

    if (!rentalSnap.exists)
      throw new HttpsError("not-found", "Rental not found");

    if (existingReviewSnap.exists)
      throw new HttpsError("already-exists", "You already reviewed this rental");

    const rental = rentalSnap.data()!;

    const renterUid = rental.renterUid;
    const ownerUid = rental.itemOwnerUid;
    const itemId = rental.itemId;

    if (!renterUid || !ownerUid)
      throw new HttpsError("failed-precondition", "Rental missing users");

    if (!itemId)
      throw new HttpsError("failed-precondition", "Rental missing itemId");

    // Must be ended or cancelled
    if (!["ended", "cancelled"].includes(rental.status))
      throw new HttpsError(
        "failed-precondition",
        "You can review only after the rental is finished or cancelled"
      );

    // Determine roles + counterpart
    let fromRole: "renter" | "owner";
    let toRole: "renter" | "owner";
    let toUserId: string;

    if (authUid === renterUid) {
      fromRole = "renter";
      toRole = "owner";
      toUserId = ownerUid;
    } else if (authUid === ownerUid) {
      fromRole = "owner";
      toRole = "renter";
      toUserId = renterUid;
    } else {
      throw new HttpsError(
        "permission-denied",
        "Only renter or owner can review this rental"
      );
    }

    // WRITE review
    tx.set(reviewRef, {
      rentalRequestId: requestId,
      itemId,

      fromUserId: authUid,
      toUserId,

      fromRole,
      toRole,

      rating: r,
      comment: cleanComment,

      createdAt: FieldValue.serverTimestamp(),
      visible: true,
    });

    // Aggregate on reviewed user
    const reviewedUserRef = db.collection("users").doc(toUserId);
    tx.set(
      reviewedUserRef,
      {
        ratingCount: FieldValue.increment(1),
        ratingSum: FieldValue.increment(r),
        ratingUpdatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    // Aggregate on item
    const itemRef = db.collection("items").doc(itemId);
    tx.set(
      itemRef,
      {
        ratingCount: FieldValue.increment(1),
        ratingSum: FieldValue.increment(r),
        ratingUpdatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    // mark on rental that this side reviewed (for UI)
    const field =
      authUid === renterUid ? "reviewedByRenterAt" : "reviewedByOwnerAt";
    tx.set(
      rentalRef,
      {
        [field]: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  });

  return { success: true, reviewId };
});
