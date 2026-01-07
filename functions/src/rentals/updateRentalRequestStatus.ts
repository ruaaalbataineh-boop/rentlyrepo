import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

export const updateRentalRequestStatus = onCall(async (request) => {
  const userUid = request.auth?.uid;
  if (!userUid) {
    throw new HttpsError("unauthenticated", "Not authenticated.");
  }

  const { requestId, newStatus, qrToken } = request.data;
  if (!requestId || !newStatus) {
    throw new HttpsError("invalid-argument", "Missing parameters.");
  }

  const allowed = ["accepted", "rejected", "active", "ended"];
  if (!allowed.includes(newStatus)) {
    throw new HttpsError("invalid-argument", "Invalid status.");
  }

  const db = getFirestore();
  const ref = db.collection("rentalRequests").doc(requestId);
  const snap = await ref.get();

  if (!snap.exists) {
    throw new HttpsError("not-found", "Request not found.");
  }

  const data = snap.data()!;

  // Owner must control everything EXCEPT activation (activation is via QR scan by renter)
  if (data.itemOwnerUid !== userUid && newStatus !== "active") {
    throw new HttpsError("permission-denied", "Not allowed.");
  }

  const renterUid = data.renterUid;
  const ownerUid = data.itemOwnerUid;

  const renterWalletRef = db.collection("wallets").doc(renterUid);
  const ownerWalletRef = db.collection("wallets").doc(ownerUid);

  const rentalPrice = Number(data.totalPrice || 0);
  const insuranceAmount = Number(data.insuranceAmount || 0);

  //  ACCEPTED
  if (newStatus === "accepted") {
    if (data.status !== "pending") {
      throw new HttpsError(
        "failed-precondition",
        "Only pending requests can be accepted."
      );
    }

    // prevent accepting old rentals
    const now = Date.now();
    const start = data.startDate?.toMillis?.() ?? 0;

    if (start <= now) {
      throw new HttpsError(
        "failed-precondition",
        "Rental start date has already passed."
      );
    }

    // check buffer rule conflicts
    const db = getFirestore();
    const conflicting = await db
      .collection("rentalRequests")
      .where("itemId", "==", data.itemId)
      .where("status", "in", ["accepted", "active"])
      .get();

    const fiveDays = 5 * 24 * 60 * 60 * 1000;
    const startDate = data.startDate.toMillis();
    const endDate = data.endDate.toMillis();

    for (const doc of conflicting.docs) {
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
        );
      }
    }

    await ref.update({
      status: "accepted",
      updatedAt: FieldValue.serverTimestamp(),
    });

    return { success: true };
  }

  //  ACTIVE
  if (newStatus === "active") {
    if (!qrToken || qrToken !== data.qrToken) {
      throw new HttpsError(
        "failed-precondition",
        "Invalid or expired QR code."
      );
    }

    await db.runTransaction(async (tx) => {
      const renterWalletSnap = await tx.get(renterWalletRef);
      const ownerWalletSnap = await tx.get(ownerWalletRef);

      const renterBalance = Number(renterWalletSnap.data()?.balance || 0);
      const ownerBalance = Number(ownerWalletSnap.data()?.balance || 0);

      const totalRequired = rentalPrice + insuranceAmount;

      if (renterBalance < totalRequired) {
        throw new HttpsError(
          "failed-precondition",
          "Insufficient wallet balance."
        );
      }

      // Deduct from renter
      tx.update(renterWalletRef, {
        balance: renterBalance - totalRequired,
      });

      // Add rental price to owner
      tx.update(ownerWalletRef, {
        balance: ownerBalance + rentalPrice,
      });

      // Update rental
      tx.update(ref, {
        status: "active",
        updatedAt: FieldValue.serverTimestamp(),
      });
    });

    return { success: true };
  }

  // ENDED
  if (newStatus === "ended") {
    await db.runTransaction(async (tx) => {
      const renterWalletSnap = await tx.get(renterWalletRef);
      const renterBalance = Number(renterWalletSnap.data()?.balance || 0);

      tx.update(renterWalletRef, {
        balance: renterBalance + insuranceAmount,
      });

      tx.update(ref, {
        status: "ended",
        updatedAt: FieldValue.serverTimestamp(),
      });
    });

    return { success: true };
  }

  // REJECTED / OTHER
  await ref.update({
    status: newStatus,
    updatedAt: FieldValue.serverTimestamp(),
  });

  return { success: true };
});
