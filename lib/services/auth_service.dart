import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _sessionKey = 'session_data';
  static const Duration _sessionTimeout = Duration(hours: 24);

  bool _isLoading = false;
  bool _isLoggedIn = false;
  Map<String, dynamic>? _userData;
  String? _currentUid;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get userData => _userData;
  String? get currentUid => _currentUid;

  AuthService() {
    _checkAuthStatus();
  }

  //  Session Check

  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    _isLoggedIn = await _isLoggedInSecurely();

    if (_isLoggedIn) {
      final user = _auth.currentUser;
      if (user != null) {
        _currentUid = user.uid;
        _userData = {
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
        };
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  //  Login

  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;

      await _syncUserToRealtimeDB(user!);

      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'error': 'Login failed'};
      }

      final token = await user.getIdToken();
      if (token == null || token.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'error': 'Failed to retrieve token',
        };
      }

      await _saveSession(
        userId: user.uid,
        idToken: token,
        rememberMe: rememberMe,
      );

      _isLoggedIn = true;
      _currentUid = user.uid;
      _userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
      };

      _isLoading = false;
      notifyListeners();

      return {
        'success': true,
        'uid': user.uid,
        'user': _userData,
      };
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'error': _firebaseErrorMessage(e.code),
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'error': 'Unexpected error: $e',
      };
    }
  }

  // Logout

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    if (_currentUid != null) {
      await FirebaseDatabase.instance
          .ref("users/$_currentUid")
          .update({
        "status": "offline",
        "lastSeen": DateTime.now().millisecondsSinceEpoch,
      });
    }

    try {
      await _auth.signOut();
      await _secureStorage.delete(key: _sessionKey);

      _isLoggedIn = false;
      _currentUid = null;
      _userData = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Password Reset

  Future<void> resetPassword(String email) async {
    if (email.trim().isEmpty) throw Exception('Email is required');
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      return {
        "success": true,
        "uid": cred.user!.uid,
      };
    } on FirebaseAuthException catch (e) {
      return {
        "success": false,
        "error": _firebaseErrorMessage(e.code),
      };
    }
  }

  //  Secure Session

  Future<bool> _isLoggedInSecurely() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final session = await _getSession();
    if (session == null) return false;

    final timestamp = session['timestamp'];
    if (timestamp is! int) return false;

    final sessionTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final expired = DateTime.now().difference(sessionTime) > _sessionTimeout;

    return !expired;
  }

  Future<void> _saveSession({
    required String userId,
    required String idToken,
    required bool rememberMe,
  }) async {
    final data = {
      'userId': userId,
      'token': idToken,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'rememberMe': rememberMe,
    };

    await _secureStorage.write(
      key: _sessionKey,
      value: jsonEncode(data),
    );
  }

  Future<Map<String, dynamic>?> _getSession() async {
    try {
      final raw = await _secureStorage.read(key: _sessionKey);
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Session read failed: $e');
      }
      return null;
    }
  }

  Future<void> _syncUserToRealtimeDB(User user) async {
    final db = FirebaseDatabase.instance.ref("users/${user.uid}");

    final fcmToken = await FirebaseMessaging.instance.getToken();

    await db.update({
      "uid": user.uid,
      "email": user.email,
      "name": user.displayName ?? user.email?.split('@').first ?? "User",
      "fcmToken": fcmToken,
      "status": "online",
      "lastSeen": DateTime.now().millisecondsSinceEpoch,
    });
  }

  //  Validation Helpers

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  //  Error Mapping

  String _firebaseErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'too-many-requests':
        return 'Too many attempts, try again later';
      case 'network-request-failed':
        return 'Network error, please check your connection';
      default:
        return 'Authentication failed';
    }
  }
}
