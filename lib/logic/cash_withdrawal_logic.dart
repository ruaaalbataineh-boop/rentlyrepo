import 'package:p2/security/error_handler.dart';
import 'package:p2/security/input_validator.dart';

class CashWithdrawalLogic {
  double currentBalance;
  final int _maxDailyLimit = 1000;
  final int _minWithdrawal = 10;
  final int _maxDecimalPlaces = 2;

  CashWithdrawalLogic({required this.currentBalance});

  String? validateAmount(String? value) {
    try {
      if (value == null || value.isEmpty) {
        return 'Please enter amount';
      }

      final sanitizedValue = InputValidator.sanitizeInput(value);
      
      if (!InputValidator.hasNoMaliciousCode(sanitizedValue)) {
        return 'Invalid amount format';
      }

      final amount = double.tryParse(sanitizedValue);
      if (amount == null || amount <= 0) {
        return 'Please enter valid amount';
      }

      if (amount < _minWithdrawal) {
        return 'Minimum withdrawal is $_minWithdrawal JD';
      }

      if (amount > currentBalance) {
        return 'Amount exceeds available balance';
      }

      if (amount > _maxDailyLimit) {
        return 'Daily limit is $_maxDailyLimit JD';
      }

      final decimalPart = sanitizedValue.split('.');
      if (decimalPart.length > 1 && decimalPart[1].length > _maxDecimalPlaces) {
        return 'Maximum $_maxDecimalPlaces decimal places';
      }

      return null;
    } catch (error) {
      ErrorHandler.logError('Validate Amount', error);
      return 'Invalid amount';
    }
  }

  String? validateIBAN(String? value) {
    try {
      if (value == null || value.isEmpty) return 'Please enter IBAN';

      final sanitizedValue = InputValidator.sanitizeInput(value);
      
      if (!InputValidator.hasNoMaliciousCode(sanitizedValue)) {
        return 'Invalid IBAN format';
      }

      final cleanIBAN = sanitizedValue.replaceAll(' ', '').toUpperCase();

      if (cleanIBAN.length < 22 || cleanIBAN.length > 34) {
        return 'Invalid IBAN length';
      }

      if (!RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z0-9]{1,30}$').hasMatch(cleanIBAN)) {
        return 'Invalid IBAN format';
      }

      return null;
    } catch (error) {
      ErrorHandler.logError('Validate IBAN', error);
      return 'Invalid IBAN';
    }
  }

  String? validateBankName(String? value) {
    try {
      if (value == null || value.isEmpty) {
        return 'Please enter bank name';
      }

      final sanitizedValue = InputValidator.sanitizeInput(value);
      
      if (!InputValidator.hasNoMaliciousCode(sanitizedValue)) {
        return 'Invalid bank name';
      }

      if (sanitizedValue.length < 3) return 'Bank name too short';
      
      if (sanitizedValue.length > 100) {
        return 'Bank name too long';
      }

      return null;
    } catch (error) {
      ErrorHandler.logError('Validate Bank Name', error);
      return 'Invalid bank name';
    }
  }

  String? validateAccountHolder(String? value) {
    try {
      if (value == null || value.isEmpty) {
        return 'Please enter account holder name';
      }

      final sanitizedValue = InputValidator.sanitizeInput(value);
      
      if (!InputValidator.hasNoMaliciousCode(sanitizedValue)) {
        return 'Invalid name format';
      }

      final nameParts = sanitizedValue.trim().split(' ');
      
      if (nameParts.length < 2) {
        return 'Please enter full name (first and last)';
      }

      for (final part in nameParts) {
        if (part.length < 2) {
          return 'Each name part must be at least 2 characters';
        }
      }

      if (sanitizedValue.length > 150) {
        return 'Name too long';
      }

      return null;
    } catch (error) {
      ErrorHandler.logError('Validate Account Holder', error);
      return 'Invalid account holder name';
    }
  }

  String? validatePickupName(String? value) {
    try {
      if (value == null || value.isEmpty) {
        return 'Please enter receiver name';
      }

      final sanitizedValue = InputValidator.sanitizeInput(value);
      
      if (!InputValidator.hasNoMaliciousCode(sanitizedValue)) {
        return 'Invalid name format';
      }

      final nameParts = sanitizedValue.trim().split(' ');
      
      if (nameParts.length < 2) {
        return 'Please enter full name (first and last)';
      }

      for (final part in nameParts) {
        if (part.length < 2) {
          return 'Each name part must be at least 2 characters';
        }
        
        if (!RegExp(r'^[A-Za-z\s\-]+$').hasMatch(part)) {
          return 'Name can only contain letters, spaces, and hyphens';
        }
      }

      return null;
    } catch (error) {
      ErrorHandler.logError('Validate Pickup Name', error);
      return 'Invalid receiver name';
    }
  }

  String? validatePickupPhone(String? value) {
    try {
      if (value == null || value.isEmpty) return 'Please enter phone number';

      final sanitizedValue = InputValidator.sanitizeInput(value);
      
      if (!InputValidator.hasNoMaliciousCode(sanitizedValue)) {
        return 'Invalid phone number format';
      }

      final phone = sanitizedValue.replaceAll(RegExp(r'[^\d]'), '');

      if (!phone.startsWith('07') || phone.length != 10) {
        return 'Invalid Jordanian phone number (07XXXXXXXX)';
      }

      if (!RegExp(r'^07[0-9]{8}$').hasMatch(phone)) {
        return 'Invalid phone number format';
      }

      return null;
    } catch (error) {
      ErrorHandler.logError('Validate Pickup Phone', error);
      return 'Invalid phone number';
    }
  }

  String? validatePickupId(String? value) {
    try {
      if (value == null || value.isEmpty) {
        return 'Please enter ID number';
      }

      final sanitizedValue = InputValidator.sanitizeInput(value);
      
      if (!InputValidator.hasNoMaliciousCode(sanitizedValue)) {
        return 'Invalid ID number format';
      }

      if (sanitizedValue.length < 6) return 'Invalid ID number';
      
      if (sanitizedValue.length > 20) {
        return 'ID number too long';
      }

      if (!RegExp(r'^[0-9]+$').hasMatch(sanitizedValue)) {
        return 'ID number can only contain digits';
      }

      return null;
    } catch (error) {
      ErrorHandler.logError('Validate Pickup ID', error);
      return 'Invalid ID number';
    }
  }

  num getMaxWithdrawalAmount() {
    return currentBalance > _maxDailyLimit ? _maxDailyLimit : currentBalance;
  }

  double getMinWithdrawalAmount() {
    return _minWithdrawal.toDouble();
  }
}
