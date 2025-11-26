import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {

  static Future<void> submitUserForApproval({
    required String uid,
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required String idPhotoUrl,
    required String selfiePhotoUrl,
  }) async {
    await FirebaseFirestore.instance.collection("pending_users").doc(uid).set({
      "email": email,
      "firstName": firstName,
      "lastName": lastName,
      "phone": phone,
      "idPhotoUrl": idPhotoUrl,
      "selfieFaceUrl": selfiePhotoUrl,
      "submittedAt": FieldValue.serverTimestamp(),
      "status": "pending",
    });
  }

  Future<void> approveUser(String uid) async {
    final pendingRef = FirebaseFirestore.instance.collection("pending_users").doc(uid);
    final usersRef = FirebaseFirestore.instance.collection("users").doc(uid);

    final data = await pendingRef.get();
    if (data.exists) {

      await pendingRef.update({
        "status": "approved",
        "reviewedAt": FieldValue.serverTimestamp(),
      });

      await usersRef.set({
        ...data.data()!,
        "status": "approved",
        "approvedAt": FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> rejectUser(String uid) async {
    await FirebaseFirestore.instance.collection("pending_users").doc(uid).update({
      "status": "rejected",
      "reviewedAt": FieldValue.serverTimestamp(),
    });
  }

}
