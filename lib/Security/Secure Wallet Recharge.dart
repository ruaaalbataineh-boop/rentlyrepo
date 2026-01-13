import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:p2/services/firestore_service.dart';
import 'package:p2/user_manager.dart';
import 'package:p2/logic/wallet_recharge_logic.dart';

// ==================== Secure Storage ====================
class SecureWalletStorage {
  static final _storage = FlutterSecureStorage();
  
  static Future<void> initialize() async {
    try {
      await _storage.write(key: '_init', value: 'ok');
      await _storage.delete(key: '_init');
    } catch (e) {
      print(' Secure Storage Failed: $e');
    }
  }

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: _encrypt(token));
  }

  static Future<String?> getToken() async {
    final encrypted = await _storage.read(key: 'auth_token');
    return encrypted != null ? _decrypt(encrypted) : null;
  }

  static Future<void> saveSession(String sessionId) async {
    await _storage.write(key: 'session_${DateTime.now().day}', value: sessionId);
  }

  static Future<bool> validateSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearSession() async {
    await _storage.deleteAll();
  }

  static String _encrypt(String text) => base64.encode(utf8.encode(text));
  static String _decrypt(String encrypted) => utf8.decode(base64.decode(encrypted));
}

// ==================== Input Security ====================
class WalletInputSecurity {
  static const _amountPattern = r'^\d{1,8}(\.\d{1,2})?$';
  static final _maliciousPatterns = [
    '<script', 'javascript:', 'onload=', 'onerror=',
    'eval(', 'document.cookie', 'alert(', 'confirm('
  ];

  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter amount';
    }

    // 1. Check for malicious code
    final lowerValue = value.toLowerCase();
    if (_maliciousPatterns.any((pattern) => lowerValue.contains(pattern))) {
      _logSecurityThreat('Malicious amount input detected');
      return 'Invalid input';
    }

    // 2. Clean input
    final cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');
    if (cleanValue.isEmpty) {
      return 'Please enter a valid number';
    }

    // 3. Validate format
    if (!RegExp(_amountPattern).hasMatch(cleanValue)) {
      return 'Invalid amount format';
    }

    // 4. Parse safely
    final amount = double.tryParse(cleanValue);
    if (amount == null) {
      return 'Invalid number';
    }

    // 5. Check limits
    if (amount <= 0) return 'Amount must be > 0';
    if (amount < WalletRechargeLogic.minRechargeAmount) {
      return 'Min: \$${WalletRechargeLogic.minRechargeAmount}';
    }
    if (amount > WalletRechargeLogic.maxRechargeAmount) {
      return 'Max: \$${WalletRechargeLogic.maxRechargeAmount}';
    }

    // 6. Check for suspicious amounts
    if (_isSuspiciousAmount(amount)) {
      _logSecurityThreat('Suspicious amount: $amount');
      return 'Amount requires verification';
    }

    return null;
  }

  static bool _isSuspiciousAmount(double amount) {
    // Round numbers check
    if (amount % 10000 == 0 && amount > 10000) return true;
    
    // Common fraud amounts
    final fraudAmounts = [999, 9999, 99999, 100001, 500001];
    if (fraudAmounts.contains(amount.toInt())) return true;
    
    return false;
  }

  static void _logSecurityThreat(String message) {
    print(' SECURITY THREAT: $message');
  }
}

// ==================== Session Security ====================
class WalletSessionSecurity {
  static DateTime? _lastActivity;
  static Timer? _sessionTimer;
  static const _sessionTimeout = Duration(minutes: 15);

  static void startMonitoring() {
    _lastActivity = DateTime.now();
    
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_lastActivity != null && 
          DateTime.now().difference(_lastActivity!) > _sessionTimeout) {
        _handleSessionExpired();
        timer.cancel();
      }
    });
  }

  static void updateActivity() {
    _lastActivity = DateTime.now();
  }

  static Future<void> _handleSessionExpired() async {
    await SecureWalletStorage.clearSession();
    print(' Session expired - cleared secure storage');
  }

  static void stopMonitoring() {
    _sessionTimer?.cancel();
  }
}

// ==================== Transaction Security ====================
class TransactionSecurity {
  static final List<Map<String, dynamic>> _recentTransactions = [];
  static const _maxTransactionsPerMinute = 5;

  static bool canProceedWithTransaction(double amount) {
    // 1. Check frequency
    final now = DateTime.now();
    _recentTransactions.removeWhere((tx) => 
        now.difference(tx['time'] as DateTime) > const Duration(minutes: 1));
    
    if (_recentTransactions.length >= _maxTransactionsPerMinute) {
      _logSecurityThreat('Transaction rate limit exceeded');
      return false;
    }

    // 2. Check amount patterns
    if (_isUnusualAmount(amount)) {
      _logSecurityThreat('Unusual amount pattern: $amount');
    }

    // 3. Record transaction
    _recentTransactions.add({
      'amount': amount,
      'time': now,
      'user': UserManager.uid ?? 'unknown'
    });

    return true;
  }

  static bool _isUnusualAmount(double amount) {
    // Just below limits
    if (amount >= WalletRechargeLogic.maxRechargeAmount * 0.95) return true;
    
    // Unusual decimals
    if (amount.toString().split('.')[1].length > 2) return true;
    
    return false;
  }

  static String generateSecureTransactionId() {
    final random = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(1000000);
    return 'TX${timestamp}_${randomNum.toString().padLeft(6, '0')}';
  }

  static void _logSecurityThreat(String message) {
    print(' TRANSACTION SECURITY: $message');
  }
}

// ==================== API Security ====================
class WalletApiSecurity {
  static Future<Map<String, dynamic>> secureApiCall(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      // 1. Validate session
      if (!await SecureWalletStorage.validateSession()) {
        throw Exception('Session invalid');
      }

      // 2. Add security headers
      final headers = await _getSecureHeaders();

      // 3. Validate data
      final validatedData = _validateRequestData(data);

      // 4. Make API call (simulated)
      await Future.delayed(const Duration(seconds: 1));

      // 5. Log for security audit
      _logApiCall(endpoint, validatedData);

      return {
        'success': true,
        'data': validatedData,
        'transaction_id': TransactionSecurity.generateSecureTransactionId()
      };

    } catch (error) {
      print(' API Security Error: $error');
      return {
        'success': false,
        'error': _getSafeErrorMessage(error)
      };
    }
  }

  static Future<Map<String, String>> _getSecureHeaders() async {
    final token = await SecureWalletStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ""}',
      'X-Request-ID': 'req_${DateTime.now().millisecondsSinceEpoch}',
      'X-Platform': 'Flutter',
      'X-Security-Level': 'high',
    };
  }

  static Map<String, dynamic> _validateRequestData(Map<String, dynamic> data) {
    final cleaned = <String, dynamic>{};
    
    for (final entry in data.entries) {
      if (entry.value is String) {
        cleaned[entry.key] = _sanitizeString(entry.value as String);
      } else if (entry.value is Map) {
        cleaned[entry.key] = _validateRequestData(entry.value as Map<String, dynamic>);
      } else {
        cleaned[entry.key] = entry.value;
      }
    }
    
    return cleaned;
  }

  static String _sanitizeString(String input) {
    return input
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .trim();
  }

  static void _logApiCall(String endpoint, Map<String, dynamic> data) {
    print(' API Call: $endpoint');
    print('   Data: ${jsonEncode(data)}');
    print('   Time: ${DateTime.now()}');
  }

  static String _getSafeErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('network') || errorStr.contains('timeout')) {
      return 'Network error. Check connection.';
    } else if (errorStr.contains('auth') || errorStr.contains('token')) {
      return 'Session expired. Please login again.';
    } else if (errorStr.contains('permission') || errorStr.contains('denied')) {
      return 'Permission denied.';
    } else {
      return 'An error occurred. Please try again.';
    }
  }
}

// ==================== UI Security Widgets ====================
class SecurityOverlay extends StatelessWidget {
  final Widget child;
  final bool showShield;

  const SecurityOverlay({
    super.key,
    required this.child,
    this.showShield = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (showShield)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Secure',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class SecureInputField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String hintText;
  final TextInputType keyboardType;

  const SecureInputField({
    super.key,
    required this.controller,
    this.validator,
    required this.hintText,
    this.keyboardType = TextInputType.number,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F0F46),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => controller.clear(),
        ),
      ),
      onChanged: (value) {
        WalletSessionSecurity.updateActivity();
      },
    );
  }
}

// ==================== Main Security Handler ====================
class WalletSecurityHandler {
  static Future<void> initialize() async {
    print(' Initializing Wallet Security...');
    
    // 1. Initialize secure storage
    await SecureWalletStorage.initialize();
    
    // 2. Start session monitoring
    WalletSessionSecurity.startMonitoring();
    
    // 3. Validate current session
    final isValid = await SecureWalletStorage.validateSession();
    
    if (!isValid) {
      print(' No valid session found');
    } else {
      print(' Security initialized successfully');
    }
  }

  static void dispose() {
    WalletSessionSecurity.stopMonitoring();
    print('🛡️ Security disposed');
  }

  static Future<bool> validatePaymentRequest({
    required double amount,
    required String method,
    required BuildContext context,
  }) async {
    try {
      // 1. Session check
      if (!await SecureWalletStorage.validateSession()) {
        _showSecurityAlert(context, 'Session expired. Please login again.');
        return false;
      }

      // 2. Amount security
      if (!WalletRechargeLogic.isAmountSecure(amount)) {
        _showSecurityAlert(context, 'Invalid amount');
        return false;
      }

      // 3. Transaction limits
      if (!TransactionSecurity.canProceedWithTransaction(amount)) {
        _showSecurityAlert(context, 'Too many transactions. Please wait.');
        return false;
      }

      // 4. Method security
      if (!WalletRechargeLogic.isPaymentMethodSecure(method)) {
        _showSecurityAlert(context, 'Payment method not available');
        return false;
      }

      // 5. Update activity
      WalletSessionSecurity.updateActivity();

      return true;

    } catch (error) {
      _showSecurityAlert(context, 'Security check failed');
      return false;
    }
  }

  static void _showSecurityAlert(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.security, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
