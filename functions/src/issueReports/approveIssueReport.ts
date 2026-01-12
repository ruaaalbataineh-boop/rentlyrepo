import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { requireWallets } from "../utils/walletHelpers";

const db = getFirestore();

export const approveIssueReport = onCall(async (req) => {
  const authUid = req.auth?.uid;
  if (!authUid) throw new HttpsError("unauthenticated", "Not logged in");

  const { reportId } = req.data;
  if (!reportId) throw new HttpsError("invalid-argument", "Missing reportId");

  const reportRef = db.collection("rentalReports").doc(reportId);
  const reportSnap = await reportRef.get();

  if (!reportSnap.exists)
    throw new HttpsError("not-found", "Report not found");

  const report = reportSnap.data()!;
  const requestId = report.requestId;
  const type = report.type;

  if (report.status !== "pending")
    throw new HttpsError("failed-precondition", "Already processed");

  const rentalRef = db.collection("rentalRequests").doc(requestId);
  const rentalSnap = await rentalRef.get();

  if (!rentalSnap.exists)
    throw new HttpsError("not-found", "Rental not found");

  const rental = rentalSnap.data()!;

  const renterUid = rental.renterUid;
  const ownerUid = rental.itemOwnerUid;

  const insuranceAmount = Number(
    rental.insurance?.amount ??
    rental.insuranceAmount ??
    0
  );
  const totalPrice = Number(rental.totalPrice || 0);

  //  PICKUP ISSUE
  if (type === "pickup_issue") {
    const { user: renterUser, holding: renterHolding } =
      await requireWallets(renterUid);

    await db.runTransaction(async (tx) => {
      const holdSnap = await tx.get(renterHolding);
      const userSnap = await tx.get(renterUser);

      const holdBal = Number(holdSnap.data()?.balance || 0);
      const userBal = Number(userSnap.data()?.balance || 0);

      if (holdBal < totalPrice)
        throw new HttpsError("failed-precondition", "Holding inconsistent");

      tx.update(renterHolding, { balance: holdBal - totalPrice });
      tx.update(renterUser, { balance: userBal + totalPrice });

      tx.set(db.collection("walletTransactions").doc(), {
        fromWalletId: renterHolding.id,
        toWalletId: renterUser.id,
        userId: renterUid,
        amount: totalPrice,
        purpose: "RENTAL_CANCEL_ITEM_ISSUE_REFUND",
        rentalRequestId: requestId,
        status: "confirmed",
        createdAt: FieldValue.serverTimestamp(),
      });

      tx.update(reportRef, {
        status: "approved",
        processedAt: FieldValue.serverTimestamp(),
        processedBy: authUid,
      });
    });

    return { success: true };
  }

  // RETURN ISSUE
  if (type === "return_issue") {
    const severity = report.severity || "mild";
    const lateDays = Number(report.lateDays || 0);

    let percent = 0.1;
    if (severity === "moderate") percent = 0.5;
    if (severity === "severe") percent = 1.0;

    const payout = insuranceAmount * percent;
    const refund = insuranceAmount - payout;

    const rentalType = rental.rentalType;
    const rentalQuantity = Number(rental.rentalQuantity || 0);
    const rentalPrice = Number(rental.rentalPrice || 0);

    const isShort =
        (rentalType === "daily" && rentalQuantity <= 30) ||
        (rentalType === "weekly" && rentalQuantity <= 4);

    let basePerDay = 0;
      if (rentalType === "daily") basePerDay = rentalPrice / rentalQuantity;
      if (rentalType === "weekly") basePerDay = rentalPrice / 7;

    const lateFee =
        lateDays > 0 && isShort && ["daily","weekly"].includes(rentalType)
          ? lateDays * basePerDay
          : 0;

    const { user: renterUser, holding: renterHolding } =
      await requireWallets(renterUid);

    const ownerWallets = await db
      .collection("wallets")
      .where("userId", "==", ownerUid)
      .where("type", "==", "USER")
      .limit(1)
      .get();

    if (ownerWallets.empty)
      throw new HttpsError("failed-precondition", "Owner wallet missing");

    const ownerUser = ownerWallets.docs[0].ref;

    await db.runTransaction(async (tx) => {
      const holdSnap = await tx.get(renterHolding);
      const ownerSnap = await tx.get(ownerUser);
      const renterSnap = await tx.get(renterUser);

      const holdBal = Number(holdSnap.data()?.balance || 0);
      const ownerBal = Number(ownerSnap.data()?.balance || 0);
      const renterBal = Number(renterSnap.data()?.balance || 0);

      if (holdBal < insuranceAmount)
        throw new HttpsError("failed-precondition", "Holding inconsistent");

      // remove full insurance from holding
      tx.update(renterHolding, {
        balance: holdBal - insuranceAmount,
      });

      // pay owner
      tx.update(ownerUser, {
        balance: ownerBal + payout,
      });

      // payout transaction (owner perspective)
      tx.set(db.collection("walletTransactions").doc(), {
        rentalRequestId: requestId,
        purpose: "INSURANCE_PAYOUT",
        severity,
        fromWalletId: renterHolding.id,
        toWalletId: ownerUser.id,
        userId: ownerUid,
        amount: payout,
        createdAt: FieldValue.serverTimestamp(),
        status: "confirmed",
      });

      // payout transaction duplicate for renter history
      tx.set(db.collection("walletTransactions").doc(), {
        rentalRequestId: requestId,
        purpose: "INSURANCE_PAYOUT",
        severity,
        fromWalletId: renterHolding.id,
        toWalletId: ownerUser.id,
        userId: renterUid,
        amount: payout,
        createdAt: FieldValue.serverTimestamp(),
        status: "confirmed",
      });

      // refund leftover to renter
      if (refund > 0) {
        tx.update(renterUser, {
          balance: renterBal + refund,
        });

        tx.set(db.collection("walletTransactions").doc(), {
          rentalRequestId: requestId,
          purpose: "PARTIAL_INSURANCE_REFUND",
          fromWalletId: renterHolding.id,
          toWalletId: renterUser.id,
          userId: renterUid,
          amount: refund,
          createdAt: FieldValue.serverTimestamp(),
          status: "confirmed",
        });
      }

      // LATE FEE if applicable
        if (lateFee > 0) {
            tx.update(renterUser, {
                balance: renterBal - lateFee,
            });

            tx.update(ownerUser, {
                balance: ownerBal + lateFee,
            });

            tx.set(db.collection("walletTransactions").doc(), {
                rentalRequestId: requestId,
                purpose: "RENTAL_LATE_FEE",
                fromWalletId: renterUser.id,
                toWalletId: ownerUser.id,
                userId: renterUid,
                amount: lateFee,
                createdAt: FieldValue.serverTimestamp(),
                status: "confirmed",
            });

            tx.set(db.collection("walletTransactions").doc(), {
                rentalRequestId: requestId,
                purpose: "RENTAL_LATE_FEE",
                fromWalletId: renterUser.id,
                toWalletId: ownerUser.id,
                userId: ownerUid,
                amount: lateFee,
                createdAt: FieldValue.serverTimestamp(),
                status: "confirmed",
            });
        }

      tx.update(reportRef, {
        status: "approved",
        processedAt: FieldValue.serverTimestamp(),
        processedBy: authUid,
      });
    });
    return { success: true };
  }

  throw new HttpsError("invalid-argument", "Invalid report type");
});
