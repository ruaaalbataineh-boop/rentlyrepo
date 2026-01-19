import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();
const db = getFirestore();

function asMillis(v: any): number {
  if (!v) return 0;

  if (typeof v.toMillis === "function") return v.toMillis();

  if (v._seconds) return v._seconds * 1000;

  if (typeof v === "string") return new Date(v).getTime();

  return Number(v) || 0;
}

export const createRentalRequest = onCall(async (request) => {
    try{
        const renterUid = request.auth?.uid;
          if (!renterUid)
            throw new HttpsError("unauthenticated", "Not authenticated.");

          const data = request.data;

          const startMs = data.startDate;
          const endMs = data.endDate;

          if (!startMs || !endMs) {
            throw new HttpsError("invalid-argument", "Missing start/end time");
          }

          const startTs = admin.firestore.Timestamp.fromMillis(startMs);
          const endTs = admin.firestore.Timestamp.fromMillis(endMs);

          const required = [
            "itemId",
            "itemTitle",
            "itemOwnerUid",
            "ownerName",
            "rentalType",
            "rentalQuantity",
            "startDate",
            "endDate",
            "pickupTime",
            "rentalPrice",
            "totalPrice",
            "insurance",
          ];

          for (const k of required) {
              if (data[k] === undefined || data[k] === null) {
                throw new HttpsError(
                    "invalid-argument",
                    `Missing field: ${k}`);
              }
          }

      if (data.rentalType === "hourly") {
        throw new HttpsError("invalid-argument","Hourly rental is not supported");
      }

          // Get user profile
          const userDoc = await db.collection("users").doc(renterUid).get();
          const user = userDoc.exists ? userDoc.data() : null;

          let renterName = "Unknown User";

          if (user) {
            const first = user.firstName ?? user.firstname ?? "";
            const last = user.lastName ?? user.lastname ?? "";

            if (first || last) {
              renterName = `${first} ${last}`.trim();
            }
          }

          const fiveDays = 5 * 24 * 60 * 60 * 1000;
          const startDate = startTs.toMillis();
          const endDate = endTs.toMillis();

          if (endDate <= startDate) {
            throw new HttpsError(
              "invalid-argument",
              "Invalid rental period."
            );
          }

          const snap = await db
            .collection("rentalRequests")
            .where("itemId", "==", data.itemId)
            .where("status", "in", ["accepted", "active"])
            .get();

          for (const doc of snap.docs) {
            const existing = doc.data();
            const existingStart = asMillis(existing.startDate);
            const existingEnd = asMillis(existing.endDate);

            const noOverlap =
                  endDate + fiveDays <= existingStart ||
                  startDate - fiveDays >= existingEnd;

            if (!noOverlap) {
              throw new HttpsError(
                "failed-precondition",
                "Conflicts with another accepted rental (buffer rule)."
              )
            }
          }

          return await db.runTransaction(async (trx) => {
              // Get wallets
              const walletsRef = db.collection("wallets");

              const userWalletSnap = await trx.get(
                walletsRef.where("userId","==", renterUid).where("type","==","USER").limit(1)
              );

              const holdingWalletSnap = await trx.get(
                walletsRef.where("userId","==", renterUid).where("type","==","HOLDING").limit(1)
              );

              if (userWalletSnap.empty || holdingWalletSnap.empty)
                throw new HttpsError("failed-precondition","Wallets not found");

              const userWallet = userWalletSnap.docs[0];
              const holdingWallet = holdingWalletSnap.docs[0];

              const userBalance = userWallet.data().balance || 0;
              const total = Number(data.totalPrice);

              if (userBalance < total)
                throw new HttpsError("failed-precondition","Insufficient wallet balance");

              // Move Money
              trx.update(userWallet.ref, {
                balance: userBalance - total,
                updatedAt: FieldValue.serverTimestamp(),
              });

              trx.update(holdingWallet.ref, {
                balance: (holdingWallet.data().balance || 0) + total,
                updatedAt: FieldValue.serverTimestamp(),
              });

              const txRef = db.collection("walletTransactions").doc();
              trx.set(txRef, {
                userId: renterUid,
                fromWalletId: userWallet.id,
                toWalletId: holdingWallet.id,
                amount: total,
                purpose: "RENTAL_LOCK",
                status: "confirmed",
                createdAt: FieldValue.serverTimestamp(),
              });

              const reqRef = db.collection("rentalRequests").doc();

              trx.set(reqRef, {
                  itemId: data.itemId,
                  itemTitle: data.itemTitle,

                  itemOwnerUid: data.itemOwnerUid,
                  ownerName: data.ownerName ?? null,

                  renterUid,
                  renterName,

                  rentalType: data.rentalType,
                  rentalQuantity: data.rentalQuantity,

                  startDate: startTs,
                  endDate: endTs,
                  pickupTime: data.pickupTime,

                  rentalPrice: data.rentalPrice,
                  totalPrice: data.totalPrice,

                  insurance: {
                      itemOriginalPrice: data.insurance.itemOriginalPrice,
                      ratePercentage: data.insurance.ratePercentage,
                      amount: data.insurance.amount,
                      accepted: data.insurance.accepted,
                  },

                  status: "pending",
                  paymentStatus: "locked",
                  createdAt: FieldValue.serverTimestamp(),
                });

            return { success: true };
          });

        } catch (e){
            console.error("CreateRentalRequest ERROR:", e);
                throw e;

            }

});