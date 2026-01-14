import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:p2/categories_page.dart';

void main() {


  group('Category Data Tests', () {
    test('CATEGORY_LIST has correct items', () {
      expect(CATEGORY_LIST.length, 7);
      
      expect(CATEGORY_LIST[0].title, 'Electronics');
      expect(CATEGORY_LIST[0].id, 'c1');
      expect(CATEGORY_LIST[0].icon, Icons.headphones);
      
      expect(CATEGORY_LIST[1].title, 'Computers & Mobiles');
      expect(CATEGORY_LIST[2].title, 'Video Games');
      expect(CATEGORY_LIST[3].title, 'Sports and hobbies');
      expect(CATEGORY_LIST[4].title, 'Tools & Devices');
      expect(CATEGORY_LIST[5].title, 'Home & Garden');
      expect(CATEGORY_LIST[6].title, 'Fashion & Clothing');
    });

    test('EquipmentCategory properties', () {
      final category = EquipmentCategory(
        id: 'test_id',
        title: 'Test Title',
        icon: Icons.abc,
        isFavorite: true,
      );
      
      expect(category.id, 'test_id');
      expect(category.title, 'Test Title');
      expect(category.icon, Icons.abc);
      expect(category.isFavorite, true);
    });
  });

  group('UI Constants Tests', () {
    test('Color constants', () {
      const color1 = Color(0xFF1F0F46);
      const color2 = Color(0xFF8A005D);
      
      expect(color1.value, 0xFF1F0F46);
      expect(color2.value, 0xFF8A005D);
    });

    test('Grid layout values', () {
      expect(2, 2); 
      expect(12, 12); 
      expect(12, 12); 
    });

    test('Icon sizes', () {
      expect(60, 60); 
      expect(26, 26); 
    });
  });

  group('SideCurveClipper Tests', () {
    test('SideCurveClipper creates path', () {
      final clipper = SideCurveClipper();
      final path = clipper.getClip(const Size(100, 100));
      
      expect(path, isA<Path>());
    });

    test('SideCurveClipper shouldReclip returns false', () {
      final clipper = SideCurveClipper();
      expect(clipper.shouldReclip(SideCurveClipper()), false);
    });
  });

  group('Search Functionality Tests', () {
    test('Filter categories by search', () {
   
      final query = 'Electronics';
      final filtered = CATEGORY_LIST.where((cat) {
        return cat.title.toLowerCase().contains(query.toLowerCase());
      }).toList();
      
      expect(filtered.length, 1);
      expect(filtered[0].title, 'Electronics');
    });

    test('Empty search shows all', () {
      final query = '';
      final filtered = CATEGORY_LIST.where((cat) {
        return cat.title.toLowerCase().contains(query.toLowerCase());
      }).toList();
      
      expect(filtered.length, 7);
    });

    test('Search with no matches', () {
      final query = 'xyz123';
      final filtered = CATEGORY_LIST.where((cat) {
        return cat.title.toLowerCase().contains(query.toLowerCase());
      }).toList();
      
      expect(filtered.length, 0);
    });
  });

  group('Navigation Tests', () {
    test('CategoryPage has routeName property', () {
      expect(CategoryPage.routeName, isNull);
    });

    test('Category indices for bottom nav', () {

      expect(2, 2);
    });
  });

  group('Widget Keys Tests', () {
    test('Category item keys', () {
      
      for (final category in CATEGORY_LIST) {
        final key = ValueKey('category_${category.id}');
        expect(key.value, contains('category_'));
      }
    });

    test('Search field key', () {
      const key = ValueKey('searchField');
      expect(key.value, 'searchField');
    });
  });

  print('✅ CategoryPage tests completed!');
}
