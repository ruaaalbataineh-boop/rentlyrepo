import 'package:flutter_test/flutter_test.dart';
import 'package:p2/models/Item.dart';
import 'package:p2/models/item_extensions.dart' show RentalType, rentalTypeFromKey, ItemPriceExtension;

void main() {
  group('RentalType & ItemPriceExtension Tests', () {
    
    final sampleItem = Item.sanitized(
      id: "item001",
      name: "Camera",
      description: "HD Camera",
      category: "Electronics",
      subCategory: "Photography",
      ownerId: "owner001",
      ownerName: "Alice",
      images: ["img1.png"],
      rentalPeriods: {"hourly": 5, "daily": 20, "weekly": 100},
      insurance: "optional",
      averageRating: 4.5,
      ratingCount: 10,
      status: "approved",
    );

    test('rentalTypeFromKey returns correct enum', () {
      expect(rentalTypeFromKey("hourly"), RentalType.hourly);
      expect(rentalTypeFromKey("daily"), RentalType.daily);
      expect(rentalTypeFromKey("weekly"), RentalType.weekly);
      expect(rentalTypeFromKey("monthly"), RentalType.monthly);
      expect(rentalTypeFromKey("yearly"), RentalType.yearly);

      expect(() => rentalTypeFromKey("unknown"), throwsA(isA<Exception>()));
    });

    test('getPrice returns correct price for each type', () {
      expect(sampleItem.getPrice(RentalType.hourly), 5.0);
      expect(sampleItem.getPrice(RentalType.daily), 20.0);
      expect(sampleItem.getPrice(RentalType.weekly), 100.0);

     
      expect(sampleItem.getPrice(RentalType.monthly), 0.0);
      expect(sampleItem.getPrice(RentalType.yearly), 0.0);
    });

    test('getPrice handles numeric types correctly', () {
      
      final itemWithDouble = sampleItem.copyWith(
        rentalPeriods: {"hourly": 7.5},
      );
      expect(itemWithDouble.getPrice(RentalType.hourly), 7.5);
    });
  });
}
