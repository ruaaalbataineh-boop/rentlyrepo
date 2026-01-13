import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/secure_storage.dart';
import 'package:p2/security/input_validator.dart';

class PersonalInfoProvider {
  String name = '';
  String email = '';
  String password = '';
  String phone = '';
  File? imageFile;
  
  final ImagePicker _picker = ImagePicker();

  Future<void> loadUserData() async {
    try {
      // أولاً: جلب البيانات من التخزين الآمن (للبيانات الحساسة)
      final secureToken = await SecureStorage.getToken();
      if (secureToken == null) {
        ErrorHandler.logSecurity('PersonalInfoProvider', 'No secure token found');
      }

      // ثانياً: جلب البيانات من SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      
      name = _sanitizeAndDecrypt(prefs.getString('name') ?? '', 'name');
      email = _sanitizeAndDecrypt(prefs.getString('email') ?? '', 'email');
      
      // كلمة المرور: لا نسترجعها كاملة، نتركها فارغة للمستخدم ليدخل كلمة مرور جديدة
      // أو نعرض نجوم إذا أردنا عرض كلمة مرور مشفرة
      password = ''; // كلمة المرور لا تسترجع لأسباب أمنية
      
      phone = _sanitizeAndDecrypt(prefs.getString('phone') ?? '', 'phone');

      // تسجيل حدث تحميل البيانات
      await _logDataLoad();

    } catch (error) {
      ErrorHandler.logError('Load User Data', error);
      throw Exception('Failed to load user data');
    }
  }

  Future<void> saveUserData() async {
    try {
      // التحقق من صحة البيانات قبل الحفظ
      await _validateDataBeforeSave();

      final prefs = await SharedPreferences.getInstance();
      
      // تنظيف وتشفير البيانات قبل الحفظ
      await prefs.setString('name', _sanitizeAndEncrypt(name, 'name'));
      await prefs.setString('email', _sanitizeAndEncrypt(email, 'email'));
      
      // حفظ كلمة المرور فقط إذا تم تغييرها
      if (password.isNotEmpty && password != '******') {
        await prefs.setString('password', _sanitizeAndEncrypt(password, 'password'));
      }
      
      await prefs.setString('phone', _sanitizeAndEncrypt(phone, 'phone'));

      // حفظ بيانات الصورة إذا كانت موجودة
      if (imageFile != null) {
        await _saveImageInfo();
      }

      // تسجيل حدث حفظ البيانات
      await _logDataSave();

      // حفظ بيانات النسخ الاحتياطي الآمن
      await _saveBackupData();

    } catch (error) {
      ErrorHandler.logError('Save User Data', error);
      throw Exception('Failed to save user data');
    }
  }

  Future<void> pickImage() async {
    try {
      
      await _logImagePickAttempt();

      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, 
        maxWidth: 800,    
        maxHeight: 800,   
      );

      if (pickedFile != null) {
        
        final file = File(pickedFile.path);
        final fileSize = await file.length();
        const maxSize = 5 * 1024 * 1024; // 5MB

        if (fileSize > maxSize) {
          throw Exception('Image size exceeds 5MB limit');
        }

        
        final extension = pickedFile.path.split('.').last.toLowerCase();
        final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif'];
        if (!allowedExtensions.contains(extension)) {
          throw Exception('Only JPG, PNG and GIF images are allowed');
        }

        imageFile = file;
        
      
        await _logImagePickSuccess(fileSize);
      }

    } catch (error) {
      ErrorHandler.logError('Pick Image', error);
      await _logImagePickError(error);
      rethrow;
    }
  }

  Future<void> _validateDataBeforeSave() async {
    try {
    
      if (name.trim().isEmpty) {
        throw Exception('Name cannot be empty');
      }

      if (!InputValidator.hasNoMaliciousCode(name)) {
        throw Exception('Invalid characters in name');
      }

      
      if (!InputValidator.isValidEmail(email)) {
        throw Exception('Invalid email address');
      }
      if (password.isNotEmpty && !InputValidator.isValidPassword(password)) {
        throw Exception('Password does not meet security requirements');
      }

      
      if (phone.isNotEmpty && !InputValidator.isValidPhone(phone)) {
        throw Exception('Invalid phone number');
      }

    } catch (error) {
      ErrorHandler.logError('Validate Data Before Save', error);
      rethrow;
    }
  }

  Future<void> _saveImageInfo() async {
    try {
      final imageInfo = {
        'path': imageFile!.path,
        'size': (await imageFile!.length()).toString(),
        'lastModified': (await imageFile!.lastModified()).toIso8601String(),
        'hash': _generateFileHash(imageFile!.path), // في تطبيق حقيقي، توليد hash للملف
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_info', ErrorHandler.safeJsonEncode(imageInfo));
    } catch (error) {
      ErrorHandler.logError('Save Image Info', error);
    }
  }

  Future<void> _saveBackupData() async {
    try {
      final backupData = {
        'timestamp': DateTime.now().toIso8601String(),
        'name': name,
        'email': email,
        'phone': phone,
        'hasImage': imageFile != null,
        'lastUpdate': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      await SecureStorage.saveData(
        'user_profile_backup',
        ErrorHandler.safeJsonEncode(backupData),
      );
    } catch (error) {
      ErrorHandler.logError('Save Backup Data', error);
    }
  }

  String _sanitizeAndEncrypt(String data, String field) {
    try {
      // 1. تنظيف البيانات
      final sanitized = InputValidator.sanitizeInput(data);
      
      // 2. في تطبيق حقيقي، هنا رح تشفر البيانات
      // لكن للبساطة، رح نستخدم encoding بسيط
      if (field == 'password' && sanitized.isNotEmpty) {
        // لكلمة المرور، لا نخزنها كنص واضح
        return 'encrypted_' + _simpleHash(sanitized);
      }
      
      return sanitized;
    } catch (error) {
      ErrorHandler.logError('Sanitize and Encrypt', error);
      return data;
    }
  }

  String _sanitizeAndDecrypt(String data, String field) {
    try {
      if (data.startsWith('encrypted_') && field == 'password') {
        
        return '******'; 
      }
      
      return data;
    } catch (error) {
      ErrorHandler.logError('Sanitize and Decrypt', error);
      return data;
    }
  }

  String _simpleHash(String input) {
    
    return input.hashCode.toString();
  }

  String _generateFileHash(String filePath) {
    
    return File(filePath).hashCode.toString();
  }

  Future<void> _logDataLoad() async {
    try {
      final logData = {
        'timestamp': DateTime.now().toIso8601String(),
        'action': 'load_user_data',
        'fieldsLoaded': ['name', 'email', 'phone'],
      };

      await SecureStorage.saveData(
        'user_data_load_${DateTime.now().millisecondsSinceEpoch}',
        ErrorHandler.safeJsonEncode(logData),
      );
    } catch (e) {
      ErrorHandler.logError('Log Data Load', e);
    }
  }

  Future<void> _logDataSave() async {
    try {
      final logData = {
        'timestamp': DateTime.now().toIso8601String(),
        'action': 'save_user_data',
        'fieldsSaved': ['name', 'email', 'phone'],
        'hasImage': imageFile != null,
      };

      await SecureStorage.saveData(
        'user_data_save_${DateTime.now().millisecondsSinceEpoch}',
        ErrorHandler.safeJsonEncode(logData),
      );
    } catch (e) {
      ErrorHandler.logError('Log Data Save', e);
    }
  }

  Future<void> _logImagePickAttempt() async {
    try {
      final logData = {
        'timestamp': DateTime.now().toIso8601String(),
        'action': 'image_pick_attempt',
      };

      await SecureStorage.saveData(
        'image_pick_attempt_${DateTime.now().millisecondsSinceEpoch}',
        ErrorHandler.safeJsonEncode(logData),
      );
    } catch (e) {
      ErrorHandler.logError('Log Image Pick Attempt', e);
    }
  }

  Future<void> _logImagePickSuccess(int fileSize) async {
    try {
      final logData = {
        'timestamp': DateTime.now().toIso8601String(),
        'action': 'image_pick_success',
        'fileSize': fileSize,
        'fileType': imageFile!.path.split('.').last,
      };

      await SecureStorage.saveData(
        'image_pick_success_${DateTime.now().millisecondsSinceEpoch}',
        ErrorHandler.safeJsonEncode(logData),
      );
    } catch (e) {
      ErrorHandler.logError('Log Image Pick Success', e);
    }
  }

  Future<void> _logImagePickError(dynamic error) async {
    try {
      final logData = {
        'timestamp': DateTime.now().toIso8601String(),
        'action': 'image_pick_error',
        'error': ErrorHandler.getSafeError(error),
      };

      await SecureStorage.saveData(
        'image_pick_error_${DateTime.now().millisecondsSinceEpoch}',
        ErrorHandler.safeJsonEncode(logData),
      );
    } catch (e) {
      ErrorHandler.logError('Log Image Pick Error', e);
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'hasPassword': password.isNotEmpty && password != '******',
      'phone': phone,
      'hasImage': imageFile != null,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  Future<void> clearSensitiveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      
      await prefs.remove('password');
      
      password = '';
      
      ErrorHandler.logInfo('PersonalInfoProvider', 'Sensitive data cleared');
    } catch (error) {
      ErrorHandler.logError('Clear Sensitive Data', error);
    }
  }

  
  bool validateCurrentData() {
    try {
      return name.trim().isNotEmpty &&
             InputValidator.isValidEmail(email) &&
             (phone.isEmpty || InputValidator.isValidPhone(phone));
    } catch (error) {
      ErrorHandler.logError('Validate Current Data', error);
      return false;
    }
  }
}
