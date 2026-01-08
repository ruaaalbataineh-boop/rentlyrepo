import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const db = getFirestore();

export const submitIssueReport = onCall(async (req) => {
  const authUid = req.auth?.uid;
  if (!authUid) throw new HttpsError("unauthenticated", "Not logged in");

  const {
    requestId,
    type,
    severity,         // only for return issue
    description,
    mediaUrls = [],
  } = req.data;

  if (!requestId || !type)
    throw new HttpsError("invalid-argument", "Missing parameters");

  const rentalRef = db.collection("rentalRequests").doc(requestId);
  const snap = await rentalRef.get();

  if (!snap.exists)
    throw new HttpsError("not-found", "Rental not found");

  const rental = snap.data()!;
  const renterUid = rental.renterUid;
  const ownerUid = rental.itemOwnerUid;

  //PICKUP ISSUE
  if (type === "pickup_issue") {
    if (authUid !== renterUid)
      throw new HttpsError("permission-denied", "Only renter can report pickup issue");

    if (rental.status !== "accepted")
      throw new HttpsError("failed-precondition", "Pickup issue allowed only while accepted");

    await db.runTransaction(async (tx) => {
      tx.set(db.collection("rentalReports").doc(), {
        requestId,
        type,
        submittedBy: authUid,
        against: ownerUid,
        description: description ?? "",
        media: mediaUrls,
        status: "pending",
        createdAt: FieldValue.serverTimestamp(),
      });

      tx.update(rentalRef, {
        status: "cancelled",
        cancelReason: "renter_item_issue",
        issueReportedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    });

    return { success: true };
  }

  //  RETURN ISSUE
  if (type === "return_issue") {
    if (authUid !== ownerUid)
      throw new HttpsError("permission-denied", "Only owner can report return issue");

    if (rental.status !== "active")
      throw new HttpsError("failed-precondition", "Return issue allowed only when active");

    await db.runTransaction(async (tx) => {
      tx.set(db.collection("rentalReports").doc(), {
        requestId,
        type,
        submittedBy: authUid,
        against: renterUid,
        severity: severity ?? null,
        description: description ?? "",
        media: mediaUrls,
        status: "pending",
        createdAt: FieldValue.serverTimestamp(),
      });

      tx.update(rentalRef, {
        status: "ended",
        endReason: "damaged",
        issueReportedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    });

    return { success: true };
  }

  throw new HttpsError("invalid-argument", "Invalid report type");
});
