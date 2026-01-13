import 'package:firebase_auth/firebase_auth.dart';

class RouteGuard {
  static bool isAuthenticated() {
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
