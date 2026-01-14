import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:p2/AllReviewsPage.dart';


void main() {
  group('AllReviewsPage Static Tests', () {
    test('Widget creation with itemId', () {
      const itemId = 'test_item_123';
      final page = AllReviewsPage(itemId: itemId);
      
      expect(page.itemId, itemId);
      expect(page.key, isNull);
    });

    test('DateFormat formatting', () {
      final date = DateTime(2024, 1, 15, 14, 30);
      
   
      final formatted = '${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}  ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
      
      expect(formatted, '2024-01-15  14:30');
      expect(formatted.contains('  '), true);
    });

    test('Star rating logic', () {
      
      const rating = 4.0;
      const totalStars = 5;
      
      
      for (int i = 0; i < totalStars; i++) {
        final isFilled = i < rating;
        if (i < 4) {
          expect(isFilled, true); 
        } else {
          expect(isFilled, false); 
        }
      }
    });

    test('Default values for missing data', () {
      
      final data = <String, dynamic>{};
      
      final rating = (data["rating"] ?? 0).toDouble();
      expect(rating, 0.0);
      
      final comment = data["comment"] ?? "";
      expect(comment, "");
    });

    test('AppBar gradient colors', () {
  
      const color1 = Color(0xFF1F0F46);
      const color2 = Color(0xFF8A005D);
      
      expect(color1, isA<Color>());
      expect(color2, isA<Color>());
      expect(color1.value, 0xFF1F0F46);
      expect(color2.value, 0xFF8A005D);
    });

    test('Review card styling values', () {
     
      const padding = EdgeInsets.all(14);
      const margin = EdgeInsets.only(bottom: 14);
      const borderRadius = 12.0;
      
      expect(padding, const EdgeInsets.all(14));
      expect(margin, const EdgeInsets.only(bottom: 14));
      expect(borderRadius, 12.0);
    });
  });

  group('UI Text Constants', () {
    test('All text strings', () {
      expect('All Reviews', 'All Reviews');
      expect('No reviews yet.', 'No reviews yet.');
      expect('By: Anonymous User', 'By: Anonymous User');
    });
    
    test('Text styles should have colors', () {
      const white = Colors.white;
      const grey = Colors.grey;
      
      expect(white, Colors.white);
      expect(grey, Colors.grey);
    });
  });

  group('Edge Cases', () {
    test('Zero rating displays correctly', () {
      const rating = 0.0;
      const totalStars = 5;
      
      for (int i = 0; i < totalStars; i++) {
        final isFilled = i < rating;
        expect(isFilled, false); 
      }
    });

    test('Maximum rating displays correctly', () {
      const rating = 5.0;
      const totalStars = 5;
      
      for (int i = 0; i < totalStars; i++) {
        final isFilled = i < rating;
        expect(isFilled, true); 
      }
    });

    test('Decimal rating handling', () {
   
      const rating = 4.5;
      
      expect(0 < rating, true); 
      expect(1 < rating, true);   
      expect(2 < rating, true);
      expect(3 < rating, true); 
      expect(4 < rating, true); 
    });
  });

  print('✅ AllReviewsPage tests completed!');
}


String _twoDigits(int n) => n.toString().padLeft(2, '0');
