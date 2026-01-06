import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FcmService {
  static final _messaging = FirebaseMessaging.instance;
  static final _db = FirebaseDatabase.instance;

  static Future<void> init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 
    await _messaging.requestPermission();

    // get token
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(user.uid, token);
    }

    // listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await _saveToken(user.uid, newToken);
    });
  }

  static Future<void> _saveToken(String uid, String token) async {
    await _db.ref("users/$uid").update({
      "fcmToken": token,
      "updatedAt": ServerValue.timestamp,
    });
  }
}

