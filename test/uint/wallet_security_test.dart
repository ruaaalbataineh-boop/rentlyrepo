import 'package:flutter_test/flutter_test.dart';
import 'package:p2/security/wallet_security.dart';

void main() {
  group('WalletSecurity - Amount Validation', () {

    test('Valid amount with 2 decimals passes', () {
      expect(WalletSecurity.isValidAmount(123.45), true);
    });

    test('Amount with more than 2 decimals fails', () {
      expect(WalletSecurity.isValidAmount(123.456), false);
    });

    test('Negative amount fails', () {
      expect(WalletSecurity.isValidAmount(-10), false);
    });

    test('Zero amount fails', () {
      expect(WalletSecurity.isValidAmount(0), false);
    });

    test('NaN amount fails', () {
      expect(WalletSecurity.isValidAmount(double.nan), false);
    });

    test('Infinite amount fails', () {
      expect(WalletSecurity.isValidAmount(double.infinity), false);
    });
  });

  group('WalletSecurity - Deposit Validation', () {

    test('Valid deposit passes', () {
      final result = WalletSecurity.validateDeposit(
        100.00,
        'Credit Card',
      );

      expect(result['isValid'], true);
      expect(result['errors'], isEmpty);
    });

    test('Deposit exceeding max limit fails', () {
      final result = WalletSecurity.validateDeposit(
        2000000,
        'Credit Card',
      );

      expect(result['isValid'], false);
      expect(result['errors'], isNotEmpty);
    });

    test('Unsupported payment method gives warning', () {
      final result = WalletSecurity.validateDeposit(
        100,
        'Bitcoin',
      );

      expect(result['isValid'], true);
      expect(result['warnings'], isNotEmpty);
    });
  });

  group('WalletSecurity - Transaction Validation', () {

    test('Valid deposit transaction passes', () {
      final tx = {
        'id': 'tx1',
        'type': 'deposit',
        'amount': 100.0,
        'date': '2026-01-01',
        'time': '12:00:00',
        'method': 'Credit Card',
        'status': 'completed',
      };

      expect(WalletSecurity.isValidTransaction(tx), true);
    });

    test('Transaction missing required field fails', () {
      final tx = {
        'id': 'tx1',
        'type': 'deposit',
        'amount': 100.0,
      };

      expect(WalletSecurity.isValidTransaction(tx), false);
    });

    test('Invalid transaction amount fails', () {
      final tx = {
        'id': 'tx1',
        'type': 'deposit',
        'amount': -50,
        'date': '2026-01-01',
        'time': '12:00:00',
        'method': 'Credit Card',
        'status': 'completed',
      };

      expect(WalletSecurity.isValidTransaction(tx), false);
    });
  });

  group('WalletSecurity - Sanitize Transaction', () {

    test('Sanitize removes invalid amount', () {
      final tx = {
        'id': 'tx1',
        'type': 'deposit',
        'amount': -500,
        'date': '2026-01-01',
        'time': '12:00:00',
        'method': '<script>',
        'status': 'completed',
      };

      final sanitized = WalletSecurity.sanitizeTransaction(tx);

      expect(sanitized['amount'], 0.0);
      expect(sanitized['is_valid'], false);
    });

    test('Sanitized transaction always has id', () {
      final sanitized = WalletSecurity.sanitizeTransaction({});

      expect(sanitized.containsKey('id'), true);
    });
  });
}
