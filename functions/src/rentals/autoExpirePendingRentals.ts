import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { requireWallets } from "../utils/walletHelpers";

if (!admin.apps.length) admin.initializeApp();
const db = getFirestore();

export const autoExpirePendingRentals = onSchedule(
  { schedule: "every 5 minutes" },
  async () => {
    const now = Timestamp.now();

    const snap = await db
      .collection("rentalRequests")
      .where("status", "==", "pending")
      .where("startDate", "<", now)
      .get();

    if (snap.empty) {
      console.log("No expired pending rentals");
      return;
    }

    console.log(`Found ${snap.size} outdated rentals to process`);

    for (const doc of snap.docs) {
      const rental = doc.data();
      const requestId = doc.id;

      const renterUid = rental.renterUid;
      const totalPrice = Number(rental.totalPrice || 0);

      if (!renterUid || !totalPrice) {
        console.warn("Missing rental data, skipping", requestId);
        continue;
      }

      try {
        await db.runTransaction(async (tx) => {
          const fresh = await tx.get(doc.ref);
          if (!fresh.exists) return;

          if (fresh.data()!.status !== "pending") return; // already processed

          // Get renter wallets
          const { user: userWallet, holding: holdingWallet } =
                await requireWallets(renterUid);

          const holdSnap = await tx.get(holdingWallet);
          const userSnap = await tx.get(userWallet);

          const holdBal = Number(holdSnap.data()?.balance || 0);
          const userBal = Number(userSnap.data()?.balance || 0);

          if (holdBal < totalPrice) {
            throw new Error("Holding inconsistent for " + renterUid);
          }

          // MONEY MOVE: HOLDING to USER
          tx.update(holdingWallet, {
            balance: holdBal - totalPrice,
          });

          tx.update(userWallet, {
            balance: userBal + totalPrice,
          });

          tx.set(db.collection("walletTransactions").doc(), {
            rentalRequestId: requestId,
            purpose: "RENTAL_OUTDATED_REFUND",
            fromWalletId: holdingWallet.id,
            toWalletId: userWallet.id,
            userId: renterUid,
            amount: totalPrice,
            status: "confirmed",
            createdAt: FieldValue.serverTimestamp(),
          });

          // UPDATE RENTAL STATUS
          tx.update(doc.ref, {
            status: "outdated",
            updatedAt: FieldValue.serverTimestamp(),
          });

          console.log("Expired pending rental", requestId);
        });
      } catch (err) {
        console.error("Failed to expire rental", requestId, err);
      }
    }
  }
);
