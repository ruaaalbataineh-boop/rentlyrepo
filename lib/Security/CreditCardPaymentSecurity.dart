import 'dart:convert';
import 'dart:math';
import 'package:p2/security/secure_storage.dart';
import 'package:p2/security/error_handler.dart';

class CreditCardPaymentSecurity {
  // حدود الدفع
  static const double minPaymentAmount = 1.0;
  static const double maxPaymentAmount = 10000.0;
  static const int maxPaymentsPerHour = 10;
  static const int maxPaymentsPerDay = 50;

  //  تسجيل دخول صفحة الدفع
  static void logPaymentPageAccess(double amount, String reference) {
    ErrorHandler.logInfo('Payment Page Access', '''
Amount: ${amount.toStringAsFixed(2)}
Reference: ${_maskReference(reference)}
Time: ${DateTime.now().toIso8601String()}
''');
  }

  //  التحقق من صحة المبلغ
  static bool isValidAmount(double amount) {
    if (amount <= 0) return false;
    if (amount < minPaymentAmount) return false;
    if (amount > maxPaymentAmount) return false;
    if (amount.isNaN || amount.isInfinite) return false;
    return true;
  }

  //  التحقق من صحة المرجع
  static bool isValidReference(String reference) {
    if (reference.isEmpty) return false;
    if (reference.length < 5) return false;
    if (reference.length > 50) return false;
    return RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(reference);
  }

  //  التحقق من حدود الدفع
  static bool isWithinPaymentLimits(double amount) {
    if (!isValidAmount(amount)) return false;
    
    // يمكن إضافة تحقق من تاريخ المستخدم هنا
    return true;
  }

  //  تسجيل بدء جلسة الدفع
  static Future<void> logPaymentSessionStart({
    required double amount,
    required String reference,
  }) async {
    await SecureStorage.saveData(
      'payment_session_start_${DateTime.now().millisecondsSinceEpoch}',
      json.encode({
        'amount': amount,
        'reference': _maskReference(reference),
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  }

  //  تسجيل محاولة دفع
  static Future<void> logPaymentAttempt(double amount) async {
    final attempts = await _getPaymentAttempts();
    attempts.add({
      'amount': amount,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // الحفاظ على آخر 100 محاولة فقط
    if (attempts.length > 100) {
      attempts.removeAt(0);
    }

    await SecureStorage.saveData(
      'payment_attempts',
      json.encode(attempts),
    );
  }

  //  تسجيل نجاح الدفع
  static Future<void> logPaymentSuccess({
    required double amount,
    required String reference,
    required int duration,
  }) async {
    final successData = {
      'amount': amount,
      'reference': _maskReference(reference),
      'duration_ms': duration,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'success',
    };

    await SecureStorage.saveData(
      'payment_success_${DateTime.now().millisecondsSinceEpoch}',
      json.encode(successData),
    );

    ErrorHandler.logInfo('Payment Success', '''
Amount: ${amount.toStringAsFixed(2)}
Reference: ${_maskReference(reference)}
Duration: ${duration}ms
''');
  }

  //  تسجيل فشل الدفع
  static Future<void> logPaymentFailure({
    required double amount,
    required String reference,
    required String error,
  }) async {
    final failureData = {
      'amount': amount,
      'reference': _maskReference(reference),
      'error': _sanitizeError(error),
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'failed',
    };

    await SecureStorage.saveData(
      'payment_failure_${DateTime.now().millisecondsSinceEpoch}',
      json.encode(failureData),
    );

    ErrorHandler.logError('Payment Failure', '''
Amount: ${amount.toStringAsFixed(2)}
Reference: ${_maskReference(reference)}
Error: ${_sanitizeError(error)}
''');
  }

  // 🔒 توليد ID للمعاملة
  static String generateTransactionId() {
    final random = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(1000000);
    return 'TXN_${timestamp}_${randomNum.toString().padLeft(6, '0')}';
  }

  // ==================== دوال مساعدة ====================

  static Future<List<dynamic>> _getPaymentAttempts() async {
    final attemptsJson = await SecureStorage.getData('payment_attempts');
    if (attemptsJson == null) return [];
    
    try {
      return List<dynamic>.from(json.decode(attemptsJson));
    } catch (e) {
      return [];
    }
  }

  static String _maskReference(String reference) {
    if (reference.length <= 8) return '***';
    return '${reference.substring(0, 3)}...${reference.substring(reference.length - 3)}';
  }

  static String _sanitizeError(String error) {
    // إزالة البيانات الحساسة من رسائل الخطأ
    return error
        .replaceAll(RegExp(r'\b4[0-9]{12}(?:[0-9]{3})?\b'), '[CARD]') // أرقام بطاقات
        .replaceAll(RegExp(r'\b3[47][0-9]{13}\b'), '[CARD]') // أمريكان إكسبريس
        .replaceAll(RegExp(r'\b(?:5[1-5][0-9]{2}|222[1-9]|22[3-9][0-9]|2[3-6][0-9]{2}|27[01][0-9]|2720)[0-9]{12}\b'), '[CARD]') // ماستركارد
        .replaceAll(RegExp(r'\b\d{3}\b'), '[CVV]') // CVV
        .replaceAll(RegExp(r'\b\d{2}/\d{2}\b'), '[EXP]'); // تاريخ الانتهاء
  }
}
