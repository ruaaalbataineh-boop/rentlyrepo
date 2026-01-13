import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  static const String _sessionKey = 'secure_session_token';
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

  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final UserCredential credential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user!;
      final token = await user.getIdToken();

      if (token == null || token.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'error': 'Failed to retrieve token'};
      }

      await _saveSecureSession(
        userId: user.uid,
        idToken: token,
        rememberMe: rememberMe,
      );

      await _logSecurityEvent(
        userId: user.uid,
        event: 'LOGIN_SUCCESS',
        details: {'method': 'email'},
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
      await _logSecurityEvent(
        userId: email,
        event: 'LOGIN_FAILED',
        details: {'error': e.code},
      );

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
        'error': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  Future<void> logout({bool fromAllDevices = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.signOut();
      await _secureStorage.deleteAll();

      _isLoggedIn = false;
      _currentUid = null;
      _userData = null;
      
      await _logSecurityEvent(
        userId: _currentUid ?? 'unknown',
        event: 'LOGOUT_SUCCESS',
        details: {'fromAllDevices': fromAllDevices},
      );
    } catch (e) {
      await _logSecurityEvent(
        userId: _currentUid ?? 'unknown',
        event: 'LOGOUT_FAILED',
        details: {'error': e.toString()},
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _isLoggedInSecurely() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final session = await _getSecureSession();
      if (session == null) return false;

      final timestamp = session['timestamp'];
      if (timestamp == null || _isSessionExpired(timestamp)) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'emailVerified': user.emailVerified,
    };
  }

  String? getCurrentUid() {
    return _auth.currentUser?.uid;
  }

  Future<void> _saveSecureSession({
    required String userId,
    required String idToken,
    required bool rememberMe,
  }) async {
    final sessionData = {
      'userId': userId,
      'token': idToken,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'rememberMe': rememberMe,
    };

    final encrypted = _encrypt(jsonEncode(sessionData));
    await _secureStorage.write(key: _sessionKey, value: encrypted);
  }

  Future<Map<String, dynamic>?> _getSecureSession() async {
    try {
      final encrypted = await _secureStorage.read(key: _sessionKey);
      if (encrypted == null) return null;
      return _decrypt(encrypted);
    } catch (e) {
      return null;
    }
  }

  bool _isSessionExpired(dynamic timestamp) {
    try {
      if (timestamp is! int) return true;
      final sessionTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateTime.now().difference(sessionTime) > _sessionTimeout;
    } catch (e) {
      return true;
    }
  }

  String _encrypt(String data) {
    try {
      final bytes = utf8.encode(data);
      final hash = sha256.convert(bytes).bytes;
      return base64Encode(hash + bytes);
    } catch (e) {
      return data;
    }
  }

  Map<String, dynamic>? _decrypt(String encrypted) {
    try {
      final bytes = base64Decode(encrypted);
      final data = bytes.sublist(32);
      return jsonDecode(utf8.decode(data));
    } catch (_) {
      return null;
    }
  }

  Future<void> _logSecurityEvent({
    required String userId,
    required String event,
    required Map<String, dynamic> details,
  }) async {
    try {
      await _firestore.collection('security_logs').add({
        'userId': userId,
        'event': event,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'deviceToken': await FirebaseMessaging.instance.getToken() ?? 'unknown',
      });
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log security event: $e');
      }
    }
  }

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
        return 'Authentication failed: $code';
    }
  }
  
  Future<void> resetPassword(String email) async {
    if (email.trim().isEmpty) {
      throw Exception('Email is required');
    }

    await _auth.sendPasswordResetEmail(email: email.trim());

    await _logSecurityEvent(
      userId: email,
      event: 'PASSWORD_RESET_REQUESTED',
      details: {},
    );
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
}
