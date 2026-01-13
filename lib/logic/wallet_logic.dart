import 'dart:math';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/wallet_security.dart';

class WalletLogic {
  static double getTotalDeposits(List<Map<String, dynamic>> transactions) {
    try {
      // تنظيف المعاملات أولاً
      final sanitizedTransactions = transactions.map(
        (tx) => WalletSecurity.sanitizeTransaction(tx)
      ).where((tx) => tx['is_valid'] == true).toList();

      return sanitizedTransactions
          .where((t) => t['type'] == 'deposit')
          .fold(0.0, (sum, t) => sum + (t['amount'] as double));
    } catch (error) {
      ErrorHandler.logError('Get Total Deposits', error);
      return 0.0;
    }
  }

  static double getTotalWithdrawals(List<Map<String, dynamic>> transactions) {
    try {
      final sanitizedTransactions = transactions.map(
        (tx) => WalletSecurity.sanitizeTransaction(tx)
      ).where((tx) => tx['is_valid'] == true).toList();

      return sanitizedTransactions
          .where((t) => t['type'] == 'withdrawal')
          .fold(0.0, (sum, t) => sum + (t['amount'] as double));
    } catch (error) {
      ErrorHandler.logError('Get Total Withdrawals', error);
      return 0.0;
    }
  }

  static int getTransactionCount(List<Map<String, dynamic>> transactions) {
    try {
      final sanitizedTransactions = transactions.map(
        (tx) => WalletSecurity.sanitizeTransaction(tx)
      ).where((tx) => tx['is_valid'] == true).toList();

      return sanitizedTransactions.length;
    } catch (error) {
      ErrorHandler.logError('Get Transaction Count', error);
      return 0;
    }
  }

  static bool canWithdraw(double currentBalance, double amount) {
    try {
      if (!WalletSecurity.isValidAmount(amount)) {
        return false;
      }

      return currentBalance >= amount && amount > 0;
    } catch (error) {
      ErrorHandler.logError('Can Withdraw', error);
      return false;
    }
  }

  static bool isValidAmount(double amount) {
    try {
      return WalletSecurity.isValidAmount(amount);
    } catch (error) {
      ErrorHandler.logError('Is Valid Amount', error);
      return false;
    }
  }

  static String formatBalance(double amount) {
    try {
      // التحقق من صحة المبلغ أولاً
      if (!isValidAmount(amount)) {
        ErrorHandler.logWarning('Format Balance', 'Invalid amount: $amount');
        return '0.00';
      }

      return amount.toStringAsFixed(2);
    } catch (error) {
      ErrorHandler.logError('Format Balance', error);
      return '0.00';
    }
  }

  static String? validateDeposit(double amount, String method) {
    try {
      final validation = WalletSecurity.validateDeposit(amount, method);
      
      if (!validation['isValid']) {
        final errors = validation['errors'] as List<String>;
        return errors.isNotEmpty ? errors.first : 'Invalid deposit data';
      }

      // تسجيل التحذيرات إذا وجدت
      final warnings = validation['warnings'] as List<String>;
      if (warnings.isNotEmpty) {
        for (final warning in warnings) {
          ErrorHandler.logWarning('Deposit Validation', warning);
        }
      }

      return null;
    } catch (error) {
      ErrorHandler.logError('Validate Deposit', error);
      return 'Validation failed: ${ErrorHandler.getSafeError(error)}';
    }
  }

  static Future<String?> validateWithdrawal(
    double amount, 
    String method, 
    double currentBalance,
  ) async {
    try {
      final validation = await WalletSecurity.validateWithdrawal(amount, method, currentBalance);
      
      if (!validation['isValid']) {
        final errors = validation['errors'] as List<String>;
        return errors.isNotEmpty ? errors.first : 'Invalid withdrawal data';
      }

      // التحقق من الأنشطة المشبوهة
      if (validation['isSuspicious'] == true) {
        ErrorHandler.logSecurity('Withdrawal Validation', 
            'Suspicious withdrawal detected: $amount, $method');
        return 'Withdrawal requires additional verification';
      }

      // تسجيل التحذيرات
      final warnings = validation['warnings'] as List<String>;
      if (warnings.isNotEmpty) {
        for (final warning in warnings) {
          ErrorHandler.logWarning('Withdrawal Validation', warning);
        }
      }

      return null;
    } catch (error) {
      ErrorHandler.logError('Validate Withdrawal', error);
      return 'Validation failed: ${ErrorHandler.getSafeError(error)}';
    }
  }

  static List<Map<String, dynamic>> filterByDateRange(
    List<Map<String, dynamic>> transactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    try {
      final sanitizedTransactions = transactions.map(
        (tx) => WalletSecurity.sanitizeTransaction(tx)
      ).where((tx) => tx['is_valid'] == true).toList();

      return sanitizedTransactions.where((transaction) {
        final dateStr = transaction['date'] as String;
        final parts = dateStr.split('-');
        if (parts.length != 3) return false;
        
        final year = int.tryParse(parts[0]) ?? 0;
        final month = int.tryParse(parts[1]) ?? 0;
        final day = int.tryParse(parts[2]) ?? 0;
        
        if (year == 0 || month == 0 || day == 0) return false;
        
        final transactionDate = DateTime(year, month, day);
        
        return transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
               transactionDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    } catch (error) {
      ErrorHandler.logError('Filter By Date Range', error);
      return [];
    }
  }

  static List<Map<String, dynamic>> filterByType(
    List<Map<String, dynamic>> transactions,
    String type,
  ) {
    try {
      if (type != 'deposit' && type != 'withdrawal') {
        ErrorHandler.logWarning('Filter By Type', 'Invalid type: $type');
        return [];
      }

      final sanitizedTransactions = transactions.map(
        (tx) => WalletSecurity.sanitizeTransaction(tx)
      ).where((tx) => tx['is_valid'] == true).toList();

      return sanitizedTransactions.where((t) => t['type'] == type).toList();
    } catch (error) {
      ErrorHandler.logError('Filter By Type', error);
      return [];
    }
  }

  static List<Map<String, dynamic>> filterByMethod(
    List<Map<String, dynamic>> transactions,
    String method,
  ) {
    try {
      final sanitizedMethod = method.trim();
      if (sanitizedMethod.isEmpty) {
        return [];
      }

      final sanitizedTransactions = transactions.map(
        (tx) => WalletSecurity.sanitizeTransaction(tx)
      ).where((tx) => tx['is_valid'] == true).toList();

      return sanitizedTransactions.where((t) {
        final txMethod = (t['method'] as String).toLowerCase();
        return txMethod.contains(sanitizedMethod.toLowerCase());
      }).toList();
    } catch (error) {
      ErrorHandler.logError('Filter By Method', error);
      return [];
    }
  }

  static List<Map<String, dynamic>> sortByDate(
    List<Map<String, dynamic>> transactions,
    {bool ascending = false}
  ) {
    try {
      final sanitizedTransactions = transactions.map(
        (tx) => WalletSecurity.sanitizeTransaction(tx)
      ).where((tx) => tx['is_valid'] == true).toList();

      final sorted = List<Map<String, dynamic>>.from(sanitizedTransactions);
      sorted.sort((a, b) {
        try {
          final dateA = _parseDate(a['date'] as String);
          final dateB = _parseDate(b['date'] as String);
          final timeA = _parseTime(a['time'] as String);
          final timeB = _parseTime(b['time'] as String);
          
          final dateTimeA = DateTime(dateA.year, dateA.month, dateA.day, timeA.hour, timeA.minute);
          final dateTimeB = DateTime(dateB.year, dateB.month, dateB.day, timeB.hour, timeB.minute);
          
          return ascending
              ? dateTimeA.compareTo(dateTimeB)
              : dateTimeB.compareTo(dateTimeA);
        } catch (error) {
          return 0;
        }
      });
      return sorted;
    } catch (error) {
      ErrorHandler.logError('Sort By Date', error);
      return transactions;
    }
  }

  static List<Map<String, dynamic>> sortByAmount(
    List<Map<String, dynamic>> transactions,
    {bool ascending = false}
  ) {
    try {
      final sanitizedTransactions = transactions.map(
        (tx) => WalletSecurity.sanitizeTransaction(tx)
      ).where((tx) => tx['is_valid'] == true).toList();

      final sorted = List<Map<String, dynamic>>.from(sanitizedTransactions);
      sorted.sort((a, b) {
        try {
          final amountA = a['amount'] as double;
          final amountB = b['amount'] as double;
          return ascending
              ? amountA.compareTo(amountB)
              : amountB.compareTo(amountA);
        } catch (error) {
          return 0;
        }
      });
      return sorted;
    } catch (error) {
      ErrorHandler.logError('Sort By Amount', error);
      return transactions;
    }
  }

  static DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length != 3) {
        throw FormatException('Invalid date format: $dateStr');
      }
      return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } catch (error) {
      ErrorHandler.logError('Parse Date', error);
      return DateTime.now();
    }
  }

  static DateTime _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length < 2) {
        throw FormatException('Invalid time format: $timeStr');
      }
      return DateTime(0, 0, 0, int.parse(parts[0]), int.parse(parts[1]));
    } catch (error) {
      ErrorHandler.logError('Parse Time', error);
      return DateTime.now();
    }
  }

  // دالة جديدة لجلب ملخص المحفظة
  static Future<Map<String, dynamic>> getWalletSummary(
    double currentBalance,
    double holdingBalance,
    List<Map<String, dynamic>> transactions,
  ) async {
    try {
      return await WalletSecurity.getWalletSummary(
        currentBalance,
        holdingBalance,
        transactions,
      );
    } catch (error) {
      ErrorHandler.logError('Get Wallet Summary', error);
      return {
        'current_balance': currentBalance,
        'holding_balance': holdingBalance,
        'error': ErrorHandler.getSafeError(error),
      };
    }
  }

  // دالة جديدة للتحقق من صحة المعاملة
  static bool isValidTransaction(Map<String, dynamic> transaction) {
    try {
      return WalletSecurity.isValidTransaction(transaction);
    } catch (error) {
      ErrorHandler.logError('Is Valid Transaction', error);
      return false;
    }
  }

  // دالة جديدة لتنظيف المعاملة
  static Map<String, dynamic> sanitizeTransaction(Map<String, dynamic> transaction) {
    try {
      return WalletSecurity.sanitizeTransaction(transaction);
    } catch (error) {
      ErrorHandler.logError('Sanitize Transaction', error);
      return {
        'id': 'error_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'error',
        'amount': 0.0,
        'date': '1970-01-01',
        'time': '00:00',
        'method': 'Error',
        'status': 'failed',
      };
    }
  }

  // دالة جديدة لتنسيق المبلغ مع رمز العملة
  static String formatAmountWithCurrency(double amount, {String currency = 'JD'}) {
    try {
      if (!isValidAmount(amount)) {
        return '0.00 $currency';
      }
      return '${amount.toStringAsFixed(2)} $currency';
    } catch (error) {
      ErrorHandler.logError('Format Amount With Currency', error);
      return '0.00 $currency';
    }
  }

  // دالة جديدة لحساب نسبة الرصيد المحجوز
  static double calculateHoldingRatio(double currentBalance, double holdingBalance) {
    try {
      final totalBalance = currentBalance + holdingBalance;
      if (totalBalance == 0) return 0.0;
      return (holdingBalance / totalBalance) * 100;
    } catch (error) {
      ErrorHandler.logError('Calculate Holding Ratio', error);
      return 0.0;
    }
  }

  // دالة جديدة لتقدير الضرائب والرسوم
  static Map<String, double> calculateFees(double amount, {bool isDeposit = true}) {
    try {
      if (!isValidAmount(amount)) {
        return {'total': 0.0, 'tax': 0.0, 'fee': 0.0};
      }

      double taxRate = 0.0;
      double feeRate = isDeposit ? 0.02 : 0.015; // 2% للإيداع، 1.5% للسحب

      final tax = amount * taxRate;
      final fee = amount * feeRate;
      final total = tax + fee;

      return {
        'tax': double.parse(tax.toStringAsFixed(2)),
        'fee': double.parse(fee.toStringAsFixed(2)),
        'total': double.parse(total.toStringAsFixed(2)),
        'net_amount': double.parse((amount - total).toStringAsFixed(2)),
      };
    } catch (error) {
      ErrorHandler.logError('Calculate Fees', error);
      return {'total': 0.0, 'tax': 0.0, 'fee': 0.0, 'net_amount': amount};
    }
  }
}
