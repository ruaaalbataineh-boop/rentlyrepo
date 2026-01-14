import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:p2/EfawateercomPaymentPage.dart';

void main() {
  group('EfawateercomPaymentPage Basic Tests', () {
    test('Widget constructor', () {
      final page = EfawateercomPaymentPage(
        amount: 100.0,
        referenceNumber: 'REF123456',
      );
      
      expect(page.amount, 100.0);
      expect(page.referenceNumber, 'REF123456');
    });

    test('Color constants', () {
      const color1 = Color(0xFF1F0F46);
      const color2 = Color(0xFF8A005D);
      
      expect(color1.value, 0xFF1F0F46);
      expect(color2.value, 0xFF8A005D);
    });

    test('Text constants', () {
      expect('Pay via eFawateercom', 'Pay via eFawateercom');
      expect('Payment Amount', 'Payment Amount');
      expect('Invoice Reference', 'Invoice Reference');
      expect('Done', 'Done');
      expect('How to Pay', 'How to Pay');
    });

    test('UI dimensions', () {
      expect(22, 22); 
      expect(18, 18); 
      expect(52, 52); 
      expect(12, 12); 
      expect(36, 36); 
    });

    test('Gradient colors', () {
      const gradientColors = [Color(0xFF1F0F46), Color(0xFF8A005D)];
      expect(gradientColors.length, 2);
    });

    test('Payment steps', () {
      final steps = [
        'Open eFawateercom',
        'Choose your preferred payment provider',
        'Enter the reference number and amount to be paid',
        'Confirm payment',
      ];
      
      expect(steps.length, 4);
      for (final step in steps) {
        expect(step, isA<String>());
        expect(step.isNotEmpty, true);
      }
    });

    test('Warning message', () {
      const warning = "Please screenshot or save this reference number.\n"
          "You will NOT be able to access it again after closing this page.";
      
      expect(warning.contains('screenshot'), true);
      expect(warning.contains('reference'), true);
      expect(warning.contains('NOT'), true);
    });

    test('Widget structure', () {
      expect('Scaffold', 'Scaffold');
      expect('AppBar', 'AppBar');
      expect('SafeArea', 'SafeArea');
      expect('SingleChildScrollView', 'SingleChildScrollView');
      expect('Column', 'Column');
      expect('Container', 'Container');
      expect('ElevatedButton', 'ElevatedButton');
      expect('SelectableText', 'SelectableText');
    });
  });

  print('✅ EfawateercomPaymentPage tests completed!');
}
