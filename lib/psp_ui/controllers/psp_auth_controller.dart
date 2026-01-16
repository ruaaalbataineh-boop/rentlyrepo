import 'package:firebase_auth/firebase_auth.dart';

class PspAuthController {
  Future<void> login(String email, String password) {
    return FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
  }

  Stream<User?> authState() {
    return FirebaseAuth.instance.authStateChanges();
  }

  Future<void> logout() {
    return FirebaseAuth.instance.signOut();
  }
}
