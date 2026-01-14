import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/payment_failed_logic.dart';
import 'package:p2/security/validation_exception.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PaymentFailedLogic Constructor Validation', () {
    test('Should create instance with valid returnTo', () {
      expect(
        () => PaymentFailedLogic(returnTo: 'wallet'),
        returnsNormally,
      );
    });

    test('Should throw exception for invalid returnTo', () {
      expect(
        () => PaymentFailedLogic(returnTo: 'invalid_value'),
        throwsA(isA<PaymentValidationException>()),
      );
    });
  });

  group('Page Title Logic', () {
    test('Wallet title', () {
      final logic = PaymentFailedLogic(returnTo: 'wallet');
      expect(logic.getPageTitle(), 'Wallet Recharge Failed');
    });

    test('Checkout title', () {
      final logic = PaymentFailedLogic(returnTo: 'checkout');
      expect(logic.getPageTitle(), 'Checkout Failed');
    });

    test('Subscription title', () {
      final logic = PaymentFailedLogic(returnTo: 'subscription');
      expect(logic.getPageTitle(), 'Subscription Failed');
    });

    test('Default title', () {
      final logic = PaymentFailedLogic();
      expect(logic.getPageTitle(), 'Payment Failed');
    });
  });

  group('Error Message Logic', () {
    test('Wallet error message', () {
      final logic = PaymentFailedLogic(returnTo: 'wallet');
      expect(
        logic.getErrorMessage(),
        'We couldn\'t recharge your wallet',
      );
    });

    test('Checkout error message', () {
      final logic = PaymentFailedLogic(returnTo: 'checkout');
      expect(
        logic.getErrorMessage(),
        'Checkout process failed',
      );
    });

    test('Default error message', () {
      final logic = PaymentFailedLogic();
      expect(
        logic.getErrorMessage(),
        'We couldn\'t process your payment',
      );
    });
  });

  group('Validate Payment Data', () {
    test('Valid payment data should return true', () {
      final result = PaymentFailedLogic.validatePaymentData(
        referenceNumber: 'REF12345678',
        clientSecret:
            'A' * 64, 
        amount: 100.0,
      );

      expect(result, true);
    });

    test('Invalid reference number', () {
      final result = PaymentFailedLogic.validatePaymentData(
        referenceNumber: '###',
        clientSecret: 'A' * 64,
        amount: 50,
      );

      expect(result, false);
    });

    test('Invalid client secret length', () {
      final result = PaymentFailedLogic.validatePaymentData(
        referenceNumber: 'REF12345678',
        clientSecret: 'ABC',
        amount: 50,
      );

      expect(result, false);
    });

    test('Invalid amount (negative)', () {
      final result = PaymentFailedLogic.validatePaymentData(
        referenceNumber: 'REF12345678',
        clientSecret: 'A' * 64,
        amount: -10,
      );

      expect(result, false);
    });

    test('Invalid amount (too large)', () {
      final result = PaymentFailedLogic.validatePaymentData(
        referenceNumber: 'REF12345678',
        clientSecret: 'A' * 64,
        amount: 200000,
      );

      expect(result, false);
    });
  });

  group('Sanitize Support Info', () {
    test('Should remove script tags and JS keywords', () {
      final sanitized = PaymentFailedLogic.sanitizeSupportInfo(
        '<script>alert("hack")</script>javascript',
      );

      expect(sanitized.contains('script'), false);
      expect(sanitized.contains('javascript'), false);
    });

    test('Should return clean text', () {
      final sanitized =
          PaymentFailedLogic.sanitizeSupportInfo('support@rently.com');

      expect(sanitized, 'support@rently.com');
    });
  });

  group('UI Mode Methods', () {
    test('setImmersiveMode should not throw', () {
      final logic = PaymentFailedLogic();
      expect(() => logic.setImmersiveMode(), returnsNormally);
    });

    test('enableFullSystemUI should not throw', () {
      final logic = PaymentFailedLogic();
      expect(() => logic.enableFullSystemUI(), returnsNormally);
    });
  });
}
