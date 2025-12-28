import 'package:flutter_test/flutter_test.dart';
import 'package:p2/models/Item.dart';
import 'package:p2/models/item_extensions.dart';

void main() {
  group('ItemPriceExtension getPrice', () {
    late Item item;

    setUp(() {
      item = Item(
        id: '1',
        name: 'Test Item',
        description: 'Description',
        category: 'Electronics',
        subCategory: 'Audio',
        ownerId: 'owner1',
        ownerName: 'Owner Name',
        images: [],
        rentalPeriods: {
          'hourly': 5,
          'daily': 20,
          'weekly': 100,
          'monthly': '300', // String value
        },
        insurance: null,
        latitude: null,
        longitude: null,
        averageRating: 0,
        ratingCount: 0,
        status: 'approved',
      );
    });

    test('Returns correct double for int value', () {
      expect(ItemPriceExtension(item).getPrice(RentalType.hourly), 5.0);
      expect(ItemPriceExtension(item).getPrice(RentalType.daily), 20.0);
      expect(ItemPriceExtension(item).getPrice(RentalType.weekly), 100.0);
    });

    test('Parses String to double', () {
      expect(ItemPriceExtension(item).getPrice(RentalType.monthly), 300.0);
    });

    test('Returns 0.0 for missing rental period', () {
      expect(ItemPriceExtension(item).getPrice(RentalType.yearly), 0.0);
    });

    test('Returns 0.0 for invalid String', () {
      item.rentalPeriods['yearly'] = 'invalid';
      expect(ItemPriceExtension(item).getPrice(RentalType.yearly), 0.0);
    });
  });
}


extension ItemPriceExtension on Item {
  double getPrice(RentalType type) {
    String key = type.toString().split('.').last; // hourly, daily, weekly...

    final value = rentalPeriods[key];

    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value) ?? 0.0;
    } else {
      return 0.0;
    }
  }
}
