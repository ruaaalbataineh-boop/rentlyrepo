import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { requireWallets } from "../utils/walletHelpers";

if (!admin.apps.length) admin.initializeApp();
const db = getFirestore();

export const autoNeverReturned = onSchedule(
  { schedule: "every 5 minutes" },
  async () => {
    const now = Timestamp.now();

    const snap = await db
      .collection("rentalRequests")
      .where("status", "==", "active")
      .where("endDatePlus3", "<=", now)
      .get();

    if (snap.empty) {
      console.log("No overdue never-returned rentals found");
      return;
    }

    console.log(`Processing ${snap.size} overdue rentals`);

    for (const doc of snap.docs) {
      const rental = doc.data();
      const requestId = doc.id;

      const renterUid = rental.renterUid;
      const ownerUid = rental.itemOwnerUid;
      const insuranceAmount = Number(rental.insurance?.amount || 0);

      if (!renterUid || !ownerUid || !insuranceAmount) {
        console.warn("Missing rental data", requestId);
        continue;
      }

      try {
        await db.runTransaction(async (tx) => {
          const fresh = await tx.get(doc.ref);

          if (!fresh.exists) return;
          const r = fresh.data()!;

          // Ensure still active & still overdue
          if (r.status !== "active") return;

          const now = Timestamp.now();
          const endDate = r.endDate.toDate();
          const deadline = new Date(endDate);
          deadline.setDate(deadline.getDate() + 3);

          if (now.toDate() < deadline) return;

          // GET RENTER WALLETS
          const { holding: renterHolding } =
             await requireWallets(renterUid);

          // GET OWNER USER WALLET
          const ownerWalletSnap = await db
            .collection("wallets")
            .where("userId", "==", ownerUid)
            .where("type", "==", "USER")
            .limit(1)
            .get();

          if (ownerWalletSnap.empty)
            throw new Error("Owner wallet missing");

          const ownerUser = ownerWalletSnap.docs[0].ref;

          // READ BALANCES
          const holdSnap = await tx.get(renterHolding);
          const ownerSnap = await tx.get(ownerUser);

          const holdBal = Number(holdSnap.data()?.balance || 0);
          const ownerBal = Number(ownerSnap.data()?.balance || 0);

          if (holdBal < insuranceAmount)
            throw new Error("Holding inconsistent");

          // TRANSFER INSURANCE FULLY
          tx.update(renterHolding, {
            balance: holdBal - insuranceAmount,
          });

          tx.update(ownerUser, {
            balance: ownerBal + insuranceAmount,
          });

          tx.set(db.collection("walletTransactions").doc(), {
            rentalRequestId: requestId,
            purpose: "RENTAL_INSURANCE_PAYOUT_OWNER_FULL",
            fromWalletId: renterHolding.id,
            toWalletId: ownerUser.id,
            userId: ownerUid,
            amount: insuranceAmount,
            status: "confirmed",
            createdAt: FieldValue.serverTimestamp(),
          });

          tx.set(db.collection("walletTransactions").doc(), {
                      rentalRequestId: requestId,
                      purpose: "RENTAL_INSURANCE_PAYOUT_OWNER_FULL",
                      fromWalletId: renterHolding.id,
                      toWalletId: ownerUser.id,
                      userId: renterUid,
                      amount: insuranceAmount,
                      status: "confirmed",
                      createdAt: FieldValue.serverTimestamp(),
                    });

          // UPDATE RENTAL
          tx.update(doc.ref, {
            status: "ended",
            endReason: "never_returned",
            updatedAt: FieldValue.serverTimestamp(),
          });

          // BLOCK RENTER
          tx.update(db.collection("users").doc(renterUid), {
            rentalBlocked: true,
            blockedAt: FieldValue.serverTimestamp(),
          });

          console.log("Marked never returned:", requestId);
        });
      } catch (err) {
        console.error("Failed never-return process", requestId, err);
      }
    }
  }
);
