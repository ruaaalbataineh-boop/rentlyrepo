import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:p2/models/item.dart'; 

void main() {
  group('Item Unit Tests', () {
    final sampleData = {
      "name": "Camera",
      "description": "HD Camera",
      "category": "Electronics",
      "subCategory": "Photography",
      "ownerId": "owner001",
      "ownerName": "Alice",
      "images": ["img1.png", "img2.png"],
      "rentalPeriods": {"daily": 10, "weekly": 60},
      "insurance": {"type": "optional", "amount": 50},
      "latitude": 31.9539,
      "longitude": 35.9106,
      "averageRating": 4.5,
      "ratingCount": 10,
      "status": "approved",
      "submittedAt": Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
      "updatedAt": Timestamp.fromDate(DateTime.now()),
    };

    test('fromFirestore parses correctly', () {
      final doc = _MockDocumentSnapshot("item001", sampleData);
      final item = Item.fromFirestore(doc);

      expect(item.id, "item001");
      expect(item.name, "Camera");
      expect(item.isApproved, true);
      expect(item.isPending, false);
      expect(item.isRejected, false);
      expect(item.getMinRentalPrice(), 10);
      expect(item.getFormattedRentalPeriods().length, 2);
      expect(item.insurance, "optional"); 
    });

    test('toMap returns correct map', () {
      final doc = _MockDocumentSnapshot("item001", sampleData);
      final item = Item.fromFirestore(doc);
      final map = item.toMap();

      expect(map["name"], "Camera");
      expect(map["insurance"], "optional");
      expect(map["rentalPeriods"], isA<Map<String, dynamic>>());
    });

    test('copyWith creates updated copy', () {
      final doc = _MockDocumentSnapshot("item001", sampleData);
      final item = Item.fromFirestore(doc);
      final updated = item.copyWith(name: "New Camera", status: "pending");

      expect(updated.name, "New Camera");
      expect(updated.status, "pending");
      expect(updated.id, item.id);
    });

    test('isValid returns correct boolean', () {
      final doc = _MockDocumentSnapshot("item001", sampleData);
      final item = Item.fromFirestore(doc);

      expect(item.isValid(), true);

      final invalidItem = item.copyWith(name: "");
      expect(invalidItem.isValid(), false);
    });

    test('getPriceText returns correct string', () {
      final doc = _MockDocumentSnapshot("item001", sampleData);
      final item = Item.fromFirestore(doc);

      final text = item.getPriceText();
      expect(text, startsWith("From JOD"));
    });
  });
}



// ignore: subtype_of_sealed_class
class _MockDocumentSnapshot implements DocumentSnapshot {
  @override
  final String id;
  final Map<String, dynamic> _data;

  _MockDocumentSnapshot(this.id, this._data);

  @override
  Map<String, dynamic> data() => _data;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

