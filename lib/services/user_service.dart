import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;

  static Future<bool> isApproved(String uid) async {
    final doc = await _db.collection("users").doc(uid).get();
    return doc.exists;
  }
}
