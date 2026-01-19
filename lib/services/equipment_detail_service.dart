import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class EquipmentDetailService {
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  EquipmentDetailService(this._db, this._functions);

  Future<String> getOwnerName(String uid) async {
    final snap = await _db.collection("users").doc(uid).get();
    if (!snap.exists) return "Owner";

    final data = snap.data() ?? {};
    final first = data["firstName"] ?? data["firstname"] ?? "";
    final last = data["lastName"] ?? data["lastname"] ?? "";
    final full = "$first $last".trim();
    return full.isEmpty ? "Owner" : full;
  }

  Future<double> getWalletBalance(String uid) async {
    final stream = FirestoreService.combinedWalletStream(uid);
    final snapshot = await stream.first;
    return (snapshot['userBalance'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, dynamic>> getItemInsurance(String itemId) async {
    // Prefer Firestore item.insurance if you store it there.
    final snap = await _db.collection("items").doc(itemId).get();
    final data = snap.data() ?? {};
    final insurance = (data["insurance"] as Map?) ?? {};
    return Map<String, dynamic>.from(insurance);
  }

  Future<List<Map<String, dynamic>>> getTopReviews(String itemId) async {
    final snap = await _db
        .collection("reviews")
        .where("itemId", isEqualTo: itemId)
        .where("fromRole", isEqualTo: "renter")
        .orderBy("createdAt", descending: true)
        .limit(3)
        .get();

    return snap.docs.map((d) {
      final data = d.data();
      return {
        "rating": (data["rating"] ?? 0).toDouble(),
        "comment": data["comment"] ?? "",
        "createdAt": (data["createdAt"] as Timestamp?)?.toDate() ?? DateTime.now(),
      };
    }).toList();
  }

  Future<List<DateTimeRange>> getUnavailableRanges(String itemId) async {
    final rentals = await FirestoreService.getAcceptedRequestsForItem(itemId);

    return rentals.map((r) {
      final start = DateTime.parse(r["startDate"].toString());
      final end = DateTime.parse(r["endDate"].toString());
      return DateTimeRange(start: start, end: end);
    }).toList();
  }

  Future<void> createRentalRequest(Map<String, dynamic> payload) async {
    await _functions
        .httpsCallable("createRentalRequest")
        .call(payload);
  }

  Future<bool> isUserRentalBlocked(String uid) async {
    final snap = await _db.collection("users").doc(uid).get();
    final data = snap.data() ?? {};
    return (data["rentalBlocked"] == true);
  }

}
