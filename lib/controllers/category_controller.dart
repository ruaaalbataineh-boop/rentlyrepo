import 'package:flutter/material.dart';
import '../models/Item.dart';
import '../models/equipment_category.dart';

class CategoryController {
  static final List<EquipmentCategory> _categories = [
    EquipmentCategory(id: 'c1', title: 'Electronics', icon: Icons.headphones),
    EquipmentCategory(id: 'c2', title: 'Computers & Mobiles', icon: Icons.devices),
    EquipmentCategory(id: 'c3', title: 'Video Games', icon: Icons.sports_esports),
    EquipmentCategory(id: 'c4', title: 'Sports & Hobbies', icon: Icons.directions_bike),
    EquipmentCategory(id: 'c5', title: 'Tools & Devices', icon: Icons.handyman),
    EquipmentCategory(id: 'c6', title: 'Home & Garden', icon: Icons.grass),
    EquipmentCategory(id: 'c7', title: 'Fashion & Clothing', icon: Icons.checkroom),
  ];

  static List<EquipmentCategory> filter(String query) {
    if (query.isEmpty) return _categories;

    final q = query.toLowerCase();

    return _categories
        .where((c) => c.title.toLowerCase().contains(q))
        .toList();
  }
}
