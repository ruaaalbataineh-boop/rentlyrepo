import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/rental_logic.dart';

void main() {
  group('RentalCalculator', () {
    final basePrice = 10.0;
    final today = DateTime(2024, 1, 1); 
    final tomorrow = DateTime(2024, 1, 2);

    final startTime = TimeOfDay(hour: 9, minute: 0);
    final endTime = TimeOfDay(hour: 17, minute: 0);

    group('calculateTotalPrice - Hourly', () {
      test('1 hour should return base price', () {
        final price = RentalCalculator.calculateTotalPrice(
          rentalType: RentalType.hourly,
          basePrice: basePrice,
          startDate: today,
          endDate: today,
          startTime: startTime,
          endTime: TimeOfDay(hour: 10, minute: 0),
        );
        expect(price, 10.0);
      });

      test('8 hours should return 8 * base price', () {
        final price = RentalCalculator.calculateTotalPrice(
          rentalType: RentalType.hourly,
          basePrice: basePrice,
          startDate: today,
          endDate: today,
          startTime: startTime,
          endTime: endTime,
        );
        expect(price, 80.0);
      });

      test('should return 0 when end time before start time', () {
        final price = RentalCalculator.calculateTotalPrice(
          rentalType: RentalType.hourly,
          basePrice: basePrice,
          startDate: today,
          endDate: today,
          startTime: endTime,
          endTime: startTime,
        );
        expect(price, 0.0);
      });
    });

    group('calculateTotalPrice - Daily', () {
      test('same day should return base price', () {
        final price = RentalCalculator.calculateTotalPrice(
          rentalType: RentalType.daily,
          basePrice: basePrice,
          startDate: today,
          endDate: today,
          startTime: null,
          endTime: null,
        );
        expect(price, 10.0);
      });

      test('3 days should return 3 * base price', () {
        final price = RentalCalculator.calculateTotalPrice(
          rentalType: RentalType.daily,
          basePrice: basePrice,
          startDate: today,
          endDate: DateTime(2024, 1, 3),
          startTime: null,
          endTime: null,
        );
        expect(price, 30.0);
      });

      test('should return 0 when end date before start date', () {
        final price = RentalCalculator.calculateTotalPrice(
          rentalType: RentalType.daily,
          basePrice: basePrice,
          startDate: tomorrow,
          endDate: today,
          startTime: null,
          endTime: null,
        );
        expect(price, 0.0);
      });
    });

    group('calculateTotalHours', () {
      test('hourly - 8 hours difference', () {
        final hours = RentalCalculator.calculateTotalHours(
          rentalType: RentalType.hourly,
          startDate: today,
          endDate: today,
          startTime: startTime,
          endTime: endTime,
        );
        expect(hours, 8.0);
      });

      test('daily - same day should be 24 hours', () {
        final hours = RentalCalculator.calculateTotalHours(
          rentalType: RentalType.daily,
          startDate: today,
          endDate: today,
          startTime: null,
          endTime: null,
        );
        expect(hours, 24.0);
      });

      test('daily - 3 days should be 72 hours', () {
        final hours = RentalCalculator.calculateTotalHours(
          rentalType: RentalType.daily,
          startDate: today,
          endDate: DateTime(2024, 1, 3),
          startTime: null,
          endTime: null,
        );
        expect(hours, 72.0); 
      });
    });

    group('isValidRentalTypeForDuration', () {
      test('hourly - 8 hours should be valid', () {
        final isValid = RentalCalculator.isValidRentalTypeForDuration(
          rentalType: RentalType.hourly,
          startDate: today,
          endDate: today,
          startTime: startTime,
          endTime: endTime,
        );
        expect(isValid, true);
      });

    test('hourly - 25 hours across two days should be invalid', () {
  final isValid = RentalCalculator.isValidRentalTypeForDuration(
    rentalType: RentalType.hourly,
    startDate: today,
    endDate: tomorrow, 
    startTime: TimeOfDay(hour: 9, minute: 0),
    endTime: TimeOfDay(hour: 10, minute: 0), 
  );
  expect(isValid, false); 
});

test('hourly - same day 8 hours should be valid', () {
  final isValid = RentalCalculator.isValidRentalTypeForDuration(
    rentalType: RentalType.hourly,
    startDate: today,
    endDate: today, 
    startTime: TimeOfDay(hour: 9, minute: 0),
    endTime: TimeOfDay(hour: 17, minute: 0), 
  );
  expect(isValid, true);
});

      test('daily - 3 days should be valid', () {
        final isValid = RentalCalculator.isValidRentalTypeForDuration(
          rentalType: RentalType.daily,
          startDate: today,
          endDate: DateTime(2024, 1, 3),
          startTime: null,
          endTime: null,
        );
        expect(isValid, true);
      });
    });

    group('Edge Cases', () {
      test('null dates should return 0 price', () {
        final price = RentalCalculator.calculateTotalPrice(
          rentalType: RentalType.daily,
          basePrice: basePrice,
          startDate: null,
          endDate: null,
          startTime: null,
          endTime: null,
        );
        expect(price, 0.0);
      });

      test('null times for hourly should return 0', () {
        final price = RentalCalculator.calculateTotalPrice(
          rentalType: RentalType.hourly,
          basePrice: basePrice,
          startDate: today,
          endDate: today,
          startTime: null,
          endTime: null,
        );
        expect(price, 0.0);
      });
    });
  });
}
