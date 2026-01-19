import 'dart:io';
import 'package:p2/security/input_validator.dart';

class ContinueCreateAccountLogic {
  
  static String? validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter your first name";
    }
    final trimmedValue = InputValidator.sanitizeInput(value.trim());
    if (trimmedValue.length < 2) {
      return "First name must be at least 2 characters";
    }
    if (!RegExp(r'^[a-zA-Z\u0600-\u06FF\s\-]+$').hasMatch(trimmedValue)) {
      return "First name can only contain letters, spaces, and hyphens";
    }
    return null;
  }

  static String? validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter your last name";
    }
    final trimmedValue = InputValidator.sanitizeInput(value.trim());
    if (trimmedValue.length < 2) {
      return "Last name must be at least 2 characters";
    }
    if (!RegExp(r'^[a-zA-Z\u0600-\u06FF\s\-]+$').hasMatch(trimmedValue)) {
      return "Last name can only contain letters, spaces, and hyphens";
    }
    return null;
  }

  static String? validateBirthDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Please select your birth date";
    }
    
    final trimmedValue = value.trim();
    
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmedValue)) {
      return "Invalid date format. Use YYYY-MM-DD";
    }
    
    try {
      final parts = trimmedValue.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      
      if (month < 1 || month > 12 || day < 1 || day > 31) {
        return "Invalid date";
      }
      
      final birthDate = DateTime(year, month, day);
      final now = DateTime.now();
      
      if (birthDate.isAfter(now)) {
        return "Birth date cannot be in the future";
      }
      
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month || 
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      
      if (age < 18) {
        return "You must be at least 18 years old";
      }
      if (age > 120) {
        return "Please enter a valid birth date";
      }
    } catch (e) {
      return "Invalid date";
    }
    
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter your phone number";
    }
    
    final cleanedPhone = value.replaceAll(RegExp(r'[^\d+]'), '');
    
    String phoneDigits;
    if (cleanedPhone.startsWith('+962')) {
      phoneDigits = cleanedPhone.substring(4); 
    } else if (cleanedPhone.startsWith('962')) {
      phoneDigits = cleanedPhone.substring(3); 
    } else if (cleanedPhone.startsWith('0')) {
      phoneDigits = cleanedPhone.substring(1); 
    } else {
      phoneDigits = cleanedPhone;
    }
    
    if (phoneDigits.length != 9) {
      return "Phone number must be 9 digits (after country code)";
    }
    
    if (phoneDigits[0] != '7') {
      return "Jordanian mobile numbers must start with 7";
    }
    
    final secondDigit = phoneDigits[1];
    if (secondDigit != '7' && secondDigit != '8' && secondDigit != '9') {
      return "Second digit must be 7, 8, or 9";
    }
    
    return null;
  }

  static String? validateIdImage(File? image) {
    if (image == null) {
      return "Please upload your ID photo";
    }
    if (!image.existsSync()) {
      return "ID photo file not found";
    }
    return null;
  }

  static String? validateFaceImage(File? image, bool faceDetected) {
    if (image == null) {
      return "Please upload your face photo";
    }
    if (!image.existsSync()) {
      return "Face photo file not found";
    }
    if (!faceDetected) {
      return "Face not detected in the image";
    }
    return null;
  }

  static List<String> validateAllFields({
    required String firstName,
    required String lastName,
    required String birthDate,
    required String phone,
    required File? idImage,
    required File? faceImage,
    required bool faceDetected,
  }) {
    final errors = <String>[];
    
    final firstNameError = validateFirstName(firstName);
    final lastNameError = validateLastName(lastName);
    final birthDateError = validateBirthDate(birthDate);
    final phoneError = validatePhoneNumber(phone);
    final idImageError = validateIdImage(idImage);
    final faceImageError = validateFaceImage(faceImage, faceDetected);
    
    if (firstNameError != null) errors.add(firstNameError);
    if (lastNameError != null) errors.add(lastNameError);
    if (birthDateError != null) errors.add(birthDateError);
    if (phoneError != null) errors.add(phoneError);
    if (idImageError != null) errors.add(idImageError);
    if (faceImageError != null) errors.add(faceImageError);
    
    return errors;
  }

  static String formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
