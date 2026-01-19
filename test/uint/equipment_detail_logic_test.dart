import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:p2/controllers/equipment_detail_controller.dart';
import 'package:p2/models/Item.dart';
import 'package:p2/services/equipment_detail_service.dart';



class MockEquipmentDetailService extends Mock implements EquipmentDetailService {}

void main() {
  group('EquipmentDetailController Tests', () {
    late EquipmentDetailController controller;
    late MockEquipmentDetailService mockService;


 final insurance = Insurance(
      amount: 500.0,
      originalPrice: 5000.0,
      rate: 0.1,
    );
    final testItem = Item(
      id: 'item123',
      name: 'Test Item',
      description: 'Test Description',
      category: 'Electronics',
      subCategory: 'Cameras',
      ownerId: 'owner123',
      ownerName: 'John Doe',
      images: ['https://example.com/image.jpg'],
      rentalPeriods: {
        'daily': 10.0,
        'weekly': 60.0,
        'monthly': 250.0,
        'yearly': 3000.0,
      },
      insurance: insurance, 
      averageRating: 4.5,
      ratingCount: 10,
      status: 'approved',
   
      latitude: null,
      longitude: null,
      submittedAt: null,
      updatedAt: null,
    );

    setUp(() {
  mockService = MockEquipmentDetailService();
  controller = EquipmentDetailController(mockService);
  
 
  controller.item = Item(
    id: 'default',
    name: 'Default Item',
    description: '',
    category: '',
    subCategory: '',
    ownerId: '',
    ownerName: '',
    images: [],
    rentalPeriods: {'daily': 0.0},
    insurance: Insurance(
      amount: 0.0,
      originalPrice: 0.0,
      rate: 0.0,
    ),
    averageRating: 0,
    ratingCount: 0,
    status: '',
  );
});

    
    test('initial state is correct', () {
      expect(controller.isLoading, true);
      expect(controller.ownerName, 'Loading...');
      expect(controller.renterWallet, 0.0);
      expect(controller.topReviews, isEmpty);
      expect(controller.unavailableRanges, isEmpty);
      expect(controller.selectedPeriod, isNull);
      expect(controller.startDate, isNull);
      expect(controller.endDate, isNull);
      expect(controller.count, 1);
      expect(controller.pickupTime, isNull);
      expect(controller.insuranceAccepted, false);
    });

   
    test('selectPeriod resets fields correctly', () {
  
  controller.item = Item(
    id: 'test',
    name: 'Test',
    description: '',
    category: '',
    subCategory: '',
    ownerId: '',
    ownerName: '',
    images: [],
    rentalPeriods: {'daily': 10.0, 'weekly': 50.0},
    insurance: Insurance(
      amount: 100.0,
      originalPrice: 1000.0,
      rate: 0.1,
    ),
    averageRating: 0,
    ratingCount: 0,
    status: '',
  );

  // Set some initial values
  controller.selectedPeriod = 'daily';
  controller.startDate = DateTime.now();
  controller.endDate = DateTime.now();
  controller.count = 5;
  controller.pickupTime = '10:00';
  controller.insuranceAccepted = true;

  controller.selectPeriod('weekly');

  expect(controller.selectedPeriod, 'weekly');
  expect(controller.startDate, isNull);
  expect(controller.endDate, isNull);
  expect(controller.count, 1);
  expect(controller.pickupTime, isNull);
  expect(controller.insuranceAccepted, false);
});
  
    test('incrementCount increases count', () {
      controller.count = 1;
      controller.incrementCount();
      expect(controller.count, 2);
    });

   
    test('decrementCount does not go below 1', () {
      controller.count = 1;
      controller.decrementCount();
      expect(controller.count, 1);
    });

    test('decrementCount decreases count when above 1', () {
      controller.count = 3;
      controller.decrementCount();
      expect(controller.count, 2);
    });

    
    test('setPickupTime updates pickup time', () {
      controller.setPickupTime('14:30');
      expect(controller.pickupTime, '14:30');
    });

  
    test('setInsuranceAccepted updates value', () {
      controller.setInsuranceAccepted(true);
      expect(controller.insuranceAccepted, true);
      
      controller.setInsuranceAccepted(false);
      expect(controller.insuranceAccepted, false);
    });

  
    test('calculateEndDate for daily period', () {
      controller.selectedPeriod = 'daily';
      controller.startDate = DateTime(2024, 1, 1);
      controller.count = 3;
      
      controller.calculateEndDate();
      
      expect(controller.endDate, DateTime(2024, 1, 4)); 
    });

    test('calculateEndDate for weekly period', () {
      controller.selectedPeriod = 'weekly';
      controller.startDate = DateTime(2024, 1, 1);
      controller.count = 2;
      
      controller.calculateEndDate();
      
      expect(controller.endDate, DateTime(2024, 1, 15));
    });

    test('calculateEndDate returns null when no period', () {
      controller.selectedPeriod = null;
      controller.startDate = DateTime.now();
      
      controller.calculateEndDate();
      
      expect(controller.endDate, isNull);
    });

    
    test('computeRentalPrice for daily period', () {
      controller.item = testItem;
      controller.selectedPeriod = 'daily';
      controller.count = 2;
      
      final price = controller.computeRentalPrice();
      
      expect(price, 20.0); 
    });

    test('computeInsuranceAmount calculates correctly', () {
      controller.insuranceInfo = {
        'itemOriginalPrice': 5000.0,
        'ratePercentage': 0.1,
      };
      
      final amount = controller.computeInsuranceAmount();
      
      expect(amount, 500.0);
    });

    test('computeInsuranceAmount returns 0 when no info', () {
      controller.insuranceInfo = null;
      
      final amount = controller.computeInsuranceAmount();
      
      expect(amount, 0.0);
    });

  
    test('checkDateConflict returns true when overlap', () {
      controller.startDate = DateTime(2024, 1, 10);
      controller.endDate = DateTime(2024, 1, 15);
      controller.unavailableRanges = [
        DateTimeRange(
          start: DateTime(2024, 1, 12),
          end: DateTime(2024, 1, 18),
        ),
      ];
      
      final conflict = controller.checkDateConflict();
      
      expect(conflict, true);
    });

    test('checkDateConflict returns false when no overlap', () {
      controller.startDate = DateTime(2024, 1, 10);
      controller.endDate = DateTime(2024, 1, 15);
      controller.unavailableRanges = [
        DateTimeRange(
          start: DateTime(2024, 1, 20),
          end: DateTime(2024, 1, 25),
        ),
      ];
      
      final conflict = controller.checkDateConflict();
      
      expect(conflict, false);
    });

  
    test('getUnitLabel returns correct labels', () {
      controller.selectedPeriod = 'daily';
      expect(controller.getUnitLabel(), 'Days');
      
      controller.selectedPeriod = 'weekly';
      expect(controller.getUnitLabel(), 'Weeks');
      
      controller.selectedPeriod = 'monthly';
      expect(controller.getUnitLabel(), 'Months');
      
      controller.selectedPeriod = 'yearly';
      expect(controller.getUnitLabel(), 'Years');
    });

    test('formatEndDate returns formatted string', () {
      controller.endDate = DateTime(2024, 12, 25);
      expect(controller.formatEndDate(), '2024-12-25');
    });

    test('penaltyMessage returns correct message', () {
      expect(controller.penaltyMessage, 
          'Late return will result in penalties based on daily rate.');
    });

    // Test 11: Buffer days
    test('applyBuffer adds buffer to date ranges', () {
      final ranges = [
        DateTimeRange(
          start: DateTime(2024, 1, 10),
          end: DateTime(2024, 1, 15),
        ),
      ];
      
      final buffered = controller.applyBuffer(ranges);
      
      expect(buffered[0].start, DateTime(2024, 1, 5)); 
      expect(buffered[0].end, DateTime(2024, 1, 20)); 
    });

    
    test('hasSufficientBalance true when enough money', () {
      controller.renterWallet = 1000.0;
      controller.totalPrice = 500.0;
      
      expect(controller.hasSufficientBalance, true);
    });

    test('hasSufficientBalance false when not enough money', () {
      controller.renterWallet = 500.0;
      controller.totalPrice = 1000.0;
      
      expect(controller.hasSufficientBalance, false);
    });

    
    test('isOwner returns correct value', () async {
    
      controller.item = testItem;
      controller.currentUserId = 'owner123';
      
      expect(controller.isOwner, true); 
      
      controller.currentUserId = 'different_user';
      expect(controller.isOwner, false);
    });

   
    test('buildBlockedDays creates blocked dates correctly', () {
      final rentals = [
        DateTimeRange(
          start: DateTime(2024, 1, 10),
          end: DateTime(2024, 1, 12),
        ),
      ];
      
      final blocked = EquipmentDetailController.buildBlockedDays(rentals);
      
      
      expect(blocked.length, 13);
      
    
      expect(blocked[0], DateTime(2024, 1, 5)); 
      expect(blocked[5], DateTime(2024, 1, 10)); 
      expect(blocked[7], DateTime(2024, 1, 12)); 
      expect(blocked[12], DateTime(2024, 1, 17)); 
    });
  });
}
