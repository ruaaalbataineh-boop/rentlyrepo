import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/rental_request.dart';

class FirestoreService {

  static final functions =
  FirebaseFunctions.instanceFor(region: "us-central1");

  static Future<void> submitUserForApproval(Map<String, dynamic> data) async {
    final callable = FirebaseFunctions.instance
        .httpsCallableFromUrl(
        "https://us-central1-p22rently.cloudfunctions.net/submitUserForApproval"
    );

    await callable.call(data);
  }

  static Future<void> submitItemForApproval(Map<String, dynamic> data) async {
    await FirebaseFunctions.instance
        .httpsCallable("submitItemForApproval")
        .call(data);
  }

  static Future<void> createRentalRequest(Map<String, dynamic> data) async {
    await FirebaseFunctions.instance
        .httpsCallable("createRentalRequest")
        .call(data);
  }

  static Future<void> updateRentalRequestStatus(
      String requestId, String newStatus,
      {String? qrToken}) async {
    await FirebaseFunctions.instance
        .httpsCallable("updateRentalRequestStatus")
        .call({
      "requestId": requestId,
      "newStatus": newStatus,
      "qrToken": qrToken,
    });
  }

  static Stream<List<RentalRequest>> getRenterRequestsByStatuses(
      String renterUid, List<String> statuses) {
    return FirebaseFirestore.instance
        .collection("rentalRequests")
        .where("renterUid", isEqualTo: renterUid)
        .where("status", whereIn: statuses)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => RentalRequest.fromFirestore(doc.id, doc.data()))
        .toList());
  }

  static Stream<List<RentalRequest>> getOwnerRequests(String ownerUid) {
    return FirebaseFirestore.instance
        .collection("rentalRequests")
        .where("itemOwnerUid", isEqualTo: ownerUid)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => RentalRequest.fromFirestore(doc.id, doc.data()))
        .toList());
  }

  static Future<List<Map<String, dynamic>>> getAcceptedRequestsForItem(
      String itemId) async {

    final snap = await FirebaseFirestore.instance
        .collection("rentalRequests")
        .where("itemId", isEqualTo: itemId)
        .where("status", whereIn: ["accepted", "active"])
        .get();

    return snap.docs.map((d) => d.data()).toList();
  }

  static Future<Map<String, dynamic>?> getItemInsurance(String itemId) async {
    final doc = await FirebaseFirestore.instance
        .collection("items")
        .doc(itemId)
        .get();

    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null) return null;

    final insurance = data["insurance"];
    if (insurance is Map<String, dynamic>) {
      return insurance;
    } else if (insurance is Map) {
      // convert Map<dynamic, dynamic> to Map<String, dynamic>
      return insurance.map((key, value) =>
          MapEntry(key.toString(), value));
    }

    return null;
  }

  static Future<Map<String, dynamic>> createInvoice(double amount, String method) async {
    final callable = FirebaseFunctions.instance.httpsCallable("createInvoice");
    final result = await callable.call({
      "amount": amount,
      "method": method,
    });

    return Map<String, dynamic>.from(result.data);
  }

  static Future<void> markInvoicePaid(String referenceNumber) async {
    final callable = FirebaseFunctions.instance.httpsCallable("markInvoicePaid");
    await callable.call({
      "referenceNumber": referenceNumber,
    });
  }

}
