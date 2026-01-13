import 'package:flutter/services.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/validation_exception.dart'; 

class PaymentFailedLogic {
  final String returnTo;

  PaymentFailedLogic({this.returnTo = 'payment'}) {
  
    _validateConstructorInputs();
  }

  void _validateConstructorInputs() {
    try {
      final validReturnTo = ['payment', 'wallet', 'checkout', 'subscription'];
      if (!validReturnTo.contains(returnTo)) {
        throw PaymentValidationException(
          'Invalid returnTo value: $returnTo',
          code: 'INVALID_RETURN_TO'
        );
      }
    } catch (e) {
      ErrorHandler.logError('PaymentFailedLogic Constructor Validation', e);
      throw e;
    }
  }

  void enableFullSystemUI() {
    try {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    } catch (e) {
      ErrorHandler.logError('Enable Full System UI', e);
    }
  }

  void setImmersiveMode() {
    try {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } catch (e) {
      ErrorHandler.logError('Set Immersive Mode', e);
    }
  }

  List<String> getPossibleReasons() {
    try {
      return [
        'Insufficient funds in your account',
        'Incorrect card details',
        'Network connection issues',
        'Card expired or blocked',
        'Daily transaction limit exceeded',
        'Temporary bank server issue',
        'Security verification failed',
        'Currency conversion error',
      ];
    } catch (e) {
      ErrorHandler.logError('Get Possible Reasons', e);
      return [
        'Technical issue occurred',
        'Please try again or contact support',
      ];
    }
  }

  List<String> getHelpfulTips() {
    try {
      return [
        'Check your card balance',
        'Verify card details are correct',
        'Try a different payment method',
        'Contact your bank if issues persist',
        'Ensure stable internet connection',
        'Check card expiration date',
        'Verify billing address matches',
        'Wait a few minutes and try again',
      ];
    } catch (e) {
      ErrorHandler.logError('Get Helpful Tips', e);
      return [
        'Please try again',
        'Contact support for assistance',
      ];
    }
  }

  Map<String, String> getContactSupportInfo() {
    try {
      // في تطبيق حقيقي، يجب جلب هذه البيانات من API أو config آمن
      return {
        'phone': '1-800-123-4567',
        'email': 'support@rently.com',
        'liveChat': 'Available in app',
        'hours': '24/7',
        'website': 'help.rently.com',
      };
    } catch (e) {
      ErrorHandler.logError('Get Contact Support Info', e);
      return {
        'support': 'Contact via app settings',
        'hours': 'Business hours',
      };
    }
  }

  String getPageTitle() {
    try {
      switch (returnTo) {
        case 'wallet':
          return 'Wallet Recharge Failed';
        case 'checkout':
          return 'Checkout Failed';
        case 'subscription':
          return 'Subscription Failed';
        default:
          return 'Payment Failed';
      }
    } catch (e) {
      ErrorHandler.logError('Get Page Title', e);
      return 'Transaction Failed';
    }
  }
  
  String getErrorMessage() {
    try {
      switch (returnTo) {
        case 'wallet':
          return 'We couldn\'t recharge your wallet';
        case 'checkout':
          return 'Checkout process failed';
        case 'subscription':
          return 'Subscription payment failed';
        default:
          return 'We couldn\'t process your payment';
      }
    } catch (e) {
      ErrorHandler.logError('Get Error Message', e);
      return 'An error occurred with your transaction';
    }
  }

  
  static bool validatePaymentData({
    required String referenceNumber,
    required String clientSecret,
    required double amount,
  }) {
    try {
     
      final refRegex = RegExp(r'^[A-Za-z0-9\-_]{8,50}$');
      if (!refRegex.hasMatch(referenceNumber)) {
        return false;
      }

     
      final secretRegex = RegExp(r'^[A-Za-z0-9]{64}$');
      if (!secretRegex.hasMatch(clientSecret)) {
        return false;
      }
 
      if (amount <= 0 || amount > 100000) {
        return false;
      }

      return true;
    } catch (e) {
      ErrorHandler.logError('Validate Payment Data', e);
      return false;
    }
  }

  // دالة لتنظيف ومعالجة معلومات الاتصال
  static String sanitizeSupportInfo(String info) {
    try {
      return info
          .replaceAll('<', '')
          .replaceAll('>', '')
          .replaceAll('script', '')
          .replaceAll('javascript', '')
          .trim();
    } catch (e) {
      ErrorHandler.logError('Sanitize Support Info', e);
      return 'Contact support';
    }
  }
}
