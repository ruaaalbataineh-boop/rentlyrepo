import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/psp_service.dart';

class PspDashboardController {
  final PspService _service = PspService();

  Stream<QuerySnapshot<Map<String, dynamic>>> getTopups() {
    return _service.pendingTopups();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getWithdrawals() {
    return _service.pendingWithdrawals();
  }

  Future<void> approveTopup(String id) => _service.approveTopup(id);
  Future<void> rejectTopup(String id) => _service.rejectTopup(id);

  Future<void> approveWithdrawal(String id) => _service.approveWithdrawal(id);
  Future<void> rejectWithdrawal(String id) => _service.rejectWithdrawal(id);
}
