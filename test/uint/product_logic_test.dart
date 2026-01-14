import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/product_logic.dart';
import 'package:p2/security/input_validator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:p2/models/Item.dart';


// ignore: subtype_of_sealed_class
class FakeDoc implements QueryDocumentSnapshot {
  final String _id;
  final Map<String, dynamic> _data;
  FakeDoc(this._id, this._data);

  @override
  String get id => _id;

  @override
  dynamic data([bool serverTimestampBehavior = false]) => _data;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ProductLogic Tests', () {
    test('validateItemData returns true for valid product', () {
      final product = {
        "name": "Camera",
        "category": "Electronics",
        "subCategory": "Cameras",
        "ownerId": "user123",
        "status": "approved",
        "images": ["https://example.com/image.jpg"]
      };

      final isValid = ProductLogic.validateItemData(product);
      expect(isValid, true);
    });

    test('validateItemData returns false for missing fields', () {
      final product = {
        "name": "",
        "category": "Electronics",
      };
      final isValid = ProductLogic.validateItemData(product);
      expect(isValid, false);
    });

   test('secureConvertToItem returns sanitized Item', () {
  final data = {
    "name": "Camera<script>",
    "description": "<b>desc</b>",
    "category": "Electronics",
    "subCategory": "Cameras",
    "ownerId": "user123",
    "ownerName": "John",
    "status": "approved",
    "images": ["https://example.com/image.jpg"],
    "rentalPeriods": {"hour": 5.0},
    "averageRating": 4.5,
    "ratingCount": 10
  };

  final item = ProductLogic.secureConvertToItem("item1", data);


  expect(item.name.contains('<'), false);
  expect(item.description.contains('<'), false);

  expect(item.category, "Electronics");
  expect(item.subCategory, "Cameras");
  expect(item.rentalPeriods['hour'], 5.0);
  expect(item.averageRating, 4.5);
  expect(item.ratingCount, 10);
  expect(item.status, "approved");
});

    test('formatCategoryTitle truncates long text', () {
      final category = "A" * 100;
      final subCategory = "B" * 100;
      final formatted = ProductLogic.formatCategoryTitle(category, subCategory);
      expect(formatted.length <= 53, true); 
    });

    test('getPriceText returns correct text', () {
      final rental = {"hour": 5.0, "day": 20.0};
      final priceText = ProductLogic.getPriceText(rental);
      expect(priceText.contains("From JOD"), true);
      expect(priceText.contains("hour"), true);
    });

    test('_isValidImageUrl returns true for valid URL', () {
      final url = "https://example.com/image.png";
      final isValid = ProductLogic.isValidImageUrl(url);
      expect(isValid, true);
    });

    test('_isValidImageUrl returns false for invalid URL', () {
      final url = "javascript:alert(1)";
      final isValid = ProductLogic.isValidImageUrl(url);
      expect(isValid, false);
    });

    test('secureFilterProducts filters based on search query', () async {
      final docs = [
        FakeDoc("1", {"name": "Camera", "category": "Electronics", "subCategory": "Cameras", "ownerId": "u1", "status":"approved"}),
        FakeDoc("2", {"name": "Tripod", "category": "Electronics", "subCategory": "Accessories", "ownerId": "u2", "status":"approved"}),
      ];

      final filtered = await ProductLogic.secureFilterProducts(docs, "camera");
      expect(filtered.length, 1);
      expect(filtered.first.id, "1");
    });
  });
}
