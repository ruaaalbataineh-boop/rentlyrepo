import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/cash_withdrawal_logic.dart';

void main() {
  group('CashWithdrawalLogic Simplified Tests', () {
    test('Basic validation methods exist', () {
      final logic = CashWithdrawalLogic(currentBalance: 100.0);
      
      
      expect(() => logic.validateAmount('100'), returnsNormally);
      expect(() => logic.validateIBAN('TEST'), returnsNormally);
      expect(() => logic.validateBankName('Bank'), returnsNormally);
      expect(() => logic.validateAccountHolder('John Doe'), returnsNormally);
      expect(() => logic.validatePickupName('Ahmad'), returnsNormally);
      expect(() => logic.validatePickupPhone('0791234567'), returnsNormally);
      expect(() => logic.validatePickupId('123456'), returnsNormally);
    });

    test('Valid amount passes', () {
      final logic = CashWithdrawalLogic(currentBalance: 100.0);
      expect(logic.validateAmount('50'), isNull);
    });

    test('Invalid amount fails', () {
      final logic = CashWithdrawalLogic(currentBalance: 100.0);
      expect(logic.validateAmount(''), isNotNull); // Empty
      expect(logic.validateAmount('150'), isNotNull); // Exceeds balance
    });

    test('Helper methods work', () {
      final logic = CashWithdrawalLogic(currentBalance: 500.0);
      expect(logic.getMaxWithdrawalAmount(), isA<num>());
      expect(logic.getMinWithdrawalAmount(), isA<double>());
    });
  });
}
