import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:p2/services/app_locale.dart';

void main() {
  group('AppLocale Simple Tests', () {
    
    setUp(() {
      AppLocale.locale.value = const Locale('en');
    });

    test('Basic translation functionality', () {
     
      AppLocale.locale.value = const Locale('en');
      expect(AppLocale.t('my_profile'), 'My Profile');
      expect(AppLocale.t('login'), 'Login');
      expect(AppLocale.t('logout'), 'Logout');
      expect(AppLocale.t('settings'), 'Settings');
      
     
      AppLocale.locale.value = const Locale('ar');
      expect(AppLocale.t('my_profile'), 'ملفي الشخصي');
      expect(AppLocale.t('login'), 'تسجيل الدخول');
      expect(AppLocale.t('logout'), 'تسجيل الخروج');
      expect(AppLocale.t('settings'), 'الإعدادات');
    });

    test('Locale validation', () {
      expect(AppLocale.isValidLocaleCode('en'), true);
      expect(AppLocale.isValidLocaleCode('ar'), true);
      expect(AppLocale.isValidLocaleCode('fr'), false);
      expect(AppLocale.isValidLocaleCode('es'), false);
      expect(AppLocale.isValidLocaleCode(''), false);
    });

    test('Text direction detection', () {
      AppLocale.locale.value = const Locale('en');
      expect(AppLocale.isRTL(), false);
      expect(AppLocale.getTextDirection(), TextDirection.ltr);
      
      AppLocale.locale.value = const Locale('ar');
      expect(AppLocale.isRTL(), true);
      expect(AppLocale.getTextDirection(), TextDirection.rtl);
    });

    test('Fallback behavior for missing translations', () {
      const unknownKey = 'some_unknown_key_xyz123';
      
      expect(AppLocale.t(unknownKey), unknownKey);
      
      
      expect(AppLocale.t(''), '[Invalid Key]');
    });

    test('Translation map retrieval', () {
      final englishMap = AppLocale.getTranslationsForLocale('en');
      final arabicMap = AppLocale.getTranslationsForLocale('ar');
      
      expect(englishMap, isNotNull);
      expect(arabicMap, isNotNull);
      
      expect(englishMap!['my_profile'], 'My Profile');
      expect(arabicMap!['my_profile'], 'ملفي الشخصي');
      
      expect(AppLocale.getTranslationsForLocale('fr'), null);
      expect(AppLocale.getTranslationsForLocale('invalid'), null);
    });

    test('Supported locales list', () {
      expect(AppLocale.supportedLocales.length, 2);
      expect(AppLocale.supportedLocales[0].languageCode, 'en');
      expect(AppLocale.supportedLocales[1].languageCode, 'ar');
    });

    test('Current locale code', () {
      AppLocale.locale.value = const Locale('en');
      expect(AppLocale.getCurrentLocaleCode(), 'en');
      
      AppLocale.locale.value = const Locale('ar');
      expect(AppLocale.getCurrentLocaleCode(), 'ar');
    });
  });

  group('Edge Cases and Error Handling', () {
    test('Multiple rapid locale switches', () {
      for (int i = 0; i < 10; i++) {
        AppLocale.locale.value = const Locale('en');
        expect(AppLocale.t('continue'), 'Continue');
        
        AppLocale.locale.value = const Locale('ar');
        expect(AppLocale.t('continue'), 'استمر');
      }
    });

    test('Translation with same key multiple times', () {
      AppLocale.locale.value = const Locale('en');
      
      
      for (int i = 0; i < 100; i++) {
        expect(AppLocale.t('my_profile'), 'My Profile');
      }
      
      AppLocale.locale.value = const Locale('ar');
      for (int i = 0; i < 100; i++) {
        expect(AppLocale.t('my_profile'), 'ملفي الشخصي');
      }
    });

    test('Mix of valid and invalid keys', () {
      AppLocale.locale.value = const Locale('en');
      
      const validKeys = ['my_profile', 'login', 'logout', 'settings'];
      const invalidKeys = ['invalid1', 'invalid2', '', 'key_with_space'];
      
      for (final key in validKeys) {
        expect(AppLocale.t(key), isNot(equals(key))); 
      }
      
      for (final key in invalidKeys) {
        if (key.isEmpty) {
          expect(AppLocale.t(key), '[Invalid Key]');
        } else {
          expect(AppLocale.t(key), key); 
        }
      }
    });
  });

  print('✅ All AppLocale tests completed successfully!');
}
