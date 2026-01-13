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
  
  // Security fields
  DateTime? _lastUpdateAttempt;
  int _updateAttempts = 0;
  static const int _maxUpdateAttempts = 5;
  static const Duration _updateCooldown = Duration(minutes: 15);

  ProfileLogic({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.location,
    required this.bank,
    this.profileImage,
  }) {
    _initializeSecurity();
  }

  Future<void> _initializeSecurity() async {
    try {
      // التحقق من المصادقة أولاً
      if (!RouteGuard.isAuthenticated()) {
        throw Exception('User not authenticated');
      }
      
      // جلب التوكن للتخزين الآمن
      final token = await SecureStorage.getToken();
      if (token == null) {
        ErrorHandler.logSecurity('Profile Logic', 'No authentication token found');
      }
      
      // تسجيل تهيئة الصفحة
      await _logProfileAccess();
    } catch (error) {
      ErrorHandler.logError('Initialize Profile Security', error);
    }
  }

  Future<void> _logProfileAccess() async {
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
      ErrorHandler.logInfo('Log Profile Access', 'Failed to log access');
    }
  }

  bool hasImage() {
    return profileImage != null;
  }

  bool _checkRateLimit() {
    if (_updateAttempts >= _maxUpdateAttempts) {
      if (_lastUpdateAttempt != null) {
        final timeSinceLastAttempt = DateTime.now().difference(_lastUpdateAttempt!);
        if (timeSinceLastAttempt < _updateCooldown) {
          return false;
        }
      }
      // Reset attempts after cooldown
      _updateAttempts = 0;
    }
    return true;
  }

  Future<bool> validateForm(String? name, String? email, String? phone) async {
    try {
      // التحقق من rate limiting أولاً
      if (!_checkRateLimit()) {
        ErrorHandler.logSecurity('Profile Update', 
            'Rate limit exceeded for user: $email');
        return false;
      }

      // التحقق من أن الحقول ليست فارغة
      if (name?.isEmpty == true || email?.isEmpty == true || phone?.isEmpty == true) {
        ErrorHandler.logError('Profile Validation', 'Empty fields detected');
        return false;
      }

      // التحقق من صحة الاسم
      final safeName = InputValidator.sanitizeInput(name!);
      if (safeName.isEmpty) {
        ErrorHandler.logError('Profile Validation', 'Invalid name format');
        return false;
      }

      // التحقق من صحة البريد الإلكتروني
      final safeEmail = InputValidator.sanitizeInput(email!);
      if (!InputValidator.isValidEmail(safeEmail)) {
        ErrorHandler.logError('Profile Validation', 'Invalid email format');
        return false;
      }

      // التحقق من صحة رقم الهاتف
      final safePhone = InputValidator.sanitizeInput(phone!);
      if (!InputValidator.isValidPhone(safePhone)) {
        ErrorHandler.logError('Profile Validation', 'Invalid phone number');
        return false;
      }

      // التحقق من عدم وجود محتوى ضار
      if (!InputValidator.hasNoMaliciousCode(safeName) ||
          !InputValidator.hasNoMaliciousCode(safeEmail) ||
          !InputValidator.hasNoMaliciousCode(safePhone)) {
        ErrorHandler.logSecurity('Profile Validation', 
            'Malicious content detected in profile data');
        return false;
      }

      // التحقق من طول الحقول
      if (safeName.length > 100 || safeEmail.length > 100 || safePhone.length > 20) {
        ErrorHandler.logError('Profile Validation', 'Field lengths exceed limits');
        return false;
      }

      return true;
    } catch (error) {
      ErrorHandler.logError('Validate Form', error);
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
      // التحقق من المصادقة أولاً
      if (!RouteGuard.isAuthenticated()) {
        throw Exception('User not authenticated for profile update');
      }

      // التحقق من rate limiting
      if (!_checkRateLimit()) {
        ErrorHandler.logSecurity('Profile Update', 
            'Rate limit exceeded. Please try again later.');
        return false;
      }

      // التحقق من صحة البيانات
      final validationResult = await validateForm(name, email, phone);
      if (!validationResult) {
        _updateAttempts++;
        _lastUpdateAttempt = DateTime.now();
        await _logUpdateAttempt(false, 'Validation failed');
        return false;
      }

      // تنظيف البيانات المدخلة
      final safeName = InputValidator.sanitizeInput(name!);
      final safeEmail = InputValidator.sanitizeInput(email!);
      final safePhone = InputValidator.sanitizeInput(phone!);

      // تحديث الحقول المحلية
      if (safeName.isNotEmpty) fullName = safeName;
      if (safeEmail.isNotEmpty) this.email = safeEmail;
      if (safePhone.isNotEmpty) this.phone = safePhone;
      if (image != null) {
        // التحقق من أن الصورة آمنة
        if (await validateImageSafety(image)) {
          profileImage = image;
        } else {
          ErrorHandler.logSecurity('Profile Update', 
              'Unsafe image detected');
          return false;
        }
      }

      // تحديث البيانات على الخادم
      final updateSuccess = await _updateProfileOnServer(
        name: safeName,
        email: safeEmail,
        phone: safePhone,
        image: image,
      );

      if (updateSuccess) {
        _updateAttempts = 0;
        await _logUpdateAttempt(true, 'Profile updated successfully');
        
        // تحديث البيانات المحلية الآمنة
        await _updateSecureStorage();
        
        return true;
      } else {
        _updateAttempts++;
        _lastUpdateAttempt = DateTime.now();
        return false;
      }
    } catch (error) {
      ErrorHandler.logError('Update Profile', error);
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
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      // تحضير البيانات الآمنة للإرسال
      final secureData = {
        'fullName': name,
        'email': email,
        'phone': phone,
        'location': location,
        'bank': bank,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // إرسال طلب التحديث الآمن
      final response = await ApiSecurity.securePost(
        endpoint: 'profile/update',
        data: secureData,
        token: token,
        requiresAuth: true,
      );

      // إذا كانت هناك صورة، رفعها بشكل منفصل
      if (image != null && await validateImageSafety(image)) {
        await _uploadProfileImage(image, token);
      }

      return response['success'] == true;
    } catch (error) {
      ErrorHandler.logError('Update Profile on Server', error);
      return false;
    }
  }

  Future<void> _uploadProfileImage(File image, String token) async {
    try {
      // هنا يمكنك إضافة كود لرفع الصورة بشكل آمن
      // يمكن استخدام multipart request مع التحقق من الأمان
      ErrorHandler.logInfo('Upload Profile Image', 
          'Image upload would happen here securely');
    } catch (error) {
      ErrorHandler.logError('Upload Profile Image', error);
    }
  }

  Future<bool> validateImageSafety(File image) async {
    try {
      // التحقق من حجم الصورة (حد أقصى 5MB)
      final fileSize = await image.length();
      const maxSize = 5 * 1024 * 1024; // 5MB
      
      if (fileSize > maxSize) {
        ErrorHandler.logSecurity('Image Validation', 
            'Image size exceeds limit: ${fileSize / 1024 / 1024}MB');
        return false;
      }

      // التحقق من امتداد الملف
      final fileName = image.path.toLowerCase();
      final allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif'];
      
      if (!allowedExtensions.any((ext) => fileName.endsWith(ext))) {
        ErrorHandler.logSecurity('Image Validation', 
            'Invalid image format: $fileName');
        return false;
      }

   

      return true;
    } catch (error) {
      ErrorHandler.logError('Validate Image Safety', error);
      return false;
    }
  }

  Future<void> _updateSecureStorage() async {
    try {
      // حفظ البيانات الحساسة في التخزين الآمن
      await SecureStorage.saveData('user_fullName', fullName);
      await SecureStorage.saveData('user_email', email);
      await SecureStorage.saveData('user_phone', phone);
      
      ErrorHandler.logInfo('Update Secure Storage', 
          'User data saved securely');
    } catch (error) {
      ErrorHandler.logError('Update Secure Storage', error);
    }
  }

  Future<void> _logUpdateAttempt(bool success, String details) async {
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
      ErrorHandler.logInfo('Log Update Attempt', 'Failed to log update attempt');
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
      ErrorHandler.logError('Get Secure Profile Data', error);
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

  String getUpdateSuccessMessage() {
    return "Profile Updated Successfully! ✅\nYour changes have been saved securely.";
  }

  String getUpdateErrorMessage() {
    if (!_checkRateLimit()) {
      return "Too many update attempts. Please try again in 15 minutes.";
    }
    return "Failed to update profile. Please check your information and try again.";
  }

  String getValidationErrorMessage() {
    return "Please check your information:\n• Name must be valid\n• Email must be valid\n• Phone must be 10-15 digits";
  }

  bool isProfileChanged({
    String? name,
    String? email,
    String? phone,
    File? image,
  }) {
    try {
      final safeName = name != null ? InputValidator.sanitizeInput(name) : fullName;
      final safeEmail = email != null ? InputValidator.sanitizeInput(email) : this.email;
      final safePhone = phone != null ? InputValidator.sanitizeInput(phone) : this.phone;
      
      return safeName != fullName ||
             safeEmail != this.email ||
             safePhone != this.phone ||
             image != profileImage;
    } catch (error) {
      ErrorHandler.logError('Is Profile Changed', error);
      return false;
    }
  }

  // دالة جديدة للحصول على بيانات المستخدم الآمنة
  Future<Map<String, dynamic>> getSecureUserData() async {
    try {
      final token = await SecureStorage.getToken();
      
      final response = await ApiSecurity.secureGet(
        endpoint: 'profile/data',
        token: token,
        requiresAuth: true,
      );
      
      if (response['success'] == true) {
        return response['data'] ?? {};
      } else {
        return getSecureProfileData();
      }
    } catch (error) {
      ErrorHandler.logError('Get Secure User Data', error);
      return getSecureProfileData();
    }
  }

  // دالة للتحقق من صحة بيانات المستخدم الحالية
  Future<bool> validateCurrentProfile() async {
    try {
      return await validateForm(fullName, email, phone) &&
             InputValidator.hasNoMaliciousCode(location) &&
             InputValidator.hasNoMaliciousCode(bank);
    } catch (error) {
      ErrorHandler.logError('Validate Current Profile', error);
      return false;
    }
  }

  // دالة لتنظيف جميع بيانات الملف الشخصي
  void sanitizeProfileData() {
    fullName = InputValidator.sanitizeInput(fullName);
    email = InputValidator.sanitizeInput(email);
    phone = InputValidator.sanitizeInput(phone);
    location = InputValidator.sanitizeInput(location);
    bank = InputValidator.sanitizeInput(bank);
  }

  // دالة لإعادة تعيين محاولات التحديث
  void resetUpdateAttempts() {
    _updateAttempts = 0;
    _lastUpdateAttempt = null;
  }
}
