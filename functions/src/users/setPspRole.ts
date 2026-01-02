import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

export const setPspRole = onCall(async (request) => {
  const uid = request.data?.uid;
  if (!uid) throw new Error("Missing uid");

  await admin.auth().setCustomUserClaims(uid, {
    role: "psp_simulator",
  });

  return { success: true };
});
