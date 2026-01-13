import 'dart:math';
import 'package:flutter/material.dart';

class WalletRechargeLogic {
  // ==================== السكيوريتي الثوابت ====================
  static const double minRechargeAmount = 10.0;
  static const double maxRechargeAmount = 1000000.0;
  static const double defaultBalance = 1250.75;
  
  // Security constants
  static const int _maxTransactionsPerMinute = 5;
  static const String _amountPattern = r'^\d{1,8}(\.\d{1,2})?$';
  static final List<DateTime> _recentTransactions = [];

  // ==================== البيانات الأساسية ====================
  static List<Map<String, dynamic>> quickAmounts = [
    {'amount': '50', 'icon': 'attach_money', 'color': 'primary'},
    {'amount': '100', 'icon': 'money', 'color': 'purple'},
    {'amount': '200', 'icon': 'account_balance_wallet', 'color': 'deep_purple'},
    {'amount': '500', 'icon': 'savings', 'color': 'indigo'},
    {'amount': '1000', 'icon': 'diamond', 'color': 'dark_purple'},
  ];

  static List<Map<String, dynamic>> paymentMethods = [
    {
      'id': 'credit_card',
      'name': 'Credit/Debit Card',
      'description': 'Visa, MasterCard, American Express',
      'icon': 'credit_card',
      'isAvailable': true,
    },
    {
      'id': 'efawateercom',
      'name': 'eFawateercom',
      'description': 'Digital wallet payment',
      'icon': 'account_balance_wallet',
      'isAvailable': true,
    },
  ];

  static List<String> importantInfo = [
    'Minimum recharge amount: \$10',
    'No transaction fees',
    'Funds available instantly',
    '24/7 customer support',
    'Bank-level security encryption',
  ];

  // ==================== التحقق الآمن ====================
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return getErrorMessage('empty_amount');
    }

    // 1. التحقق من وجود أكواد خبيثة
    if (_containsMaliciousCode(value)) {
      return 'Invalid input detected';
    }

    // 2. تنظيف المدخلات
    final cleanValue = _sanitizeAmountInput(value);
    if (cleanValue.isEmpty) {
      return 'Please enter a valid number';
    }

    // 3. التحقق من النمط
    if (!RegExp(_amountPattern).hasMatch(cleanValue)) {
      return getErrorMessage('invalid_amount');
    }

    final amount = double.tryParse(cleanValue);
    if (amount == null) {
      return getErrorMessage('invalid_amount');
    }

    if (amount <= 0) {
      return getErrorMessage('zero_amount');
    }

    if (amount < minRechargeAmount) {
      return getErrorMessage('min_amount');
    }

    if (amount > maxRechargeAmount) {
      return getErrorMessage('max_amount');
    }

    // 4. تحقق أمني إضافي
    if (_isSuspiciousAmount(amount)) {
      return 'Amount requires verification';
    }

    return null;
  }

  // ==================== النسخة الآمنة للتحقق ====================
  static String? secureValidateAmount(String? value) {
    final basicValidation = validateAmount(value);
    if (basicValidation != null) return basicValidation;

    if (value == null) return null;

    final amount = double.tryParse(value);
    if (amount == null) return null;

    // تحقق من التكرار السريع للمعاملات
    if (!_canProceedWithTransaction()) {
      return 'Too many transactions. Please wait.';
    }

    // تسجيل المعاملة للتحقق من التكرار
    _recordTransactionAttempt();

    return null;
  }

  static String? validatePaymentMethod(String? method) {
    if (method == null || method.isEmpty) {
      return getErrorMessage('empty_method');
    }

    // التحقق من وجود أكواد خبيثة
    if (_containsMaliciousCode(method)) {
      return 'Invalid payment method';
    }

    final validMethods = paymentMethods.map((m) => m['id']).toList();
    if (!validMethods.contains(method)) {
      return getErrorMessage('invalid_method');
    }

    // التحقق إذا كانت الطريقة متاحة
    final methodInfo = getPaymentMethodInfo(method);
    if (methodInfo['isAvailable'] == false) {
      return 'Payment method temporarily unavailable';
    }

    return null;
  }

  // ==================== الدوال الآمنة الجديدة ====================
  static String _sanitizeAmountInput(String input) {
    // إزالة أي حروف غير رقمية أو نقطة عشرية
    var result = input.replaceAll(RegExp(r'[^\d.]'), '');
    
    // السماح بنقطة عشرية واحدة فقط
    final decimalParts = result.split('.');
    if (decimalParts.length > 2) {
      result = '${decimalParts[0]}.${decimalParts[1]}';
    }
    
    // تحديد منزلتين عشريتين كحد أقصى
    if (result.contains('.')) {
      final parts = result.split('.');
      if (parts[1].length > 2) {
        result = '${parts[0]}.${parts[1].substring(0, 2)}';
      }
    }
    
    return result;
  }

  static bool _containsMaliciousCode(String input) {
    final maliciousPatterns = [
      '<script', 'javascript:', 'onload=', 'onerror=',
      'eval(', 'document.cookie', 'alert(', 'confirm('
    ];
    
    final lowerInput = input.toLowerCase();
    return maliciousPatterns.any((pattern) => lowerInput.contains(pattern));
  }

  static bool _isSuspiciousAmount(double amount) {
    // الكشف عن المبالغ المشبوهة
    // 1. أرقام دائرية كبيرة
    if (amount % 10000 == 0 && amount > 10000) {
      return true;
    }
    
    // 2. مبالغ احتيالية شائعة
    final fraudAmounts = [999, 999.99, 9999, 9999.99, 100001, 500001];
    if (fraudAmounts.contains(amount) || fraudAmounts.contains(amount.toInt())) {
      return true;
    }
    
    // 3. مبالغ قريبة من الحد الأقصى
    if (amount >= maxRechargeAmount * 0.95) {
      return true;
    }
    
    return false;
  }

  static bool _canProceedWithTransaction() {
    final now = DateTime.now();
    
    // إزالة المعاملات الأقدم من دقيقة
    _recentTransactions.removeWhere((time) => 
        now.difference(time) > const Duration(minutes: 1));
    
    // التحقق من العدد المسموح
    return _recentTransactions.length < _maxTransactionsPerMinute;
  }

  static void _recordTransactionAttempt() {
    _recentTransactions.add(DateTime.now());
    
    // الحفاظ على السجل نظيفًا
    if (_recentTransactions.length > 10) {
      _recentTransactions.removeAt(0);
    }
  }

  // ==================== الدوال المساعدة الآمنة ====================
  static bool canProceedToPayment(String? amount, String? method) {
    if (amount == null || amount.isEmpty) return false;
    if (method == null || method.isEmpty) return false;

    final parsedAmount = double.tryParse(amount);
    if (parsedAmount == null) return false;

    // تحقق أمني إضافي
    if (!_canProceedWithTransaction()) {
      return false;
    }

    return parsedAmount >= minRechargeAmount && parsedAmount <= maxRechargeAmount;
  }

  static Map<String, dynamic> createSecureRechargeRecord({
    required double amount,
    required String method,
    required String userId,
  }) {
    final transactionId = _generateSecureTransactionId();
    final now = DateTime.now();
    
    return {
      'id': transactionId,
      'type': 'deposit',
      'amount': amount,
      'method': method,
      'userId': userId,
      'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
      'status': 'pending',
      'securityLevel': 'high',
      'timestamp': now.toIso8601String(),
    };
  }

  static String _generateSecureTransactionId() {
    final random = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(1000000);
    return 'RECH${timestamp}_${randomNum.toString().padLeft(6, '0')}';
  }

  static Future<bool> performSecurityCheck({
    required double amount,
    required String method,
    required BuildContext context,
  }) async {
    // 1. تحقق من الحدود
    if (!isAmountSecure(amount)) {
      return false;
    }

    // 2. تحقق من طريقة الدفع
    if (!isPaymentMethodSecure(method)) {
      return false;
    }

    // 3. تحقق من التكرار
    if (!_canProceedWithTransaction()) {
      return false;
    }

    // 4. تحقق من المبالغ المشبوهة
    if (_isSuspiciousAmount(amount)) {
      // يمكن إضافة تنبيه هنا
      return true; // أو false حسب السياسة
    }

    return true;
  }

  // ==================== الدوال الأصلية (بعد التعديل) ====================
  static double parseAmount(String amountStr) {
    final cleanStr = _sanitizeAmountInput(amountStr);
    return double.tryParse(cleanStr) ?? 0.0;
  }

  static double calculateNewBalance(double currentBalance, double rechargeAmount) {
    // تحقق أمني إضافي
    if (rechargeAmount <= 0) return currentBalance;
    if (rechargeAmount > maxRechargeAmount) return currentBalance;
    
    return currentBalance + rechargeAmount;
  }

  static String formatBalance(double balance) {
    // تقييد المنازل العشرية للأمان
    final formatted = balance.toStringAsFixed(2);
    return double.parse(formatted).toStringAsFixed(2);
  }

  static String formatAmount(double amount) {
    // تقييد المنازل العشرية للأمان
    final formatted = amount.toStringAsFixed(2);
    return double.parse(formatted).toStringAsFixed(2);
  }

  static double calculateTax(double amount, double taxRate) {
    if (amount <= 0 || taxRate < 0) return 0.0;
    return amount * taxRate;
  }

  static double calculateTotalAmount(double amount, double taxRate) {
    final tax = calculateTax(amount, taxRate);
    return amount + tax;
  }

  static Map<String, dynamic> getPaymentMethodInfo(String methodId) {
    return paymentMethods.firstWhere(
      (method) => method['id'] == methodId,
      orElse: () => {
        'id': 'unknown',
        'name': 'Unknown',
        'description': 'Please select a valid method',
        'icon': 'error',
        'isAvailable': false,
      },
    );
  }

  static bool isCreditCardPayment(String methodId) {
    return methodId == 'credit_card';
  }

  static bool isEfawateercomPayment(String methodId) {
    return methodId == 'efawateercom';
  }

  static Map<String, String> getBalanceStats(double currentBalance) {
    return {
      'today': '+ \$25.50',
      'thisWeek': '+ \$350.25',
      'lastMonth': '+ \$1,200.00',
      'security': '🔒 Secured',
    };
  }

  static String getQuickAmountIcon(String iconName) {
    switch (iconName) {
      case 'attach_money':
        return 'attach_money';
      case 'money':
        return 'money';
      case 'account_balance_wallet':
        return 'account_balance_wallet';
      case 'savings':
        return 'savings';
      case 'diamond':
        return 'diamond';
      default:
        return 'attach_money';
    }
  }

  static String getQuickAmountColor(String colorName) {
    switch (colorName) {
      case 'primary':
        return '#8A005D';
      case 'purple':
        return '#9C27B0';
      case 'deep_purple':
        return '#673AB7';
      case 'indigo':
        return '#3F51B5';
      case 'dark_purple':
        return '#1F0F46';
      default:
        return '#8A005D';
    }
  }

  static bool isValidDouble(String value) {
    final cleanValue = _sanitizeAmountInput(value);
    return double.tryParse(cleanValue) != null;
  }

  static String generateTransactionId() {
    return _generateSecureTransactionId();
  }

  static Map<String, dynamic> createRechargeRecord({
    required double amount,
    required String method,
    required String transactionId,
  }) {
    final now = DateTime.now();
    return {
      'id': transactionId,
      'type': 'deposit',
      'amount': amount,
      'method': method,
      'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      'status': 'Pending',
      'securityChecked': true,
    };
  }

  static bool isAmountSecure(double amount) {
    if (amount < minRechargeAmount) return false;
    if (amount > maxRechargeAmount) return false;
    if (_isSuspiciousAmount(amount)) return false;
    return true;
  }

  static bool isPaymentMethodSecure(String methodId) {
    final secureMethods = ['credit_card', 'efawateercom'];
    if (!secureMethods.contains(methodId)) return false;
    
    final methodInfo = getPaymentMethodInfo(methodId);
    return methodInfo['isAvailable'] == true;
  }

  static Map<String, String> getErrorMessages() {
    return {
      'empty_amount': 'Please enter amount',
      'invalid_amount': 'Please enter a valid number',
      'zero_amount': 'Amount must be greater than 0',
      'min_amount': 'Minimum amount is \$$minRechargeAmount',
      'max_amount': 'Maximum amount is \$$maxRechargeAmount',
      'empty_method': 'Please select a payment method',
      'invalid_method': 'Please select a valid payment method',
      'suspicious_amount': 'Amount requires verification',
      'too_many_transactions': 'Too many transactions. Please wait.',
    };
  }

  static String getErrorMessage(String errorCode) {
    final errors = getErrorMessages();
    return errors[errorCode] ?? 'An error occurred';
  }

  // ==================== دوال التتبع الآمن ====================
  static void logSecurityEvent(String event, Map<String, dynamic>? data) {
    print('🔒 SECURITY EVENT: $event');
    if (data != null) {
      print('   Data: $data');
    }
    print('   Time: ${DateTime.now()}');
  }

  static void clearTransactionHistory() {
    _recentTransactions.clear();
  }

  // ==================== تحسينات الأداء ====================
  static bool isQuickAmountValid(String amount) {
    try {
      final value = double.tryParse(amount);
      if (value == null) return false;
      return value >= minRechargeAmount && value <= maxRechargeAmount;
    } catch (e) {
      return false;
    }
  }

  static List<Map<String, dynamic>> getAvailablePaymentMethods() {
    return paymentMethods.where((method) => method['isAvailable'] == true).toList();
  }

  static void disablePaymentMethod(String methodId) {
    final index = paymentMethods.indexWhere((method) => method['id'] == methodId);
    if (index != -1) {
      paymentMethods[index]['isAvailable'] = false;
    }
  }

  static void enablePaymentMethod(String methodId) {
    final index = paymentMethods.indexWhere((method) => method['id'] == methodId);
    if (index != -1) {
      paymentMethods[index]['isAvailable'] = true;
    }
  }
}
