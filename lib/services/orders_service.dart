import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/rental_request.dart';

class OrdersService {
  final FirebaseFirestore _db;
  OrdersService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Stream<List<RentalRequest>> renterRequestsStream({
    required String renterUid,
    required List<String> statuses,
  }) {
    return _db
        .collection("rentalRequests")
        .where("renterUid", isEqualTo: renterUid)
        .where("status", whereIn: statuses)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RentalRequest.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> deletePendingRequest({
    required String requestId,
  }) async {
    await FirebaseFunctions.instance
        .httpsCallable("deletePendingRentalRequest")
        .call({
      "requestId": requestId,
    });
  }

}
