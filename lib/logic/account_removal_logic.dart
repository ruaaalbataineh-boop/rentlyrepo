import 'package:p2/security/input_validator.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/api_security.dart';
import 'package:p2/security/secure_storage.dart';
import 'package:p2/security/route_guard.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountRemovalLogic {
  static Future<bool> validateAccountRemoval() async {
    try {
      // التحقق من المصادقة أولاً
      if (!RouteGuard.isAuthenticated()) {
        ErrorHandler.logError('Account Removal', 'User not authenticated');
        return false;
      }

      // التحقق من الـ rate limiting
      final rateLimitOk = await _checkRateLimit();
      if (!rateLimitOk) {
        ErrorHandler.logError('Account Removal', 
            'Rate limit exceeded for account removal');
        return false;
      }

      // التحقق من أن المستخدم ليس لديه معاملات نشطة
      final hasActiveTransactions = await _checkActiveTransactions();
      if (hasActiveTransactions) {
        ErrorHandler.logSecurity('Account Removal', 
            'User has active transactions');
        return false;
      }

      // التحقق من أن المستخدم ليس لديه رصيد
      final hasBalance = await _checkUserBalance();
      if (hasBalance) {
        ErrorHandler.logSecurity('Account Removal', 
            'User has remaining balance');
        return false;
      }

      // التحقق من آخر نشاط للمستخدم
      final isRecentActivity = await _checkRecentActivity();
      if (isRecentActivity) {
        ErrorHandler.logSecurity('Account Removal', 
            'User has recent activity');
        return false;
      }

      return true;
    } catch (error) {
      ErrorHandler.logError('Validate Account Removal', error);
      return false;
    }
  }

  static Future<bool> initiateAccountRemoval() async {
    try {
      // التحقق من صحة العملية أولاً
      final validationResult = await validateAccountRemoval();
      if (!validationResult) {
        await _logRemovalAttempt(false, 'Validation failed');
        return false;
      }

      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      final userId = await _getCurrentUserId();

      // تسجيل طلب الحذف
      await ApiSecurity.securePost(
        endpoint: 'account/removal/initiate',
        data: {
          'user_id': userId,
          'initiated_at': DateTime.now().toIso8601String(),
          'reason': 'user_requested',
          'status': 'pending',
        },
        token: token,
        requiresAuth: true,
      );

      // إرسال رمز التحقق
      await _sendVerificationCode();

      await _logRemovalAttempt(true, 'Removal initiated successfully');
      return true;
    } catch (error) {
      ErrorHandler.logError('Initiate Account Removal', error);
      await _logRemovalAttempt(false, error.toString());
      return false;
    }
  }

  static Future<bool> confirmAccountRemoval(String verificationCode) async {
    try {
      // التحقق من صحة رمز التحقق
      final isValidCode = await _validateVerificationCode(verificationCode);
      if (!isValidCode) {
        ErrorHandler.logSecurity('Account Removal', 'Invalid verification code');
        await _logRemovalAttempt(false, 'Invalid verification code');
        return false;
      }

      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      final userId = await _getCurrentUserId();

      // تسجيل تأكيد الحذف
      await ApiSecurity.securePost(
        endpoint: 'account/removal/confirm',
        data: {
          'user_id': userId,
          'confirmed_at': DateTime.now().toIso8601String(),
          'verification_code': verificationCode,
          'status': 'confirmed',
        },
        token: token,
        requiresAuth: true,
      );

      // حذف البيانات من التخزين الآمن
      await _clearSecureStorage();

      // تسجيل خروج المستخدم
      await _signOutUser();

      // تسجيل الحذف النهائي
      await ApiSecurity.securePost(
        endpoint: 'account/removal/complete',
        data: {
          'user_id': userId,
          'completed_at': DateTime.now().toIso8601String(),
          'status': 'completed',
        },
        token: token,
        requiresAuth: false, // قد يكون التوكن قد انتهى
      );

      await _logRemovalAttempt(true, 'Account removal completed');
      return true;
    } catch (error) {
      ErrorHandler.logError('Confirm Account Removal', error);
      await _logRemovalAttempt(false, error.toString());
      return false;
    }
  }

  static Future<bool> _checkRateLimit() async {
    try {
      final token = await SecureStorage.getToken();
      
      final response = await ApiSecurity.secureGet(
        endpoint: 'account/removal/rate_limit',
        token: token,
        requiresAuth: true,
      );
      
      return response['success'] == true && 
             response['data']?['allowed'] == true;
    } catch (e) {
      ErrorHandler.logError('Check Rate Limit', e);
      return true;
    }
  }

  static Future<bool> _checkActiveTransactions() async {
    try {
      final token = await SecureStorage.getToken();
      
      final response = await ApiSecurity.secureGet(
        endpoint: 'account/removal/active_transactions',
        token: token,
        requiresAuth: true,
      );
      
      if (response['success'] == true) {
        final activeCount = response['data']?['active_count'] ?? 0;
        return activeCount > 0;
      }
      return false;
    } catch (e) {
      ErrorHandler.logError('Check Active Transactions', e);
      return false;
    }
  }

  static Future<bool> _checkUserBalance() async {
    try {
      final token = await SecureStorage.getToken();
      
      final response = await ApiSecurity.secureGet(
        endpoint: 'account/removal/balance',
        token: token,
        requiresAuth: true,
      );
      
      if (response['success'] == true) {
        final balance = response['data']?['balance'] ?? 0.0;
        return balance > 0;
      }
      return false;
    } catch (e) {
      ErrorHandler.logError('Check User Balance', e);
      return false;
    }
  }

  static Future<bool> _checkRecentActivity() async {
    try {
      final token = await SecureStorage.getToken();
      
      final response = await ApiSecurity.secureGet(
        endpoint: 'account/removal/recent_activity',
        token: token,
        requiresAuth: true,
      );
      
      if (response['success'] == true) {
        final hoursSinceLastActivity = response['data']?['hours_since_last_activity'] ?? 0;
        // إذا كان آخر نشاط أقل من 24 ساعة
        return hoursSinceLastActivity < 24;
      }
      return false;
    } catch (e) {
      ErrorHandler.logError('Check Recent Activity', e);
      return false;
    }
  }

  static Future<void> _sendVerificationCode() async {
    try {
      final token = await SecureStorage.getToken();
      final userId = await _getCurrentUserId();
      
      await ApiSecurity.securePost(
        endpoint: 'account/removal/send_verification',
        data: {
          'user_id': userId,
          'sent_at': DateTime.now().toIso8601String(),
          'method': 'email', // أو sms حسب التفضيل
        },
        token: token,
        requiresAuth: true,
      );
    } catch (e) {
      ErrorHandler.logError('Send Verification Code', e);
    }
  }

  static Future<bool> _validateVerificationCode(String code) async {
    try {
      final safeCode = InputValidator.sanitizeInput(code);
      
      // التحقق من طول الرمز (6 أرقام عادة)
      if (safeCode.length != 6) {
        return false;
      }

      // التحقق من أن الرمز يتكون من أرقام فقط
      if (!RegExp(r'^[0-9]+$').hasMatch(safeCode)) {
        return false;
      }

      final token = await SecureStorage.getToken();
      final userId = await _getCurrentUserId();
      
      final response = await ApiSecurity.securePost(
        endpoint: 'account/removal/verify_code',
        data: {
          'user_id': userId,
          'code': safeCode,
          'verified_at': DateTime.now().toIso8601String(),
        },
        token: token,
        requiresAuth: true,
      );
      
      return response['success'] == true && 
             response['data']?['valid'] == true;
    } catch (e) {
      ErrorHandler.logError('Validate Verification Code', e);
      return false;
    }
  }

  static Future<String> _getCurrentUserId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return user.uid;
      }
      
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception('No user ID or token available');
      }
      
      // محاولة استخراج ID من التوكن
      return 'user_${DateTime.now().millisecondsSinceEpoch}';
    } catch (error) {
      ErrorHandler.logError('Get Current User ID', error);
      return 'unknown_user';
    }
  }

  static Future<void> _clearSecureStorage() async {
    try {
      await SecureStorage.clearAll();
      ErrorHandler.logInfo('Clear Secure Storage', 
          'All secure data cleared');
    } catch (error) {
      ErrorHandler.logError('Clear Secure Storage', error);
    }
  }

  static Future<void> _signOutUser() async {
    try {
      await FirebaseAuth.instance.signOut();
      ErrorHandler.logInfo('Sign Out User', 
          'User signed out successfully');
    } catch (error) {
      ErrorHandler.logError('Sign Out User', error);
    }
  }

  static Future<void> _logRemovalAttempt(bool success, String details) async {
    try {
      final token = await SecureStorage.getToken();
      
      await ApiSecurity.securePost(
        endpoint: 'logs/account_removal',
        data: {
          'success': success,
          'details': details,
          'timestamp': DateTime.now().toIso8601String(),
          'ip_address': 'mobile_app',
        },
        token: token,
        requiresAuth: !success, // في حالة الفشل قد يكون التوكن لا يزال صالحاً
      );
    } catch (e) {
      ErrorHandler.logInfo('Log Removal Attempt', 'Failed to log removal attempt');
    }
  }

  static String getSuccessMessage() {
    return "Account removal initiated. Please check your email for verification.";
  }

  static String getConfirmationMessage() {
    return "Account removed successfully. All your data has been deleted.";
  }

  static String getErrorMessage() {
    return "Failed to remove account. Please try again later.";
  }

  static String getValidationErrorMessage() {
    return "Cannot remove account:\n• You have active transactions\n• You have remaining balance\n• Recent activity detected";
  }

  static String getVerificationErrorMessage() {
    return "Invalid verification code. Please check and try again.";
  }

  static Future<Map<String, dynamic>> getRemovalConsequences() async {
    try {
      final token = await SecureStorage.getToken();
      
      final response = await ApiSecurity.secureGet(
        endpoint: 'account/removal/consequences',
        token: token,
        requiresAuth: true,
      );
      
      if (response['success'] == true) {
        return response['data'] ?? {
          'data_deleted': true,
          'transactions_lost': true,
          'cannot_undo': true,
          'timeframe': '30 days',
        };
      } else {
        return {
          'data_deleted': true,
          'transactions_lost': true,
          'cannot_undo': true,
          'timeframe': '30 days',
          'error': 'Failed to get consequences info',
        };
      }
    } catch (error) {
      ErrorHandler.logError('Get Removal Consequences', error);
      return {
        'data_deleted': true,
        'transactions_lost': true,
        'cannot_undo': true,
        'timeframe': '30 days',
        'error': ErrorHandler.getSafeError(error),
      };
    }
  }

  static Future<bool> cancelRemovalRequest() async {
    try {
      final token = await SecureStorage.getToken();
      final userId = await _getCurrentUserId();
      
      final response = await ApiSecurity.securePost(
        endpoint: 'account/removal/cancel',
        data: {
          'user_id': userId,
          'cancelled_at': DateTime.now().toIso8601String(),
          'status': 'cancelled',
        },
        token: token,
        requiresAuth: true,
      );
      
      return response['success'] == true;
    } catch (error) {
      ErrorHandler.logError('Cancel Removal Request', error);
      return false;
    }
  }

  static String getRemovalWarning() {
    return "⚠️ WARNING: Account removal is permanent!\n\n"
        "• All your data will be deleted\n"
        "• Active transactions will be cancelled\n"
        "• This action cannot be undone\n"
        "• You will lose access to all services\n\n"
        "Are you absolutely sure you want to continue?";
  }
}
