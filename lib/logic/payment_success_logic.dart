import 'dart:math';
import 'package:flutter/services.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/input_validator.dart';
import 'package:p2/security/validation_exception.dart'; 

class PaymentSuccessLogic {
  final double amount;
  final String? returnTo;
  final String transactionId;
  final String referenceNumber;
  late final DateTime paymentTime;

  PaymentSuccessLogic({
    required this.amount,
    required this.transactionId,
    required this.referenceNumber,
    this.returnTo = 'wallet',
  }) {
    
    _validateConstructorInputs();
    
    paymentTime = DateTime.now();
    
 
    _validateTransactionId();
  }

  void _validateConstructorInputs() {
    try {
      // التحقق من صيغة transactionId
      final txRegex = RegExp(r'^TXN\d{10,20}$');
      if (!txRegex.hasMatch(transactionId)) {
        throw PaymentValidationException(
          'Invalid transactionId format: $transactionId',
          code: 'INVALID_TRANSACTION_ID'
        );
      }

      // التحقق من صيغة referenceNumber
      final refRegex = RegExp(r'^[A-Za-z0-9\-_]{8,50}$');
      if (!refRegex.hasMatch(referenceNumber)) {
        throw PaymentValidationException(
          'Invalid referenceNumber format: $referenceNumber',
          code: 'INVALID_REFERENCE_NUMBER'
        );
      }

      // التحقق من قيمة المبلغ
      if (amount <= 0 || amount > 100000) {
        throw PaymentValidationException(
          'Invalid amount value: $amount',
          code: 'INVALID_AMOUNT'
        );
      }

      // التحقق من قيمة returnTo
      final validReturnTo = ['wallet', 'checkout', 'subscription', 'payment'];
      if (returnTo != null && !validReturnTo.contains(returnTo)) {
        throw PaymentValidationException(
          'Invalid returnTo value: $returnTo',
          code: 'INVALID_RETURN_TO'
        );
      }

      // التحقق من عدم وجود أحرف خطيرة
      if (!InputValidator.hasNoMaliciousCode(transactionId) ||
          !InputValidator.hasNoMaliciousCode(referenceNumber)) {
        throw PaymentValidationException(
          'Malicious code detected in input data',
          code: 'MALICIOUS_CODE'
        );
      }

    } catch (e) {
      ErrorHandler.logError('PaymentSuccessLogic Constructor Validation', e);
      throw e;
    }
  }

  void _validateTransactionId() {
    try {
      // التحقق من أن transactionId فريد
      if (transactionId.length < 10 || transactionId.length > 30) {
        throw PaymentValidationException(
          'Invalid transaction ID length',
          code: 'INVALID_TXN_LENGTH'
        );
      }
      
      // التحقق من أن transactionId يبدأ بـ TXN
      if (!transactionId.startsWith('TXN')) {
        throw PaymentValidationException(
          'Invalid transaction ID prefix',
          code: 'INVALID_TXN_PREFIX'
        );
      }
      
    } catch (e) {
      ErrorHandler.logError('Validate Transaction ID', e);
      throw e;
    }
  }

  String getFormattedDate() {
    try {
      final day = paymentTime.day.toString().padLeft(2, '0');
      final month = paymentTime.month.toString().padLeft(2, '0');
      final year = paymentTime.year.toString();
      
      return '$day/$month/$year';
    } catch (e) {
      ErrorHandler.logError('Get Formatted Date', e);
      return 'DD/MM/YYYY';
    }
  }

  String getFormattedTime() {
    try {
      final hour = paymentTime.hour.toString().padLeft(2, '0');
      final minute = paymentTime.minute.toString().padLeft(2, '0');
      final second = paymentTime.second.toString().padLeft(2, '0');
      
      return '$hour:$minute:$second';
    } catch (e) {
      ErrorHandler.logError('Get Formatted Time', e);
      return 'HH:MM:SS';
    }
  }

  Map<String, dynamic> getReceiptData() {
    try {
      
      final safeTransactionId = InputValidator.sanitizeInput(transactionId);
      final safeReferenceNumber = InputValidator.sanitizeInput(referenceNumber);
      
      return {
        'transactionId': safeTransactionId,
        'referenceNumber': safeReferenceNumber,
        'amount': amount,
        'currency': 'JOD',
        'date': getFormattedDate(),
        'time': getFormattedTime(),
        'status': 'Completed',
        'paymentMethod': 'Credit Card',
        'merchant': 'Rently',
      };
    } catch (e) {
      ErrorHandler.logError('Get Receipt Data', e);
      return {
        'transactionId': 'ERROR',
        'amount': amount,
        'status': 'Error',
        'error': ErrorHandler.getSafeError(e),
      };
    }
  }

  String getReceiptAsText() {
    try {
      final receipt = getReceiptData();
      final buffer = StringBuffer();
      
      buffer.writeln('========== PAYMENT RECEIPT ==========');
      buffer.writeln('Transaction ID: ${receipt['transactionId']}');
      buffer.writeln('Reference: ${receipt['referenceNumber']}');
      buffer.writeln('Amount: JD ${receipt['amount'].toStringAsFixed(2)}');
      buffer.writeln('Date: ${receipt['date']}');
      buffer.writeln('Time: ${receipt['time']}');
      buffer.writeln('Status: ${receipt['status']}');
      buffer.writeln('Payment Method: ${receipt['paymentMethod']}');
      buffer.writeln('Merchant: ${receipt['merchant']}');
      buffer.writeln('=====================================');
      
      return buffer.toString();
    } catch (e) {
      ErrorHandler.logError('Get Receipt As Text', e);
      return 'Receipt generation failed.';
    }
  }

  void enableFullSystemUI() {
    try {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    } catch (e) {
      ErrorHandler.logError('Enable Full System UI', e);
    }
  }

  void setImmersiveMode() {
    try {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } catch (e) {
      ErrorHandler.logError('Set Immersive Mode', e);
    }
  }

  
  static bool validatePaymentData({
    required String transactionId,
    required String referenceNumber,
    required double amount,
  }) {
    try {
    
      final txRegex = RegExp(r'^TXN\d{10,20}$');
      if (!txRegex.hasMatch(transactionId)) {
        return false;
      }

      
      final refRegex = RegExp(r'^[A-Za-z0-9\-_]{8,50}$');
      if (!refRegex.hasMatch(referenceNumber)) {
        return false;
      }

      
      if (amount <= 0 || amount > 100000) {
        return false;
      }

      // التحقق من عدم وجود أحرف خطيرة
      if (!InputValidator.hasNoMaliciousCode(transactionId) ||
          !InputValidator.hasNoMaliciousCode(referenceNumber)) {
        return false;
      }

      return true;
    } catch (e) {
      ErrorHandler.logError('Validate Payment Data', e);
      return false;
    }
  }

 
  static String generateSecureTransactionId() {
    try {
      final random = Random.secure();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final randomPart = random.nextInt(9999).toString().padLeft(4, '0');
      final secureRandom = random.nextInt(999999).toString().padLeft(6, '0');
      
      return 'TXN${timestamp.substring(timestamp.length - 8)}$secureRandom$randomPart';
    } catch (e) {
      ErrorHandler.logError('Generate Secure Transaction ID', e);
      return 'TXN${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(9999)}';
    }
  }

  // دالة لتنظيف وإخفاء معلومات حساسة
  static String maskTransactionInfo(String info) {
    try {
      if (info.length <= 8) return info;
      
      final firstPart = info.substring(0, 4);
      final lastPart = info.substring(info.length - 4);
      
      return '$firstPart***$lastPart';
    } catch (e) {
      ErrorHandler.logError('Mask Transaction Info', e);
      return '***';
    }
  }
}
