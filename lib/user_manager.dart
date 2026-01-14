import 'package:firebase_auth/firebase_auth.dart';

class UserManager {
  
  static String? _testUid;

  
  static void setTestUid(String? uid) {
    _testUid = uid;
  }

  static String? get uid {
    
    if (_testUid != null) {
      return _testUid;
    }

    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }
}
