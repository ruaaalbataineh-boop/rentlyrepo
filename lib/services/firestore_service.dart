import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/foundation.dart';

import '../models/rental_request.dart';

class FirestoreService {

  static Future<List<RentalRequest>> getRenterRequestsByStatusesOnce(
  String renterUid,
  List<String> statuses,
) async {
  final snapshot = await FirebaseFirestore.instance
      .collection("rentalRequests")
      .where("renterUid", isEqualTo: renterUid)
      .where("status", whereIn: statuses)
      .orderBy("createdAt", descending: true)
      .get();

       return snapshot.docs
      .map((doc) => RentalRequest.fromFirestore(doc.id, doc.data()))
      .toList();
    }


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
  try {
    await FirebaseFunctions.instanceFor(region: "us-central1")
        .httpsCallable("submitItemForApproval")
        .call(data);
  } on FirebaseFunctionsException catch (e) {
    print("🔥 Functions error [submitItemForApproval]");
    print("code: ${e.code}");
    print("message: ${e.message}");
    print("details: ${e.details}");
    rethrow;
  } catch (e) {
    print("🔥 Unknown error [submitItemForApproval]: $e");
    rethrow;
  }
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

  static Stream<double> walletBalanceStream(String uid) {
    return FirebaseFirestore.instance
        .collection("wallets")
        .where("userId", isEqualTo: uid)
        .where("type", isEqualTo: "USER")
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return 0.0;

      final data = snapshot.docs.first.data();
      final balance = (data["balance"] ?? 0).toDouble();

      return balance;
    });
  }

  static Stream<Map<String, double>> combinedWalletStream(String uid) {
    return FirebaseFirestore.instance
        .collection("wallets")
        .where("userId", isEqualTo: uid)
        .snapshots()
        .map((snap) {
      double userBalance = 0.0;
      double holdingBalance = 0.0;

      for (final doc in snap.docs) {
        final data = doc.data();
        final type = data["type"];

        final balance = (data["balance"] ?? 0).toDouble();

        if (type == "USER") {
          userBalance = balance;
        } else if (type == "HOLDING") {
          holdingBalance = balance;
        }
      }

      return {
        "userBalance": userBalance,
        "holdingBalance": holdingBalance,
      };
    });
  }

  static Future<Map<String, dynamic>> createStripeTopUp({
    required double amount,
    required String userId,
  }) async {
    final callable = FirebaseFunctions.instance
        .httpsCallable("createStripeTopUp");

    final result = await callable.call({
      "amount": amount,
      "userId": userId,
    });

    return Map<String, dynamic>.from(result.data);
  }

  static Future<Map<String, dynamic>> createEfawateerkomTopUp({
    required double amount,
    required String userId,
  }) async {
    final callable = FirebaseFunctions.instance
        .httpsCallable("createEfawateerkomTopUp");

    final result = await callable.call({
      "amount": amount,
      "userId": userId,
    });

    return Map<String, dynamic>.from(result.data);
  }

  static Stream<Map<String, dynamic>?> topUpStatusStream(String referenceNumber) {
    return FirebaseFirestore.instance
        .collection("topUpRequests")
        .where("referenceNumber", isEqualTo: referenceNumber)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return snap.docs.first.data();
    });
  }

  static Future<Map<String, dynamic>> createWithdrawalRequest({
    required double amount,
    required String userId,
    required String method,
    String? iban,
    String? bankName,
    String? accountHolderName,
    String? pickupName,
    String? pickupPhone,
    String? pickupIdNumber,
  }) async {

    final callable = FirebaseFunctions.instance
        .httpsCallable("requestWithdrawal");

    final result = await callable.call({
      "userId": userId,
      "amount": amount,
      "method": method,
      "iban": iban,
      "bankName": bankName,
      "accountHolderName": accountHolderName,
      "pickupName": pickupName,
      "pickupPhone": pickupPhone,
      "pickupIdNumber": pickupIdNumber,
    });

    return Map<String, dynamic>.from(result.data);
  }

  static Stream<List<Map<String, dynamic>>> userRecentTransactionsStream(String uid) async* {
    //Get USER wallet id
    final walletSnap = await FirebaseFirestore.instance
        .collection("wallets")
        .where("userId", isEqualTo: uid)
        .where("type", isEqualTo: "USER")
        .limit(1)
        .get();

    if (walletSnap.docs.isEmpty) {
      yield [];
      return;
    }

    final userWalletId = walletSnap.docs.first.id;

    yield* FirebaseFirestore.instance
        .collection("walletTransactions")
        .where("userId", isEqualTo: uid)
        .where("status", isEqualTo: "confirmed")
        .orderBy("createdAt", descending: true)
        .limit(50)
        .snapshots()
        .map((snap) {
      final all = snap.docs.where((d) {
        final data = d.data();
        return data["toWalletId"] == userWalletId ||
            data["fromWalletId"] == userWalletId;
      }).map((d) {
        final data = d.data();
        final ts = (data["createdAt"] as Timestamp).toDate();

        final isDeposit = data["toWalletId"] == userWalletId;

        return {
          "id": d.id,
          "amount": (data["amount"] as num).toDouble(),
          "type": isDeposit ? "deposit" : "withdrawal",
          "method": data["purpose"] ?? "Wallet",
          "status": data["status"],
          "date":
          "${ts.year}-${ts.month.toString().padLeft(2,'0')}-${ts.day.toString().padLeft(2,'0')}",
          "time":
          "${ts.hour.toString().padLeft(2,'0')}:${ts.minute.toString().padLeft(2,'0')}",
          "icon": isDeposit ? "credit_card" : "money",
          "color": isDeposit ? "green" : "red",
        };
      }).toList();

      return all;
    });
  }

  static Future<void> confirmPickup({
  required String requestId,
  required String qrToken,
  bool force = false,
}) async {

  // 🟢 DEV MODE (زر ⚡ فقط)
  if (kDebugMode && force) {
    await FirebaseFirestore.instance
        .collection('rentalRequests')
        .doc(requestId)
        .update({
      'status': 'active',
      'activatedAt': FieldValue.serverTimestamp(),
    });
    return;
  }

  // 🔐 PROD MODE (QR حقيقي)
  await FirebaseFunctions.instance
      .httpsCallable("confirmPickup")
      .call({
    "requestId": requestId,
    "qrToken": qrToken,
  });
}


  static Future<void> confirmReturn({
  required String requestId,
  required String qrToken,
  bool force = false,
}) async {

  // 🟢 DEV MODE (زر ⚡ فقط)
  if (kDebugMode && force) {
    await FirebaseFirestore.instance
        .collection('rentalRequests')
        .doc(requestId)
        .update({
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
    });
    return;
  }

  // 🔐 PROD MODE (QR حقيقي)
  await FirebaseFunctions.instance
      .httpsCallable("confirmReturn")
      .call({
    "requestId": requestId,
    "qrToken": qrToken,
  });
}

  static Future<void> submitIssueReport({
    required String requestId,
    required String type,
    String? severity,
    String? description,
    List<String>? mediaUrls,
  }) async {
    final callable =
    FirebaseFunctions.instance.httpsCallable('submitIssueReport');

    await callable.call({
      'requestId': requestId,
      'type': type,
      'severity': severity,
      'description': description,
      'mediaUrls': mediaUrls ?? [],
    });
  }

}
