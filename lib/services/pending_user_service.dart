import 'package:cloud_functions/cloud_functions.dart';

class PendingUserService {
  static final _functions = FirebaseFunctions.instance;

  static Future<void> submitUserForApproval(Map<String, dynamic> data) async {
    final callable = _functions.httpsCallable('submitUserForApproval');
    await callable.call(data);
  }
}