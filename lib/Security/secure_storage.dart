import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:p2/security/error_handler.dart';
class SecureStorage {
  static final FlutterSecureStorage _storage = FlutterSecureStorage();


static Future<void> initialize() async {
  try {
    // التحقق من أن Secure Storage يعمل
    // هذا مهم خاصة على iOS
    await _storage.write(key: '_init_check', value: 'ok');
    final check = await _storage.read(key: '_init_check');
    await _storage.delete(key: '_init_check');
    
    if (check != 'ok') {
      throw Exception('Secure storage initialization failed');
    }
    
    ErrorHandler.logInfo('Secure Storage', 'Initialized successfully');
  } catch (error) {
    ErrorHandler.logError('Secure Storage Initialize', error);
    rethrow;
  }
}
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  static Future<void> saveData(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> getData(String key) async {
    return await _storage.read(key: key);
  }

  static Future<void> deleteData(String key) async {
    await _storage.delete(key: key);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
