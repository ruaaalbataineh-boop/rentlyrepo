import 'package:flutter/material.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/input_validator.dart';

class SubCategoryLogic {
  // البيانات الأصلية مع التحقق
  static final Map<String, List<Map<String, dynamic>>> _subCategoryData = {
    "c1": [
      {"title": "Cameras & Photography", "icon": Icons.photo_camera},
      {"title": "Audio & Video", "icon": Icons.speaker},
    ],
    "c2": [
      {"title": "Mobiles", "icon": Icons.phone_android},
      {"title": "Laptops", "icon": Icons.laptop_mac},
      {"title": "Printers", "icon": Icons.print},
      {"title": "Projectors", "icon": Icons.video_camera_back},
      {"title": "Servers", "icon": Icons.dns},
    ],
    "c3": [
      {"title": "Gaming Devices", "icon": Icons.sports_esports},
    ],
    "c4": [
      {"title": "Bicycles", "icon": Icons.pedal_bike},
      {"title": "Books", "icon": Icons.menu_book},
      {"title": "Skates & Scooters", "icon": Icons.roller_skating_outlined},
      {"title": "Camping", "icon": Icons.park},
    ],
    "c5": [
      {"title": "Maintenance Tools", "icon": Icons.build},
      {"title": "Medical Devices", "icon": Icons.monitor_heart},
      {"title": "Cleaning Equipment", "icon": Icons.cleaning_services},
    ],
    "c6": [
      {"title": "Garden Equipment", "icon": Icons.yard_outlined},
      {"title": "Home Supplies", "icon": Icons.home},
    ],
    "c7": [
      {"title": "Men", "icon": Icons.man},
      {"title": "Women", "icon": Icons.woman},
      {"title": "Customs", "icon": Icons.checkroom},
      {"title": "Baby Supplies", "icon": Icons.child_friendly},
    ],
  };

  // الحصول على الفئات الفرعية مع التحقق
  static List<Map<String, dynamic>> getSubCategories(String categoryId) {
    try {
      // التحقق من صحة categoryId
      if (categoryId.isEmpty) {
        ErrorHandler.logError('Get SubCategories', 'Empty category ID');
        return [];
      }

      // التحقق من وجود الفئة
      if (!_subCategoryData.containsKey(categoryId)) {
        ErrorHandler.logError('Get SubCategories', 'Category not found: $categoryId');
        return [];
      }

      // جلب البيانات الأصلية
      final rawData = _subCategoryData[categoryId]!;
      
      // تنظيف البيانات
      final cleanedData = rawData.map(_cleanSubCategoryData).toList();

      ErrorHandler.logInfo('Get SubCategories', 
          'Category: $categoryId, Count: ${cleanedData.length}');

      return cleanedData;
    } catch (error) {
      ErrorHandler.logError('Get SubCategories', error);
      return [];
    }
  }

  // تنظيف بيانات الفئة الفرعية
  static Map<String, dynamic> _cleanSubCategoryData(Map<String, dynamic> data) {
    try {
      final cleaned = <String, dynamic>{};

      // تنظيف العنوان
      if (data.containsKey('title') && data['title'] is String) {
        final title = data['title'] as String;
        cleaned['title'] = InputValidator.sanitizeInput(title);
      } else {
        cleaned['title'] = 'Unknown';
      }

      // التحقق من الأيقونة
      if (data.containsKey('icon') && data['icon'] is IconData) {
        cleaned['icon'] = data['icon'];
      } else {
        cleaned['icon'] = Icons.error;
      }

      return cleaned;
    } catch (error) {
      ErrorHandler.logError('Clean SubCategory Data', error);
      return {
        'title': 'Error',
        'icon': Icons.error,
      };
    }
  }

  // الحصول على عدد الفئات الفرعية
  static int getSubCategoryCount(String categoryId) {
    try {
      if (!_subCategoryData.containsKey(categoryId)) {
        return 0;
      }
      return _subCategoryData[categoryId]!.length;
    } catch (error) {
      ErrorHandler.logError('Get SubCategory Count', error);
      return 0;
    }
  }

  // التحقق من وجود فئات فرعية
  static bool hasSubCategories(String categoryId) {
    try {
      return _subCategoryData.containsKey(categoryId) && 
             _subCategoryData[categoryId]!.isNotEmpty;
    } catch (error) {
      ErrorHandler.logError('Has SubCategories', error);
      return false;
    }
  }

  // الحصول على عنوان الفئة الفرعية
  static String getSubCategoryTitle(String categoryId, int index) {
    try {
      final subCategories = _subCategoryData[categoryId];
      if (subCategories == null || index >= subCategories.length) {
        ErrorHandler.logError('Get SubCategory Title', 
            'Invalid index: $index for category: $categoryId');
        return '';
      }
      return subCategories[index]['title'] as String;
    } catch (error) {
      ErrorHandler.logError('Get SubCategory Title', error);
      return '';
    }
  }

  // الحصول على أيقونة الفئة الفرعية
  static IconData getSubCategoryIcon(String categoryId, int index) {
    try {
      final subCategories = _subCategoryData[categoryId];
      if (subCategories == null || index >= subCategories.length) {
        ErrorHandler.logError('Get SubCategory Icon', 
            'Invalid index: $index for category: $categoryId');
        return Icons.error;
      }
      return subCategories[index]['icon'] as IconData;
    } catch (error) {
      ErrorHandler.logError('Get SubCategory Icon', error);
      return Icons.error;
    }
  }

  // الحصول على جميع معرفات الفئات
  static List<String> getAllCategoryIds() {
    try {
      return _subCategoryData.keys.toList();
    } catch (error) {
      ErrorHandler.logError('Get All Category IDs', error);
      return [];
    }
  }

  // التحقق من وجود الفئة
  static bool categoryExists(String categoryId) {
    try {
      return _subCategoryData.containsKey(categoryId);
    } catch (error) {
      ErrorHandler.logError('Category Exists', error);
      return false;
    }
  }

  // بحث آمن في الفئات الفرعية
  static List<Map<String, dynamic>> searchSubCategories(String query) {
    try {
      if (query.isEmpty) {
        return [];
      }

      // تنظيف الاستعلام
      final sanitizedQuery = InputValidator.sanitizeInput(query);
      if (sanitizedQuery.isEmpty) {
        return [];
      }

      final lowercaseQuery = sanitizedQuery.toLowerCase();
      final results = <Map<String, dynamic>>[];
      
      for (final category in _subCategoryData.values) {
        for (final subCategory in category) {
          final title = subCategory['title'] as String;
          if (title.toLowerCase().contains(lowercaseQuery)) {
            results.add(_cleanSubCategoryData(subCategory));
          }
        }
      }

      ErrorHandler.logInfo('Search SubCategories', 
          'Query: "$sanitizedQuery", Results: ${results.length}');

      return results;
    } catch (error) {
      ErrorHandler.logError('Search SubCategories', error);
      return [];
    }
  }

  // الحصول على معلومات الفئة
  static Map<String, dynamic> getCategoryInfo(String categoryId) {
    try {
      if (!categoryExists(categoryId)) {
        return {
          'exists': false,
          'error': 'Category not found',
        };
      }

      final subCategories = _subCategoryData[categoryId]!;
      
      return {
        'exists': true,
        'categoryId': categoryId,
        'subCategoryCount': subCategories.length,
        'titles': subCategories.map((cat) => cat['title'] as String).toList(),
        'hasSubCategories': subCategories.isNotEmpty,
      };
    } catch (error) {
      ErrorHandler.logError('Get Category Info', error);
      return {
        'exists': false,
        'error': ErrorHandler.getSafeError(error),
      };
    }
  }
}
