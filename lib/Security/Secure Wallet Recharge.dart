import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:p2/logic/wallet_recharge_logic.dart';
import 'package:p2/services/auth_service.dart';
import 'package:provider/provider.dart';

// ==================== Secure Storage ====================
class SecureWalletStorage {
  static final _storage = FlutterSecureStorage();

  static Future<void> initialize() async {
    try {
      await _storage.write(key: '_init', value: 'ok');
      await _storage.delete(key: '_init');
    } catch (e) {
      print('Secure Storage Failed: $e');
    }
  }

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: _encrypt(token));
  }

  static Future<String?> getToken() async {
    final encrypted = await _storage.read(key: 'auth_token');
    return encrypted != null ? _decrypt(encrypted) : null;
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

  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) return 'Please enter amount';

    final cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');
    if (!RegExp(_amountPattern).hasMatch(cleanValue)) return 'Invalid format';

    final amount = double.tryParse(cleanValue);
    if (amount == null) return 'Invalid number';

    if (amount <= 0) return 'Amount must be > 0';
    if (amount < WalletRechargeLogic.minRechargeAmount) return 'Min: ${WalletRechargeLogic.minRechargeAmount}';
    if (amount > WalletRechargeLogic.maxRechargeAmount) return 'Max: ${WalletRechargeLogic.maxRechargeAmount}';

    return null;
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

  static void updateActivity() => _lastActivity = DateTime.now();

  static Future<void> _handleSessionExpired() async {
    await SecureWalletStorage.clearSession();
    print('Session expired');
  }

  static void stopMonitoring() => _sessionTimer?.cancel();
}

// ==================== Transaction Security ====================
class TransactionSecurity {
  static final List<Map<String, dynamic>> _recentTransactions = [];
  static const _maxTransactionsPerMinute = 5;

  static bool canProceedWithTransaction(double amount, BuildContext context) {
    final now = DateTime.now();

    _recentTransactions.removeWhere(
          (tx) => now.difference(tx['time']) > const Duration(minutes: 1),
    );

    if (_recentTransactions.length >= _maxTransactionsPerMinute) {
      return false;
    }

    final uid = context.read<AuthService>().currentUid ?? 'unknown';

    _recentTransactions.add({
      'amount': amount,
      'time': now,
      'user': uid,
    });

    return true;
  }

  static String generateSecureTransactionId() {
    final random = Random.secure();
    return "TX${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(999999).toString().padLeft(6, "0")}";
  }
}

// ==================== API Security ====================
class WalletApiSecurity {
  static Future<Map<String, dynamic>> secureApiCall(
      String endpoint, Map<String, dynamic> data) async {
    try {
      if (!await SecureWalletStorage.validateSession()) {
        throw Exception('Session invalid');
      }

      final validated = _validateRequestData(data);

      await Future.delayed(const Duration(seconds: 1));

      _logApiCall(endpoint, validated);

      return {
        'success': true,
        'data': validated,
        'transaction_id': TransactionSecurity.generateSecureTransactionId()
      };
    } catch (e) {
      return {'success': false, 'error': _getSafeErrorMessage(e)};
    }
  }

  static Map<String, dynamic> _validateRequestData(Map<String, dynamic> data) {
    final cleaned = <String, dynamic>{};
    for (final e in data.entries) {
      cleaned[e.key] = e.value is String ? _sanitize(e.value) : e.value;
    }
    return cleaned;
  }
  static String _sanitize(String v) {
    return v.replaceAll(RegExp('[<>"\']'), '').trim();
  }

  static void _logApiCall(String endpoint, Map data) {
    print('API Call: $endpoint');
    print('Data: ${jsonEncode(data)}');
  }

  static String _getSafeErrorMessage(dynamic error) {
    final e = error.toString().toLowerCase();
    if (e.contains('network')) return 'Network error';
    if (e.contains('auth')) return 'Session expired';
    return 'Unexpected error';
  }
}

// ==================== UI Widgets ====================
class SecurityOverlay extends StatelessWidget {
  final Widget child;
  const SecurityOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      child,
      Positioned(
        top: 10,
        right: 10,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(children: [
            Icon(Icons.verified_user, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text('Secure', style: TextStyle(color: Colors.white))
          ]),
        ),
      )
    ]);
  }
}

// ==================== Main Security Handler ====================
class WalletSecurityHandler {
  static Future<void> initialize() async {
    await SecureWalletStorage.initialize();
    WalletSessionSecurity.startMonitoring();
  }

  static void dispose() => WalletSessionSecurity.stopMonitoring();

  static Future<bool> validatePaymentRequest({
    required double amount,
    required String method,
    required BuildContext context,
  }) async {
    if (!await SecureWalletStorage.validateSession()) {
      _alert(context, 'Session expired');
      return false;
    }

    if (!WalletRechargeLogic.isAmountSecure(amount)) {
      _alert(context, 'Invalid amount');
      return false;
    }

    if (!TransactionSecurity.canProceedWithTransaction(amount, context)) {
      _alert(context, 'Too many transactions');
      return false;
    }

    if (!WalletRechargeLogic.isPaymentMethodSecure(method)) {
      _alert(context, 'Invalid payment method');
      return false;
    }

    WalletSessionSecurity.updateActivity();
    return true;
  }

  static void _alert(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }
}
