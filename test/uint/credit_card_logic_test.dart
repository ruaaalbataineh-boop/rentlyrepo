import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/credit_card_logic.dart';

void main() {
  group('CreditCardLogic Tests', () {
    late CreditCardLogic logic;

    setUp(() {
      logic = CreditCardLogic(amount: 100.0);
    });

    test('Constructor sets amount', () {
      expect(logic.amount, 100.0);
    });

    test('Initial state', () {
      expect(logic.cardNumber, '');
      expect(logic.cardHolder, '');
      expect(logic.expiryDate, '');
      expect(logic.cvv, '');
      expect(logic.isProcessing, false);
      expect(logic.cardType, null);
    });

    group('Card Number Validation', () {
      test('Valid card number format', () {
        logic.updateCardNumber('4111111111111111');
        expect(logic.cardNumber, '4111 1111 1111 1111');
      });

      test('Empty card number error', () {
        logic.updateCardNumber('');
        expect(logic.cardNumberError, isNotNull);
      });

      test('Short card number error', () {
        logic.updateCardNumber('411111111111111');
        expect(logic.cardNumberError, isNotNull);
      });

      test('Card type detection - Visa', () {
        logic.updateCardNumber('4111111111111111');
        expect(logic.cardType, isNotNull);
      });
    });

    group('Card Holder Validation', () {
      test('Valid name', () {
        logic.updateCardHolder('John Doe');
        expect(logic.cardHolderError, isNull);
      });

      test('Empty name error', () {
        logic.updateCardHolder('');
        expect(logic.cardHolderError, isNotNull);
      });

      test('Single name error', () {
        logic.updateCardHolder('John');
        expect(logic.cardHolderError, isNotNull);
      });
    });

    group('Expiry Date Validation', () {
      test('Empty expiry date error', () {
        logic.updateExpiryDate('');
        expect(logic.expiryDateError, isNotNull);
      });

      test('Invalid format error', () {
        logic.updateExpiryDate('123');
        expect(logic.expiryDateError, isNotNull);
      });

      test('Auto formatting with slash', () {
        logic.updateExpiryDate('12');
        expect(logic.expiryDate.contains('/'), true);
      });
    });

    group('CVV Validation', () {
      test('Valid CVV', () {
        logic.updateCVV('123');
        expect(logic.cvvError, isNull);
      });

      test('Empty CVV error', () {
        logic.updateCVV('');
        expect(logic.cvvError, isNotNull);
      });

      test('Invalid CVV length error', () {
        logic.updateCVV('12');
        expect(logic.cvvError, isNotNull);
      });
    });

    group('Form Validation', () {
      test('Valid form returns true', () {
        logic.updateCardNumber('4111111111111111');
        logic.updateCardHolder('John Doe');
        logic.updateExpiryDate('12/30');
        logic.updateCVV('123');
        
        expect(logic.validateAll(), true);
      });

      test('Invalid form returns false', () {
        expect(logic.validateAll(), false);
      });

      test('Has errors detection', () {
        logic.updateCardNumber('');
        logic.validateAll();
        expect(logic.hasErrors(), true);
      });
    });

    group('Helper Methods', () {
      test('getErrorMessage returns string', () {
        expect(logic.getErrorMessage(), isA<String>());
      });

      test('processPayment returns true', () async {
        final result = await logic.processPayment();
        expect(result, true);
      });

      test('reset clears fields', () {
        logic.updateCardNumber('4111111111111111');
        logic.reset();
        expect(logic.cardNumber, '');
      });

      test('Clear errors works', () {
        logic.updateCardNumber('');
        logic.validateAll();
        logic.clearErrors();
        expect(logic.cardNumberError, isNull);
      });
    });

    group('Property Getters', () {
      test('isFormValid works', () {
        expect(logic.isFormValid, false);
        
        logic.updateCardNumber('4111111111111111');
        logic.updateCardHolder('John Doe');
        logic.updateExpiryDate('12/30');
        logic.updateCVV('123');
        
        expect(logic.isFormValid, true);
      });
    });

    print('✅ CreditCardLogic tests completed!');
  });
}
