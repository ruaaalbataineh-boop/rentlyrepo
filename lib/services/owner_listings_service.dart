import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/rental_request.dart';

class OwnerListingsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> ownerItemsStream(String ownerUid) {
    return _db
        .collection("items")
        .where("ownerId", isEqualTo: ownerUid)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
      final data = d.data();
      return {
        ...data,
        "itemId": data["itemId"] ?? d.id,
      };
    }).toList());
  }

  Stream<List<RentalRequest>> ownerRequestsStream(String ownerUid) {
    return _db
        .collection("rentalRequests")
        .where("itemOwnerUid", isEqualTo: ownerUid)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => RentalRequest.fromFirestore(d.id, d.data())).toList());
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    await FirebaseFunctions.instance
        .httpsCallable("updateRentalRequestStatus")
        .call({
      "requestId": requestId,
      "newStatus": status,
    });
  }

  Stream<int> myItemsCount(String ownerUid) {
    return _db
        .collection("items")
        .where("ownerId", isEqualTo: ownerUid)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Stream<int> pendingRequestsCount(String ownerUid) {
    return _db
        .collection("rentalRequests")
        .where("itemOwnerUid", isEqualTo: ownerUid)
        .where("status", isEqualTo: "pending")
        .snapshots()
        .map((s) => s.docs.length);
  }

  Future<void> forceActivate(String requestId) async {
    await _db.collection("rentalRequests").doc(requestId).update({
      "status": "active",
      "activatedAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> forceEnd(String requestId) async {
    await _db.collection("rentalRequests").doc(requestId).update({
      "status": "ended",
      "endedAt": FieldValue.serverTimestamp(),
    });
  }
}
