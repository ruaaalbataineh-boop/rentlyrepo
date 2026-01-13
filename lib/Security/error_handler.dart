import 'dart:convert';

class ErrorHandler {
  static String getSafeError(dynamic error) {
    try {
      String errorMsg = error.toString();
      
      // Hide sensitive info
      final lowerError = errorMsg.toLowerCase();
      if (lowerError.contains('password') || 
          lowerError.contains('token') || 
          lowerError.contains('email') ||
          lowerError.contains('uid') ||
          lowerError.contains('auth') ||
          lowerError.contains('firebase') ||
          lowerError.contains('apikey') ||
          lowerError.contains('secret')) {
        return 'Authentication error. Please try again.';
      }
      
      if (lowerError.contains('timeout') || 
          lowerError.contains('network') ||
          lowerError.contains('socket') ||
          lowerError.contains('connection')) {
        return 'Network error. Check your connection.';
      }
      
      if (lowerError.contains('permission') ||
          lowerError.contains('denied') ||
          lowerError.contains('unauthorized')) {
        return 'Access denied. Please check your permissions.';
      }
      
      if (lowerError.contains('database') ||
          lowerError.contains('firestore') ||
          lowerError.contains('realtime')) {
        return 'Database error. Please try again.';
      }
      
      return 'An error occurred. Please try again.';
    } catch (e) {
      return 'An unknown error occurred.';
    }
  }

  static void logError(String context, dynamic error) {
    try {
      final safeError = getSafeError(error);
      print(' [$context] Error: $safeError');
      
      // يمكن إضافة تسجيل إلى خدمة تحليلات هنا
    } catch (e) {
      print(' Error logging failed: $e');
    }
  }

  static void logWarning(String context, String message) {
    try {
      print(' [$context] Warning: $message');
    } catch (e) {
      print(' Warning logging failed: $e');
    }
  }

  static void logInfo(String context, String message) {
    try {
      print('[$context] Info: $message');
    } catch (e) {
      print(' Info logging failed: $e');
    }
  }

  static void logSecurity(String context, String message) {
    try {
      print(' [$context] Security: $message');
    } catch (e) {
      print(' Security logging failed: $e');
    }
  }

  static void logSuccess(String context, String message) {
    try {
      print(' [$context] Success: $message');
    } catch (e) {
      print(' Success logging failed: $e');
    }
  }

  static void logDebug(String context, String message) {
    try {
      // في وضع الإنتاج، قد لا نريد طباعة رسائل التصحيح
      // يمكنك إضافة شرط للتحقق من وضع التطبيق
      print(' [$context] Debug: $message');
    } catch (e) {
      print(' Debug logging failed: $e');
    }
  }

  static dynamic safeJsonDecode(String jsonString) {
    try {
      return json.decode(jsonString);
    } catch (e) {
      logError('Safe JSON Decode', e);
      return null;
    }
  }

  static String safeJsonEncode(dynamic object) {
    try {
      return json.encode(object);
    } catch (e) {
      logError('Safe JSON Encode', e);
      return '{}';
    }
  }

  static String getErrorLevel(dynamic error) {
    try {
      final errorStr = error.toString().toLowerCase();
      
      if (errorStr.contains('password') || 
          errorStr.contains('token') ||
          errorStr.contains('auth')) {
        return 'HIGH'; // أخطاء أمان عالية الخطورة
      }
      
      if (errorStr.contains('database') ||
          errorStr.contains('firestore')) {
        return 'MEDIUM'; // أخطاء بيانات متوسطة الخطورة
      }
      
      if (errorStr.contains('network') ||
          errorStr.contains('timeout')) {
        return 'LOW'; // أخطاء شبكة منخفضة الخطورة
      }
      
      return 'UNKNOWN';
    } catch (e) {
      return 'ERROR';
    }
  }

  static Map<String, dynamic> getErrorReport(dynamic error, String context) {
    try {
      final safeError = getSafeError(error);
      final errorLevel = getErrorLevel(error);
      
      return {
        'context': context,
        'message': safeError,
        'level': errorLevel,
        'timestamp': DateTime.now().toIso8601String(),
        'original_error': error.toString().length > 100 
            ? error.toString().substring(0, 100) + '...'
            : error.toString(),
        'stack_trace': error is Error ? error.stackTrace.toString() : null,
      };
    } catch (e) {
      return {
        'context': 'ErrorHandler',
        'message': 'Failed to create error report',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  static bool isNetworkError(dynamic error) {
    try {
      final errorStr = error.toString().toLowerCase();
      return errorStr.contains('network') ||
             errorStr.contains('timeout') ||
             errorStr.contains('socket') ||
             errorStr.contains('connection');
    } catch (e) {
      return false;
    }
  }

  static bool isAuthError(dynamic error) {
    try {
      final errorStr = error.toString().toLowerCase();
      return errorStr.contains('auth') ||
             errorStr.contains('unauthorized') ||
             errorStr.contains('permission') ||
             errorStr.contains('token');
    } catch (e) {
      return false;
    }
  }

  static bool isDatabaseError(dynamic error) {
    try {
      final errorStr = error.toString().toLowerCase();
      return errorStr.contains('database') ||
             errorStr.contains('firestore') ||
             errorStr.contains('realtime') ||
             errorStr.contains('query');
    } catch (e) {
      return false;
    }
  }

  static String getErrorMessage(dynamic error, {String? defaultMessage}) {
    try {
      final safeError = getSafeError(error);
      
      if (isNetworkError(error)) {
        return 'Network error. Please check your internet connection.';
      } else if (isAuthError(error)) {
        return 'Authentication failed. Please login again.';
      } else if (isDatabaseError(error)) {
        return 'Database error. Please try again later.';
      }
      
      return safeError;
    } catch (e) {
      return defaultMessage ?? 'An unknown error occurred.';
    }
  }

  static Future<void> logErrorAsync(String context, dynamic error) async {
    try {
      final errorReport = getErrorReport(error, context);
      
      // طباعة في الكونسول
      print(' [$context] Error Report:');
      print('   Level: ${errorReport['level']}');
      print('   Message: ${errorReport['message']}');
      print('   Timestamp: ${errorReport['timestamp']}');
      
      // يمكن إضافة إرسال إلى خدمة تحليلات هنا
      // await AnalyticsService.logError(errorReport);
      
    } catch (e) {
      print(' Async error logging failed: $e');
    }
  }
}
