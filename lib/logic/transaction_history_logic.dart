

import 'dart:math';
import 'package:flutter/material.dart';

class TransactionHistoryLogic {
  List<Map<String, dynamic>> transactions;
  String filter;

  TransactionHistoryLogic({
    required this.transactions,
    this.filter = 'All',
  });

  List<Map<String, dynamic>> get filteredTransactions {
    if (filter == 'Deposits') {
      return transactions.where((t) => t['type'] == 'deposit').toList();
    } else if (filter == 'Withdrawals') {
      return transactions.where((t) => t['type'] == 'withdrawal').toList();
    } else {
      return transactions;
    }
  }

  void setFilter(String newFilter) {
    filter = newFilter;
  }

  bool isFilterActive(String filterName) {
    return filter == filterName;
  }
 
  double get totalDeposits {
    return transactions
        .where((t) => t['type'] == 'deposit')
        .fold(0.0, (sum, t) {
          final amount = t['amount'];
          if (amount is double) {
            return sum + amount;
          } else if (amount is int) {
            return sum + amount.toDouble();
          } else if (amount is String) {
            return sum + (double.tryParse(amount) ?? 0.0);
          }
          return sum;
        });
  }

  double get totalWithdrawals {
    return transactions
        .where((t) => t['type'] == 'withdrawal')
        .fold(0.0, (sum, t) {
          final amount = t['amount'];
          if (amount is double) {
            return sum + amount;
          } else if (amount is int) {
            return sum + amount.toDouble();
          } else if (amount is String) {
            return sum + (double.tryParse(amount) ?? 0.0);
          }
          return sum;
        });
  }

  double get currentBalance {
    return totalDeposits - totalWithdrawals;
  }

  int get transactionCount {
    return transactions.length;
  }

  int get filteredTransactionCount {
    return filteredTransactions.length;
  }

  String get filterDisplayName {
    switch (filter) {
      case 'All':
        return 'All Transactions';
      case 'Deposits':
        return 'All Deposits';
      case 'Withdrawals':
        return 'All Withdrawals';
      default:
        return 'Transactions';
    }
  }

  List<Map<String, dynamic>> getTransactionsByDateRange(DateTime startDate, DateTime endDate) {
    return transactions.where((transaction) {
      final dateStr = transaction['date'] as String;
      final transactionDate = _parseDate(dateStr);
      return transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
             transactionDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  List<Map<String, dynamic>> getTransactionsByMethod(String method) {
    return transactions.where((t) => t['method'] == method).toList();
  }

  List<Map<String, dynamic>> getTransactionsByStatus(String status) {
    return transactions.where((t) => t['status'] == status).toList();
  }

  List<Map<String, dynamic>> sortByDate({bool ascending = false}) {
    final sorted = List<Map<String, dynamic>>.from(filteredTransactions);
    sorted.sort((a, b) {
      final dateTimeA = _parseDateTime(a['date'] as String, a['time'] as String);
      final dateTimeB = _parseDateTime(b['date'] as String, b['time'] as String);
      return ascending ? dateTimeA.compareTo(dateTimeB) : dateTimeB.compareTo(dateTimeA);
    });
    return sorted;
  }

  List<Map<String, dynamic>> sortByAmount({bool ascending = false}) {
    final sorted = List<Map<String, dynamic>>.from(filteredTransactions);
    sorted.sort((a, b) {
      final amountA = _parseAmount(a['amount']);
      final amountB = _parseAmount(b['amount']);
      return ascending ? amountA.compareTo(amountB) : amountB.compareTo(amountA);
    });
    return sorted;
  }

  List<Map<String, dynamic>> sortByStatus({bool completedFirst = true}) {
    final sorted = List<Map<String, dynamic>>.from(filteredTransactions);
    sorted.sort((a, b) {
      final statusA = a['status'] as String;
      final statusB = b['status'] as String;
      if (completedFirst) {
        if (statusA == 'Completed' && statusB != 'Completed') return -1;
        if (statusA != 'Completed' && statusB == 'Completed') return 1;
      }
      return 0;
    });
    return sorted;
  }
  
  List<Map<String, dynamic>> searchTransactions(String query) {
    final lowerQuery = query.toLowerCase();
    return filteredTransactions.where((transaction) {
      return (transaction['id'] as String).toLowerCase().contains(lowerQuery) ||
             (transaction['method'] as String).toLowerCase().contains(lowerQuery) ||
             (transaction['type'] as String).toLowerCase().contains(lowerQuery) ||
             (transaction['status'] as String).toLowerCase().contains(lowerQuery);
    }).toList();
  }

  List<Map<String, dynamic>> searchTransactionsByAmount(double minAmount, double maxAmount) {
    return filteredTransactions.where((transaction) {
      final amount = _parseAmount(transaction['amount']);
      return amount >= minAmount && amount <= maxAmount;
    }).toList();
  }

  Map<String, dynamic> getTransactionDetails(String transactionId) {
    return transactions.firstWhere(
      (t) => t['id'] == transactionId,
      orElse: () => {},
    );
  }

  double getTransactionAmount(String transactionId) {
    final transaction = getTransactionDetails(transactionId);
    return _parseAmount(transaction['amount']);
  }

  String getTransactionType(String transactionId) {
    final transaction = getTransactionDetails(transactionId);
    return transaction['type'] as String? ?? '';
  }

  String getTransactionStatus(String transactionId) {
    final transaction = getTransactionDetails(transactionId);
    return transaction['status'] as String? ?? '';
  }

  bool hasTransactions() {
    return transactions.isNotEmpty;
  }

  bool hasFilteredTransactions() {
    return filteredTransactions.isNotEmpty;
  }

  bool isTransactionValid(Map<String, dynamic> transaction) {
    final requiredKeys = ['id', 'type', 'amount', 'date', 'time', 'method', 'status'];
    for (final key in requiredKeys) {
      if (!transaction.containsKey(key)) {
        return false;
      }
    }
    
    final amount = transaction['amount'];
    if (amount is! double && amount is! int && amount is! String) {
      return false;
    }
    
    return true;
  }

  List<String> validateTransaction(Map<String, dynamic> transaction) {
    final errors = <String>[];
    
    if (!transaction.containsKey('id')) {
      errors.add('Transaction ID is missing');
    }
    
    if (!transaction.containsKey('amount')) {
      errors.add('Amount is missing');
    } else {
      final amount = transaction['amount'];
      final parsedAmount = _parseAmount(amount);
      if (parsedAmount <= 0) {
        errors.add('Amount must be greater than 0');
      }
    }
    
    if (!transaction.containsKey('type')) {
      errors.add('Type is missing');
    } else if (transaction['type'] != 'deposit' && transaction['type'] != 'withdrawal') {
      errors.add('Type must be deposit or withdrawal');
    }
    
    return errors;
  }

  DateTime _parseDate(String dateStr) {
    final parts = dateStr.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  DateTime _parseDateTime(String dateStr, String timeStr) {
    final date = _parseDate(dateStr);
    final timeParts = timeStr.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  double _parseAmount(dynamic amount) {
    if (amount is double) {
      return amount;
    } else if (amount is int) {
      return amount.toDouble();
    } else if (amount is String) {
      return double.tryParse(amount) ?? 0.0;
    }
    return 0.0;
  }

  String formatBalance(double balance) {
    return balance.toStringAsFixed(2);
  }

  String formatAmount(dynamic amount) {
    return _parseAmount(amount).toStringAsFixed(2);
  }

  String formatDate(String dateStr) {
    final date = _parseDate(dateStr);
    return '${date.day}/${date.month}/${date.year}';
  }

  String formatDateTime(String dateStr, String timeStr) {
    return '${formatDate(dateStr)} at $timeStr';
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      case 'failed':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'processing':
        return Icons.timelapse;
      case 'pending':
        return Icons.schedule;
      case 'failed':
        return Icons.error;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Color getTypeColor(String type) {
    return type == 'deposit' ? Colors.green : Colors.red;
  }

  IconData getTypeIcon(String type) {
    return type == 'deposit' ? Icons.add_circle : Icons.remove_circle;
  }

  String getTypeDisplayName(String type) {
    return type == 'deposit' ? 'Wallet Recharge' : 'Cash Withdrawal';
  }

  List<Map<String, dynamic>> exportToCSV() {
    return filteredTransactions.map((transaction) {
      return {
        'Transaction ID': transaction['id'],
        'Date': transaction['date'],
        'Time': transaction['time'],
        'Type': transaction['type'],
        'Amount': formatAmount(transaction['amount']),
        'Method': transaction['method'],
        'Status': transaction['status'],
      };
    }).toList();
  }

  Map<String, dynamic> getSummary() {
    return {
      'totalTransactions': transactionCount,
      'totalDeposits': totalDeposits,
      'totalWithdrawals': totalWithdrawals,
      'currentBalance': currentBalance,
      'averageTransaction': transactionCount > 0 ? (totalDeposits + totalWithdrawals) / transactionCount : 0,
      'depositPercentage': totalDeposits > 0 ? (totalDeposits / (totalDeposits + totalWithdrawals)) * 100 : 0,
      'withdrawalPercentage': totalWithdrawals > 0 ? (totalWithdrawals / (totalDeposits + totalWithdrawals)) * 100 : 0,
    };
  }
}
