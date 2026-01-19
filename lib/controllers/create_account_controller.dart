import '../services/auth_service.dart';

class CreateAccountController {
  final AuthService _auth;

  CreateAccountController(this._auth);

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
  }) async {
    return _auth.createUser(email: email, password: password);
  }
}
