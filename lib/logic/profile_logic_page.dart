import 'dart:io';
import 'package:p2/security/input_validator.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/api_security.dart';
import 'package:p2/security/secure_storage.dart';
import 'package:p2/security/route_guard.dart';

class ProfileLogic {
  File? profileImage;
  String fullName;
  String email;
  String phone;
  String location;
  String bank;

 
  DateTime? _lastUpdateAttempt;
  int _updateAttempts = 0;
  static const int _maxUpdateAttempts = 5;
  static const Duration _updateCooldown = Duration(minutes: 15);

  
  final bool testMode;

  ProfileLogic({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.location,
    required this.bank,
    this.profileImage,
    this.testMode = false,
  }) {
    if (!testMode) {
      _initializeSecurity();
    }
  }

  
  Future<void> _initializeSecurity() async {
    try {
      if (!RouteGuard.isAuthenticated()) {
        throw Exception('User not authenticated');
      }
      final token = await SecureStorage.getToken();
      if (token == null) {
        ErrorHandler.logSecurity('Profile Logic', 'No authentication token found');
      }
      await _logProfileAccess();
    } catch (error) {
      if (!testMode) ErrorHandler.logError('Initialize Profile Security', error);
    }
  }

  Future<void> _logProfileAccess() async {
    if (testMode) return;
    try {
      final token = await SecureStorage.getToken();
      await ApiSecurity.securePost(
        endpoint: 'logs/profile_access',
        data: {
          'action': 'profile_page_access',
          'timestamp': DateTime.now().toIso8601String(),
          'user_authenticated': RouteGuard.isAuthenticated(),
        },
        token: token,
        requiresAuth: true,
      );
    } catch (e) {
      if (!testMode) ErrorHandler.logInfo('Log Profile Access', 'Failed to log access');
    }
  }

  bool hasImage() => profileImage != null;

  bool _checkRateLimit() {
    if (_updateAttempts >= _maxUpdateAttempts) {
      if (_lastUpdateAttempt != null) {
        final timeSinceLastAttempt = DateTime.now().difference(_lastUpdateAttempt!);
        if (timeSinceLastAttempt < _updateCooldown) return false;
      }
      _updateAttempts = 0;
    }
    return true;
  }

  
  Future<bool> validateForm(String? name, String? email, String? phone) async {
    try {
      if (!_checkRateLimit()) return false;
      if (name?.isEmpty == true || email?.isEmpty == true || phone?.isEmpty == true) return false;

      final safeName = InputValidator.sanitizeInput(name!);
      final safeEmail = InputValidator.sanitizeInput(email!);
      final safePhone = InputValidator.sanitizeInput(phone!);

      if (safeName.isEmpty || !InputValidator.isValidEmail(safeEmail) || !InputValidator.isValidPhone(safePhone)) return false;
      if (!InputValidator.hasNoMaliciousCode(safeName) ||
          !InputValidator.hasNoMaliciousCode(safeEmail) ||
          !InputValidator.hasNoMaliciousCode(safePhone)) return false;
      if (safeName.length > 100 || safeEmail.length > 100 || safePhone.length > 20) return false;

      return true;
    } catch (error) {
      if (!testMode) ErrorHandler.logError('Validate Form', error);
      return false;
    }
  }

 
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? phone,
    File? image,
  }) async {
    try {
      if (!testMode && !RouteGuard.isAuthenticated()) throw Exception('User not authenticated for profile update');
      if (!_checkRateLimit()) return false;

      final validationResult = await validateForm(name, email, phone);
      if (!validationResult) {
        _updateAttempts++;
        _lastUpdateAttempt = DateTime.now();
        await _logUpdateAttempt(false, 'Validation failed');
        return false;
      }

      final safeName = InputValidator.sanitizeInput(name!);
      final safeEmail = InputValidator.sanitizeInput(email!);
      final safePhone = InputValidator.sanitizeInput(phone!);

      if (safeName.isNotEmpty) fullName = safeName;
      if (safeEmail.isNotEmpty) this.email = safeEmail;
      if (safePhone.isNotEmpty) this.phone = safePhone;
      if (image != null && await validateImageSafety(image)) profileImage = image;

      final updateSuccess = testMode
          ? true
          : await _updateProfileOnServer(name: safeName, email: safeEmail, phone: safePhone, image: image);

      if (updateSuccess) {
        _updateAttempts = 0;
        await _logUpdateAttempt(true, 'Profile updated successfully');
        if (!testMode) await _updateSecureStorage();
        return true;
      } else {
        _updateAttempts++;
        _lastUpdateAttempt = DateTime.now();
        return false;
      }
    } catch (error) {
      if (!testMode) ErrorHandler.logError('Update Profile', error);
      _updateAttempts++;
      _lastUpdateAttempt = DateTime.now();
      await _logUpdateAttempt(false, error.toString());
      return false;
    }
  }

  Future<bool> _updateProfileOnServer({
    required String name,
    required String email,
    required String phone,
    File? image,
  }) async {
    if (testMode) return true;
    try {
      final token = await SecureStorage.getToken();
      if (token == null) throw Exception('No authentication token available');

      final secureData = {
        'fullName': name,
        'email': email,
        'phone': phone,
        'location': location,
        'bank': bank,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final response = await ApiSecurity.securePost(
        endpoint: 'profile/update',
        data: secureData,
        token: token,
        requiresAuth: true,
      );

      if (image != null && await validateImageSafety(image)) await _uploadProfileImage(image, token);

      return response['success'] == true;
    } catch (error) {
      if (!testMode) ErrorHandler.logError('Update Profile on Server', error);
      return false;
    }
  }

  Future<void> _uploadProfileImage(File image, String token) async {
    if (testMode) return;
    try {
      ErrorHandler.logInfo('Upload Profile Image', 'Image upload would happen here securely');
    } catch (error) {
      ErrorHandler.logError('Upload Profile Image', error);
    }
  }

  Future<bool> validateImageSafety(File image) async {
    try {
      final fileSize = await image.length();
      const maxSize = 5 * 1024 * 1024;
      if (fileSize > maxSize) return false;

      final fileName = image.path.toLowerCase();
      final allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif'];
      if (!allowedExtensions.any((ext) => fileName.endsWith(ext))) return false;

      return true;
    } catch (error) {
      if (!testMode) ErrorHandler.logError('Validate Image Safety', error);
      return false;
    }
  }

  Future<void> _updateSecureStorage() async {
    if (testMode) return;
    try {
      await SecureStorage.saveData('user_fullName', fullName);
      await SecureStorage.saveData('user_email', email);
      await SecureStorage.saveData('user_phone', phone);
    } catch (error) {
      if (!testMode) ErrorHandler.logError('Update Secure Storage', error);
    }
  }

  Future<void> _logUpdateAttempt(bool success, String details) async {
    if (testMode) return;
    try {
      final token = await SecureStorage.getToken();
      await ApiSecurity.securePost(
        endpoint: 'logs/profile_update',
        data: {
          'action': 'profile_update_attempt',
          'timestamp': DateTime.now().toIso8601String(),
          'success': success,
          'details': details,
          'attempt_number': _updateAttempts,
          'rate_limited': !_checkRateLimit(),
        },
        token: token,
        requiresAuth: true,
      );
    } catch (e) {
      if (!testMode) ErrorHandler.logInfo('Log Update Attempt', 'Failed to log update attempt');
    }
  }

  Map<String, dynamic> getSecureProfileData() {
    try {
      return {
        'fullName': InputValidator.sanitizeInput(fullName),
        'email': InputValidator.sanitizeInput(email),
        'phone': InputValidator.sanitizeInput(phone),
        'location': InputValidator.sanitizeInput(location),
        'bank': InputValidator.sanitizeInput(bank),
        'hasImage': hasImage(),
        'lastUpdate': _lastUpdateAttempt?.toIso8601String(),
        'updateAttempts': _updateAttempts,
      };
    } catch (error) {
      if (!testMode) ErrorHandler.logError('Get Secure Profile Data', error);
      return {
        'fullName': '',
        'email': '',
        'phone': '',
        'location': '',
        'bank': '',
        'hasImage': false,
        'error': 'Failed to get profile data',
      };
    }
  }

  String getUpdateSuccessMessage() =>
      "Profile Updated Successfully! ✅\nYour changes have been saved securely.";

  String getUpdateErrorMessage() {
    final now = DateTime.now();
    final rateLimited = _updateAttempts >= _maxUpdateAttempts &&
        (_lastUpdateAttempt != null &&
         now.difference(_lastUpdateAttempt!) < _updateCooldown);

    if (rateLimited) {
      final minutesLeft = _lastUpdateAttempt != null
          ? _updateCooldown.inMinutes - now.difference(_lastUpdateAttempt!).inMinutes
          : 15;
      return "Too many update attempts. Please try again in $minutesLeft minutes.";
    }

    return "Failed to update profile. Please check your information and try again.";
  }

  String getValidationErrorMessage() =>
      "Please check your information:\n• Name must be valid\n• Email must be valid\n• Phone must be 10-15 digits";

  bool isProfileChanged({String? name, String? email, String? phone, File? image}) {
    try {
      final safeName = name != null ? InputValidator.sanitizeInput(name) : fullName;
      final safeEmail = email != null ? InputValidator.sanitizeInput(email) : this.email;
      final safePhone = phone != null ? InputValidator.sanitizeInput(phone) : this.phone;

      return safeName != fullName || safeEmail != this.email || safePhone != this.phone || image != profileImage;
    } catch (error) {
      if (!testMode) ErrorHandler.logError('Is Profile Changed', error);
      return false;
    }
  }

  
  Future<bool> validateCurrentProfile() async {
    try {
      return await validateForm(fullName, email, phone);
    } catch (error) {
      if (!testMode) ErrorHandler.logError('Validate Current Profile', error);
      return false;
    }
  }

  void sanitizeProfileData() {
    try {
      fullName = InputValidator.sanitizeInput(fullName);
      email = InputValidator.sanitizeInput(email);
      phone = InputValidator.sanitizeInput(phone);
      location = InputValidator.sanitizeInput(location);
      bank = InputValidator.sanitizeInput(bank);
    } catch (error) {
      if (!testMode) ErrorHandler.logError('Sanitize Profile Data', error);
    }
  }
}
