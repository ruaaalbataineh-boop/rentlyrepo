import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LogoutService {
  static final LogoutService _instance = LogoutService._internal();
  factory LogoutService() => _instance;
  LogoutService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Standard logout
  Future<Map<String, dynamic>> logout({bool fromAllDevices = false}) async {
    try {
      final user = _auth.currentUser;
      final userId = user?.uid;

      // Remove device token if logging out from all devices
      if (fromAllDevices && userId != null) {
        final deviceToken = await _getDeviceToken();
        if (deviceToken != null) {
          await _firestore.collection('users').doc(userId).update({
            'device_tokens': FieldValue.arrayRemove([deviceToken]),
            'last_logout': FieldValue.serverTimestamp(),
          });
        }
      }

      // Firebase sign out
      await _auth.signOut();

      // Clear secure local storage
      await _secureStorage.deleteAll();

      return {
        'success': true,
        'message': 'Logged out successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Logout failed: $e',
      };
    }
  }

  /// Get device token (FCM – optional)
  Future<String?> _getDeviceToken() async {
    // You can integrate Firebase Cloud Messaging here if needed
    return null;
  }
}
