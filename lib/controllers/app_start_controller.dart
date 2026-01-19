import '../services/auth_service.dart';

class AppStartController {
  final AuthService auth;

  AppStartController(this.auth);

  Future<String> getInitialRoute() async {
    return auth.isLoggedIn ? '/category' : '/login';
  }
}
