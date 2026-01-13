import 'package:firebase_auth/firebase_auth.dart';
import 'package:p2/security/secure_storage.dart';

class ErrorConverter {
  // تحويل أي خطأ إلى Exception آمن
  static Exception safeConvert(dynamic error) {
    try {
      if (error is ArgumentError) {
        return Exception('Validation error: ${error.message ?? error.toString()}');
      }
      
      if (error is Exception) {
        return error;
      }
      
      if (error is String) {
        return Exception(error);
      }
      
      return Exception(error.toString());
    } catch (e) {
      return Exception('Error conversion failed');
    }
  }
  
  //  دالة آمنة للتحقق من المصادقة
  static bool safeIsAuthenticated() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      return user != null;
    } on ArgumentError catch (e) {
      // لا ترمي الخطأ، فقط أرجع false
      print(' Auth ArgumentError handled silently: ${e.message}');
      return false;
    } catch (e) {
      print(' Auth Error handled silently: $e');
      return false;
    }
  }
  
  //  دالة آمنة للحصول على التوكن
  static Future<String?> safeGetToken() async {
    try {
      return await SecureStorage.getToken();
    } on ArgumentError catch (e) {
      print(' Token ArgumentError handled silently: ${e.message}');
      return null;
    } catch (e) {
      print(' Token Error handled silently: $e');
      return null;
    }
  }
  
  //  دالة آمنة للتسجيل
  static void safeLogError(String context, dynamic error) {
    try {
      final safeError = safeConvert(error);
      print(' [$context] Safe Error: $safeError');
    } catch (e) {
      print(' Ultimate error in safeLogError: $e');
    }
  }
  
  //  دالة آمنة للحفظ
  static Future<void> safeSaveData(String key, String value) async {
    try {
      await SecureStorage.saveData(key, value);
    } on ArgumentError catch (e) {
      print(' SaveData ArgumentError handled silently: ${e.message}');
    } catch (e) {
      print(' SaveData Error handled silently: $e');
    }
  }
}
