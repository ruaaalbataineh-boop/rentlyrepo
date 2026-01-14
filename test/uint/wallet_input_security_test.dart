import 'package:flutter_test/flutter_test.dart';
import 'package:p2/Security/Secure%20Wallet%20Recharge.dart';


void main() {
  group('WalletInputSecurity', () {
    test('Valid amount returns null', () {
      final result = WalletInputSecurity.validateAmount('100');
      expect(result, null);
    });

    test('Empty amount returns error', () {
      final result = WalletInputSecurity.validateAmount('');
      expect(result, 'Please enter amount');
    });

    test('Malicious input is rejected', () {
      final result = WalletInputSecurity.validateAmount('<script>alert(1)</script>');
      expect(result, 'Invalid input');
    });

    test('Invalid format is rejected', () {
      final result = WalletInputSecurity.validateAmount('12.123');
      expect(result, 'Invalid amount format');
    });

   test('Suspicious round amount is detected', () {
  final result = WalletInputSecurity.validateAmount('20000');
  expect(result, 'Amount requires verification');
});

  });
}
