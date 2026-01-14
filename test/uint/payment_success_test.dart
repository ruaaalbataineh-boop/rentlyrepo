import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/payment_success_logic.dart';
import 'package:p2/security/input_validator.dart';
import 'package:p2/security/validation_exception.dart';

void main() {
  group('PaymentSuccessLogic Unit Tests', () {
    late PaymentSuccessLogic logic;
    final validTransactionId = 'TXN1234567890';
    final validReference = 'REF12345678';
    final validAmount = 150.50;

    setUp(() {
      logic = PaymentSuccessLogic(
        transactionId: validTransactionId,
        referenceNumber: validReference,
        amount: validAmount,
      );
    });

    test('Constructor should set paymentTime', () {
      expect(logic.paymentTime, isNotNull);
    });

    test('getFormattedDate returns correct format', () {
      final date = logic.getFormattedDate();
      final regex = RegExp(r'\d{2}/\d{2}/\d{4}');
      expect(regex.hasMatch(date), true);
    });

    test('getFormattedTime returns correct format', () {
      final time = logic.getFormattedTime();
      final regex = RegExp(r'\d{2}:\d{2}:\d{2}');
      expect(regex.hasMatch(time), true);
    });

    test('getReceiptData returns map with correct keys', () {
      final receipt = logic.getReceiptData();
      expect(receipt.keys, containsAll([
        'transactionId',
        'referenceNumber',
        'amount',
        'currency',
        'date',
        'time',
        'status',
        'paymentMethod',
        'merchant',
      ]));
    });

    test('getReceiptAsText contains transactionId', () {
      final text = logic.getReceiptAsText();
      expect(text, contains(validTransactionId));
    });

    test('maskTransactionInfo masks correctly', () {
      final masked = PaymentSuccessLogic.maskTransactionInfo('TXN1234567890');
      expect(masked, 'TXN1***7890');
    });

    test('validatePaymentData returns true for valid inputs', () {
      final isValid = PaymentSuccessLogic.validatePaymentData(
        transactionId: validTransactionId,
        referenceNumber: validReference,
        amount: validAmount,
      );
      expect(isValid, true);
    });

    test('validatePaymentData returns false for invalid transactionId', () {
      final isValid = PaymentSuccessLogic.validatePaymentData(
        transactionId: 'INVALID',
        referenceNumber: validReference,
        amount: validAmount,
      );
      expect(isValid, false);
    });

    test('generateSecureTransactionId returns string starting with TXN', () {
      final id = PaymentSuccessLogic.generateSecureTransactionId();
      expect(id.startsWith('TXN'), true);
      expect(id.length, greaterThan(10));
    });

    test('Constructor throws exception for invalid transactionId', () {
      expect(
        () => PaymentSuccessLogic(
          transactionId: 'BADID',
          referenceNumber: validReference,
          amount: validAmount,
        ),
        throwsA(isA<PaymentValidationException>()),
      );
    });

    test('Constructor throws exception for invalid referenceNumber', () {
      expect(
        () => PaymentSuccessLogic(
          transactionId: validTransactionId,
          referenceNumber: 'BAD@REF',
          amount: validAmount,
        ),
        throwsA(isA<PaymentValidationException>()),
      );
    });

    test('Constructor throws exception for invalid amount', () {
      expect(
        () => PaymentSuccessLogic(
          transactionId: validTransactionId,
          referenceNumber: validReference,
          amount: -50,
        ),
        throwsA(isA<PaymentValidationException>()),
      );
    });
  });
}
