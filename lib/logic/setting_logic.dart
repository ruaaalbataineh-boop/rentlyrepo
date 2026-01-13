import 'package:p2/security/input_validator.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/secure_storage.dart';
import 'package:p2/security/route_guard.dart';
import 'package:p2/security/api_security.dart'; 

class SettingLogic {
  bool muteNotifications = false;
  bool appAppearance = false;
  String? _userId;
  DateTime? _lastUpdate;
  static const Duration _updateCooldown = Duration(seconds: 2);

  SettingLogic() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      if (!RouteGuard.isAuthenticated()) {
        ErrorHandler.logSecurity('Setting Logic', 'User not authenticated');
        return;
      }

      final savedMute = await SecureStorage.getData('setting_mute_notifications');
      final savedAppearance = await SecureStorage.getData('setting_app_appearance');

      setStateSafely(() {
        muteNotifications = savedMute == 'true';
        appAppearance = savedAppearance == 'true';
      });

      ErrorHandler.logInfo('Load Settings', 
          'Settings loaded: mute=$muteNotifications, appearance=$appAppearance');
    } catch (error) {
      ErrorHandler.logError('Load Settings', error);
    }
  }

  void setStateSafely(Function() callback) {
    try {
      callback();
    } catch (error) {
      ErrorHandler.logError('Set State Safely', error);
    }
  }

  Future<void> toggleNotifications() async {
    try {
      if (!_canUpdateSettings()) {
        ErrorHandler.logSecurity('Toggle Notifications', 
            'Settings update too frequent');
        return;
      }

      final newValue = !muteNotifications;
      final safeValue = newValue.toString();

      setStateSafely(() {
        muteNotifications = newValue;
      });

      await SecureStorage.saveData('setting_mute_notifications', safeValue);

      // إرسال إلى الخادم
      await _updateSettingOnServer('mute_notifications', safeValue);

      _lastUpdate = DateTime.now();
      
      ErrorHandler.logInfo('Toggle Notifications', 
          'Notifications ${newValue ? 'muted' : 'enabled'}');
    } catch (error) {
      ErrorHandler.logError('Toggle Notifications', error);
      setStateSafely(() {
        muteNotifications = !muteNotifications;
      });
    }
  }

  Future<void> toggleAppAppearance() async {
    try {
      if (!_canUpdateSettings()) {
        ErrorHandler.logSecurity('Toggle App Appearance', 
            'Settings update too frequent');
        return;
      }

      final newValue = !appAppearance;
      final safeValue = newValue.toString();

      setStateSafely(() {
        appAppearance = newValue;
      });

      await SecureStorage.saveData('setting_app_appearance', safeValue);

      await _updateSettingOnServer('app_appearance', safeValue);

      _lastUpdate = DateTime.now();
      
      ErrorHandler.logInfo('Toggle App Appearance', 
          'Appearance changed to ${newValue ? 'dark' : 'light'} mode');
    } catch (error) {
      ErrorHandler.logError('Toggle App Appearance', error);
      setStateSafely(() {
        appAppearance = !appAppearance;
      });
    }
  }

  Map<String, bool> getSettings() {
    try {
      return {
        'muteNotifications': muteNotifications,
        'appAppearance': appAppearance,
        'isAuthenticated': RouteGuard.isAuthenticated(),
      };
    } catch (error) {
      ErrorHandler.logError('Get Settings', error);
      return {
        'muteNotifications': false,
        'appAppearance': false,
        'isAuthenticated': false,
      };
    }
  }

  Future<void> updateSettings(bool notifications, bool appearance) async {
    try {
      if (!RouteGuard.isAuthenticated()) {
        throw Exception('User not authenticated');
      }

      if (!_validateBooleanValue(notifications) || !_validateBooleanValue(appearance)) {
        throw Exception('Invalid settings values');
      }

      if (!_canUpdateSettings()) {
        throw Exception('Settings update too frequent');
      }

      setStateSafely(() {
        muteNotifications = notifications;
        appAppearance = appearance;
      });

      await Future.wait([
        SecureStorage.saveData('setting_mute_notifications', notifications.toString()),
        SecureStorage.saveData('setting_app_appearance', appearance.toString()),
      ]);

      await _updateSettingsBatch({
        'mute_notifications': notifications.toString(),
        'app_appearance': appearance.toString(),
      });

      _lastUpdate = DateTime.now();

      ErrorHandler.logInfo('Update Settings', 
          'Settings updated: notifications=$notifications, appearance=$appearance');
    } catch (error) {
      ErrorHandler.logError('Update Settings', error);
      rethrow;
    }
  }

  Future<void> syncWithServer() async {
    try {
      ErrorHandler.logInfo('Sync Settings', 'Starting sync with server...');
      
      // استخدم ApiSecurity بدلاً من SecureApi
      final response = await ApiSecurity.secureGet(
        endpoint: 'settings/user',
        requiresAuth: true,
      );

      if (response['success'] == true && response['data'] != null) {
        final serverSettings = response['data'] as Map<String, dynamic>;
        
        final serverMute = serverSettings['mute_notifications'] == true;
        final serverAppearance = serverSettings['app_appearance'] == true;

        setStateSafely(() {
          muteNotifications = serverMute;
          appAppearance = serverAppearance;
        });

        await Future.wait([
          SecureStorage.saveData('setting_mute_notifications', serverMute.toString()),
          SecureStorage.saveData('setting_app_appearance', serverAppearance.toString()),
        ]);

        ErrorHandler.logInfo('Sync Settings', 
            'Settings synced: mute=$serverMute, appearance=$serverAppearance');
      }
    } catch (error) {
      ErrorHandler.logError('Sync With Server', error);
    }
  }

  bool _canUpdateSettings() {
    if (_lastUpdate == null) return true;
    
    final timeSinceLastUpdate = DateTime.now().difference(_lastUpdate!);
    return timeSinceLastUpdate > _updateCooldown;
  }

  Future<void> _updateSettingOnServer(String settingKey, String settingValue) async {
    try {
      final token = await SecureStorage.getToken();
      
      final response = await ApiSecurity.securePost(
        endpoint: 'settings/update',
        data: {
          'setting_key': InputValidator.sanitizeInput(settingKey),
          'setting_value': InputValidator.sanitizeInput(settingValue),
          'updated_at': DateTime.now().toIso8601String(),
        },
        token: token,
        requiresAuth: true,
      );

      if (response['success'] != true) {
        ErrorHandler.logInfo('Update Setting', 
            'Failed to update setting on server');
      }
    } catch (error) {
      ErrorHandler.logError('Update Setting On Server', error);
      // لا نعيد الخطأ هنا لأن الإعدادات مخزنة محلياً
    }
  }

  Future<void> _updateSettingsBatch(Map<String, String> settings) async {
    try {
      final token = await SecureStorage.getToken();
      
      final safeSettings = <String, String>{};
      settings.forEach((key, value) {
        safeSettings[InputValidator.sanitizeInput(key)] = 
            InputValidator.sanitizeInput(value);
      });

      final response = await ApiSecurity.securePost(
        endpoint: 'settings/update_batch',
        data: {
          'settings': safeSettings,
          'updated_at': DateTime.now().toIso8601String(),
        },
        token: token,
        requiresAuth: true,
      );

      if (response['success'] != true) {
        ErrorHandler.logInfo('Update Settings Batch', 
            'Failed to update batch settings');
      }
    } catch (error) {
      ErrorHandler.logError('Update Settings Batch', error);
    }
  }

  bool _validateBooleanValue(bool value) {
    return value == true || value == false;
  }

  Future<void> resetToDefault() async {
    try {
      if (!RouteGuard.isAuthenticated()) {
        throw Exception('User not authenticated');
      }

      if (!_canUpdateSettings()) {
        throw Exception('Please wait before resetting settings');
      }

      setStateSafely(() {
        muteNotifications = false;
        appAppearance = false;
      });

      await Future.wait([
        SecureStorage.saveData('setting_mute_notifications', 'false'),
        SecureStorage.saveData('setting_app_appearance', 'false'),
      ]);

      await _updateSettingsBatch({
        'mute_notifications': 'false',
        'app_appearance': 'false',
      });

      _lastUpdate = DateTime.now();

      ErrorHandler.logInfo('Reset Settings', 'Settings reset to default');
    } catch (error) {
      ErrorHandler.logError('Reset Settings', error);
      rethrow;
    }
  }

  Future<bool> validateAllSettings() async {
    try {
      final settingsValid = _validateBooleanValue(muteNotifications) && 
                           _validateBooleanValue(appAppearance);
      
      final token = await SecureStorage.getToken();
      if (token == null) {
        return settingsValid;
      }

      final response = await ApiSecurity.secureGet(
        endpoint: 'settings/validate',
        token: token,
        requiresAuth: true,
      );
      
      return settingsValid && (response['success'] == true);
    } catch (error) {
      ErrorHandler.logError('Validate All Settings', error);
      return false;
    }
  }

  // دالة جديدة لفحص اتصال الخادم
  Future<bool> checkServerConnection() async {
    try {
      return await ApiSecurity.checkConnection();
    } catch (error) {
      ErrorHandler.logError('Check Server Connection', error);
      return false;
    }
  }

  // دالة لجلب معلومات الإعدادات
  Future<Map<String, dynamic>> getSettingsInfo() async {
    try {
      final token = await SecureStorage.getToken();
      final isAuthenticated = RouteGuard.isAuthenticated();
      final lastUpdate = _lastUpdate?.toIso8601String() ?? 'Never';
      
      return {
        'muteNotifications': muteNotifications,
        'appAppearance': appAppearance,
        'isAuthenticated': isAuthenticated,
        'hasToken': token != null,
        'lastUpdate': lastUpdate,
        'canUpdate': _canUpdateSettings(),
        'settingsValid': _validateBooleanValue(muteNotifications) && 
                         _validateBooleanValue(appAppearance),
      };
    } catch (error) {
      ErrorHandler.logError('Get Settings Info', error);
      return {
        'muteNotifications': false,
        'appAppearance': false,
        'isAuthenticated': false,
        'hasToken': false,
        'error': ErrorHandler.getSafeError(error),
      };
    }
  }
}
