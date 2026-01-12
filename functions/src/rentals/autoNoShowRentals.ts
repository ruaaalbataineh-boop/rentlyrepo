import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { requireWallets } from "../utils/walletHelpers";

if (!admin.apps.length) admin.initializeApp();
const db = getFirestore();

export const autoNoShowRentals = onSchedule(
  { schedule: "every 5 minutes" },
  async () => {
    const now = Timestamp.now();

    const snap = await db
      .collection("rentalRequests")
      .where("status", "==", "accepted")
      .where("startDate", "<", now)
      .get();

    if (snap.empty) {
      console.log("No no-show rentals found");
      return;
    }

    console.log(`Found ${snap.size} potential no-shows`);

    for (const doc of snap.docs) {
      const rental = doc.data();
      const requestId = doc.id;

      const renterUid = rental.renterUid;
      const ownerUid = rental.itemOwnerUid;

      const rentalPrice = Number(rental.rentalPrice || 0);
      const totalPrice = Number(rental.totalPrice || 0);

      if (!renterUid || !ownerUid || !totalPrice) {
        console.warn("Rental missing required data", requestId);
        continue;
      }

      // penalty rules
      let penalty = 0;
      if (rentalPrice > 10) penalty = rentalPrice * 0.1;

      try {
        await db.runTransaction(async (tx) => {
          const fresh = await tx.get(doc.ref);
          if (!fresh.exists) return;

          // ensure still accepted, not processed
          if (fresh.data()!.status !== "accepted") return;

          // GET RENTER WALLETS
          const { user: renterUser, holding: renterHolding } =
                await requireWallets(renterUid);

          // GET OWNER USER WALLET
          const ownerWallets = await db
            .collection("wallets")
            .where("userId", "==", ownerUid)
            .where("type", "==", "USER")
            .limit(1)
            .get();

          if (ownerWallets.empty)
            throw new Error("Owner user wallet missing");

          const ownerUser = ownerWallets.docs[0].ref;

          const holdSnap = await tx.get(renterHolding);
          const renterUserSnap = await tx.get(renterUser);
          const ownerSnap = await tx.get(ownerUser);

          const holdBal = Number(holdSnap.data()?.balance || 0);
          const renterBal = Number(renterUserSnap.data()?.balance || 0);
          const ownerBal = Number(ownerSnap.data()?.balance || 0);

          if (holdBal < totalPrice)
            throw new Error("Holding inconsistent");

          const refundAmount = totalPrice - penalty;

          // HOLDING to OWNER (penalty)
          if (penalty > 0) {
            tx.update(ownerUser, {
              balance: ownerBal + penalty,
            });

            tx.set(db.collection("walletTransactions").doc(), {
              rentalRequestId: requestId,
              purpose: "RENTAL_NO_SHOW_PENALTY_OWNER",
              fromWalletId: renterHolding.id,
              toWalletId: ownerUser.id,
              userId: ownerUid,
              amount: penalty,
              status: "confirmed",
              createdAt: FieldValue.serverTimestamp(),
            });

            tx.set(db.collection("walletTransactions").doc(), {
                          rentalRequestId: requestId,
                          purpose: "RENTAL_NO_SHOW_PENALTY_OWNER",
                          fromWalletId: renterHolding.id,
                          toWalletId: ownerUser.id,
                          userId: renterUid,
                          amount: penalty,
                          status: "confirmed",
                          createdAt: FieldValue.serverTimestamp(),
                        });
          }

          // HOLDING to RENTER (refund rest)
          tx.update(renterHolding, {
            balance: holdBal - totalPrice,
          });

          tx.update(renterUser, {
            balance: renterBal + refundAmount,
          });

          tx.set(db.collection("walletTransactions").doc(), {
            rentalRequestId: requestId,
            purpose: "RENTAL_NO_SHOW_REFUND",
            fromWalletId: renterHolding.id,
            toWalletId: renterUser.id,
            userId: renterUid,
            amount: refundAmount,
            status: "confirmed",
            createdAt: FieldValue.serverTimestamp(),
          });

          // UPDATE RENTAL STATUS
          tx.update(doc.ref, {
            status: "cancelled",
            cancelReason: "no_show",
            updatedAt: FieldValue.serverTimestamp(),
          });

          console.log("No-show processed", requestId);
        });
      } catch (err) {
        console.error("Failed processing no-show", requestId, err);
      }
    }
  }
);
