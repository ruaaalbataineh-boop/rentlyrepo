import 'package:flutter/material.dart';
import 'dart:convert';

// Add security imports
import '../security/secure_storage.dart';
import '../security/error_handler.dart';
import '../security/input_validator.dart';

class AppLocale {
  
  static ValueNotifier<Locale> locale = ValueNotifier(const Locale('en'));
  
  // Security: Store supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
  ];

  // Security: Validate locale code
  static bool isValidLocaleCode(String code) {
    return code == 'en' || code == 'ar';
  }

  // Secure initialization
  static Future<void> init() async {
    try {
      // Security: Load saved locale from secure storage
      final savedLocale = await SecureStorage.getData('app_locale');
      
      if (savedLocale != null && savedLocale.isNotEmpty) {
        // Security: Validate locale before using
        if (isValidLocaleCode(savedLocale)) {
          locale.value = Locale(savedLocale);
        } else {
          // Security: Default to English if invalid
          await SecureStorage.saveData('app_locale', 'en');
          locale.value = const Locale('en');
        }
      } else {
        // Security: Default locale
        await SecureStorage.saveData('app_locale', 'en');
        locale.value = const Locale('en');
      }
    } catch (error) {
      // Security: Error handling
      ErrorHandler.logError('AppLocale Init', error);
      // Default to English on error
      locale.value = const Locale('en');
    }
  }

  // Secure locale change
  static Future<void> setLocale(Locale newLocale) async {
    try {
      // Security: Validate locale
      if (!isValidLocaleCode(newLocale.languageCode)) {
        throw Exception('Invalid locale code: ${newLocale.languageCode}');
      }

      // Security: Save to secure storage
      await SecureStorage.saveData('app_locale', newLocale.languageCode);
      
      // Update notifier
      locale.value = newLocale;
      
      // Security: Log locale change (without user data)
      ErrorHandler.logError('Locale Changed', 'Changed to: ${newLocale.languageCode}');
      
    } catch (error) {
      ErrorHandler.logError('Set Locale', error);
      // Revert to English on error
      locale.value = const Locale('en');
    }
  }

  // Security: Get current locale code safely
  static String getCurrentLocaleCode() {
    try {
      return locale.value.languageCode;
    } catch (error) {
      return 'en'; // Default on error
    }
  }

  // Secure translation with validation
  static String t(String key) {
    try {
      // Security: Validate key
      if (key.isEmpty || !InputValidator.hasNoMaliciousCode(key)) {
        return '[Invalid Key]';
      }

      // Security: Sanitize key
      final sanitizedKey = InputValidator.sanitizeInput(key);
      
      // Security: Hardcoded translations (protected from injection)
      final Map<String, Map<String, String>> localizedValues = {
        'en': {
          'my_profile': 'My Profile',
          'personal_info': 'Personal Information',
          'rently_wallet': 'My Wallet',
          'favourite': 'Favourites',
          'about_app': 'About App',
          'support_help': 'Contact Us',
          'app_language': 'App Language',
          'remove_account': 'Deactivate Account',
          'logout': 'Logout',
          'orders': 'Orders',
          'pending_orders': 'Pending',
          'active_orders': 'Active',
          'previous_orders': 'Previous',
          'no_pending_orders': 'No Pending Orders',
          'no_active_orders': 'No Active Orders',
          'no_previous_orders': 'No Previous Orders',
          'settings': 'Settings',
          'phone_number': 'Phone Number',
          'add_id_photo': 'Add ID Photo',
          'face_scan': 'Face Scan',
          'continue': 'Continue',
          'skip': 'Skip',
          'create_account': 'Create Account',
          'login': 'Login',
          'sign_in': 'Sign In',
          'sign_up': 'Sign Up',
          'forgot_password': 'Forgot Password',
          'resend_code': 'Resend the code',
          'verify': 'Verify',
          // Security: Add error messages
          'error_generic': 'An error occurred',
          'error_network': 'Network error',
          'error_auth': 'Authentication failed',
        },
        'ar': {
          'my_profile': 'ملفي الشخصي',
          'personal_info': 'المعلومات الشخصية',
          'rently_wallet': 'محفظة رنتلي',
          'favourite': 'المفضلة',
          'coupons': 'كوبونات',
          'about_app': 'عن التطبيق',
          'support_help': 'الدعم والمساعدة',
          'app_language': 'لغة التطبيق',
          'remove_account': 'حذف الحساب',
          'logout': 'تسجيل الخروج',
          'orders': 'الطلبات',
          'pending_orders': 'قيد الانتظار',
          'active_orders': 'نشطة',
          'previous_orders': 'سابقة',
          'no_pending_orders': 'لا توجد طلبات قيد الانتظار',
          'no_active_orders': 'لا توجد طلبات نشطة',
          'no_previous_orders': 'لا توجد طلبات سابقة',
          'settings': 'الإعدادات',
          'phone_number': 'رقم الهاتف',
          'add_id_photo': 'أضف صورة الهوية',
          'face_scan': 'مسح الوجه',
          'continue': 'استمر',
          'skip': 'تخطي',
          'create_account': 'إنشاء حساب',
          'login': 'تسجيل الدخول',
          'sign_in': 'تسجيل الدخول',
          'sign_up': 'إنشاء حساب',
          'forgot_password': 'نسيت كلمة المرور',
          'resend_code': 'إعادة إرسال الكود',
          'verify': 'تحقق',
          // Security: Add error messages in Arabic
          'error_generic': 'حدث خطأ',
          'error_network': 'خطأ في الشبكة',
          'error_auth': 'فشل في المصادقة',
        },
      };

      final currentLocale = getCurrentLocaleCode();
      
      // Security: Validate locale exists
      if (!localizedValues.containsKey(currentLocale)) {
        return sanitizedKey;
      }

      // Security: Get translation
      final translation = localizedValues[currentLocale]?[sanitizedKey];
      
      // Security: Fallback to English if translation not found
      if (translation == null) {
        final englishTranslation = localizedValues['en']?[sanitizedKey];
        return englishTranslation ?? sanitizedKey;
      }

      return translation;
      
    } catch (error) {
      // Security: Error handling - return key as fallback
      ErrorHandler.logError('Translation Error', error);
      return key;
    }
  }

  // Security: Secure method to get all translations for a locale (for debugging)
  static Map<String, String>? getTranslationsForLocale(String localeCode) {
    try {
      // Security: Validate locale
      if (!isValidLocaleCode(localeCode)) {
        return null;
      }

      final Map<String, Map<String, String>> localizedValues = {
        'en': {
          'my_profile': 'My Profile',
          'personal_info': 'Personal Information',
          'rently_wallet': 'Rently Wallet',
          'favourite': 'Favourite',
          'coupons': 'Coupons',
          'about_app': 'About App',
          'support_help': 'Support & Help',
          'app_language': 'App Language',
          'remove_account': 'Remove Account',
          'logout': 'Logout',
          'orders': 'Orders',
          'pending_orders': 'Pending',
          'active_orders': 'Active',
          'previous_orders': 'Previous',
          'no_pending_orders': 'No Pending Orders',
          'no_active_orders': 'No Active Orders',
          'no_previous_orders': 'No Previous Orders',
          'settings': 'Settings',
          'phone_number': 'Phone Number',
          'add_id_photo': 'Add ID Photo',
          'face_scan': 'Face Scan',
          'continue': 'Continue',
          'skip': 'Skip',
          'create_account': 'Create Account',
          'login': 'Login',
          'sign_in': 'Sign In',
          'sign_up': 'Sign Up',
          'forgot_password': 'Forgot Password',
          'resend_code': 'Resend the code',
          'verify': 'Verify',
        },
        'ar': {
          'my_profile': 'ملفي الشخصي',
          'personal_info': 'المعلومات الشخصية',
          'rently_wallet': 'محفظة رنتلي',
          'favourite': 'المفضلة',
          'coupons': 'كوبونات',
          'about_app': 'عن التطبيق',
          'support_help': 'الدعم والمساعدة',
          'app_language': 'لغة التطبيق',
          'remove_account': 'حذف الحساب',
          'logout': 'تسجيل الخروج',
          'orders': 'الطلبات',
          'pending_orders': 'قيد الانتظار',
          'active_orders': 'نشطة',
          'previous_orders': 'سابقة',
          'no_pending_orders': 'لا توجد طلبات قيد الانتظار',
          'no_active_orders': 'لا توجد طلبات نشطة',
          'no_previous_orders': 'لا توجد طلبات سابقة',
          'settings': 'الإعدادات',
          'phone_number': 'رقم الهاتف',
          'add_id_photo': 'أضف صورة الهوية',
          'face_scan': 'مسح الوجه',
          'continue': 'استمر',
          'skip': 'تخطي',
          'create_account': 'إنشاء حساب',
          'login': 'تسجيل الدخول',
          'sign_in': 'تسجيل الدخول',
          'sign_up': 'إنشاء حساب',
          'forgot_password': 'نسيت كلمة المرور',
          'resend_code': 'إعادة إرسال الكود',
          'verify': 'تحقق',
        },
      };

      return localizedValues[localeCode];
    } catch (error) {
      ErrorHandler.logError('Get Translations', error);
      return null;
    }
  }

  // Security: Reset to default locale
  static Future<void> resetToDefault() async {
    try {
      await SecureStorage.saveData('app_locale', 'en');
      locale.value = const Locale('en');
    } catch (error) {
      ErrorHandler.logError('Reset Locale', error);
    }
  }

  // Security: Check if locale is RTL
  static bool isRTL() {
    return getCurrentLocaleCode() == 'ar';
  }

  // Security: Get text direction
  static TextDirection getTextDirection() {
    return isRTL() ? TextDirection.rtl : TextDirection.ltr;
  }
}
