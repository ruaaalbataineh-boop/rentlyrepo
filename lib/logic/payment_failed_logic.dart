
import 'package:flutter/services.dart';

class PaymentFailedLogic {
  final String returnTo;

  PaymentFailedLogic({this.returnTo = 'payment'});

  void enableFullSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  void setImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  List<String> getPossibleReasons() {
    return [
      'Insufficient funds in your account',
      'Incorrect card details',
      'Network connection issues',
      'Card expired or blocked',
      'Daily transaction limit exceeded',
    ];
  }

  List<String> getHelpfulTips() {
    return [
      'Check your card balance',
      'Verify card details are correct',
      'Try a different payment method',
      'Contact your bank if issues persist',
    ];
  }

  Map<String, String> getContactSupportInfo() {
    return {
      'phone': '1-800-123-4567',
      'email': 'support@rently.com',
      'liveChat': 'Available in app',
      'hours': '24/7',
    };
  }

  String getPageTitle() => 'Payment Failed';
  
  String getErrorMessage() => 'We couldn\'t process your payment';
}
