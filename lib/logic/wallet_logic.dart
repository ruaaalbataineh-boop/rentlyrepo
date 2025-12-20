

import 'dart:math';

class WalletLogic {
  
  static double currentBalance = 1250.75;
  
  static List<Map<String, dynamic>> recentTransactions = [
    {
      'id': 'TXN001',
      'type': 'deposit',
      'amount': 200.00,
      'date': '2025-12-01',
      'time': '17:19',
      'method': 'Credit Card',
      'icon': 'credit_card',
      'color': 'green',
      'status': 'Completed',
    },
    {
      'id': 'TXN002',
      'type': 'withdrawal',
      'amount': 100.00,
      'date': '2025-12-01',
      'time': '14:30',
      'method': 'Cash',
      'icon': 'money',
      'color': 'red',
      'status': 'Completed',
    },
    {
      'id': 'TXN003',
      'type': 'deposit',
      'amount': 500.00,
      'date': '2025-11-28',
      'time': '11:45',
      'method': 'Click',
      'icon': 'wallet',
      'color': 'green',
      'status': 'Completed',
    },
  ];

  static double getTotalDeposits(List<Map<String, dynamic>> transactions) {
    return transactions
        .where((t) => t['type'] == 'deposit')
        .fold(0.0, (sum, t) => sum + (t['amount'] as double));
  }

  static double getTotalWithdrawals(List<Map<String, dynamic>> transactions) {
    return transactions
        .where((t) => t['type'] == 'withdrawal')
        .fold(0.0, (sum, t) => sum + (t['amount'] as double));
  }

  static double getAverageDeposit(List<Map<String, dynamic>> transactions) {
    final deposits = transactions.where((t) => t['type'] == 'deposit');
    if (deposits.isEmpty) return 0.0;
    return getTotalDeposits(transactions) / deposits.length;
  }

  static int getTransactionCount(List<Map<String, dynamic>> transactions) {
    return transactions.length;
  }

  static double calculateNewBalance(double currentBalance, double amount, bool isDeposit) {
    return isDeposit ? currentBalance + amount : currentBalance - amount;
  }

  static bool canWithdraw(double currentBalance, double amount) {
    return currentBalance >= amount && amount > 0;
  }

  static bool isValidAmount(double amount) {
    return amount > 0 && amount <= 1000000; 
  }

  static String formatBalance(double amount) {
    return amount.toStringAsFixed(2);
  }

  
  static Map<String, dynamic> createTransaction({
    required String type,
    required double amount,
    required String method,
    String? customId,
  }) {
    final now = DateTime.now();
    final id = customId ?? generateTransactionId();
    

    String icon;
    String color;
    
    if (type == 'deposit') {
      icon = _getDepositIcon(method);
      color = 'green';
    } else {
      icon = _getWithdrawalIcon(method);
      color = 'red';
    }
    
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      'method': method,
      'icon': icon,
      'color': color,
      'status': 'Completed',
    };
  }

  static String generateTransactionId() {
    final random = Random();
    final id = random.nextInt(999999).toString().padLeft(6, '0');
    return 'TXN$id';
  }

  static List<Map<String, dynamic>> addTransaction(
    List<Map<String, dynamic>> transactions,
    Map<String, dynamic> newTransaction,
  ) {
    final updatedTransactions = List<Map<String, dynamic>>.from(transactions);
    updatedTransactions.insert(0, newTransaction);
    return updatedTransactions;
  }

  
  static String? validateDeposit(double amount, String method) {
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    if (amount > 1000000) {
      return 'Maximum deposit amount is \$1,000,000';
    }
    if (method.isEmpty) {
      return 'Please select a payment method';
    }
    return null;
  }

  static String? validateWithdrawal(double amount, String method, double currentBalance) {
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    if (amount > currentBalance) {
      return 'Insufficient balance';
    }
    if (amount > 5000) {
      return 'Maximum withdrawal amount is \$5,000 per transaction';
    }
    if (method.isEmpty) {
      return 'Please select a withdrawal method';
    }
    return null;
  }

  static String _getDepositIcon(String method) {
    switch (method.toLowerCase()) {
      case 'credit card':
        return 'credit_card';
      case 'debit card':
        return 'credit_card';
      case 'bank transfer':
        return 'account_balance';
      case 'click':
        return 'touch_app';
      case 'paypal':
        return 'payments';
      default:
        return 'account_balance_wallet';
    }
  }

  static String _getWithdrawalIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'money';
      case 'bank transfer':
        return 'account_balance';
      case 'debit card':
        return 'credit_card';
      default:
        return 'money';
    }
  }


  static Map<String, double> getDailyStats(List<Map<String, dynamic>> transactions) {
    final dailyDeposits = <String, double>{};
    final dailyWithdrawals = <String, double>{};
    
    for (final transaction in transactions) {
      final date = transaction['date'] as String;
      final amount = transaction['amount'] as double;
      final type = transaction['type'] as String;
      
      if (type == 'deposit') {
        dailyDeposits[date] = (dailyDeposits[date] ?? 0) + amount;
      } else {
        dailyWithdrawals[date] = (dailyWithdrawals[date] ?? 0) + amount;
      }
    }
    
    return {
      'todayDeposits': dailyDeposits.values.isNotEmpty ? dailyDeposits.values.reduce(max) : 0,
      'todayWithdrawals': dailyWithdrawals.values.isNotEmpty ? dailyWithdrawals.values.reduce(max) : 0,
    };
  }

  static Map<String, double> getMonthlyStats(List<Map<String, dynamic>> transactions) {
    double monthlyDeposit = 0;
    double monthlyWithdrawal = 0;
    
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    
    for (final transaction in transactions) {
      final date = transaction['date'] as String;
      final parts = date.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        
        if (year == currentYear && month == currentMonth) {
          final amount = transaction['amount'] as double;
          final type = transaction['type'] as String;
          
          if (type == 'deposit') {
            monthlyDeposit += amount;
          } else {
            monthlyWithdrawal += amount;
          }
        }
      }
    }
    
    return {
      'monthlyDeposit': monthlyDeposit,
      'monthlyWithdrawal': monthlyWithdrawal,
    };
  }

  static List<Map<String, dynamic>> filterByDateRange(
    List<Map<String, dynamic>> transactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    return transactions.where((transaction) {
      final dateStr = transaction['date'] as String;
      final parts = dateStr.split('-');
      if (parts.length != 3) return false;
      
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      final transactionDate = DateTime(year, month, day);
      
      return transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
             transactionDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  static List<Map<String, dynamic>> filterByType(
    List<Map<String, dynamic>> transactions,
    String type,
  ) {
    return transactions.where((t) => t['type'] == type).toList();
  }

  static List<Map<String, dynamic>> filterByMethod(
    List<Map<String, dynamic>> transactions,
    String method,
  ) {
    return transactions.where((t) => t['method'] == method).toList();
  }

  
  static List<Map<String, dynamic>> sortByDate(
    List<Map<String, dynamic>> transactions,
    {bool ascending = false}
  ) {
    final sorted = List<Map<String, dynamic>>.from(transactions);
    sorted.sort((a, b) {
      final dateA = _parseDate(a['date'] as String);
      final dateB = _parseDate(b['date'] as String);
      final timeA = _parseTime(a['time'] as String);
      final timeB = _parseTime(b['time'] as String);
      
      final dateTimeA = DateTime(dateA.year, dateA.month, dateA.day, timeA.hour, timeA.minute);
      final dateTimeB = DateTime(dateB.year, dateB.month, dateB.day, timeB.hour, timeB.minute);
      
      return ascending
          ? dateTimeA.compareTo(dateTimeB)
          : dateTimeB.compareTo(dateTimeA);
    });
    return sorted;
  }

  static List<Map<String, dynamic>> sortByAmount(
    List<Map<String, dynamic>> transactions,
    {bool ascending = false}
  ) {
    final sorted = List<Map<String, dynamic>>.from(transactions);
    sorted.sort((a, b) {
      final amountA = a['amount'] as double;
      final amountB = b['amount'] as double;
      return ascending
          ? amountA.compareTo(amountB)
          : amountB.compareTo(amountA);
    });
    return sorted;
  }


  static DateTime _parseDate(String dateStr) {
    final parts = dateStr.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  static DateTime _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return DateTime(0, 0, 0, int.parse(parts[0]), int.parse(parts[1]));
  }
}
