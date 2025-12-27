
import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/payment_success_logic.dart';

void main() {
  group('PaymentSuccessLogic Tests', () {
    test('Constructor sets correct values', () {
      final logic = PaymentSuccessLogic(amount: 100.0, returnTo: 'wallet');
      
      expect(logic.amount, 100.0);
      expect(logic.returnTo, 'wallet');
      expect(logic.transactionId, startsWith('TXN'));
      expect(logic.paymentTime, isA<DateTime>());
    });

    test('Default returnTo is wallet', () {
      final logic = PaymentSuccessLogic(amount: 50.0);
      expect(logic.returnTo, 'wallet');
    });

   test('generateTransactionId creates valid ID', () {
  final logic = PaymentSuccessLogic(amount: 100.0);
  
  expect(logic.transactionId, startsWith('TXN'));
  expect(logic.transactionId.length, 17);
});

    test('getFormattedDate returns string with slashes', () {
      final logic = PaymentSuccessLogic(amount: 100.0);
      final date = logic.getFormattedDate();
      
      expect(date, contains('/'));
      expect(date.split('/').length, 3);
    });

    test('getFormattedTime returns HH:MM format', () {
      final logic = PaymentSuccessLogic(amount: 100.0);
      final time = logic.getFormattedTime();
      
      expect(time, contains(':'));
      expect(time.length, 5);
      expect(time.split(':')[0].length, 2);
      expect(time.split(':')[1].length, 2);
    });

    test('getReceiptData returns complete receipt', () {
      final logic = PaymentSuccessLogic(amount: 75.50);
      final receipt = logic.getReceiptData();
      
      expect(receipt['amount'], 75.50);
      expect(receipt['transactionId'], isA<String>());
      expect(receipt['date'], isA<String>());
      expect(receipt['time'], isA<String>());
      expect(receipt['status'], 'Completed');
      expect(receipt.keys.length, 5);
    });

    test('Different instances have different transaction IDs', () {
      final logic1 = PaymentSuccessLogic(amount: 100.0);
      final logic2 = PaymentSuccessLogic(amount: 100.0);
      
      
      expect(logic1.transactionId, isNot(logic2.transactionId));
      

      expect(logic1.transactionId, matches(RegExp(r'^TXN\d{14}$')));
      expect(logic2.transactionId, matches(RegExp(r'^TXN\d{14}$')));
    });

    test('Transaction ID format is correct', () {
      final logic = PaymentSuccessLogic(amount: 100.0);
      final id = logic.transactionId;
      
     
      expect(id, matches(RegExp(r'^TXN\d{14}$')));
    });

    test('Multiple instances create unique IDs', () {
      final ids = <String>{};
      
    
      for (int i = 0; i < 10; i++) {
        final logic = PaymentSuccessLogic(amount: i * 10.0);
        ids.add(logic.transactionId);
      }
      
      expect(ids.length, 10); 
    });
  });
}
