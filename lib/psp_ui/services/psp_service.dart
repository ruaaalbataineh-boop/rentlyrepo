import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class PspService {
  final _firestore = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> pendingTopups() {
    return _firestore
        .collection('topUpRequests')
        .where('status', isEqualTo: 'pending')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> pendingWithdrawals() {
    return _firestore
        .collection('withdrawalRequests')
        .where('status', isEqualTo: 'pending')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt')
        .snapshots();
  }

  Future<void> approveTopup(String id) {
    return _functions
        .httpsCallable('approveEfawateerkomTopUp')
        .call({'topUpId': id});
  }

  Future<void> rejectTopup(String id) {
    return _functions
        .httpsCallable('rejectEfawateerkomTopUp')
        .call({'topUpId': id});
  }

  Future<void> approveWithdrawal(String id) {
    return _functions
        .httpsCallable('approveWithdrawal')
        .call({'withdrawalId': id});
  }

  Future<void> rejectWithdrawal(String id) {
    return _functions
        .httpsCallable('rejectWithdrawal')
        .call({'withdrawalId': id});
  }
}
