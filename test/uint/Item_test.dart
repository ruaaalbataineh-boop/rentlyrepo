// ignore_for_file: subtype_of_sealed_class

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:p2/models/item.dart';

void main() {
  test('Item fromFirestore parses data correctly', () {
    final fakeDoc = FakeDocumentSnapshot(
      id: 'item001',
      data: {
        "name": "Camera",
        "description": "4K Camera",
        "category": "Electronics",
        "subCategory": "Cameras",
        "ownerId": "owner001",
        "ownerName": "Ahmad",
        "images": ["img1.jpg", "img2.jpg"],
        "rentalPeriods": {"Daily": 10},
        "averageRating": 4.5,
        "ratingCount": 12,
        "status": "approved",
        "submittedAt": Timestamp.fromDate(DateTime(2025, 1, 1)),
      },
    );

    final item = Item.fromFirestore(fakeDoc);

    expect(item.id, "item001");
    expect(item.name, "Camera");
    expect(item.category, "Electronics");
    expect(item.averageRating, 4.5);
    expect(item.ratingCount, 12);
    expect(item.status, "approved");
    expect(item.submittedAt, isNotNull);
  });

  test('Item toMap converts data correctly', () {
    final item = Item(
      id: "item002",
      name: "Laptop",
      description: "Gaming Laptop",
      category: "Computers",
      subCategory: "Laptops",
      ownerId: "owner002",
      ownerName: "Ali",
      images: [],
      rentalPeriods: {},
      insurance: null,
      latitude: null,
      longitude: null,
      averageRating: 0,
      ratingCount: 0,
      status: "pending",
      submittedAt: DateTime(2025, 2, 1),
      updatedAt: null,
    );

    final map = item.toMap();

    expect(map["name"], "Laptop");
    expect(map["status"], "pending");
    expect(map["submittedAt"], isA<Timestamp>());
    expect(map["updatedAt"], null);
  });
}





class FakeDocumentSnapshot implements DocumentSnapshot {
  @override final String id;
  final Map<String, dynamic> _data;

  FakeDocumentSnapshot({required this.id, required Map<String, dynamic> data})
      : _data = data;

  @override
  Map<String, dynamic> data() => _data;
  
  @override
  operator [](Object field) {
    // TODO: implement []
    throw UnimplementedError();
  }
  
  @override
  // TODO: implement exists
  bool get exists => throw UnimplementedError();
  
  @override
  get(Object field) {
    // TODO: implement get
    throw UnimplementedError();
  }
  
  @override
  // TODO: implement metadata
  SnapshotMetadata get metadata => throw UnimplementedError();
  
  @override
  // TODO: implement reference
  DocumentReference<Object?> get reference => throw UnimplementedError();

  
}
