import 'package:firebase_auth/firebase_auth.dart';

import '../main_user.dart';

class RouteGuard {
  static bool testAuthenticated = false;
  static bool isAuthenticated() {
    if (testAuthenticated) return true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      return user != null;
    } on ArgumentError catch (e) {
      
      print(' RouteGuard ArgumentError: ${e.message}');
      return false;
    } catch (e) {
      print(' RouteGuard Error: $e');
      return false;
    }
  }
}
