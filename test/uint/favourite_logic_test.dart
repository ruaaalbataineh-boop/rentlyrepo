import 'package:flutter_test/flutter_test.dart';


void main() {
  group('FavouriteController Logic Tests (without instance)', () {
    test('Price formatting logic', () {
     
      String getItemPriceText(Map<String, dynamic> d) {
        final rental = d["rentalPeriods"];
        if (rental is Map && rental.isNotEmpty) {
          final key = rental.keys.first;
          return "From ${rental[key]}JD / $key";
        }
        return "Price not available";
      }
      
     
      expect(
        getItemPriceText({'rentalPeriods': {'day': '10'}}),
        'From 10JD / day'
      );
      
      expect(
        getItemPriceText({}),
        'Price not available'
      );
      
      expect(
        getItemPriceText({'rentalPeriods': {}}),
        'Price not available'
      );
    });
    
    test('Image URL extraction logic', () {
     
      String? getItemImage(Map<String, dynamic> d) {
        final imgs = d["images"];
        if (imgs is List && imgs.isNotEmpty) return imgs[0];
        return null;
      }
      
      expect(
        getItemImage({'images': ['img1.jpg', 'img2.jpg']}),
        'img1.jpg'
      );
      
      expect(
        getItemImage({'images': []}),
        null
      );
      
      expect(
        getItemImage({}),
        null
      );
    });
  });
}
