import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:p2/models/rental_request.dart';

void main() {
  test('RentalRequest fromFirestore parses data correctly', () {
    final data = {
      "itemId": "item123",
      "itemTitle": "Camera",
      "itemOwnerUid": "owner001",
      "customerUid": "user001",
      "rentalType": "Daily",
      "rentalQuantity": 3,
      "startDate": "2025-01-01",
      "endDate": "2025-01-05",
      "totalPrice": 150,
      "status": "approved",
      "createdAt": Timestamp.fromDate(DateTime(2025, 1, 1)),
    };

    final request = RentalRequest.fromFirestore("req001", data);

    expect(request.id, "req001");
    expect(request.itemId, "item123");
    expect(request.itemTitle, "Camera");
    expect(request.rentalQuantity, 3);
    expect(request.totalPrice, 150);
    expect(request.status, "approved");
    expect(request.startDate, DateTime(2025, 1, 1));
    expect(request.endDate, DateTime(2025, 1, 5));
    expect(request.createdAt, isNotNull);
  });

  test('Default values are set when optional fields are missing', () {
    final data = {
      "itemId": "item123",
      "startDate": "2025-01-01",
      "endDate": "2025-01-02",
    };

    final request = RentalRequest.fromFirestore("req002", data);

    expect(request.status, "pending");
    expect(request.totalPrice, 0);
    expect(request.qrToken, null);
    expect(request.qrGeneratedAt, null);
  });
}
