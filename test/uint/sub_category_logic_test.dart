import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/sub_category_logic.dart';
import 'package:flutter/material.dart';

void main() {
  group('SubCategoryLogic Tests', () {
    test('getSubCategories returns data for valid category', () {
      final list = SubCategoryLogic.getSubCategories('c1');
      expect(list.isNotEmpty, true);
      expect(list[0]['title'], 'Cameras & Photography');
      expect(list[0]['icon'], isA<IconData>());
    });

    test('getSubCategories returns empty for invalid category', () {
      final list = SubCategoryLogic.getSubCategories('invalid');
      expect(list.isEmpty, true);
    });

    test('getSubCategoryCount returns correct count', () {
      final count = SubCategoryLogic.getSubCategoryCount('c2');
      expect(count, 5);
    });

    test('categoryExists returns true for existing category', () {
      expect(SubCategoryLogic.categoryExists('c3'), true);
    });

    test('categoryExists returns false for non-existing category', () {
      expect(SubCategoryLogic.categoryExists('nonexistent'), false);
    });

    test('searchSubCategories finds matching sub-categories', () {
      final results = SubCategoryLogic.searchSubCategories('audio');
      expect(results.length, 1);
      expect(results[0]['title'], 'Audio & Video');
    });
  });
}
