
import 'package:flutter/material.dart';

class AppLocale {
  
  static ValueNotifier<Locale> locale = ValueNotifier(const Locale('en'));

  
  static void init() {
    locale.value = const Locale('en'); 
  }

  
  static void setLocale(Locale newLocale) {
    locale.value = newLocale;
  }

  
  static String t(String key) {
    Map<String, Map<String, String>> localizedValues = {
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
        'no_new_orders': 'No New Orders',
        'no_current_orders': 'No Current Orders',
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
        'new_orders': 'جديدة',
        'current_orders': 'جارية',
        'previous_orders': 'سابقة',
        'no_new_orders': 'لا توجد طلبات جديدة',
        'no_current_orders': 'لا توجد طلبات جارية',
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

    return localizedValues[locale.value.languageCode]?[key] ?? key;
  }
}
