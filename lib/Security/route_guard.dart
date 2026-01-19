import 'package:firebase_auth/firebase_auth.dart';

import '../main_user.dart';
import '../services/auth_service.dart';

class RouteGuard {
  static bool testAuthenticated = false;

  static bool isAuthenticated() {
    if (testAuthenticated) return true;
    return false;
  }
}
