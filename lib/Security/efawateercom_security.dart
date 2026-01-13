import 'dart:convert';
import 'package:p2/security/secure_storage.dart';
import 'package:p2/security/error_handler.dart';

class EfawateercomSecurity {
  // حدود الدفع
  static const double minAmount = 0.01;
  static const double maxAmount = 100000.0;

  //  التحقق من صحة المبلغ
  static bool isValidAmount(double amount) {
    try {
      if (amount <= 0) return false;
      if (amount < minAmount) return false;
      if (amount > maxAmount) return false;
      if (amount.isNaN || amount.isInfinite) return false;
      
      // التحقق من المنازل العشرية
      final amountString = amount.toString();
      final decimalParts = amountString.split('.');
      if (decimalParts.length > 1 && decimalParts[1].length > 2) {
        return false;
      }
      
      return true;
    } catch (error) {
      ErrorHandler.logError('Validate Amount', error);
      return false;
    }
  }

  //  التحقق من صحة المرجع
  static bool isValidReference(String reference) {
    try {
      if (reference.isEmpty) return false;
      if (reference.length < 5) return false;
      if (reference.length > 50) return false;
      
      // فقط الحروف والأرقام والشرطات
      return RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(reference);
    } catch (error) {
      ErrorHandler.logError('Validate Reference', error);
      return false;
    }
  }

  //  تسجيل دخول الصفحة
  static Future<void> logPageAccess({
    required double amount,
    required String reference,
  }) async {
    try {
      final maskedReference = _maskReference(reference);
      
      ErrorHandler.logInfo('Efawateercom Page Access', '''
Amount: ${amount.toStringAsFixed(2)} JD
Reference: $maskedReference
Time: ${DateTime.now().toIso8601String()}
''');

      // تخزين في السجل
      await _storeAuditLog('page_access', {
        'amount': amount,
        'reference': maskedReference,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (error) {
      ErrorHandler.logError('Log Page Access', error);
    }
  }

  //  تسجيل خروج الصفحة
  static void logPageExit({
    required double amount,
    required String reference,
  }) {
    try {
      final maskedReference = _maskReference(reference);
      
      ErrorHandler.logInfo('Efawateercom Page Exit', '''
Amount: ${amount.toStringAsFixed(2)} JD
Reference: $maskedReference
Time: ${DateTime.now().toIso8601String()}
''');
    } catch (error) {
      ErrorHandler.logError('Log Page Exit', error);
    }
  }

  // ==================== دوال مساعدة ====================

  //  إخفاء المرجع جزئياً
  static String _maskReference(String reference) {
    if (reference.length <= 8) return '***';
    return '${reference.substring(0, 3)}...${reference.substring(reference.length - 3)}';
  }

  //  تخزين في سجل التدقيق
  static Future<void> _storeAuditLog(String event, Map<String, dynamic> data) async {
    try {
      final existingLogs = await SecureStorage.getData('efawateercom_audit_logs') ?? '[]';
      final List<dynamic> logs = List<dynamic>.from(json.decode(existingLogs));
      
      logs.add({
        'event': event,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // الحفاظ على آخر 100 إدخال فقط
      if (logs.length > 100) {
        logs.removeAt(0);
      }
      
      await SecureStorage.saveData('efawateercom_audit_logs', json.encode(logs));
    } catch (error) {
      ErrorHandler.logError('Store Audit Log', error);
    }
  }

  //  التحقق من وجود أنشطة مشبوهة
  static Future<bool> detectSuspiciousActivity() async {
    try {
      final logsJson = await SecureStorage.getData('efawateercom_audit_logs') ?? '[]';
      final List<dynamic> logs = List<dynamic>.from(json.decode(logsJson));
      
      if (logs.isEmpty) return false;
      
      // التحقق من الوصول المتكرر في وقت قصير
      final recentAccesses = logs.where((log) {
        if (log is Map<String, dynamic> && log['event'] == 'page_access') {
          final timestamp = log['timestamp'] as String;
          final logTime = DateTime.tryParse(timestamp);
          if (logTime != null) {
            final timeDifference = DateTime.now().difference(logTime);
            return timeDifference.inMinutes < 5; // آخر 5 دقائق
          }
        }
        return false;
      }).toList();
      
      if (recentAccesses.length > 10) {
        ErrorHandler.logSecurity('Suspicious Activity', 
            'Multiple page accesses detected: ${recentAccesses.length} in 5 minutes');
        return true;
      }
      
      return false;
    } catch (error) {
      ErrorHandler.logError('Detect Suspicious Activity', error);
      return false;
    }
  }

  //  تنظيف سجلات التدقيق القديمة
  static Future<void> cleanupOldLogs() async {
    try {
      final logsJson = await SecureStorage.getData('efawateercom_audit_logs') ?? '[]';
      final List<dynamic> logs = List<dynamic>.from(json.decode(logsJson));
      
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      
      final filteredLogs = logs.where((log) {
        if (log is Map<String, dynamic>) {
          final timestamp = log['timestamp'] as String;
          final logTime = DateTime.tryParse(timestamp);
          if (logTime != null) {
            return logTime.isAfter(thirtyDaysAgo);
          }
        }
        return false;
      }).toList();
      
      if (filteredLogs.length != logs.length) {
        await SecureStorage.saveData('efawateercom_audit_logs', json.encode(filteredLogs));
      }
    } catch (error) {
      ErrorHandler.logError('Cleanup Old Logs', error);
    }
  }
}
