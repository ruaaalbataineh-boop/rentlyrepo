
import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/payment_failed_logic.dart';


void main() {
  group('PaymentFailedLogic Tests', () {
    test('Constructor with default value', () {
      final logic = PaymentFailedLogic();
      expect(logic.returnTo, 'payment');
    });

    test('Constructor with custom value', () {
      final logic = PaymentFailedLogic(returnTo: 'checkout');
      expect(logic.returnTo, 'checkout');
    });

    test('getPossibleReasons returns list of reasons', () {
      final logic = PaymentFailedLogic();
      final reasons = logic.getPossibleReasons();
      
      expect(reasons, isA<List<String>>());
      expect(reasons.length, 5);
      expect(reasons, contains('Insufficient funds in your account'));
      expect(reasons, contains('Network connection issues'));
    });

    test('getHelpfulTips returns list of tips', () {
      final logic = PaymentFailedLogic();
      final tips = logic.getHelpfulTips();
      
      expect(tips, isA<List<String>>());
      expect(tips.length, 4);
      expect(tips, contains('Check your card balance'));
      expect(tips, contains('Try a different payment method'));
    });

    test('getContactSupportInfo returns complete contact info', () {
      final logic = PaymentFailedLogic();
      final contactInfo = logic.getContactSupportInfo();
      
      expect(contactInfo['phone'], '1-800-123-4567');
      expect(contactInfo['email'], 'support@rently.com');
      expect(contactInfo['liveChat'], 'Available in app');
      expect(contactInfo['hours'], '24/7');
    });

    test('getPageTitle returns correct title', () {
      final logic = PaymentFailedLogic();
      expect(logic.getPageTitle(), 'Payment Failed');
    });

    test('getErrorMessage returns correct message', () {
      final logic = PaymentFailedLogic();
      expect(logic.getErrorMessage(), 'We couldn\'t process your payment');
    });

    test('Multiple instances work independently', () {
      final logic1 = PaymentFailedLogic(returnTo: 'payment');
      final logic2 = PaymentFailedLogic(returnTo: 'checkout');
      
      expect(logic1.returnTo, 'payment');
      expect(logic2.returnTo, 'checkout');
    });
  });
}
