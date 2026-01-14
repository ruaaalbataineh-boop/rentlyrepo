import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/secure_storage.dart';
import 'package:p2/security/input_validator.dart';

abstract class ISharedPreferencesService {
  Future<SharedPreferences> getInstance();
}


class SharedPreferencesService implements ISharedPreferencesService {
  @override
  Future<SharedPreferences> getInstance() async {
    return await SharedPreferences.getInstance();
  }
}

abstract class ISecureStorage {
  Future<String?> getToken();
  Future<void> saveData(String key, String value);
  Future<String?> getData(String key);
}


class SecureStorageService implements ISecureStorage {
  @override
  Future<String?> getToken() => SecureStorage.getToken();

  @override
  Future<void> saveData(String key, String value) => SecureStorage.saveData(key, value);

  @override
  Future<String?> getData(String key) => SecureStorage.getData(key);
}

abstract class IErrorHandler {
  void logError(String location, dynamic error);
  void logSecurity(String location, String message);
  void logInfo(String location, String message);
  String getSafeError(dynamic error);
  String safeJsonEncode(Map<String, dynamic> data);
}
class ErrorHandlerService implements IErrorHandler {
  @override
  void logError(String location, dynamic error) => ErrorHandler.logError(location, error);

  @override
  void logSecurity(String location, String message) => ErrorHandler.logSecurity(location, message);

  @override
  void logInfo(String location, String message) => ErrorHandler.logInfo(location, message);

  @override
  String getSafeError(dynamic error) => ErrorHandler.getSafeError(error);

  @override
  String safeJsonEncode(Map<String, dynamic> data) => ErrorHandler.safeJsonEncode(data);
}


abstract class IImagePickerService {
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  });
}


class ImagePickerService implements IImagePickerService {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) {
    return _picker.pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }
}

class PersonalInfoProvider {
  String name = '';
  String email = '';
  String password = '';
  String phone = '';
  File? imageFile;
  
  
  final ISharedPreferencesService _sharedPrefsService;
  final ISecureStorage _secureStorage;
  final IErrorHandler _errorHandler;
  final IImagePickerService _imagePicker;
  

  PersonalInfoProvider({
    ISharedPreferencesService? sharedPrefsService,
    ISecureStorage? secureStorage,
    IErrorHandler? errorHandler,
    IImagePickerService? imagePicker,
  }) : 
    _sharedPrefsService = sharedPrefsService ?? SharedPreferencesService(),
    _secureStorage = secureStorage ?? SecureStorageService(),
    _errorHandler = errorHandler ?? ErrorHandlerService(),
    _imagePicker = imagePicker ?? ImagePickerService();

  Future<void> loadUserData() async {
    try {
      
      final secureToken = await _secureStorage.getToken();
      if (secureToken == null) {
        _errorHandler.logSecurity('PersonalInfoProvider', 'No secure token found');
      }

    
      final prefs = await _sharedPrefsService.getInstance();
      
      name = sanitizeAndDecrypt(prefs.getString('name') ?? '', 'name');
      email = sanitizeAndDecrypt(prefs.getString('email') ?? '', 'email');
      
      
      password = ''; 
      
      phone = sanitizeAndDecrypt(prefs.getString('phone') ?? '', 'phone');

      
      await _logDataLoad();

    } catch (error) {
      _errorHandler.logError('Load User Data', error);
      throw Exception('Failed to load user data');
    }
  }

  Future<void> saveUserData() async {
    try {
      
      await validateDataBeforeSave();

      final prefs = await _sharedPrefsService.getInstance();
      
      
      await prefs.setString('name', sanitizeAndEncrypt(name, 'name'));
      await prefs.setString('email', sanitizeAndEncrypt(email, 'email'));
    
      if (password.isNotEmpty && password != '******') {
        await prefs.setString('password', sanitizeAndEncrypt(password, 'password'));
      }
      
      await prefs.setString('phone', sanitizeAndEncrypt(phone, 'phone'));

      if (imageFile != null) {
        await _saveImageInfo();
      }

      
      await _logDataSave();

      await _saveBackupData();

    } catch (error) {
      _errorHandler.logError('Save User Data', error);
      throw Exception('Failed to save user data');
    }
  }

  Future<void> pickImage() async {
    try {
      
      await _logImagePickAttempt();

      final pickedFile = await _imagePicker.pickImage(
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
      _errorHandler.logError('Pick Image', error);
      await _logImagePickError(error);
      rethrow;
    }
  }

  Future<void> validateDataBeforeSave() async {
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
      _errorHandler.logError('Validate Data Before Save', error);
      rethrow;
    }
  }

  Future<void> _saveImageInfo() async {
    try {
      final imageInfo = {
        'path': imageFile!.path,
        'size': (await imageFile!.length()).toString(),
        'lastModified': (await imageFile!.lastModified()).toIso8601String(),
        'hash': _generateFileHash(imageFile!.path),
      };

      final prefs = await _sharedPrefsService.getInstance();
      await prefs.setString('profile_image_info', _errorHandler.safeJsonEncode(imageInfo));
    } catch (error) {
      _errorHandler.logError('Save Image Info', error);
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

      await _secureStorage.saveData(
        'user_profile_backup',
        _errorHandler.safeJsonEncode(backupData),
      );
    } catch (error) {
      _errorHandler.logError('Save Backup Data', error);
    }
  }

  String sanitizeAndEncrypt(String data, String field) {
    try {
  
      final sanitized = InputValidator.sanitizeInput(data);
      
      
      if (field == 'password' && sanitized.isNotEmpty) {
        return 'encrypted_' + _simpleHash(sanitized);
      }
      
      return sanitized;
    } catch (error) {
      _errorHandler.logError('Sanitize and Encrypt', error);
      return data;
    }
  }

  String sanitizeAndDecrypt(String data, String field) {
    try {
      if (data.startsWith('encrypted_') && field == 'password') {
        return '******'; 
      }
      
      return data;
    } catch (error) {
      _errorHandler.logError('Sanitize and Decrypt', error);
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

      await _secureStorage.saveData(
        'user_data_load_${DateTime.now().millisecondsSinceEpoch}',
        _errorHandler.safeJsonEncode(logData),
      );
    } catch (e) {
      _errorHandler.logError('Log Data Load', e);
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

      await _secureStorage.saveData(
        'user_data_save_${DateTime.now().millisecondsSinceEpoch}',
        _errorHandler.safeJsonEncode(logData),
      );
    } catch (e) {
      _errorHandler.logError('Log Data Save', e);
    }
  }

  Future<void> _logImagePickAttempt() async {
    try {
      final logData = {
        'timestamp': DateTime.now().toIso8601String(),
        'action': 'image_pick_attempt',
      };

      await _secureStorage.saveData(
        'image_pick_attempt_${DateTime.now().millisecondsSinceEpoch}',
        _errorHandler.safeJsonEncode(logData),
      );
    } catch (e) {
      _errorHandler.logError('Log Image Pick Attempt', e);
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

      await _secureStorage.saveData(
        'image_pick_success_${DateTime.now().millisecondsSinceEpoch}',
        _errorHandler.safeJsonEncode(logData),
      );
    } catch (e) {
      _errorHandler.logError('Log Image Pick Success', e);
    }
  }

  Future<void> _logImagePickError(dynamic error) async {
    try {
      final logData = {
        'timestamp': DateTime.now().toIso8601String(),
        'action': 'image_pick_error',
        'error': _errorHandler.getSafeError(error),
      };

      await _secureStorage.saveData(
        'image_pick_error_${DateTime.now().millisecondsSinceEpoch}',
        _errorHandler.safeJsonEncode(logData),
      );
    } catch (e) {
      _errorHandler.logError('Log Image Pick Error', e);
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
      final prefs = await _sharedPrefsService.getInstance();
      
      await prefs.remove('password');
      
      password = '';
      
      _errorHandler.logInfo('PersonalInfoProvider', 'Sensitive data cleared');
    } catch (error) {
      _errorHandler.logError('Clear Sensitive Data', error);
    }
  }

  bool validateCurrentData() {
    try {
      return name.trim().isNotEmpty &&
             InputValidator.isValidEmail(email) &&
             (phone.isEmpty || InputValidator.isValidPhone(phone));
    } catch (error) {
      _errorHandler.logError('Validate Current Data', error);
      return false;
    }
  }

  
  void setTestData({
    String? testName,
    String? testEmail,
    String? testPassword,
    String? testPhone,
    File? testImage,
  }) {
    if (testName != null) name = testName;
    if (testEmail != null) email = testEmail;
    if (testPassword != null) password = testPassword;
    if (testPhone != null) phone = testPhone;
    if (testImage != null) imageFile = testImage;
  }
}
