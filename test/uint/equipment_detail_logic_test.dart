import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:p2/logic/equipment_detail_logic.dart';
import 'package:p2/models/Item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EquipmentDetailLogic logic;

  setUp(() {
    logic = EquipmentDetailLogic(userId: 'test_user');
    logic.isInitialized = true;
  });


  group('User Validation', () {
    test('valid user id', () {
      expect(logic.isValidUserId('user_123'), true);
      expect(logic.isValidUserId(''), false);
      expect(logic.isValidUserId('user@123'), false);
    });
  });

  group('Item Ownership', () {
    test('isOwner true when owner matches', () async {
      final item = Item(
        id: '1',
        name: 'Camera',
        description: 'Nice camera',
        category: 'Electronics',
        subCategory: 'Camera',
        images: [],
        rentalPeriods: {'daily': '100'},
        averageRating: 4.5,
        ratingCount: 10,
        ownerId: 'test_user',
        ownerName: 'Owner',
        latitude: 0,
        longitude: 0,
        status: 'available',
        insurance: '',
      );

      await logic.setItem(item);
      expect(logic.isOwner, true);
    });
  });

  group('Price Calculation', () {
    setUp(() async {
      final item = Item(
        id: '1',
        name: 'Camera',
        description: 'Nice camera',
        category: 'Electronics',
        subCategory: 'Camera',
        images: [],
        rentalPeriods: {
          'daily': '100',
          'weekly': '600',
        },
        averageRating: 4.5,
        ratingCount: 10,
        ownerId: 'owner',
        ownerName: 'Owner',
        latitude: 0,
        longitude: 0,
        status: 'available',
        insurance: '',
      );

      await logic.setItem(item);
    });

    test('compute total price daily', () {
      logic.selectedPeriod = 'daily';
      logic.count = 3;

      expect(logic.computeTotalPrice(), 300.0);
    });

    test('compute price without period', () {
      logic.selectedPeriod = null;
      expect(logic.computeTotalPrice(), 0.0);
    });
  });

  group('Date Calculation', () {
    test('calculate end date daily', () {
      logic.selectedPeriod = 'daily';
      logic.startDate = DateTime(2024, 1, 1);
      logic.count = 5;

      logic.calculateEndDate();
      expect(logic.endDate, DateTime(2024, 1, 6));
    });

    test('no period gives null end date', () {
      logic.selectedPeriod = null;
      logic.calculateEndDate();
      expect(logic.endDate, null);
    });
  });

  group('Insurance', () {
    test('calculate insurance amount', () {
      logic.itemInsuranceInfo = {
        'itemOriginalPrice': 1000.0,
        'ratePercentage': 0.15,
      };

      logic.calculateInsuranceAmount();
      expect(logic.insuranceAmount, 150.0);
    });
  });

  group('Wallet Balance', () {
    test('sufficient balance', () {
      logic.renterWallet = 1000;
      logic.totalRequired = 500;

      logic.checkWalletBalance();
      expect(logic.hasSufficientBalance, true);
    });

    test('insufficient balance', () {
      logic.renterWallet = 100;
      logic.totalRequired = 500;

      logic.checkWalletBalance();
      expect(logic.hasSufficientBalance, false);
    });
  });

  group('Security Logic', () {
    test('isLocked when attempts exceeded', () {
      logic.rentalAttempts = 30;
      expect(logic.isLocked, true);
    });

    test('cooldown active', () {
      logic.lastRentalAttempt = DateTime.now();
      expect(logic.isOnCooldown, true);
    });
  });

  group('Cleanup', () {
    test('cleanup resets state', () {
      logic.selectedPeriod = 'daily';
      logic.startDate = DateTime.now();
      logic.pickupTime = '10:00';
      logic.insuranceAccepted = true;

      logic.cleanupResources();

      expect(logic.selectedPeriod, null);
      expect(logic.startDate, null);
      expect(logic.pickupTime, null);
      expect(logic.insuranceAccepted, false);
    });
  });
}
