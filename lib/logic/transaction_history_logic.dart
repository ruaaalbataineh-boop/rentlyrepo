import 'dart:math';
import 'package:flutter/material.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/transaction_security.dart';

class TransactionHistoryLogic {
  List<Map<String, dynamic>> transactions;
  String filter;

  TransactionHistoryLogic({
    required List<Map<String, dynamic>> transactions,
    this.filter = 'All',
  }) : transactions = TransactionSecurity.sanitizeTransactions(transactions);

  List<Map<String, dynamic>> get filteredTransactions {
    try {
      if (filter == 'Deposits') {
        return transactions.where((t) => t['type'] == 'deposit').toList();
      } else if (filter == 'Withdrawals') {
        return transactions.where((t) => t['type'] == 'withdrawal').toList();
      } else {
        return transactions;
      }
    } catch (error) {
      ErrorHandler.logError('Get Filtered Transactions', error);
      return [];
    }
  }

  void setFilter(String newFilter) {
    try {
      if (newFilter.isEmpty) {
        ErrorHandler.logWarning('Set Filter', 'Empty filter provided');
        return;
      }

      final validFilters = ['All', 'Deposits', 'Withdrawals'];
      if (!validFilters.contains(newFilter)) {
        ErrorHandler.logSecurity('Set Filter', 
            'Invalid filter: $newFilter');
        return;
      }

      filter = newFilter;
      ErrorHandler.logInfo('Set Filter', 'Filter changed to: $newFilter');
    } catch (error) {
      ErrorHandler.logError('Set Filter', error);
    }
  }

  bool isFilterActive(String filterName) {
    try {
      return filter == filterName;
    } catch (error) {
      ErrorHandler.logError('Is Filter Active', error);
      return false;
    }
  }
 
  double get totalDeposits {
    try {
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
    } catch (error) {
      ErrorHandler.logError('Get Total Deposits', error);
      return 0.0;
    }
  }

  double get totalWithdrawals {
    try {
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
    } catch (error) {
      ErrorHandler.logError('Get Total Withdrawals', error);
      return 0.0;
    }
  }

  double get currentBalance {
    try {
      return totalDeposits - totalWithdrawals;
    } catch (error) {
      ErrorHandler.logError('Get Current Balance', error);
      return 0.0;
    }
  }

  int get transactionCount {
    try {
      return transactions.length;
    } catch (error) {
      ErrorHandler.logError('Get Transaction Count', error);
      return 0;
    }
  }

  int get filteredTransactionCount {
    try {
      return filteredTransactions.length;
    } catch (error) {
      ErrorHandler.logError('Get Filtered Transaction Count', error);
      return 0;
    }
  }

  String get filterDisplayName {
    try {
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
    } catch (error) {
      ErrorHandler.logError('Get Filter Display Name', error);
      return 'Transactions';
    }
  }

  List<Map<String, dynamic>> getTransactionsByDateRange(DateTime startDate, DateTime endDate) {
    try {
      return transactions.where((transaction) {
        final dateStr = transaction['date'] as String;
        final transactionDate = _parseDate(dateStr);
        return transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
               transactionDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    } catch (error) {
      ErrorHandler.logError('Get Transactions By Date Range', error);
      return [];
    }
  }

  List<Map<String, dynamic>> getTransactionsByMethod(String method) {
    try {
      final sanitizedMethod = TransactionSecurity.sanitizeTransaction({'method': method})['method'];
      return transactions.where((t) => t['method'] == sanitizedMethod).toList();
    } catch (error) {
      ErrorHandler.logError('Get Transactions By Method', error);
      return [];
    }
  }

  List<Map<String, dynamic>> getTransactionsByStatus(String status) {
    try {
      final sanitizedStatus = TransactionSecurity.sanitizeTransaction({'status': status})['status'];
      return transactions.where((t) => t['status'] == sanitizedStatus).toList();
    } catch (error) {
      ErrorHandler.logError('Get Transactions By Status', error);
      return [];
    }
  }

  List<Map<String, dynamic>> sortByDate({bool ascending = false}) {
    try {
      final sorted = List<Map<String, dynamic>>.from(filteredTransactions);
      sorted.sort((a, b) {
        final dateTimeA = _parseDateTime(a['date'] as String, a['time'] as String);
        final dateTimeB = _parseDateTime(b['date'] as String, b['time'] as String);
        return ascending ? dateTimeA.compareTo(dateTimeB) : dateTimeB.compareTo(dateTimeA);
      });
      return sorted;
    } catch (error) {
      ErrorHandler.logError('Sort By Date', error);
      return filteredTransactions;
    }
  }

  List<Map<String, dynamic>> sortByAmount({bool ascending = false}) {
    try {
      final sorted = List<Map<String, dynamic>>.from(filteredTransactions);
      sorted.sort((a, b) {
        final amountA = _parseAmount(a['amount']);
        final amountB = _parseAmount(b['amount']);
        return ascending ? amountA.compareTo(amountB) : amountB.compareTo(amountA);
      });
      return sorted;
    } catch (error) {
      ErrorHandler.logError('Sort By Amount', error);
      return filteredTransactions;
    }
  }

  List<Map<String, dynamic>> sortByStatus({bool completedFirst = true}) {
    try {
      final sorted = List<Map<String, dynamic>>.from(filteredTransactions);
      sorted.sort((a, b) {
        final statusA = a['status'] as String;
        final statusB = b['status'] as String;
        if (completedFirst) {
          if (statusA == 'completed' && statusB != 'completed') return -1;
          if (statusA != 'completed' && statusB == 'completed') return 1;
        }
        return 0;
      });
      return sorted;
    } catch (error) {
      ErrorHandler.logError('Sort By Status', error);
      return filteredTransactions;
    }
  }
  
  List<Map<String, dynamic>> searchTransactions(String query) {
    try {
      final sanitizedQuery = query.trim();
      if (sanitizedQuery.isEmpty) {
        return filteredTransactions;
      }

      final lowerQuery = sanitizedQuery.toLowerCase();
      return filteredTransactions.where((transaction) {
        return (transaction['id'] as String).toLowerCase().contains(lowerQuery) ||
               (transaction['method'] as String).toLowerCase().contains(lowerQuery) ||
               (transaction['type'] as String).toLowerCase().contains(lowerQuery) ||
               (transaction['status'] as String).toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (error) {
      ErrorHandler.logError('Search Transactions', error);
      return [];
    }
  }

  List<Map<String, dynamic>> searchTransactionsByAmount(double minAmount, double maxAmount) {
    try {
      if (minAmount < 0 || maxAmount < 0 || minAmount > maxAmount) {
        ErrorHandler.logWarning('Search Transactions By Amount', 
            'Invalid amount range: $minAmount - $maxAmount');
        return [];
      }

      return filteredTransactions.where((transaction) {
        final amount = _parseAmount(transaction['amount']);
        return amount >= minAmount && amount <= maxAmount;
      }).toList();
    } catch (error) {
      ErrorHandler.logError('Search Transactions By Amount', error);
      return [];
    }
  }

  Map<String, dynamic> getTransactionDetails(String transactionId) {
    try {
      final sanitizedId = transactionId.trim();
      if (sanitizedId.isEmpty) {
        return {};
      }

      return transactions.firstWhere(
        (t) => t['id'] == sanitizedId,
        orElse: () => {},
      );
    } catch (error) {
      ErrorHandler.logError('Get Transaction Details', error);
      return {};
    }
  }

  double getTransactionAmount(String transactionId) {
    try {
      final transaction = getTransactionDetails(transactionId);
      return _parseAmount(transaction['amount']);
    } catch (error) {
      ErrorHandler.logError('Get Transaction Amount', error);
      return 0.0;
    }
  }

  String getTransactionType(String transactionId) {
    try {
      final transaction = getTransactionDetails(transactionId);
      return transaction['type'] as String? ?? '';
    } catch (error) {
      ErrorHandler.logError('Get Transaction Type', error);
      return '';
    }
  }

  String getTransactionStatus(String transactionId) {
    try {
      final transaction = getTransactionDetails(transactionId);
      return transaction['status'] as String? ?? '';
    } catch (error) {
      ErrorHandler.logError('Get Transaction Status', error);
      return '';
    }
  }

  bool hasTransactions() {
    try {
      return transactions.isNotEmpty;
    } catch (error) {
      ErrorHandler.logError('Has Transactions', error);
      return false;
    }
  }

  bool hasFilteredTransactions() {
    try {
      return filteredTransactions.isNotEmpty;
    } catch (error) {
      ErrorHandler.logError('Has Filtered Transactions', error);
      return false;
    }
  }

  bool isTransactionValid(Map<String, dynamic> transaction) {
    try {
      return TransactionSecurity.isValidTransaction(transaction);
    } catch (error) {
      ErrorHandler.logError('Is Transaction Valid', error);
      return false;
    }
  }

  List<String> validateTransaction(Map<String, dynamic> transaction) {
    try {
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
    } catch (error) {
      ErrorHandler.logError('Validate Transaction', error);
      return ['Failed to validate transaction'];
    }
  }

  DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } catch (error) {
      ErrorHandler.logError('Parse Date', error);
      return DateTime.now();
    }
  }

  DateTime _parseDateTime(String dateStr, String timeStr) {
    try {
      final date = _parseDate(dateStr);
      final timeParts = timeStr.split(':');
      return DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    } catch (error) {
      ErrorHandler.logError('Parse DateTime', error);
      return DateTime.now();
    }
  }

  double _parseAmount(dynamic amount) {
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
      ErrorHandler.logError('Parse Amount', error);
      return 0.0;
    }
  }

  String formatBalance(double balance) {
    try {
      return balance.toStringAsFixed(2);
    } catch (error) {
      ErrorHandler.logError('Format Balance', error);
      return '0.00';
    }
  }

  String formatAmount(dynamic amount) {
    try {
      return _parseAmount(amount).toStringAsFixed(2);
    } catch (error) {
      ErrorHandler.logError('Format Amount', error);
      return '0.00';
    }
  }

  String formatDate(String dateStr) {
    try {
      final date = _parseDate(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (error) {
      ErrorHandler.logError('Format Date', error);
      return 'Invalid Date';
    }
  }

  String formatDateTime(String dateStr, String timeStr) {
    try {
      return '${formatDate(dateStr)} at $timeStr';
    } catch (error) {
      ErrorHandler.logError('Format DateTime', error);
      return 'Invalid Date/Time';
    }
  }

  Color getStatusColor(String status) {
    try {
      final sanitizedStatus = status.toLowerCase();
      switch (sanitizedStatus) {
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
    } catch (error) {
      ErrorHandler.logError('Get Status Color', error);
      return Colors.grey;
    }
  }

  IconData getStatusIcon(String status) {
    try {
      final sanitizedStatus = status.toLowerCase();
      switch (sanitizedStatus) {
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
    } catch (error) {
      ErrorHandler.logError('Get Status Icon', error);
      return Icons.error;
    }
  }

  Color getTypeColor(String type) {
    try {
      return type == 'deposit' ? Colors.green : Colors.red;
    } catch (error) {
      ErrorHandler.logError('Get Type Color', error);
      return Colors.grey;
    }
  }

  IconData getTypeIcon(String type) {
    try {
      return type == 'deposit' ? Icons.add_circle : Icons.remove_circle;
    } catch (error) {
      ErrorHandler.logError('Get Type Icon', error);
      return Icons.error;
    }
  }

  String getTypeDisplayName(String type) {
    try {
      return type == 'deposit' ? 'Wallet Recharge' : 'Cash Withdrawal';
    } catch (error) {
      ErrorHandler.logError('Get Type Display Name', error);
      return 'Transaction';
    }
  }

  List<Map<String, dynamic>> exportToCSV() {
    try {
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
    } catch (error) {
      ErrorHandler.logError('Export To CSV', error);
      return [];
    }
  }

  Map<String, dynamic> getSummary() {
    try {
      return {
        'totalTransactions': transactionCount,
        'totalDeposits': totalDeposits,
        'totalWithdrawals': totalWithdrawals,
        'currentBalance': currentBalance,
        'averageTransaction': transactionCount > 0 ? (totalDeposits + totalWithdrawals) / transactionCount : 0,
        'depositPercentage': totalDeposits > 0 ? (totalDeposits / (totalDeposits + totalWithdrawals)) * 100 : 0,
        'withdrawalPercentage': totalWithdrawals > 0 ? (totalWithdrawals / (totalDeposits + totalWithdrawals)) * 100 : 0,
        'hasSuspiciousActivity': false, // يمكن تحديث هذا بناءً على تحليل الأمان
      };
    } catch (error) {
      ErrorHandler.logError('Get Summary', error);
      return {
        'error': ErrorHandler.getSafeError(error),
      };
    }
  }

  // دالة جديدة لفحص سلامة البيانات
  Future<Map<String, dynamic>> checkDataIntegrity() async {
    try {
      final validTransactions = transactions.where(isTransactionValid).toList();
      final invalidTransactions = transactions.where((t) => !isTransactionValid(t)).toList();
      
      final suspiciousActivity = await TransactionSecurity.detectSuspiciousActivity(transactions);
      
      return {
        'totalTransactions': transactionCount,
        'validTransactions': validTransactions.length,
        'invalidTransactions': invalidTransactions.length,
        'dataIntegrityScore': transactionCount > 0 
            ? (validTransactions.length / transactionCount) * 100 
            : 100,
        'hasSuspiciousActivity': suspiciousActivity,
        'averageAmount': transactionCount > 0 
            ? (totalDeposits + totalWithdrawals) / transactionCount 
            : 0,
        'largestTransaction': _getLargestTransaction(),
        'recentTransactions': _getRecentTransactions(7), // آخر 7 أيام
      };
    } catch (error) {
      ErrorHandler.logError('Check Data Integrity', error);
      return {
        'error': ErrorHandler.getSafeError(error),
      };
    }
  }

  double _getLargestTransaction() {
    try {
      if (transactions.isEmpty) return 0.0;
      
      double largest = 0.0;
      for (final transaction in transactions) {
        final amount = _parseAmount(transaction['amount']);
        if (amount > largest) {
          largest = amount;
        }
      }
      return largest;
    } catch (error) {
      return 0.0;
    }
  }

  List<Map<String, dynamic>> _getRecentTransactions(int days) {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      return transactions.where((transaction) {
        final dateStr = transaction['date'] as String;
        final transactionDate = _parseDate(dateStr);
        return transactionDate.isAfter(cutoffDate);
      }).toList();
    } catch (error) {
      return [];
    }
  }
}
