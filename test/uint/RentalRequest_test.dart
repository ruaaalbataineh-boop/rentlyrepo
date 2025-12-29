import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:p2/models/rental_request.dart';

void main() {
  test('RentalRequest fromFirestore parses data correctly', () {
    final data = {
      "itemId": "item123",
      "itemTitle": "Camera",
      "itemOwnerUid": "owner001",
      "ownerName": "John Doe",
      "renterUid": "user001", 
      "renterName": "Jane Smith",
      "rentalType": "Daily",
      "rentalQuantity": 3,
      "startDate": "2025-01-01",
      "endDate": "2025-01-05",
      "rentalPrice": 50, 
      "totalPrice": 150,
      "status": "approved",
      
      
      "insurance": {
        "amount": 10,
        "ratePercentage": 5,
        "itemOriginalPrice": 1000,
        "accepted": true,
      },
      
      
      "penalty": {
        "hourlyRate": 5,
        "dailyRate": 50,
        "maxHours": 24,
        "maxDays": 7,
      },
      
      "createdAt": Timestamp.fromDate(DateTime(2025, 1, 1)),
      "updatedAt": Timestamp.fromDate(DateTime(2025, 1, 2)),
    };

    final request = RentalRequest.fromFirestore("req001", data);

    expect(request.id, "req001");
    expect(request.itemId, "item123");
    expect(request.itemTitle, "Camera");
    expect(request.ownerName, "John Doe");
    expect(request.renterUid, "user001");
    expect(request.renterName, "Jane Smith");
    expect(request.rentalQuantity, 3);
    expect(request.rentalPrice, 50);
    expect(request.totalPrice, 150);
    expect(request.status, "approved");
    expect(request.startDate, DateTime(2025, 1, 1));
    expect(request.endDate, DateTime(2025, 1, 5));
    expect(request.createdAt, isNotNull);
    expect(request.updatedAt, isNotNull);
    
    expect(request.insuranceAmount, 10);
    expect(request.insuranceRate, 5);
    expect(request.insuranceOriginalPrice, 1000);
    expect(request.insuranceAccepted, true);
    
    
    expect(request.penaltyHourlyRate, 5);
    expect(request.penaltyDailyRate, 50);
    expect(request.penaltyMaxHours, 24);
    expect(request.penaltyMaxDays, 7);
  });

  test('Default values are set when optional fields are missing', () {
    final data = {
      "itemId": "item123",
      "itemTitle": "Test Item",
      "itemOwnerUid": "owner001",
      "renterUid": "renter001",
      "renterName": "Renter",
      "rentalType": "Daily",
      "rentalQuantity": 1,
      "startDate": "2025-01-01",
      "endDate": "2025-01-02",
      "rentalPrice": 0,
      "totalPrice": 0,
      "insurance": {
        "amount": 0,
        "ratePercentage": 0,
        "itemOriginalPrice": 0,
        "accepted": false,
      },
      "penalty": {
        "hourlyRate": 0,
        "dailyRate": 0,
        "maxHours": 0,
        "maxDays": 0,
      },
    };

    final request = RentalRequest.fromFirestore("req002", data);

    expect(request.status, "pending");
    expect(request.totalPrice, 0);
    expect(request.qrToken, null);
    expect(request.qrGeneratedAt, null);
    expect(request.startTime, null);
    expect(request.endTime, null);
    expect(request.pickupTime, null);
    expect(request.insuranceAccepted, false);
  });

  test('Handles Timestamp for date fields', () {
    final data = {
      "itemId": "item123",
      "itemTitle": "Test Item",
      "itemOwnerUid": "owner001",
      "renterUid": "renter001",
      "renterName": "Renter",
      "rentalType": "Daily",
      "rentalQuantity": 1,
      "startDate": Timestamp.fromDate(DateTime(2025, 1, 1)),
      "endDate": Timestamp.fromDate(DateTime(2025, 1, 2)),
      "rentalPrice": 100,
      "totalPrice": 100,
      "insurance": {
        "amount": 0,
        "ratePercentage": 0,
        "itemOriginalPrice": 0,
        "accepted": false,
      },
      "penalty": {
        "hourlyRate": 0,
        "dailyRate": 0,
        "maxHours": 0,
        "maxDays": 0,
      },
    };

    final request = RentalRequest.fromFirestore("req003", data);

    expect(request.startDate, DateTime(2025, 1, 1));
    expect(request.endDate, DateTime(2025, 1, 2));
  });
}
