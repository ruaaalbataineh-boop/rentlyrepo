import 'package:flutter_test/flutter_test.dart';


enum RentalType { daily, weekly, monthly, yearly }

RentalType rentalTypeFromKey(String key) {
  switch (key.toLowerCase()) {
    case "daily": return RentalType.daily;
    case "weekly": return RentalType.weekly;
    case "monthly": return RentalType.monthly;
    case "yearly": return RentalType.yearly;
    default: throw Exception("Unknown rental period: $key");
  }
}


class MockItem {
  final Map<String, dynamic> rentalPeriods;
  
  MockItem(this.rentalPeriods);
  
  double getPrice(RentalType type) {
    String key = type.toString().split('.').last;
    if (rentalPeriods.containsKey(key)) {
      return (rentalPeriods[key] as num).toDouble();
    }
    return 0.0;
  }
}

void main() {
  group('Basic Rental Tests', () {
    test('rentalTypeFromKey works for all cases', () {
      expect(rentalTypeFromKey('daily'), RentalType.daily);
      expect(rentalTypeFromKey('weekly'), RentalType.weekly);
      expect(rentalTypeFromKey('monthly'), RentalType.monthly);
      expect(rentalTypeFromKey('yearly'), RentalType.yearly);
      expect(rentalTypeFromKey('DAILY'), RentalType.daily);
    });

    test('rentalTypeFromKey throws for invalid keys', () {
      expect(() => rentalTypeFromKey(''), throwsException);
      expect(() => rentalTypeFromKey('hourly'), throwsException);
    });

    test('getPrice returns correct price', () {
      final item = MockItem({'daily': 50, 'weekly': 300});
      expect(item.getPrice(RentalType.daily), 50.0);
      expect(item.getPrice(RentalType.weekly), 300.0);
      expect(item.getPrice(RentalType.monthly), 0.0); 
    });

    test('getPrice returns 0 for missing prices', () {
      final item = MockItem({});
      expect(item.getPrice(RentalType.daily), 0.0);
    });
  });
}
