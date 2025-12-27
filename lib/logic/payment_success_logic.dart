
import 'dart:math';
import 'package:flutter/services.dart';

class PaymentSuccessLogic {
  final double amount;
  final String? returnTo;
  late final String transactionId;
  late final DateTime paymentTime;
  static int _counter = 0; 

  PaymentSuccessLogic({
    required this.amount,
    this.returnTo = 'wallet',
  }) {
    paymentTime = DateTime.now();
    transactionId = _generateTransactionId();
  }

  String _generateTransactionId() {
    final timestamp = paymentTime.millisecondsSinceEpoch.toString();
    final randomPart = Random().nextInt(9999).toString().padLeft(4, '0');
    _counter = (_counter + 1) % 10000;
    
    return 'TXN${timestamp.substring(timestamp.length - 6)}$randomPart${_counter.toString().padLeft(4, '0')}';
  }

  String getFormattedDate() {
    return '${paymentTime.day}/${paymentTime.month}/${paymentTime.year}';
  }

  String getFormattedTime() {
    final hour = paymentTime.hour.toString().padLeft(2, '0');
    final minute = paymentTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Map<String, dynamic> getReceiptData() {
    return {
      'transactionId': transactionId,
      'amount': amount,
      'date': getFormattedDate(),
      'time': getFormattedTime(),
      'status': 'Completed',
    };
  }

  void enableFullSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  void setImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
}
