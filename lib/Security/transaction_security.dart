import 'package:p2/security/error_handler.dart';
import 'package:p2/security/secure_storage.dart';
import 'package:p2/security/input_validator.dart';
import 'package:p2/logic/transaction_history_logic.dart';

class TransactionSecurity {
  // أنواع المعاملات المدعومة
  static const List<String> supportedTypes = ['deposit', 'withdrawal'];
  
  // طرق الدفع المدعومة
  static const List<String> supportedMethods = [
    'Credit Card',
    'Bank Transfer',
    'Cash',
    'Online Payment',
    'Wallet',
  ];
  
  // حالات المعاملات المدعومة
  static const List<String> supportedStatuses = [
    'completed',
    'processing',
    'pending',
    'failed',
    'cancelled',
  ];

  // التحقق من صحة المعاملة
  static bool isValidTransaction(Map<String, dynamic> transaction) {
    try {
      if (transaction.isEmpty) {
        return false;
      }

      // التحقق من وجود الحقول المطلوبة
      final requiredFields = ['id', 'type', 'amount', 'date', 'time', 'method', 'status'];
      for (final field in requiredFields) {
        if (!transaction.containsKey(field)) {
          ErrorHandler.logSecurity('Transaction Validation', 
              'Missing required field: $field');
          return false;
        }
      }

      // التحقق من صحة النوع
      final type = transaction['type'].toString().toLowerCase();
      if (!supportedTypes.contains(type)) {
        ErrorHandler.logSecurity('Transaction Validation', 
            'Invalid transaction type: $type');
        return false;
      }

      // التحقق من صحة المبلغ
      final amount = _parseAmount(transaction['amount']);
      if (amount <= 0) {
        ErrorHandler.logSecurity('Transaction Validation', 
            'Invalid amount: $amount');
        return false;
      }

      // التحقق من صحة طريقة الدفع
      final method = transaction['method'].toString();
      if (!supportedMethods.contains(method)) {
        ErrorHandler.logWarning('Transaction Validation', 
            'Unsupported payment method: $method');
      }

      // التحقق من صحة الحالة
      final status = transaction['status'].toString().toLowerCase();
      if (!supportedStatuses.contains(status)) {
        ErrorHandler.logWarning('Transaction Validation', 
            'Unsupported status: $status');
      }

      // التحقق من صحة التاريخ والوقت
      final date = transaction['date'].toString();
      final time = transaction['time'].toString();
      if (!_isValidDateTime(date, time)) {
        ErrorHandler.logSecurity('Transaction Validation', 
            'Invalid date/time: $date $time');
        return false;
      }

      // التحقق من صحة ID
      final id = transaction['id'].toString();
      if (id.isEmpty || id.length > 50) {
        ErrorHandler.logSecurity('Transaction Validation', 
            'Invalid transaction ID: $id');
        return false;
      }

      return true;
    } catch (error) {
      ErrorHandler.logError('Validate Transaction', error);
      return false;
    }
  }

  // تنظيف بيانات المعاملة
  static Map<String, dynamic> sanitizeTransaction(Map<String, dynamic> transaction) {
    try {
      final sanitized = <String, dynamic>{};

      // تنظيف ID
      if (transaction.containsKey('id')) {
        sanitized['id'] = InputValidator.sanitizeInput(transaction['id'].toString());
      } else {
        sanitized['id'] = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
      }

      // تنظيف النوع
      if (transaction.containsKey('type')) {
        final type = transaction['type'].toString().toLowerCase();
        sanitized['type'] = supportedTypes.contains(type) ? type : 'unknown';
      } else {
        sanitized['type'] = 'unknown';
      }

      // تنظيف المبلغ
      if (transaction.containsKey('amount')) {
        final amount = _parseAmount(transaction['amount']);
        sanitized['amount'] = amount > 0 ? amount : 0.0;
      } else {
        sanitized['amount'] = 0.0;
      }

      // تنظيف التاريخ والوقت
      sanitized['date'] = transaction.containsKey('date') 
          ? _sanitizeDate(transaction['date'].toString())
          : DateTime.now().toIso8601String().split('T')[0];
      
      sanitized['time'] = transaction.containsKey('time') 
          ? _sanitizeTime(transaction['time'].toString())
          : DateTime.now().toIso8601String().split('T')[1].substring(0, 8);

      // تنظيف طريقة الدفع
      if (transaction.containsKey('method')) {
        final method = transaction['method'].toString();
        sanitized['method'] = InputValidator.sanitizeInput(method);
      } else {
        sanitized['method'] = 'Unknown';
      }

      // تنظيف الحالة
      if (transaction.containsKey('status')) {
        final status = transaction['status'].toString().toLowerCase();
        sanitized['status'] = supportedStatuses.contains(status) ? status : 'unknown';
      } else {
        sanitized['status'] = 'unknown';
      }

      // إضافة البيانات الوصفية
      sanitized['sanitized_at'] = DateTime.now().toIso8601String();
      sanitized['is_valid'] = isValidTransaction(sanitized);

      return sanitized;
    } catch (error) {
      ErrorHandler.logError('Sanitize Transaction', error);
      return {
        'id': 'error_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'unknown',
        'amount': 0.0,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'time': DateTime.now().toIso8601String().split('T')[1].substring(0, 8),
        'method': 'Error',
        'status': 'failed',
        'sanitized_at': DateTime.now().toIso8601String(),
        'is_valid': false,
        'error': ErrorHandler.getSafeError(error),
      };
    }
  }

  // تنظيف قائمة المعاملات
  static List<Map<String, dynamic>> sanitizeTransactions(List<Map<String, dynamic>> transactions) {
    try {
      final sanitized = <Map<String, dynamic>>[];

      for (final transaction in transactions) {
        final sanitizedTransaction = sanitizeTransaction(transaction);
        if (sanitizedTransaction['is_valid'] == true) {
          sanitized.add(sanitizedTransaction);
        } else {
          ErrorHandler.logWarning('Sanitize Transactions', 
              'Removed invalid transaction: ${sanitizedTransaction['id']}');
        }
      }

      ErrorHandler.logInfo('Sanitize Transactions', 
          'Original: ${transactions.length}, Cleaned: ${sanitized.length}');

      return sanitized;
    } catch (error) {
      ErrorHandler.logError('Sanitize Transactions', error);
      return [];
    }
  }

  // التحقق من وصول المستخدم للمعاملات
  static Future<bool> canAccessTransactions(String userId, List<Map<String, dynamic>> transactions) async {
    try {
      // يمكنك إضافة منطق للتحقق من أذونات المستخدم هنا
      // مثلاً: التحقق من أن المستخدم يملك هذه المعاملات
      
      final currentUserId = await _getCurrentUserId();
      if (currentUserId == null || currentUserId != userId) {
        ErrorHandler.logSecurity('Transaction Access', 
            'Unauthorized access attempt for user: $userId');
        return false;
      }

      // التحقق من أن عدد المعاملات منطقي
      if (transactions.length > 1000) {
        ErrorHandler.logWarning('Transaction Access', 
            'Suspicious number of transactions: ${transactions.length}');
        return false;
      }

      return true;
    } catch (error) {
      ErrorHandler.logError('Check Transaction Access', error);
      return false;
    }
  }

  // تسجيل دخول المستخدم لصفحة المعاملات
  static Future<void> logTransactionAccess(
    String userId,
    List<Map<String, dynamic>> transactions,
    String filter
  ) async {
    try {
      final token = await SecureStorage.getToken();
      
      ErrorHandler.logInfo('Transaction History Access', '''
User ID: $userId
Transactions Count: ${transactions.length}
Filter: $filter
Balance: ${_calculateTotalBalance(transactions)}
Deposits: ${_calculateTotalDeposits(transactions)}
Withdrawals: ${_calculateTotalWithdrawals(transactions)}
Timestamp: ${DateTime.now().toIso8601String()}
''');

      // حفظ في التخزين المحلي
      await SecureStorage.saveData(
        'last_transaction_access_${DateTime.now().millisecondsSinceEpoch}',
        '$userId - $filter - ${transactions.length} transactions',
      );
    } catch (error) {
      ErrorHandler.logError('Log Transaction Access', error);
    }
  }

  // الحصول على ID المستخدم الحالي
  static Future<String?> _getCurrentUserId() async {
    try {
      final token = await SecureStorage.getToken();
      if (token != null && token.isNotEmpty) {
        // يمكنك استخراج userId من التوكن
        return 'user_${token.substring(0, min(8, token.length))}...';
      }
      return null;
    } catch (error) {
      ErrorHandler.logError('Get Current User ID', error);
      return null;
    }
  }

  static int min(int a, int b) => a < b ? a : b;

  // تحليل المبلغ
  static double _parseAmount(dynamic amount) {
    try {
      if (amount is double) {
        return amount;
      } else if (amount is int) {
        return amount.toDouble();
      } else if (amount is String) {
        return double.tryParse(amount) ?? 0.0;
      }
      return 0.0;
    } catch (error) {
      return 0.0;
    }
  }

  // التحقق من صحة التاريخ والوقت
  static bool _isValidDateTime(String date, String time) {
    try {
      // التحقق من صيغة التاريخ (YYYY-MM-DD)
      final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      if (!dateRegex.hasMatch(date)) {
        return false;
      }

      // التحقق من صيغة الوقت (HH:MM)
      final timeRegex = RegExp(r'^\d{2}:\d{2}$');
      if (!timeRegex.hasMatch(time)) {
        return false;
      }

      // تحليل التاريخ
      final dateParts = date.split('-');
      final year = int.tryParse(dateParts[0]);
      final month = int.tryParse(dateParts[1]);
      final day = int.tryParse(dateParts[2]);

      if (year == null || month == null || day == null ||
          month < 1 || month > 12 || day < 1 || day > 31) {
        return false;
      }

      // تحليل الوقت
      final timeParts = time.split(':');
      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);

      if (hour == null || minute == null ||
          hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        return false;
      }

      // التحقق من أن التاريخ ليس في المستقبل
      final transactionDate = DateTime(year, month, day, hour, minute);
      if (transactionDate.isAfter(DateTime.now())) {
        ErrorHandler.logWarning('DateTime Validation', 
            'Transaction date is in the future: $date $time');
        return false;
      }

      return true;
    } catch (error) {
      ErrorHandler.logError('Validate DateTime', error);
      return false;
    }
  }

  // تنظيف التاريخ
  static String _sanitizeDate(String date) {
    try {
      return InputValidator.sanitizeInput(date);
    } catch (error) {
      return DateTime.now().toIso8601String().split('T')[0];
    }
  }

  // تنظيف الوقت
  static String _sanitizeTime(String time) {
    try {
      return InputValidator.sanitizeInput(time);
    } catch (error) {
      return DateTime.now().toIso8601String().split('T')[1].substring(0, 8);
    }
  }

  // حساب إجمالي الرصيد
  static double _calculateTotalBalance(List<Map<String, dynamic>> transactions) {
    try {
      double balance = 0.0;
      
      for (final transaction in transactions) {
        final amount = _parseAmount(transaction['amount']);
        final type = transaction['type'].toString().toLowerCase();
        
        if (type == 'deposit') {
          balance += amount;
        } else if (type == 'withdrawal') {
          balance -= amount;
        }
      }
      
      return balance;
    } catch (error) {
      ErrorHandler.logError('Calculate Total Balance', error);
      return 0.0;
    }
  }

  // حساب إجمالي الإيداعات
  static double _calculateTotalDeposits(List<Map<String, dynamic>> transactions) {
    try {
      double total = 0.0;
      
      for (final transaction in transactions) {
        final amount = _parseAmount(transaction['amount']);
        final type = transaction['type'].toString().toLowerCase();
        
        if (type == 'deposit') {
          total += amount;
        }
      }
      
      return total;
    } catch (error) {
      ErrorHandler.logError('Calculate Total Deposits', error);
      return 0.0;
    }
  }

  // حساب إجمالي السحوبات
  static double _calculateTotalWithdrawals(List<Map<String, dynamic>> transactions) {
    try {
      double total = 0.0;
      
      for (final transaction in transactions) {
        final amount = _parseAmount(transaction['amount']);
        final type = transaction['type'].toString().toLowerCase();
        
        if (type == 'withdrawal') {
          total += amount;
        }
      }
      
      return total;
    } catch (error) {
      ErrorHandler.logError('Calculate Total Withdrawals', error);
      return 0.0;
    }
  }

  // التحقق من وجود أنشطة مشبوهة
  static Future<bool> detectSuspiciousActivity(List<Map<String, dynamic>> transactions) async {
    try {
      final recentTransactions = transactions.where((t) {
        final date = t['date'].toString();
        final transactionDate = DateTime.parse(date);
        final daysDifference = DateTime.now().difference(transactionDate).inDays;
        return daysDifference <= 7; // آخر 7 أيام
      }).toList();

      // التحقق من عدد كبير من المعاملات في وقت قصير
      if (recentTransactions.length > 50) {
        ErrorHandler.logSecurity('Suspicious Activity', 
            'Large number of recent transactions: ${recentTransactions.length}');
        return true;
      }

      // التحقق من مبالغ كبيرة غير عادية
      final largeTransactions = transactions.where((t) {
        final amount = _parseAmount(t['amount']);
        return amount > 10000; // مبالغ أكبر من 10,000
      }).toList();

      if (largeTransactions.isNotEmpty) {
        ErrorHandler.logSecurity('Suspicious Activity', 
            'Large transactions detected: ${largeTransactions.length}');
        return true;
      }

      return false;
    } catch (error) {
      ErrorHandler.logError('Detect Suspicious Activity', error);
      return false;
    }
  }
}
