import 'package:p2/security/error_handler.dart';
import 'package:p2/security/secure_storage.dart';
import 'package:p2/security/input_validator.dart';
import 'package:p2/logic/wallet_logic.dart';

class WalletSecurity {
  // الحدود المالية
  static const double minTransactionAmount = 0.01;
  static const double maxDepositAmount = 1000000.0;
  static const double maxWithdrawalAmount = 5000.0;
  
  // طرق الدفع المدعومة
  static const List<String> supportedPaymentMethods = [
    'Credit Card',
    'Bank Transfer',
    'Cash',
    'Online Payment',
    'Wallet',
    'Visa',
    'MasterCard',
    'PayPal',
  ];

  // طرق السحب المدعومة
  static const List<String> supportedWithdrawalMethods = [
    'Bank Transfer',
    'Cash',
    'Online Payment',
    'Credit Card',
  ];

  // التحقق من صحة المبلغ
  static bool isValidAmount(double amount) {
    try {
      if (amount < minTransactionAmount) {
        ErrorHandler.logWarning('Amount Validation', 
            'Amount too low: $amount (min: $minTransactionAmount)');
        return false;
      }

      if (amount.isNaN || amount.isInfinite) {
        ErrorHandler.logSecurity('Amount Validation', 
            'Invalid amount value: $amount');
        return false;
      }

      // التحقق من أن الرقم لا يحتوي على أكثر من منزلتين عشريتين
      final amountString = amount.toString();
      final decimalParts = amountString.split('.');
      if (decimalParts.length > 1 && decimalParts[1].length > 2) {
        ErrorHandler.logWarning('Amount Validation', 
            'Amount has too many decimal places: $amount');
        return false;
      }

      return true;
    } catch (error) {
      ErrorHandler.logError('Validate Amount', error);
      return false;
    }
  }

  // التحقق من صحة الإيداع
  static Map<String, dynamic> validateDeposit(double amount, String method) {
    try {
      final errors = <String>[];
      final warnings = <String>[];

      // التحقق من المبلغ
      if (!isValidAmount(amount)) {
        errors.add('Invalid amount');
      }

      if (amount > maxDepositAmount) {
        errors.add('Maximum deposit amount is ${maxDepositAmount.toStringAsFixed(2)}JD');
      }

      // التحقق من طريقة الدفع
      if (method.isEmpty) {
        errors.add('Payment method is required');
      } else if (!supportedPaymentMethods.contains(method)) {
        warnings.add('Unsupported payment method: $method');
      }

      // تنظيف البيانات
      final sanitizedMethod = InputValidator.sanitizeInput(method);
      final sanitizedAmount = _sanitizeAmount(amount);

      return {
        'isValid': errors.isEmpty,
        'errors': errors,
        'warnings': warnings,
        'sanitizedAmount': sanitizedAmount,
        'sanitizedMethod': sanitizedMethod,
        'maxAllowed': maxDepositAmount,
        'minAllowed': minTransactionAmount,
      };
    } catch (error) {
      ErrorHandler.logError('Validate Deposit', error);
      return {
        'isValid': false,
        'errors': ['Validation failed: ${ErrorHandler.getSafeError(error)}'],
        'warnings': [],
        'sanitizedAmount': 0.0,
        'sanitizedMethod': '',
      };
    }
  }

  // التحقق من صحة السحب
  static Future<Map<String, dynamic>> validateWithdrawal(
    double amount, 
    String method, 
    double currentBalance,
  ) async {
    try {
      final errors = <String>[];
      final warnings = <String>[];

      // التحقق من المبلغ
      if (!isValidAmount(amount)) {
        errors.add('Invalid amount');
      }

      if (amount > maxWithdrawalAmount) {
        errors.add('Maximum withdrawal amount is ${maxWithdrawalAmount.toStringAsFixed(2)}JD');
      }

      // التحقق من الرصيد
      if (amount > currentBalance) {
        errors.add('Insufficient balance');
      }

      // التحقق من طريقة السحب
      if (method.isEmpty) {
        errors.add('Withdrawal method is required');
      } else if (!supportedWithdrawalMethods.contains(method)) {
        warnings.add('Unsupported withdrawal method: $method');
      }

      // التحقق من تكرار السحوبات
      final isSuspicious = await _isSuspiciousWithdrawal(amount);
      if (isSuspicious) {
        warnings.add('Unusual withdrawal activity detected');
      }

      // تنظيف البيانات
      final sanitizedMethod = InputValidator.sanitizeInput(method);
      final sanitizedAmount = _sanitizeAmount(amount);

      return {
        'isValid': errors.isEmpty,
        'errors': errors,
        'warnings': warnings,
        'sanitizedAmount': sanitizedAmount,
        'sanitizedMethod': sanitizedMethod,
        'maxAllowed': maxWithdrawalAmount,
        'minAllowed': minTransactionAmount,
        'currentBalance': currentBalance,
        'remainingBalance': currentBalance - amount,
        'isSuspicious': isSuspicious,
      };
    } catch (error) {
      ErrorHandler.logError('Validate Withdrawal', error);
      return {
        'isValid': false,
        'errors': ['Validation failed: ${ErrorHandler.getSafeError(error)}'],
        'warnings': [],
        'sanitizedAmount': 0.0,
        'sanitizedMethod': '',
        'currentBalance': currentBalance,
      };
    }
  }

  // التحقق من السحوبات المشبوهة
  static Future<bool> _isSuspiciousWithdrawal(double amount) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        return false;
      }

      // يمكن إضافة منطق للتحقق من الأنماط المشبوهة
      // مثلاً: سحب مبالغ كبيرة، تكرار السحوبات، إلخ
      
      if (amount > 10000) {
        ErrorHandler.logSecurity('Suspicious Withdrawal', 
            'Large withdrawal attempt: $amount by user $userId');
        return true;
      }

      // التحقق من تكرار السحوبات في فترة زمنية قصيرة
      final recentWithdrawals = await _getRecentWithdrawals(24); // آخر 24 ساعة
      if (recentWithdrawals.length > 5) {
        ErrorHandler.logSecurity('Suspicious Withdrawal', 
            'Frequent withdrawals: ${recentWithdrawals.length} in 24h by user $userId');
        return true;
      }

      return false;
    } catch (error) {
      ErrorHandler.logError('Check Suspicious Withdrawal', error);
      return false;
    }
  }

  // الحصول على السحوبات الحديثة
  static Future<List<Map<String, dynamic>>> _getRecentWithdrawals(int hours) async {
    try {
      final transactionsJson = await SecureStorage.getData('user_transactions') ?? '[]';
      final transactions = ErrorHandler.safeJsonDecode(transactionsJson) as List? ?? [];

      final cutoffTime = DateTime.now().subtract(Duration(hours: hours));

      return transactions.where((tx) {
        if (tx is Map<String, dynamic>) {
          final type = tx['type'] as String?;
          final timestamp = tx['timestamp'] as String?;
          
          if (type == 'withdrawal' && timestamp != null) {
            final txTime = DateTime.tryParse(timestamp);
            if (txTime != null && txTime.isAfter(cutoffTime)) {
              return true;
            }
          }
        }
        return false;
      }).cast<Map<String, dynamic>>().toList();
    } catch (error) {
      ErrorHandler.logError('Get Recent Withdrawals', error);
      return [];
    }
  }

  // تنظيف المبلغ
  static double _sanitizeAmount(double amount) {
    try {
      // تقريب إلى منزلتين عشريتين
      final roundedAmount = double.parse(amount.toStringAsFixed(2));
      
      // التحقق من القيم غير الطبيعية
      if (roundedAmount.isNaN || roundedAmount.isInfinite) {
        return 0.0;
      }

      return roundedAmount;
    } catch (error) {
      ErrorHandler.logError('Sanitize Amount', error);
      return 0.0;
    }
  }

  // التحقق من صحة المعاملة
  static bool isValidTransaction(Map<String, dynamic> transaction) {
    try {
      final requiredFields = ['id', 'type', 'amount', 'date', 'time', 'method', 'status'];
      
      for (final field in requiredFields) {
        if (!transaction.containsKey(field)) {
          ErrorHandler.logWarning('Transaction Validation', 
              'Missing required field: $field');
          return false;
        }
      }

      // التحقق من النوع
      final type = transaction['type'] as String;
      if (type != 'deposit' && type != 'withdrawal') {
        ErrorHandler.logWarning('Transaction Validation', 
            'Invalid transaction type: $type');
        return false;
      }

      // التحقق من المبلغ
      final amount = transaction['amount'];
      final parsedAmount = _parseAmount(amount);
      if (parsedAmount <= 0 || !isValidAmount(parsedAmount)) {
        ErrorHandler.logWarning('Transaction Validation', 
            'Invalid transaction amount: $amount');
        return false;
      }

      // التحقق من الحالة
      final status = transaction['status'] as String;
      final validStatuses = ['completed', 'processing', 'pending', 'failed', 'cancelled'];
      if (!validStatuses.contains(status.toLowerCase())) {
        ErrorHandler.logWarning('Transaction Validation', 
            'Invalid transaction status: $status');
      }

      // التحقق من طريقة الدفع/السحب
      final method = transaction['method'] as String;
      if (type == 'deposit') {
        if (!supportedPaymentMethods.contains(method)) {
          ErrorHandler.logWarning('Transaction Validation', 
              'Unsupported deposit method: $method');
        }
      } else {
        if (!supportedWithdrawalMethods.contains(method)) {
          ErrorHandler.logWarning('Transaction Validation', 
              'Unsupported withdrawal method: $method');
        }
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
        sanitized['id'] = 'tx_${DateTime.now().millisecondsSinceEpoch}';
      }

      // تنظيف النوع
      final type = transaction['type'] as String?;
      sanitized['type'] = type == 'deposit' || type == 'withdrawal' ? type : 'unknown';

      // تنظيف المبلغ
      if (transaction.containsKey('amount')) {
        final amount = _parseAmount(transaction['amount']);
        sanitized['amount'] = isValidAmount(amount) ? amount : 0.0;
      } else {
        sanitized['amount'] = 0.0;
      }

      // تنظيف التاريخ والوقت
      sanitized['date'] = transaction.containsKey('date') 
          ? InputValidator.sanitizeInput(transaction['date'].toString())
          : DateTime.now().toIso8601String().split('T')[0];
      
      sanitized['time'] = transaction.containsKey('time') 
          ? InputValidator.sanitizeInput(transaction['time'].toString())
          : DateTime.now().toIso8601String().split('T')[1].substring(0, 8);

      // تنظيف الطريقة
      if (transaction.containsKey('method')) {
        sanitized['method'] = InputValidator.sanitizeInput(transaction['method'].toString());
      } else {
        sanitized['method'] = 'Unknown';
      }

      // تنظيف الحالة
      if (transaction.containsKey('status')) {
        sanitized['status'] = InputValidator.sanitizeInput(transaction['status'].toString());
      } else {
        sanitized['status'] = 'unknown';
      }

      // إضافة الألوان والأيقونات
      sanitized['color'] = transaction['color'] ?? _getColorForTransaction(sanitized);
      sanitized['icon'] = transaction['icon'] ?? _getIconForTransaction(sanitized);

      // إضافة البيانات الوصفية
      sanitized['sanitized_at'] = DateTime.now().toIso8601String();
      sanitized['is_valid'] = isValidTransaction(sanitized);

      return sanitized;
    } catch (error) {
      ErrorHandler.logError('Sanitize Transaction', error);
      return {
        'id': 'error_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'error',
        'amount': 0.0,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'time': DateTime.now().toIso8601String().split('T')[1].substring(0, 8),
        'method': 'Error',
        'status': 'failed',
        'color': 'grey',
        'icon': 'error',
        'sanitized_at': DateTime.now().toIso8601String(),
        'is_valid': false,
      };
    }
  }

  // الحصول على لون للمعاملة
  static String _getColorForTransaction(Map<String, dynamic> transaction) {
    final type = transaction['type'] as String;
    final status = transaction['status'] as String;
    
    if (type == 'deposit') {
      return status.toLowerCase() == 'completed' ? 'green' : 'blue';
    } else {
      return status.toLowerCase() == 'completed' ? 'orange' : 'red';
    }
  }

  // الحصول على أيقونة للمعاملة
  static String _getIconForTransaction(Map<String, dynamic> transaction) {
    final type = transaction['type'] as String;
    final method = transaction['method'] as String;
    
    if (type == 'deposit') {
      if (method.toLowerCase().contains('credit')) return 'credit_card';
      if (method.toLowerCase().contains('bank')) return 'account_balance';
      return 'add_circle';
    } else {
      if (method.toLowerCase().contains('cash')) return 'money';
      if (method.toLowerCase().contains('bank')) return 'account_balance_wallet';
      return 'remove_circle';
    }
  }

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

  // الحصول على ID المستخدم الحالي
  static Future<String?> _getCurrentUserId() async {
    try {
      final token = await SecureStorage.getToken();
      if (token != null && token.isNotEmpty) {
        return 'user_${token.substring(0, min(8, token.length))}...';
      }
      return null;
    } catch (error) {
      ErrorHandler.logError('Get Current User ID', error);
      return null;
    }
  }

  static int min(int a, int b) => a < b ? a : b;

  // تسجيل الوصول لصفحة المحفظة
  static Future<void> logWalletAccess(double balance) async {
    try {
      final userId = await _getCurrentUserId();
      
      ErrorHandler.logInfo('Wallet Access', '''
User: $userId
Balance: ${balance.toStringAsFixed(2)}JD
Timestamp: ${DateTime.now().toIso8601String()}
''');

      await SecureStorage.saveData(
        'last_wallet_access_${DateTime.now().millisecondsSinceEpoch}',
        '$userId - ${balance.toStringAsFixed(2)}JD',
      );
    } catch (error) {
      ErrorHandler.logError('Log Wallet Access', error);
    }
  }

  // الحصول على ملخص المحفظة
  static Future<Map<String, dynamic>> getWalletSummary(
    double currentBalance,
    double holdingBalance,
    List<Map<String, dynamic>> transactions,
  ) async {
    try {
      final totalDeposits = WalletLogic.getTotalDeposits(transactions);
      final totalWithdrawals = WalletLogic.getTotalWithdrawals(transactions);
      final transactionCount = WalletLogic.getTransactionCount(transactions);
      
      final userId = await _getCurrentUserId();
      
      return {
        'user_id': userId,
        'current_balance': currentBalance,
        'holding_balance': holdingBalance,
        'total_balance': currentBalance + holdingBalance,
        'total_deposits': totalDeposits,
        'total_withdrawals': totalWithdrawals,
        'transaction_count': transactionCount,
        'average_transaction': transactionCount > 0 
            ? (totalDeposits + totalWithdrawals) / transactionCount 
            : 0,
        'deposit_ratio': totalDeposits > 0 
            ? currentBalance / totalDeposits 
            : 0,
        'withdrawal_ratio': totalWithdrawals > 0 
            ? currentBalance / totalWithdrawals 
            : 0,
        'has_suspicious_activity': await _detectSuspiciousActivity(transactions),
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (error) {
      ErrorHandler.logError('Get Wallet Summary', error);
      return {
        'current_balance': currentBalance,
        'holding_balance': holdingBalance,
        'error': ErrorHandler.getSafeError(error),
      };
    }
  }

  // اكتشاف الأنشطة المشبوهة
  static Future<bool> _detectSuspiciousActivity(List<Map<String, dynamic>> transactions) async {
    try {
      // التحقق من المعاملات في آخر 24 ساعة
      final recentTransactions = transactions.where((tx) {
        final date = tx['date'] as String;
        final txDate = DateTime.parse(date);
        final hoursDifference = DateTime.now().difference(txDate).inHours;
        return hoursDifference <= 24;
      }).toList();

      // إذا كان هناك أكثر من 10 معاملات في 24 ساعة
      if (recentTransactions.length > 10) {
        ErrorHandler.logSecurity('Suspicious Activity', 
            'High transaction frequency: ${recentTransactions.length} in 24h');
        return true;
      }

      // التحقق من المبالغ الكبيرة
      final largeTransactions = transactions.where((tx) {
        final amount = tx['amount'] as double;
        return amount > 5000; // مبالغ أكبر من 5000
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
