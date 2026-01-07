import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const db = getFirestore();

function asMillis(v: any): number {
  if (!v) return 0;

  if (typeof v.toMillis === "function") return v.toMillis();

  if (v._seconds) return v._seconds * 1000;

  if (typeof v === "string") return new Date(v).getTime();

  return Number(v) || 0;
}

export const updateRentalRequestStatus = onCall(async (request) => {
  try {
    const userUid = request.auth?.uid;
    if (!userUid)
      throw new HttpsError("unauthenticated", "Not authenticated.");

    const { requestId, newStatus } = request.data;
    if (!requestId || !newStatus)
      throw new HttpsError("invalid-argument", "Missing parameters.");

    const allowed = ["accepted", "rejected", "active", "ended"];
    if (!allowed.includes(newStatus))
      throw new HttpsError("invalid-argument", "Invalid status.");

    const ref = db.collection("rentalRequests").doc(requestId);
    const snap = await ref.get();

    if (!snap.exists)
      throw new HttpsError("not-found", "Request not found.");

    const data = snap.data()!;

    // Owner controls everything except QR activation
    if (data.itemOwnerUid !== userUid && newStatus !== "active")
      throw new HttpsError("permission-denied", "Not allowed.");

    const renterUid = data.renterUid;
    const totalLockedAmount = Number(data.totalPrice || 0);

    // ACCEPT LOGIC
    if (newStatus === "accepted") {
      if (data.status !== "pending")
        throw new HttpsError(
          "failed-precondition",
          "Only pending requests can be accepted."
        );

      // No accepting expired rentals
      const now = Date.now();
      const startDate = asMillis(data.startDate);
      const endDate = asMillis(data.endDate);

      if (!startDate || !endDate)
        throw new HttpsError(
          "failed-precondition",
          "Rental dates are missing or invalid."
        );

      if (startDate <= now)
        throw new HttpsError(
          "failed-precondition",
          "Rental start date has already passed."
        );

      // Buffer conflict check
      const FIVE_DAYS = 5 * 24 * 60 * 60 * 1000;

      const conflicting = await db
        .collection("rentalRequests")
        .where("itemId", "==", data.itemId)
        .where("status", "in", ["accepted", "active"])
        .get();

      for (const doc of conflicting.docs) {
        const ex = doc.data();
        const exStart = asMillis(ex.startDate);
        const exEnd = asMillis(ex.endDate);

        const noOverlap =
          endDate + FIVE_DAYS <= exStart ||
          startDate - FIVE_DAYS >= exEnd;

        if (!noOverlap) {
          throw new HttpsError(
            "failed-precondition",
            "Conflicts with another accepted rental (buffer rule)."
          );
        }
      }

      await ref.update({
        status: "accepted",
        updatedAt: FieldValue.serverTimestamp(),
      });

      return { success: true };
    }

    // REJECT LOGIC — REFUND renter
    if (newStatus === "rejected") {
      if (data.status !== "pending")
        throw new HttpsError(
          "failed-precondition",
          "Only pending requests can be rejected."
        );

      if (!totalLockedAmount)
        return { success: true }; // nothing to refund

      await db.runTransaction(async (tx) => {
        const wallets = await tx.get(
          db.collection("wallets").where("userId", "==", renterUid)
        );

        let userWalletRef: FirebaseFirestore.DocumentReference | null = null;
        let holdingWalletRef: FirebaseFirestore.DocumentReference | null = null;

        wallets.forEach((doc) => {
          const w = doc.data();
          if (w.type === "USER") userWalletRef = doc.ref;
          if (w.type === "HOLDING") holdingWalletRef = doc.ref;
        });

        if (!userWalletRef || !holdingWalletRef)
          throw new HttpsError(
            "failed-precondition",
            "User or Holding wallet missing."
          );

        const holdingSnap = await tx.get(
          holdingWalletRef as FirebaseFirestore.DocumentReference
        );
        const userSnap = await tx.get(
          userWalletRef as FirebaseFirestore.DocumentReference
        );

        const holdingBalance = Number(holdingSnap.data()?.balance || 0);
        const userBalance = Number(userSnap.data()?.balance || 0);

        if (holdingBalance < totalLockedAmount)
          throw new HttpsError(
            "failed-precondition",
            "Holding wallet inconsistent."
          );

        // Move money back
        tx.update(holdingWalletRef, {
          balance: holdingBalance - totalLockedAmount,
          updatedAt: FieldValue.serverTimestamp(),
        });

        tx.update(userWalletRef, {
          balance: userBalance + totalLockedAmount,
          updatedAt: FieldValue.serverTimestamp(),
        });

        // Record transaction
        const txRef = db.collection("walletTransactions").doc();
        tx.set(txRef, {
          userId: renterUid,
          fromWalletId: (holdingWalletRef as any).id,
          toWalletId: (userWalletRef as any).id,
          amount: totalLockedAmount,
          purpose: "RENTAL_REJECT_REFUND",
          status: "confirmed",
          createdAt: FieldValue.serverTimestamp(),
          rentalRequestId: requestId,
        });

        tx.update(ref, {
          status: "rejected",
          updatedAt: FieldValue.serverTimestamp(),
        });
      });

      return { success: true };
    }

    // DEFAULT: set status normally
    await ref.update({
      status: newStatus,
      updatedAt: FieldValue.serverTimestamp(),
    });

    return { success: true };
  } catch (e) {
    console.error("updateRentalRequestStatus ERROR:", e);
    if (e instanceof HttpsError) throw e;
    throw new HttpsError("internal", "Unexpected error occurred");
  }
});
