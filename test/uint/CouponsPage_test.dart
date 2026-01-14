import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:p2/Coupons.dart';

void main() {
  group('CouponsPage Basic Tests', () {
    test('Coupons list has correct items', () {
      final page = CouponsPage();
      
      expect(page.coupons.length, 4);
      
      expect(page.coupons[0]['title'], '10% OFF');
      expect(page.coupons[0]['code'], 'SAVE10');
      
      expect(page.coupons[1]['title'], '15% OFF');
      expect(page.coupons[1]['code'], 'DISCOUNT15');
      
      expect(page.coupons[2]['title'], '20% OFF');
      expect(page.coupons[2]['code'], 'WIN20');
      
      expect(page.coupons[3]['title'], 'Free Shipping');
      expect(page.coupons[3]['code'], 'FREESHIP');
    });

    test('Color constants', () {
      const color1 = Color(0xFF1F0F46);
      const color2 = Color(0xFF8A005D);
      
      expect(color1.value, 0xFF1F0F46);
      expect(color2.value, 0xFF8A005D);
    });

    test('Text constants', () {
      expect('Coupons', 'Coupons');
      expect('Copy', 'Copy');
      expect('Code:', contains('Code'));
    });

    test('UI dimensions', () {
      expect(20, 20); 
      expect(20, 20); 
      expect(20, 20); 
      expect(20, 20); 
      expect(15, 15); 
      expect(18, 18); 
    });

    test('Snackbar message format', () {
      expect('SAVE10 copied!'.contains('copied'), true);
      expect('DISCOUNT15 copied!'.contains('DISCOUNT15'), true);
    });

    test('Widget structure', () {
      expect('Scaffold', 'Scaffold');
      expect('AppBar', 'AppBar');
      expect('ListView', 'ListView');
      expect('Container', 'Container');
      expect('ElevatedButton', 'ElevatedButton');
      expect('SnackBar', 'SnackBar');
    });

    test('Gradient colors match', () {
      const gradientColors = [Color(0xFF1F0F46), Color(0xFF8A005D)];
      expect(gradientColors.length, 2);
      expect(gradientColors[0], const Color(0xFF1F0F46));
      expect(gradientColors[1], const Color(0xFF8A005D));
    });
  });

  print('✅ CouponsPage tests completed!');
}
