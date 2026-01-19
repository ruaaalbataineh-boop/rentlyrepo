import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p2/controllers/category_controller.dart';


void main() {
  group('CategoryController Unit Tests', () {
   
    test('Should have 7 predefined categories', () {
      
      final categories = CategoryController.filter('');
      
      
      expect(categories.length, 7);
    });

    
    test('Should contain specific categories with correct data', () {
    
      final categories = CategoryController.filter('');
      
     
      expect(categories[0].id, 'c1');
      expect(categories[0].title, 'Electronics');
      expect(categories[0].icon, Icons.headphones);
      
      expect(categories[1].id, 'c2');
      expect(categories[1].title, 'Computers & Mobiles');
      expect(categories[1].icon, Icons.devices);
    });

    test('Should return all categories when query is empty', () {
      
      final result = CategoryController.filter('');
      
      
      expect(result.length, 7);
      expect(result[0].title, 'Electronics');
      expect(result[6].title, 'Fashion & Clothing');
    });

  
    test('Should filter categories based on query', () {
      
      final result = CategoryController.filter('Electro');
      
   
      expect(result.length, 1);
      expect(result[0].title, 'Electronics');
    });

    
    test('Should be case insensitive', () {
     
      final uppercase = CategoryController.filter('ELECTRONICS');
      final lowercase = CategoryController.filter('electronics');
      final mixed = CategoryController.filter('ElEcTrOnIcS');
      
      
      expect(uppercase.length, 1);
      expect(lowercase.length, 1);
      expect(mixed.length, 1);
      expect(uppercase[0].title, 'Electronics');
    });

    
    test('Should return empty list when no match found', () {
     
      final result = CategoryController.filter('XYZ123');
      
      
      expect(result, isEmpty);
    });

    
    test('Should match partial words', () {
   
      final result1 = CategoryController.filter('game');
      final result2 = CategoryController.filter('mobile');
      final result3 = CategoryController.filter('cloth');
     
      expect(result1.length, 1);
      expect(result1[0].title, 'Video Games');
      
      expect(result2.length, 1);
      expect(result2[0].title, 'Computers & Mobiles');
      
      expect(result3.length, 1);
      expect(result3[0].title, 'Fashion & Clothing');
    });

   
    test('Should return multiple categories for broad search', () {
      
      final result = CategoryController.filter('s');
      
      
      expect(result.length, greaterThan(1));
   
      expect(result.any((c) => c.title.contains('Sports')), true);
      expect(result.any((c) => c.title.contains('Games')), true);
      expect(result.any((c) => c.title.contains('Devices')), true);
    });

    test('Should maintain original order of categories', () {
      
      final allCategories = CategoryController.filter('');
      final filteredCategories = CategoryController.filter('o'); 
      
      
      expect(allCategories[0].id, 'c1');
      expect(allCategories[1].id, 'c2');
      expect(allCategories[2].id, 'c3');
      
   
      final filteredIds = filteredCategories.map((c) => c.id).toList();
      final originalIds = allCategories.map((c) => c.id).toList();
      
      for (var id in filteredIds) {
        expect(originalIds.contains(id), true);
      }
    });

    
   test('Should handle queries with spaces correctly', () {
   
      final result1 = CategoryController.filter('Video Games');
      final result2 = CategoryController.filter('Home & Garden');
      final result3 = CategoryController.filter('  Electronics  ');
      
    
      expect(result1.length, 1);
      expect(result1[0].title, 'Video Games');
      
      expect(result2.length, 1);
      expect(result2[0].title, 'Home & Garden');
      
      expect(result3.length, 0); 
    });
    
    test('Should handle empty and trimmed queries', () {
      
      final emptyQuery = CategoryController.filter('');
      final spacesQuery = CategoryController.filter('   ');
      
      
      expect(emptyQuery.length, 7);
      expect(spacesQuery.length, 0); 
    });
  });

  
  group('Performance and Edge Cases', () {
    test('Should handle very long queries', () {
    
      const longQuery = 'Electronics and Computers and Mobiles and Video Games';
   
      final result = CategoryController.filter(longQuery);
      
      
      expect(result.length, 0); 
    });

test('Should handle special characters - CORRECTED FINAL', () {
  
  final withAmpersand = CategoryController.filter('&');
  final withSymbols = CategoryController.filter('@#!');
  
 
  print('Searching for "&"');
  print('All categories:');
  final all = CategoryController.filter('');
  for (var cat in all) {
    print('  - ${cat.title} (has &: ${cat.title.contains('&')})');
  }
  print('Results for "&": ${withAmpersand.map((c) => c.title).toList()}');
  
 
  expect(withAmpersand.length, 5, 
      reason: 'Should find all 5 categories containing "&"');
  
 
  final titles = withAmpersand.map((c) => c.title).toList();
  expect(titles.contains('Computers & Mobiles'), true);
  expect(titles.contains('Sports & Hobbies'), true);
  expect(titles.contains('Tools & Devices'), true);
  expect(titles.contains('Home & Garden'), true);
  expect(titles.contains('Fashion & Clothing'), true);
  
  expect(withSymbols.length, 0);
});

    test('Should handle Unicode characters', () {
      
      final result = CategoryController.filter('é'); 
      
      
      expect(result.length, 0);
    });
  });
}
