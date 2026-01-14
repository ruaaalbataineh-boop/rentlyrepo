import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:p2/models/rental_request.dart'; 

void main() {
  group('RentalRequest Unit Tests', () {
    final now = DateTime.now();
    final later = now.add(const Duration(days: 2));
    final earlier = now.subtract(const Duration(days: 2));

    final sampleData = {
      "itemId": "item123",
      "itemTitle": "Camera",
      "itemOwnerUid": "owner001",
      "ownerName": "Alice",
      "renterUid": "renter001",
      "renterName": "Bob",
      "rentalType": "daily",
      "rentalQuantity": 1,
      "startDate": Timestamp.fromDate(now),
      "endDate": Timestamp.fromDate(later),
      "rentalPrice": 100,
      "totalPrice": 200,
      "insurance": {"amount": 50, "ratePercentage": 10, "itemOriginalPrice": 500, "accepted": true},
      "penalty": {"hourlyRate": 5, "dailyRate": 20, "maxHours": 24, "maxDays": 7},
      "status": "active",
      "paymentStatus": "paid",
    };

    test('fromFirestore correctly parses data', () {
      final request = RentalRequest.fromFirestore("req001", sampleData);

      expect(request.id, "req001");
      expect(request.itemTitle, "Camera");
      expect(request.renterName, "Bob");
      expect(request.rentalQuantity, 1);
      expect(request.startDate, isA<DateTime>());
      expect(request.endDate, isA<DateTime>());
      expect(request.insuranceAmount, 50);
      expect(request.insuranceAccepted, true);
      expect(request.penaltyHourlyRate, 5);
      expect(request.isActive, true);
    });

    test('toJson and fromJson work correctly', () {
      final request = RentalRequest.fromFirestore("req001", sampleData);
      final json = request.toJson();

      final fromJson = RentalRequest.fromJson(json);
      expect(fromJson.id, request.id);
      expect(fromJson.itemTitle, request.itemTitle);
      expect(fromJson.insuranceAmount, request.insuranceAmount);
    });

    test('copyWith creates a modified copy', () {
      final request = RentalRequest.fromFirestore("req001", sampleData);
      final updated = request.copyWith(status: "ended", rentalQuantity: 5);

      expect(updated.status, "ended");
      expect(updated.rentalQuantity, 5);
      expect(updated.id, request.id); // unchanged
    });

    test('isUpcoming returns true for future rentals', () {
      final futureData = Map<String, dynamic>.from(sampleData);
      futureData["startDate"] = Timestamp.fromDate(later);
      futureData["status"] = "accepted";

      final futureRequest = RentalRequest.fromFirestore("req002", futureData);
      expect(futureRequest.isUpcoming, true);
      expect(futureRequest.isActive, false);
    });

    test('isCompleted returns true for ended/cancelled/rejected/outdated', () {
      final completedData = Map<String, dynamic>.from(sampleData);
      completedData["status"] = "ended";

      final completedRequest = RentalRequest.fromFirestore("req003", completedData);
      expect(completedRequest.isCompleted, true);
    });

    test('remainingTime and progressPercentage calculate correctly', () {
      final request = RentalRequest.fromFirestore("req001", sampleData);
      final remaining = request.remainingTime;
      final progress = request.progressPercentage;

      expect(remaining, isA<Duration>());
      expect(progress, inInclusiveRange(0.0, 1.0));
    });
  });
}
