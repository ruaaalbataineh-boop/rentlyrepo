import 'package:flutter/material.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/secure_storage.dart';
import 'package:p2/security/input_validator.dart';
import 'package:p2/logic/sub_category_logic.dart';

class SubCategorySecurity {
  // التحقق من صحة categoryId
  static bool isValidCategoryId(String categoryId) {
    try {
      if (categoryId.isEmpty) {
        return false;
      }

      // التحقق من أن categoryId يتبع نمط معين (مثل c1, c2, إلخ)
      final categoryRegex = RegExp(r'^c[1-9][0-9]*$');
      if (!categoryRegex.hasMatch(categoryId)) {
        ErrorHandler.logSecurity('Category ID', 'Invalid category ID format: $categoryId');
        return false;
      }

      // التحقق من وجود الفئة في البيانات
      final categoryExists = SubCategoryLogic.categoryExists(categoryId);
      if (!categoryExists) {
        ErrorHandler.logSecurity('Category ID', 'Category does not exist: $categoryId');
        return false;
      }

      return true;
    } catch (error) {
      ErrorHandler.logError('Validate Category ID', error);
      return false;
    }
  }

  // التحقق من صحة categoryTitle
  static bool isValidCategoryTitle(String categoryTitle) {
    try {
      if (categoryTitle.isEmpty || categoryTitle.length > 100) {
        return false;
      }

      // التحقق من عدم وجود أكواد خبيثة
      if (!InputValidator.hasNoMaliciousCode(categoryTitle)) {
        ErrorHandler.logSecurity('Category Title', 
            'Malicious code detected in title: $categoryTitle');
        return false;
      }

      return true;
    } catch (error) {
      ErrorHandler.logError('Validate Category Title', error);
      return false;
    }
  }

  // تنظيف وتأمين بيانات الفئة
  static Map<String, dynamic> sanitizeCategoryData(
    String categoryId, 
    String categoryTitle
  ) {
    try {
      final sanitizedId = InputValidator.sanitizeInput(categoryId);
      final sanitizedTitle = InputValidator.sanitizeInput(categoryTitle);

      return {
        'categoryId': sanitizedId,
        'categoryTitle': sanitizedTitle,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (error) {
      ErrorHandler.logError('Sanitize Category Data', error);
      return {
        'categoryId': '',
        'categoryTitle': '',
        'error': ErrorHandler.getSafeError(error),
      };
    }
  }

  // التحقق من وصول المستخدم للفئة
  static Future<bool> canAccessCategory(String categoryId) async {
    try {
      // يمكنك إضافة منطق للتحقق من أذونات المستخدم هنا
      // مثلاً: بعض الفئات قد تكون محجوبة عن بعض المستخدمين
      
      // للآن، نعود بـ true إذا كانت الفئة موجودة وصالحة
      return isValidCategoryId(categoryId);
    } catch (error) {
      ErrorHandler.logError('Check Category Access', error);
      return false;
    }
  }

  // تسجيل دخول المستخدم إلى صفحة الفئة
  static Future<void> logCategoryAccess(
    String categoryId, 
    String categoryTitle
  ) async {
    try {
      final token = await SecureStorage.getToken();
      final userId = await _getUserId();

      // يمكنك إرسال هذا السجل إلى الخادم
      ErrorHandler.logInfo('Category Access', '''
Category ID: $categoryId
Category Title: $categoryTitle
User: ${userId ?? 'Unknown'}
Timestamp: ${DateTime.now().toIso8601String()}
''');

      // حفظ في التخزين المحلي للتحليل
      await SecureStorage.saveData(
        'last_accessed_category_${DateTime.now().millisecondsSinceEpoch}',
        '$categoryId - $categoryTitle',
      );
    } catch (error) {
      ErrorHandler.logError('Log Category Access', error);
    }
  }

  // الحصول على ID المستخدم (يمكنك تعديل هذا حسب نظام المصادقة الخاص بك)
  static Future<String?> _getUserId() async {
    try {
      // مثال: الحصول من SecureStorage
      final token = await SecureStorage.getToken();
      if (token != null && token.isNotEmpty) {
        // يمكنك استخراج userId من التوكن أو الحصول عليه من مكان آخر
        return 'user_${token.substring(0, min(8, token.length))}...';
      }
      return null;
    } catch (error) {
      ErrorHandler.logError('Get User ID', error);
      return null;
    }
  }

  static int min(int a, int b) => a < b ? a : b;

  // التحقق من أن بيانات الفئة الفرعية آمنة للعرض
  static Map<String, dynamic> sanitizeSubCategoryData(Map<String, dynamic> subCategory) {
    try {
      final sanitized = <String, dynamic>{};

      // تنظيف العنوان
      if (subCategory.containsKey('title') && subCategory['title'] is String) {
        sanitized['title'] = InputValidator.sanitizeInput(subCategory['title'] as String);
      } else {
        sanitized['title'] = 'Unknown';
      }

      // التحقق من الأيقونة
      if (subCategory.containsKey('icon') && subCategory['icon'] is IconData) {
        sanitized['icon'] = subCategory['icon'];
      } else {
        sanitized['icon'] = Icons.error;
      }

      return sanitized;
    } catch (error) {
      ErrorHandler.logError('Sanitize SubCategory Data', error);
      return {
        'title': 'Error',
        'icon': Icons.error,
      };
    }
  }

  // البحث الآمن في الفئات الفرعية
  static List<Map<String, dynamic>> secureSearchSubCategories(String query) {
    try {
      if (query.isEmpty) {
        return [];
      }

      // تنظيف الاستعلام
      final sanitizedQuery = InputValidator.sanitizeInput(query);
      if (sanitizedQuery.isEmpty) {
        return [];
      }

      // البحث في البيانات
      final results = SubCategoryLogic.searchSubCategories(sanitizedQuery);
      
      // تنظيف النتائج
      final sanitizedResults = results.map(sanitizeSubCategoryData).toList();

      // تسجيل عملية البحث
      ErrorHandler.logInfo('SubCategory Search', 
          'Search query: "$sanitizedQuery", Results: ${sanitizedResults.length}');

      return sanitizedResults;
    } catch (error) {
      ErrorHandler.logError('Secure Search SubCategories', error);
      return [];
    }
  }
}
