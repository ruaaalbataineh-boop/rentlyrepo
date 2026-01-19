import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:p2/models/rental_request.dart';


void main() {
  group('RentalRequest - Constructor', () {
    test('Constructor initializes all fields', () {
      final now = DateTime.now();
      final request = RentalRequest(
        id: 'req123',
        itemId: 'item456',
        itemTitle: 'iPhone 15',
        itemOwnerUid: 'owner123',
        ownerName: 'John Doe',
        renterUid: 'renter456',
        renterName: 'Jane Smith',
        rentalType: 'daily',
        rentalQuantity: 1,
        startDate: now,
        endDate: now.add(const Duration(days: 3)),
        pickupTime: '10:00 AM',
        rentalPrice: 50.0,
        totalPrice: 150.0,
        insurance: {'amount': 100, 'ratePercentage': 10},
        status: 'pending',
        paymentStatus: 'locked',
        pickupQrToken: 'pickup123',
        pickupQrGeneratedAt: now,
        returnQrToken: 'return123',
        returnQrGeneratedAt: now,
        reviewedByRenterAt: now,
        reviewedByOwnerAt: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(request.id, 'req123');
      expect(request.itemId, 'item456');
      expect(request.itemTitle, 'iPhone 15');
      expect(request.itemOwnerUid, 'owner123');
      expect(request.ownerName, 'John Doe');
      expect(request.renterUid, 'renter456');
      expect(request.renterName, 'Jane Smith');
      expect(request.rentalType, 'daily');
      expect(request.rentalQuantity, 1);
      expect(request.startDate, now);
      expect(request.endDate, now.add(const Duration(days: 3)));
      expect(request.pickupTime, '10:00 AM');
      expect(request.rentalPrice, 50.0);
      expect(request.totalPrice, 150.0);
      expect(request.insurance, {'amount': 100, 'ratePercentage': 10});
      expect(request.status, 'pending');
      expect(request.paymentStatus, 'locked');
      expect(request.pickupQrToken, 'pickup123');
      expect(request.pickupQrGeneratedAt, now);
      expect(request.returnQrToken, 'return123');
      expect(request.returnQrGeneratedAt, now);
      expect(request.reviewedByRenterAt, now);
      expect(request.reviewedByOwnerAt, now);
      expect(request.createdAt, now);
      expect(request.updatedAt, now);
    });

    test('Constructor with null optional fields', () {
      final request = RentalRequest(
        id: 'req123',
        itemId: 'item456',
        itemTitle: 'Test Item',
        itemOwnerUid: 'owner123',
        ownerName: null,
        renterUid: 'renter456',
        renterName: 'Jane',
        rentalType: 'daily',
        rentalQuantity: 1,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        pickupTime: null,
        rentalPrice: 50.0,
        totalPrice: 50.0,
        insurance: null,
        status: 'pending',
        paymentStatus: 'locked',
        pickupQrToken: null,
        pickupQrGeneratedAt: null,
        returnQrToken: null,
        returnQrGeneratedAt: null,
        reviewedByRenterAt: null,
        reviewedByOwnerAt: null,
        createdAt: null,
        updatedAt: null,
      );

      expect(request.ownerName, isNull);
      expect(request.pickupTime, isNull);
      expect(request.insurance, isNull);
      expect(request.pickupQrToken, isNull);
      expect(request.pickupQrGeneratedAt, isNull);
      expect(request.returnQrToken, isNull);
      expect(request.returnQrGeneratedAt, isNull);
      expect(request.reviewedByRenterAt, isNull);
      expect(request.reviewedByOwnerAt, isNull);
      expect(request.createdAt, isNull);
      expect(request.updatedAt, isNull);
    });
  });

  group('RentalRequest - fromFirestore', () {
    test('fromFirestore with complete data', () {
      final now = Timestamp.now();
      final data = {
        'itemId': 'item123',
        'itemTitle': 'MacBook Pro',
        'itemOwnerUid': 'owner456',
        'ownerName': 'John Apple',
        'renterUid': 'renter789',
        'renterName': 'Jane Doe',
        'rentalType': 'weekly',
        'rentalQuantity': 1,
        'startDate': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'endDate': Timestamp.fromDate(DateTime(2024, 1, 7)),
        'pickupTime': '09:00',
        'rentalPrice': 200.0,
        'totalPrice': 200.0,
        'insurance': {'amount': 500, 'ratePercentage': 5},
        'status': 'accepted',
        'paymentStatus': 'paid',
        'pickupQrToken': 'qr123',
        'pickupQrGeneratedAt': now,
        'returnQrToken': 'qr456',
        'returnQrGeneratedAt': now,
        'reviewedByRenterAt': now,
        'reviewedByOwnerAt': now,
        'createdAt': now,
        'updatedAt': now,
      };

      final request = RentalRequest.fromFirestore('req999', data);

      expect(request.id, 'req999');
      expect(request.itemId, 'item123');
      expect(request.itemTitle, 'MacBook Pro');
      expect(request.rentalType, 'weekly');
      expect(request.rentalPrice, 200.0);
      expect(request.totalPrice, 200.0);
      expect(request.status, 'accepted');
      expect(request.paymentStatus, 'paid');
      expect(request.startDate, DateTime(2024, 1, 1));
      expect(request.endDate, DateTime(2024, 1, 7));
    });

    test('fromFirestore with missing data uses defaults', () {
      final data = <String, dynamic>{}; // Empty map

      final request = RentalRequest.fromFirestore('req1', data);

      expect(request.id, 'req1');
      expect(request.itemId, '');
      expect(request.itemTitle, '');
      expect(request.rentalType, '');
      expect(request.rentalQuantity, 0);
      expect(request.rentalPrice, 0);
      expect(request.totalPrice, 0);
      expect(request.status, 'pending');
      expect(request.paymentStatus, 'locked');
    });

    test('fromFirestore with various date formats', () {
      final testCases = [
        {
          'data': {'startDate': Timestamp.fromDate(DateTime(2024, 1, 1))},
          'expected': DateTime(2024, 1, 1),
        },
        {
          'data': {'startDate': 1704067200000}, // milliseconds
          'expected': DateTime.fromMillisecondsSinceEpoch(1704067200000),
        },
        {
          'data': {'startDate': '2024-01-01T00:00:00.000'}, // string
          'expected': DateTime(2024, 1, 1),
        },
      ];

      for (var testCase in testCases) {
        final request = RentalRequest.fromFirestore('test', testCase['data'] as Map<String, dynamic>);
        expect(request.startDate.year, (testCase['expected'] as DateTime).year);
        expect(request.startDate.month, (testCase['expected'] as DateTime).month);
        expect(request.startDate.day, (testCase['expected'] as DateTime).day);
      }
    });

    test('fromFirestore handles null insurance', () {
      final data = {
        'itemId': 'item1',
        'itemTitle': 'Test',
        'itemOwnerUid': 'owner1',
        'renterUid': 'renter1',
        'renterName': 'Test',
        'rentalType': 'daily',
        'rentalQuantity': 1,
        'startDate': Timestamp.now(),
        'endDate': Timestamp.now(),
        'rentalPrice': 50,
        'totalPrice': 50,
        'status': 'pending',
        'paymentStatus': 'locked',
      };

      final request = RentalRequest.fromFirestore('test', data);
      expect(request.insurance, isNull);
    });
  });

  group('RentalRequest - JSON Serialization', () {
    test('toJson and fromJson round trip', () {
      final original = RentalRequest(
        id: 'req123',
        itemId: 'item456',
        itemTitle: 'Test Item',
        itemOwnerUid: 'owner123',
        ownerName: 'Owner',
        renterUid: 'renter456',
        renterName: 'Renter',
        rentalType: 'monthly',
        rentalQuantity: 2,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 2, 1),
        pickupTime: '14:00',
        rentalPrice: 500.0,
        totalPrice: 1000.0,
        insurance: {'amount': 200, 'ratePercentage': 10, 'accepted': true},
        status: 'active',
        paymentStatus: 'paid',
        pickupQrToken: 'pickup123',
        pickupQrGeneratedAt: DateTime(2024, 1, 1, 10, 0),
        returnQrToken: 'return123',
        returnQrGeneratedAt: DateTime(2024, 2, 1, 10, 0),
        reviewedByRenterAt: DateTime(2024, 2, 2),
        reviewedByOwnerAt: DateTime(2024, 2, 3),
        createdAt: DateTime(2023, 12, 20),
        updatedAt: DateTime(2023, 12, 21),
      );

      final json = original.toJson();
      final restored = RentalRequest.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.itemId, original.itemId);
      expect(restored.itemTitle, original.itemTitle);
      expect(restored.rentalType, original.rentalType);
      expect(restored.rentalQuantity, original.rentalQuantity);
      expect(restored.startDate.toIso8601String(), original.startDate.toIso8601String());
      expect(restored.endDate.toIso8601String(), original.endDate.toIso8601String());
      expect(restored.rentalPrice, original.rentalPrice);
      expect(restored.totalPrice, original.totalPrice);
      expect(restored.status, original.status);
      expect(restored.paymentStatus, original.paymentStatus);
      expect(restored.insurance, original.insurance);
    });

    test('toJson with null values', () {
      final request = RentalRequest(
        id: 'req1',
        itemId: 'item1',
        itemTitle: 'Test',
        itemOwnerUid: 'owner1',
        ownerName: null,
        renterUid: 'renter1',
        renterName: 'Test',
        rentalType: 'daily',
        rentalQuantity: 1,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        pickupTime: null,
        rentalPrice: 50.0,
        totalPrice: 50.0,
        insurance: null,
        status: 'pending',
        paymentStatus: 'locked',
        pickupQrToken: null,
        pickupQrGeneratedAt: null,
        returnQrToken: null,
        returnQrGeneratedAt: null,
        reviewedByRenterAt: null,
        reviewedByOwnerAt: null,
        createdAt: null,
        updatedAt: null,
      );

      final json = request.toJson();

      expect(json['ownerName'], isNull);
      expect(json['pickupTime'], isNull);
      expect(json['insurance'], isNull);
      expect(json['pickupQrToken'], isNull);
      expect(json['pickupQrGeneratedAt'], isNull);
      expect(json['returnQrToken'], isNull);
      expect(json['returnQrGeneratedAt'], isNull);
      expect(json['reviewedByRenterAt'], isNull);
      expect(json['reviewedByOwnerAt'], isNull);
      expect(json['createdAt'], isNull);
      expect(json['updatedAt'], isNull);
    });
  });

  group('RentalRequest - Helper Getters', () {
    test('Insurance getters work correctly', () {
      final request = RentalRequest(
        id: 'req1',
        itemId: 'item1',
        itemTitle: 'Test',
        itemOwnerUid: 'owner1',
        ownerName: null,
        renterUid: 'renter1',
        renterName: 'Test',
        rentalType: 'daily',
        rentalQuantity: 1,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        pickupTime: null,
        rentalPrice: 50.0,
        totalPrice: 50.0,
        insurance: {
          'amount': 100.0,
          'ratePercentage': 10.0,
          'itemOriginalPrice': 1000.0,
          'accepted': true,
        },
        status: 'pending',
        paymentStatus: 'locked',
        pickupQrToken: null,
        pickupQrGeneratedAt: null,
        returnQrToken: null,
        returnQrGeneratedAt: null,
        reviewedByRenterAt: null,
        reviewedByOwnerAt: null,
        createdAt: null,
        updatedAt: null,
      );

      expect(request.insuranceAmount, 100.0);
      expect(request.insuranceRate, 10.0);
      expect(request.insuranceOriginalPrice, 1000.0);
      expect(request.insuranceAccepted, true);
    });

    test('Insurance getters with null insurance', () {
      final request = RentalRequest(
        id: 'req1',
        itemId: 'item1',
        itemTitle: 'Test',
        itemOwnerUid: 'owner1',
        ownerName: null,
        renterUid: 'renter1',
        renterName: 'Test',
        rentalType: 'daily',
        rentalQuantity: 1,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        pickupTime: null,
        rentalPrice: 50.0,
        totalPrice: 50.0,
        insurance: null,
        status: 'pending',
        paymentStatus: 'locked',
        pickupQrToken: null,
        pickupQrGeneratedAt: null,
        returnQrToken: null,
        returnQrGeneratedAt: null,
        reviewedByRenterAt: null,
        reviewedByOwnerAt: null,
        createdAt: null,
        updatedAt: null,
      );

      expect(request.insuranceAmount, 0);
      expect(request.insuranceRate, 0);
      expect(request.insuranceOriginalPrice, 0);
      expect(request.insuranceAccepted, false);
    });
  });

  group('RentalRequest - Status Helpers', () {
    test('isActive when status is active and within date range', () {
      final request = RentalRequest(
        id: 'req1',
        itemId: 'item1',
        itemTitle: 'Test',
        itemOwnerUid: 'owner1',
        ownerName: null,
        renterUid: 'renter1',
        renterName: 'Test',
        rentalType: 'daily',
        rentalQuantity: 1,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 1)),
        pickupTime: null,
        rentalPrice: 50.0,
        totalPrice: 50.0,
        insurance: null,
        status: 'active',
        paymentStatus: 'paid',
        pickupQrToken: null,
        pickupQrGeneratedAt: null,
        returnQrToken: null,
        returnQrGeneratedAt: null,
        reviewedByRenterAt: null,
        reviewedByOwnerAt: null,
        createdAt: null,
        updatedAt: null,
      );

      expect(request.isActive, true);
    });

    test('isUpcoming when status is accepted and start in future', () {
      final request = RentalRequest(
        id: 'req1',
        itemId: 'item1',
        itemTitle: 'Test',
        itemOwnerUid: 'owner1',
        ownerName: null,
        renterUid: 'renter1',
        renterName: 'Test',
        rentalType: 'daily',
        rentalQuantity: 1,
        startDate: DateTime.now().add(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 4)),
        pickupTime: null,
        rentalPrice: 50.0,
        totalPrice: 50.0,
        insurance: null,
        status: 'accepted',
        paymentStatus: 'paid',
        pickupQrToken: null,
        pickupQrGeneratedAt: null,
        returnQrToken: null,
        returnQrGeneratedAt: null,
        reviewedByRenterAt: null,
        reviewedByOwnerAt: null,
        createdAt: null,
        updatedAt: null,
      );

      expect(request.isUpcoming, true);
    });

    test('isCompleted for various completed statuses', () {
      final completedStatuses = ['ended', 'cancelled', 'rejected', 'outdated'];
      
      for (final status in completedStatuses) {
        final request = RentalRequest(
          id: 'req1',
          itemId: 'item1',
          itemTitle: 'Test',
          itemOwnerUid: 'owner1',
          ownerName: null,
          renterUid: 'renter1',
          renterName: 'Test',
          rentalType: 'daily',
          rentalQuantity: 1,
          startDate: DateTime.now(),
          endDate: DateTime.now(),
          pickupTime: null,
          rentalPrice: 50.0,
          totalPrice: 50.0,
          insurance: null,
          status: status,
          paymentStatus: 'paid',
          pickupQrToken: null,
          pickupQrGeneratedAt: null,
          returnQrToken: null,
          returnQrGeneratedAt: null,
          reviewedByRenterAt: null,
          reviewedByOwnerAt: null,
          createdAt: null,
          updatedAt: null,
        );

        expect(request.isCompleted, true, reason: 'Status: $status should be completed');
      }
    });

    test('remainingTime calculates correctly for active rental', () {
      final endDate = DateTime.now().add(const Duration(hours: 3));
      final request = RentalRequest(
        id: 'req1',
        itemId: 'item1',
        itemTitle: 'Test',
        itemOwnerUid: 'owner1',
        ownerName: null,
        renterUid: 'renter1',
        renterName: 'Test',
        rentalType: 'daily',
        rentalQuantity: 1,
        startDate: DateTime.now().subtract(const Duration(hours: 1)),
        endDate: endDate,
        pickupTime: null,
        rentalPrice: 50.0,
        totalPrice: 50.0,
        insurance: null,
        status: 'active',
        paymentStatus: 'paid',
        pickupQrToken: null,
        pickupQrGeneratedAt: null,
        returnQrToken: null,
        returnQrGeneratedAt: null,
        reviewedByRenterAt: null,
        reviewedByOwnerAt: null,
        createdAt: null,
        updatedAt: null,
      );

      final remaining = request.remainingTime;
      expect(remaining, isNotNull);
      expect(remaining!.inHours, closeTo(3, 1)); 
    });

    test('remainingTime returns null for non-active rental', () {
      final request = RentalRequest(
        id: 'req1',
        itemId: 'item1',
        itemTitle: 'Test',
        itemOwnerUid: 'owner1',
        ownerName: null,
        renterUid: 'renter1',
        renterName: 'Test',
        rentalType: 'daily',
        rentalQuantity: 1,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        pickupTime: null,
        rentalPrice: 50.0,
        totalPrice: 50.0,
        insurance: null,
        status: 'pending',
        paymentStatus: 'locked',
        pickupQrToken: null,
        pickupQrGeneratedAt: null,
        returnQrToken: null,
        returnQrGeneratedAt: null,
        reviewedByRenterAt: null,
        reviewedByOwnerAt: null,
        createdAt: null,
        updatedAt: null,
      );

      expect(request.remainingTime, isNull);
    });

    test('progressPercentage calculates correctly', () {
      final start = DateTime.now().subtract(const Duration(hours: 2));
      final end = DateTime.now().add(const Duration(hours: 2));
      final request = RentalRequest(
        id: 'req1',
        itemId: 'item1',
        itemTitle: 'Test',
        itemOwnerUid: 'owner1',
        ownerName: null,
        renterUid: 'renter1',
        renterName: 'Test',
        rentalType: 'daily',
        rentalQuantity: 1,
        startDate: start,
        endDate: end,
        pickupTime: null,
        rentalPrice: 50.0,
        totalPrice: 50.0,
        insurance: null,
        status: 'active',
        paymentStatus: 'paid',
        pickupQrToken: null,
        pickupQrGeneratedAt: null,
        returnQrToken: null,
        returnQrGeneratedAt: null,
        reviewedByRenterAt: null,
        reviewedByOwnerAt: null,
        createdAt: null,
        updatedAt: null,
      );

      expect(request.progressPercentage, closeTo(0.5, 0.1)); 
    });

    test('progressPercentage returns 0 for non-active rental', () {
      final request = RentalRequest(
        id: 'req1',
        itemId: 'item1',
        itemTitle: 'Test',
        itemOwnerUid: 'owner1',
        ownerName: null,
        renterUid: 'renter1',
        renterName: 'Test',
        rentalType: 'daily',
        rentalQuantity: 1,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        pickupTime: null,
        rentalPrice: 50.0,
        totalPrice: 50.0,
        insurance: null,
        status: 'pending',
        paymentStatus: 'locked',
        pickupQrToken: null,
        pickupQrGeneratedAt: null,
        returnQrToken: null,
        returnQrGeneratedAt: null,
        reviewedByRenterAt: null,
        reviewedByOwnerAt: null,
        createdAt: null,
        updatedAt: null,
      );

      expect(request.progressPercentage, 0.0);
    });
  });

  group('RentalRequest - copyWith', () {
    test('copyWith updates specified fields', () {
      final original = RentalRequest(
        id: 'req1',
        itemId: 'item1',
        itemTitle: 'Original',
        itemOwnerUid: 'owner1',
        ownerName: 'Owner',
        renterUid: 'renter1',
        renterName: 'Renter',
        rentalType: 'daily',
        rentalQuantity: 1,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 2),
        pickupTime: '10:00',
        rentalPrice: 50.0,
        totalPrice: 50.0,
        insurance: null,
        status: 'pending',
        paymentStatus: 'locked',
        pickupQrToken: null,
        pickupQrGeneratedAt: null,
        returnQrToken: null,
        returnQrGeneratedAt: null,
        reviewedByRenterAt: null,
        reviewedByOwnerAt: null,
        createdAt: null,
        updatedAt: null,
      );

      final updated = original.copyWith(
        status: 'accepted',
        paymentStatus: 'paid',
        updatedAt: DateTime(2024, 1, 1, 12, 0),
      );

      expect(updated.id, original.id);
      expect(updated.itemId, original.itemId);
      expect(updated.itemTitle, original.itemTitle);
      expect(updated.status, 'accepted'); 
      expect(updated.paymentStatus, 'paid'); 
      expect(updated.updatedAt, DateTime(2024, 1, 1, 12, 0)); 
      expect(updated.rentalType, original.rentalType); 
      expect(updated.rentalPrice, original.rentalPrice); 
    });

    test('copyWith creates completely new object', () {
      final original = RentalRequest(
        id: 'req1',
        itemId: 'item1',
        itemTitle: 'Test',
        itemOwnerUid: 'owner1',
        ownerName: null,
        renterUid: 'renter1',
        renterName: 'Test',
        rentalType: 'daily',
        rentalQuantity: 1,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        pickupTime: null,
        rentalPrice: 50.0,
        totalPrice: 50.0,
        insurance: null,
        status: 'pending',
        paymentStatus: 'locked',
        pickupQrToken: null,
        pickupQrGeneratedAt: null,
        returnQrToken: null,
        returnQrGeneratedAt: null,
        reviewedByRenterAt: null,
        reviewedByOwnerAt: null,
        createdAt: null,
        updatedAt: null,
      );

      final updated = original.copyWith(status: 'accepted');

      
      expect(identical(original, updated), false);
      expect(updated.status, 'accepted');
      expect(original.status, 'pending'); 
    });
  });

  group('RentalRequest - Edge Cases', () {
    test('Handles very large quantities', () {
      final request = RentalRequest(
        id: 'req1',
        itemId: 'item1',
        itemTitle: 'Test',
        itemOwnerUid: 'owner1',
        ownerName: null,
        renterUid: 'renter1',
        renterName: 'Test',
        rentalType: 'daily',
        rentalQuantity: 1000,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        pickupTime: null,
        rentalPrice: 50.0,
        totalPrice: 50000.0,
        insurance: null,
        status: 'pending',
        paymentStatus: 'locked',
        pickupQrToken: null,
        pickupQrGeneratedAt: null,
        returnQrToken: null,
        returnQrGeneratedAt: null,
        reviewedByRenterAt: null,
        reviewedByOwnerAt: null,
        createdAt: null,
        updatedAt: null,
      );

      expect(request.rentalQuantity, 1000);
      expect(request.totalPrice, 50000.0);
    });

    test('Handles very long date ranges', () {
      final request = RentalRequest(
        id: 'req1',
        itemId: 'item1',
        itemTitle: 'Test',
        itemOwnerUid: 'owner1',
        ownerName: null,
        renterUid: 'renter1',
        renterName: 'Test',
        rentalType: 'yearly',
        rentalQuantity: 1,
        startDate: DateTime(2020, 1, 1),
        endDate: DateTime(2030, 1, 1),
        pickupTime: null,
        rentalPrice: 1000.0,
        totalPrice: 10000.0,
        insurance: null,
        status: 'active',
        paymentStatus: 'paid',
        pickupQrToken: null,
        pickupQrGeneratedAt: null,
        returnQrToken: null,
        returnQrGeneratedAt: null,
        reviewedByRenterAt: null,
        reviewedByOwnerAt: null,
        createdAt: null,
        updatedAt: null,
      );

      expect(request.startDate.year, 2020);
      expect(request.endDate.year, 2030);
    });

    test('Handles empty strings in firestore data', () {
      final data = {
        'itemId': '',
        'itemTitle': '',
        'itemOwnerUid': '',
        'renterUid': '',
        'renterName': '',
        'rentalType': '',
        'rentalQuantity': 0,
        'startDate': Timestamp.now(),
        'endDate': Timestamp.now(),
        'rentalPrice': 0,
        'totalPrice': 0,
        'status': '',
        'paymentStatus': '',
      };

      final request = RentalRequest.fromFirestore('test', data);

      expect(request.itemId, '');
      expect(request.itemTitle, '');
      expect(request.renterName, '');
      expect(request.rentalType, '');
      expect(request.status, ''); 
      expect(request.paymentStatus, '');
    });
  });
}
