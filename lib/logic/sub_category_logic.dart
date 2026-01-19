import 'package:flutter/material.dart';

class SubCategoryLogic {

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

  static List<Map<String, dynamic>> getSubCategories(String categoryId) {
    return _subCategoryData[categoryId] ?? [];
  }

  static bool categoryExists(String categoryId) {
    return _subCategoryData.containsKey(categoryId);
  }

  static bool hasSubCategories(String categoryId) {
    return _subCategoryData[categoryId]?.isNotEmpty ?? false;
  }

  static List<String> getAllCategoryIds() {
    return _subCategoryData.keys.toList();
  }

  static List<Map<String, dynamic>> searchSubCategories(String query) {
    if (query.isEmpty) return [];

    final lower = query.toLowerCase();
    final results = <Map<String, dynamic>>[];

    for (final list in _subCategoryData.values) {
      for (final sub in list) {
        final title = sub["title"] as String;
        if (title.toLowerCase().contains(lower)) {
          results.add(sub);
        }
      }
    }

    return results;
  }
}
