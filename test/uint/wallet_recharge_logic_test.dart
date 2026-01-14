import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/wallet_recharge_logic.dart';

void main() {
  group('WalletRechargeLogic - Amount Validation', () {
    test('Empty amount returns error', () {
      expect(
        WalletRechargeLogic.validateAmount(''),
        WalletRechargeLogic.getErrorMessage('empty_amount'),
      );
    });

    test('Invalid format returns error', () {
      expect(
        WalletRechargeLogic.validateAmount('abc'),
        WalletRechargeLogic.getErrorMessage('invalid_amount'),
      );
    });

    test('Below minimum amount is rejected', () {
      expect(
        WalletRechargeLogic.validateAmount('5'),
        WalletRechargeLogic.getErrorMessage('min_amount'),
      );
    });

    test('Above maximum amount is rejected', () {
      expect(
        WalletRechargeLogic.validateAmount('10000000'),
        WalletRechargeLogic.getErrorMessage('max_amount'),
      );
    });

    test('Valid amount passes validation', () {
      expect(
        WalletRechargeLogic.validateAmount('100'),
        null,
      );
    });

    test('Suspicious amount detected', () {
      expect(
        WalletRechargeLogic.validateAmount('9999'),
        'Amount requires verification',
      );
    });
  });

  group('WalletRechargeLogic - Parsing & Formatting', () {
    test('parseAmount removes invalid characters', () {
      final result = WalletRechargeLogic.parseAmount('100abc');
      expect(result, 100);
    });

    test('formatBalance formats correctly', () {
      expect(
        WalletRechargeLogic.formatBalance(123.456),
        '123.46',
      );
    });
  });

  group('WalletRechargeLogic - Payment Method Validation', () {
    test('Empty payment method is rejected', () {
      expect(
        WalletRechargeLogic.validatePaymentMethod(null),
        WalletRechargeLogic.getErrorMessage('empty_method'),
      );
    });

    test('Invalid payment method is rejected', () {
      expect(
        WalletRechargeLogic.validatePaymentMethod('paypal'),
        WalletRechargeLogic.getErrorMessage('invalid_method'),
      );
    });

    test('Valid payment method passes', () {
      expect(
        WalletRechargeLogic.validatePaymentMethod('credit_card'),
        null,
      );
    });
  });

  group('WalletRechargeLogic - Proceed Logic', () {
    test('Cannot proceed without amount', () {
      expect(
        WalletRechargeLogic.canProceedToPayment('', 'credit_card'),
        false,
      );
    });

    test('Cannot proceed without payment method', () {
      expect(
        WalletRechargeLogic.canProceedToPayment('100', null),
        false,
      );
    });

    test('Can proceed with valid data', () {
      expect(
        WalletRechargeLogic.canProceedToPayment('100', 'credit_card'),
        true,
      );
    });
  });

  group('WalletRechargeLogic - Security', () {
    test('Suspicious large round amount is detected', () {
      expect(
        WalletRechargeLogic.isAmountSecure(20000),
        false,
      );
    });

    test('Normal amount is secure', () {
      expect(
        WalletRechargeLogic.isAmountSecure(200),
        true,
      );
    });
  });
}
