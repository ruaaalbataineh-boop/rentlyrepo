import 'package:flutter/material.dart';

class CreditCardLogic {
  String cardNumber = '';
  String cardHolder = '';
  String expiryDate = '';
  String cvv = '';
  double amount;
  
  bool isProcessing = false;
  String? cardType;
  bool showErrors = false;
  
  String? cardNumberError;
  String? cardHolderError;
  String? expiryDateError;
  String? cvvError;
  
  CreditCardLogic({required this.amount});
  
  // Card number formatting and validation
  void updateCardNumber(String value) {
    final cleanedValue = value.replaceAll(' ', '');
    var formattedValue = '';
    
    for (int i = 0; i < cleanedValue.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formattedValue += ' ';
      }
      formattedValue += cleanedValue[i];
    }
    
    cardNumber = formattedValue;
    _detectCardType();
    cardNumberError = _validateCardNumberInput(cardNumber);
  }
  
  void _detectCardType() {
    final cleanedCardNumber = cardNumber.replaceAll(' ', '');
    
    if (cleanedCardNumber.isEmpty) {
      cardType = null;
      return;
    }
    
    if (cleanedCardNumber.startsWith('4')) {
      cardType = 'Visa';
    } else {
      cardType = null;
    }
  }
  
  String? _validateCardNumberInput(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter card number';
    }
    
    final cleanedValue = value.replaceAll(' ', '');
    
    if (cleanedValue.length != 16) {
      return 'Card number must be 16 digits';
    }
    
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanedValue)) {
      return 'Card number must contain only digits';
    }
    
    if (!cleanedValue.startsWith('4')) {
      return 'Only Visa cards are accepted (must start with 4)';
    }
    
    if (!_validateCardNumber(cleanedValue)) {
      return 'Invalid Visa card number';
    }
    
    return null;
  }
  
  bool _validateCardNumber(String cardNumber) {
    final cleanedCardNumber = cardNumber.replaceAll(' ', '');
    
    if (cleanedCardNumber.length != 16) return false;
    if (!cleanedCardNumber.startsWith('4')) return false;
    
    return _luhnAlgorithm(cleanedCardNumber);
  }
  
  bool _luhnAlgorithm(String number) {
    int sum = 0;
    bool alternate = false;
    
    for (int i = number.length - 1; i >= 0; i--) {
      int digit = int.parse(number[i]);
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    return (sum % 10) == 0;
  }
  
  
  void updateCardHolder(String value) {
    cardHolder = value;
    cardHolderError = _validateCardHolder(cardHolder);
  }
  
  String? _validateCardHolder(String? name) {
    if (name == null || name.isEmpty) {
      return 'Please enter card holder name';
    }
    
    if (name.length < 3) {
      return 'Name must be at least 3 characters';
    }
    
    if (name.length > 50) {
      return 'Name is too long';
    }
    
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
      return 'Name must contain only letters and spaces';
    }
    
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length < 2) {
      return 'Please enter full name (first and last name)';
    }
    
    for (final word in words) {
      if (word.length < 2) {
        return 'Each name part must be at least 2 characters';
      }
    }
    
    return null;
  }
  
  
  void updateExpiryDate(String value) {
    final cleanedValue = value.replaceAll('/', '');
    
    
    final digitsOnly = cleanedValue.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (digitsOnly.isEmpty) {
      expiryDate = value;
    } else if (digitsOnly.length == 1) {
      expiryDate = digitsOnly;
    } else if (digitsOnly.length == 2) {
      
      if (value.contains('/') && value.length == 2) {
        expiryDate = value;
      } else {
        expiryDate = '$digitsOnly/';
      }
    } else if (digitsOnly.length >= 3) {
      final month = digitsOnly.substring(0, 2);
      final year = digitsOnly.substring(2, min(digitsOnly.length, 4));
      expiryDate = '$month/$year';
    }
    
    expiryDateError = _validateExpiryDateInput(expiryDate);
  }
  
  int min(int a, int b) => a < b ? a : b;
  
  String? _validateExpiryDateInput(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter expiry date';
    }
    
    
    final cleanedValue = value.replaceAll('/', '');
    if (cleanedValue.length < 4) {
      return 'Format: MM/YY (e.g., 12/25)';
    }
    
    if (!RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$').hasMatch(value)) {
      return 'Format: MM/YY (e.g., 12/25)';
    }
    
    if (!_validateExpiryDate(value)) {
      return 'Card has expired or invalid date';
    }
    
    return null;
  }
  
  bool _validateExpiryDate(String expiry) {
    if (!RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$').hasMatch(expiry)) {
      return false;
    }
    
    final parts = expiry.split('/');
    final month = int.parse(parts[0]);
    final year = int.parse(parts[1]);
    
    final now = DateTime.now();
    final currentYear = now.year % 100;
    final currentMonth = now.month;
    
    if (year < currentYear) return false;
    if (year == currentYear && month < currentMonth) return false;
    
    return true;
  }
  
  
  void updateCVV(String value) {
    cvv = value;
    cvvError = _validateCVV(cvv);
  }
  
  String? _validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter CVV';
    }
    
    if (!RegExp(r'^[0-9]{3}$').hasMatch(value)) {
      return 'CVV must be 3 digits';
    }
    
    return null;
  }
  
 
  bool validateAll() {
    showErrors = true;
    
    cardNumberError = _validateCardNumberInput(cardNumber);
    cardHolderError = _validateCardHolder(cardHolder);
    expiryDateError = _validateExpiryDateInput(expiryDate);
    cvvError = _validateCVV(cvv);
    
    return cardNumberError == null && 
           cardHolderError == null && 
           expiryDateError == null && 
           cvvError == null;
  }
  
  bool hasErrors() {
    return cardNumberError != null || 
           cardHolderError != null || 
           expiryDateError != null || 
           cvvError != null;
  }
  
  String getErrorMessage() {
    return 'Please fill in all required fields correctly';
  }
  
  Future<bool> processPayment() async {
    isProcessing = true;
    
    await Future.delayed(const Duration(seconds: 2));
    
    isProcessing = false;
    
    final randomFactor = DateTime.now().millisecond % 10;
    return randomFactor < 8;
  }
  
  void clearErrors() {
    showErrors = false;
    cardNumberError = null;
    cardHolderError = null;
    expiryDateError = null;
    cvvError = null;
  }
  
  void reset() {
    cardNumber = '';
    cardHolder = '';
    expiryDate = '';
    cvv = '';
    cardType = null;
    clearErrors();
  }
  
  bool get isCardNumberValid => cardNumberError == null && cardNumber.isNotEmpty;
  bool get isCardHolderValid => cardHolderError == null && cardHolder.isNotEmpty;
  bool get isExpiryDateValid => expiryDateError == null && expiryDate.isNotEmpty;
  bool get isCVVValid => cvvError == null && cvv.isNotEmpty;
  bool get isFormValid => isCardNumberValid && isCardHolderValid && isExpiryDateValid && isCVVValid;
  
  
  @visibleForTesting
  bool testLuhnAlgorithm(String cardNumber) => _luhnAlgorithm(cardNumber.replaceAll(' ', ''));
}
