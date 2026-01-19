import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:p2/models/Item.dart';


void main() {
  group('Insurance Model Tests', () {
    test('Insurance constructor initializes correctly', () {
      final insurance = Insurance(
        amount: 100.0,
        originalPrice: 1000.0,
        rate: 10.0,
      );

      expect(insurance.amount, 100.0);
      expect(insurance.originalPrice, 1000.0);
      expect(insurance.rate, 10.0);
    });

    test('Insurance.fromMap with complete data', () {
      final map = {
        "insuranceAmount": 150.0,
        "itemOriginalPrice": 1500.0,
        "ratePercentage": 10.0,
      };

      final insurance = Insurance.fromMap(map);

      expect(insurance.amount, 150.0);
      expect(insurance.originalPrice, 1500.0);
      expect(insurance.rate, 10.0);
    });

   
    test('Insurance.fromMap with null values uses defaults', () {
      final map = {
        "insuranceAmount": null,
        "itemOriginalPrice": null,
        "ratePercentage": null,
      };

      final insurance = Insurance.fromMap(map);

      expect(insurance.amount, 0.0);
      expect(insurance.originalPrice, 0.0);
      expect(insurance.rate, 0.0);
    });

    test('Insurance.toMap returns correct map', () {
      final insurance = Insurance(
        amount: 200.0,
        originalPrice: 2000.0,
        rate: 10.0,
      );

      final map = insurance.toMap();

      expect(map["insuranceAmount"], 200.0);
      expect(map["itemOriginalPrice"], 2000.0);
      expect(map["ratePercentage"], 10.0);
      expect(map.length, 3);
    });

    test('Insurance handles integer values in fromMap', () {
      final map = {
        "insuranceAmount": 100, 
        "itemOriginalPrice": 1000, 
        "ratePercentage": 10, 
      };

      final insurance = Insurance.fromMap(map);

      expect(insurance.amount, 100.0);
      expect(insurance.originalPrice, 1000.0);
      expect(insurance.rate, 10.0);
    });
  });

  group('Item Model Tests - Constructor & Properties', () {
    test('Item constructor initializes correctly', () {
      final insurance = Insurance(
        amount: 100.0,
        originalPrice: 1000.0,
        rate: 10.0,
      );

      final now = DateTime.now();
      final item = Item(
        id: 'test123',
        name: 'Test Item',
        description: 'Test Description',
        category: 'Electronics',
        subCategory: 'Laptops',
        ownerId: 'owner123',
        ownerName: 'John Doe',
        images: ['img1.jpg', 'img2.jpg'],
        rentalPeriods: {'daily': 50.0, 'weekly': 300.0},
        insurance: insurance,
        latitude: 31.5,
        longitude: 35.0,
        averageRating: 4.5,
        ratingCount: 10,
        status: 'approved',
        submittedAt: now,
        updatedAt: now,
      );

      expect(item.id, 'test123');
      expect(item.name, 'Test Item');
      expect(item.description, 'Test Description');
      expect(item.category, 'Electronics');
      expect(item.subCategory, 'Laptops');
      expect(item.ownerId, 'owner123');
      expect(item.ownerName, 'John Doe');
      expect(item.images, ['img1.jpg', 'img2.jpg']);
      expect(item.rentalPeriods, {'daily': 50.0, 'weekly': 300.0});
      expect(item.insurance.amount, 100.0);
      expect(item.latitude, 31.5);
      expect(item.longitude, 35.0);
      expect(item.averageRating, 4.5);
      expect(item.ratingCount, 10);
      expect(item.status, 'approved');
      expect(item.submittedAt, now);
      expect(item.updatedAt, now);
    });

    test('Item with null optional values', () {
      final insurance = Insurance(
        amount: 100.0,
        originalPrice: 1000.0,
        rate: 10.0,
      );

      final item = Item(
        id: 'test123',
        name: 'Test Item',
        description: 'Test Description',
        category: 'Electronics',
        subCategory: 'Laptops',
        ownerId: 'owner123',
        ownerName: 'John Doe',
        images: ['img1.jpg'],
        rentalPeriods: {'daily': 50.0},
        insurance: insurance,
        latitude: null,
        longitude: null,
        averageRating: 0.0,
        ratingCount: 0,
        status: 'pending',
        submittedAt: null,
        updatedAt: null,
      );

      expect(item.latitude, isNull);
      expect(item.longitude, isNull);
      expect(item.submittedAt, isNull);
      expect(item.updatedAt, isNull);
    });
  });

  group('Item Model Tests - fromMap', () {
    test('Item.fromMap with complete data', () {
      final data = {
        "itemId": "test123",
        "name": "iPhone 15",
        "description": "Brand new iPhone",
        "category": "Electronics",
        "subCategory": "Phones",
        "ownerId": "owner123",
        "ownerName": "Jane Smith",
        "images": ["img1.jpg", "img2.jpg"],
        "rentalPeriods": {"daily": 20.0, "weekly": 100.0},
        "insurance": {
          "insuranceAmount": 200.0,
          "itemOriginalPrice": 2000.0,
          "ratePercentage": 10.0,
        },
        "latitude": 31.5,
        "longitude": 35.0,
        "averageRating": 4.8,
        "ratingCount": 25,
        "status": "approved",
        "submittedAt": Timestamp.fromDate(DateTime(2024, 1, 1)),
        "updatedAt": Timestamp.fromDate(DateTime(2024, 1, 2)),
      };

      final item = Item.fromMap(data);

      expect(item.id, "test123");
      expect(item.name, "iPhone 15");
      expect(item.insurance.amount, 200.0);
      expect(item.latitude, 31.5);
      expect(item.averageRating, 4.8);
      expect(item.ratingCount, 25);
      expect(item.status, "approved");
      expect(item.submittedAt, DateTime(2024, 1, 1));
      expect(item.updatedAt, DateTime(2024, 1, 2));
    });

  
    test('Item.fromMap with null values', () {
      final data = {
        "name": null,
        "description": null,
        "images": null,
        "rentalPeriods": null,
        "insurance": null,
        "latitude": null,
        "longitude": null,
        "submittedAt": null,
        "updatedAt": null,
      };

      final item = Item.fromMap(data);

      expect(item.name, "");
      expect(item.description, "");
      expect(item.images, isEmpty);
      expect(item.rentalPeriods, isEmpty);
      expect(item.insurance.amount, 0.0);
      expect(item.latitude, isNull);
      expect(item.longitude, isNull);
      expect(item.submittedAt, isNull);
      expect(item.updatedAt, isNull);
    });

    test('Item.fromMap with integer numeric values', () {
      final data = {
        "averageRating": 5, 
        "ratingCount": 10, 
        "latitude": 31, 
        "longitude": 35, 
      };

      final item = Item.fromMap(data);

      expect(item.averageRating, 5.0);
      expect(item.ratingCount, 10);
      expect(item.latitude, 31.0);
      expect(item.longitude, 35.0);
    });
  });

  group('Item Model Tests - buildSearchKeywords', () {
    test('buildSearchKeywords generates correct keywords', () {
      final insurance = Insurance(
        amount: 100.0,
        originalPrice: 1000.0,
        rate: 10.0,
      );

      final item = Item(
        id: '1',
        name: 'MacBook Pro',
        description: 'Apple laptop 16GB RAM',
        category: 'Electronics',
        subCategory: 'Laptops',
        ownerId: 'owner1',
        ownerName: 'John Apple',
        images: [],
        rentalPeriods: {},
        insurance: insurance,
        latitude: null,
        longitude: null,
        averageRating: 0.0,
        ratingCount: 0,
        status: 'approved',
      );

      final keywords = item.buildSearchKeywords();

     
      expect(keywords, contains('mac'));
      expect(keywords, contains('macb'));
      expect(keywords, contains('macbo'));
      expect(keywords, contains('apple'));
      expect(keywords, contains('app'));
      expect(keywords, contains('laptop'));
      expect(keywords, contains('electronics'));
      expect(keywords, contains('john'));

      
      expect(keywords.every((k) => k == k.toLowerCase()), true);

      
      expect(keywords.any((k) => k.contains(' ')), false);
    });

    test('buildSearchKeywords with special characters', () {
      final insurance = Insurance(
        amount: 100.0,
        originalPrice: 1000.0,
        rate: 10.0,
      );

      final item = Item(
        id: '1',
        name: 'iPhone 15-Pro!',
        description: 'Apple\'s latest phone',
        category: 'Electronics/Phones',
        subCategory: 'Smartphones',
        ownerId: 'owner1',
        ownerName: 'John-Doe',
        images: [],
        rentalPeriods: {},
        insurance: insurance,
        latitude: null,
        longitude: null,
        averageRating: 0.0,
        ratingCount: 0,
        status: 'approved',
      );

      final keywords = item.buildSearchKeywords();

     
      expect(keywords.any((k) => k.contains('-')), false);
      expect(keywords.any((k) => k.contains('!')), false);
      expect(keywords.any((k) => k.contains('\'')), false);
      expect(keywords.any((k) => k.contains('/')), false);

     
      expect(keywords, contains('iphone'));
      expect(keywords, contains('apple'));
      expect(keywords, contains('latest'));
    });

    test('buildSearchKeywords with empty strings', () {
      final insurance = Insurance(
        amount: 100.0,
        originalPrice: 1000.0,
        rate: 10.0,
      );

      final item = Item(
        id: '1',
        name: '',
        description: '',
        category: '',
        subCategory: '',
        ownerId: '',
        ownerName: '',
        images: [],
        rentalPeriods: {},
        insurance: insurance,
        latitude: null,
        longitude: null,
        averageRating: 0.0,
        ratingCount: 0,
        status: 'approved',
      );

      final keywords = item.buildSearchKeywords();

      
      expect(keywords, isEmpty);
    });

    test('buildSearchKeywords returns unique values', () {
      final insurance = Insurance(
        amount: 100.0,
        originalPrice: 1000.0,
        rate: 10.0,
      );

      final item = Item(
        id: '1',
        name: 'test test test', 
        description: 'test',
        category: 'test',
        subCategory: 'test',
        ownerId: 'test',
        ownerName: 'test',
        images: [],
        rentalPeriods: {},
        insurance: insurance,
        latitude: null,
        longitude: null,
        averageRating: 0.0,
        ratingCount: 0,
        status: 'approved',
      );

      final keywords = item.buildSearchKeywords();

      final testPrefixes = ['t', 'te', 'tes', 'test'];
      for (final prefix in testPrefixes) {
        expect(keywords.where((k) => k == prefix).length, 1);
      }
    });
  });

  group('Item Model Tests - Helper Methods', () {
    test('isApproved returns true for approved status', () {
      final insurance = Insurance(
        amount: 100.0,
        originalPrice: 1000.0,
        rate: 10.0,
      );

      final approvedItem = Item(
        id: '1',
        name: 'Test',
        description: '',
        category: '',
        subCategory: '',
        ownerId: '',
        ownerName: '',
        images: [],
        rentalPeriods: {},
        insurance: insurance,
        latitude: null,
        longitude: null,
        averageRating: 0.0,
        ratingCount: 0,
        status: 'approved',
      );

      final pendingItem = Item(
        id: '1',
        name: 'Test',
        description: '',
        category: '',
        subCategory: '',
        ownerId: '',
        ownerName: '',
        images: [],
        rentalPeriods: {},
        insurance: insurance,
        latitude: null,
        longitude: null,
        averageRating: 0.0,
        ratingCount: 0,
        status: 'pending',
      );

      expect(approvedItem.isApproved, true);
      expect(pendingItem.isApproved, false);
    });

    test('getPriceText with rental periods', () {
      final insurance = Insurance(
        amount: 100.0,
        originalPrice: 1000.0,
        rate: 10.0,
      );

      final itemWithDaily = Item(
        id: '1',
        name: 'Test',
        description: '',
        category: '',
        subCategory: '',
        ownerId: '',
        ownerName: '',
        images: [],
        rentalPeriods: {'daily': 50.0},
        insurance: insurance,
        latitude: null,
        longitude: null,
        averageRating: 0.0,
        ratingCount: 0,
        status: 'approved',
      );

      final itemWithWeekly = Item(
        id: '2',
        name: 'Test',
        description: '',
        category: '',
        subCategory: '',
        ownerId: '',
        ownerName: '',
        images: [],
        rentalPeriods: {'weekly': 300.0},
        insurance: insurance,
        latitude: null,
        longitude: null,
        averageRating: 0.0,
        ratingCount: 0,
        status: 'approved',
      );

      final itemWithMultiple = Item(
        id: '3',
        name: 'Test',
        description: '',
        category: '',
        subCategory: '',
        ownerId: '',
        ownerName: '',
        images: [],
        rentalPeriods: {'daily': 50.0, 'weekly': 300.0},
        insurance: insurance,
        latitude: null,
        longitude: null,
        averageRating: 0.0,
        ratingCount: 0,
        status: 'approved',
      );

      expect(itemWithDaily.getPriceText(), "From 50.0 JD daily");
      expect(itemWithWeekly.getPriceText(), "From 300.0 JD weekly");
     
      expect(itemWithMultiple.getPriceText(), "From 50.0 JD daily");
    });

    test('getPriceText with no rental periods', () {
      final insurance = Insurance(
        amount: 100.0,
        originalPrice: 1000.0,
        rate: 10.0,
      );

      final item = Item(
        id: '1',
        name: 'Test',
        description: '',
        category: '',
        subCategory: '',
        ownerId: '',
        ownerName: '',
        images: [],
        rentalPeriods: {},
        insurance: insurance,
        latitude: null,
        longitude: null,
        averageRating: 0.0,
        ratingCount: 0,
        status: 'approved',
      );

      expect(item.getPriceText(), "No price");
    });

    test('getPriceText with integer price', () {
      final insurance = Insurance(
        amount: 100.0,
        originalPrice: 1000.0,
        rate: 10.0,
      );

      final item = Item(
        id: '1',
        name: 'Test',
        description: '',
        category: '',
        subCategory: '',
        ownerId: '',
        ownerName: '',
        images: [],
        rentalPeriods: {'daily': 50}, 
        insurance: insurance,
        latitude: null,
        longitude: null,
        averageRating: 0.0,
        ratingCount: 0,
        status: 'approved',
      );

      expect(item.getPriceText(), "From 50 JD daily");
    });
  });

  group('Item Model Tests - toMap', () {
    test('Item.toMap returns correct structure', () {
      final now = DateTime.now();
      final insurance = Insurance(
        amount: 100.0,
        originalPrice: 1000.0,
        rate: 10.0,
      );

      final item = Item(
        id: 'test123',
        name: 'Test Item',
        description: 'Description',
        category: 'Category',
        subCategory: 'SubCategory',
        ownerId: 'owner123',
        ownerName: 'Owner Name',
        images: ['img1.jpg'],
        rentalPeriods: {'daily': 50.0},
        insurance: insurance,
        latitude: 31.5,
        longitude: 35.0,
        averageRating: 4.5,
        ratingCount: 10,
        status: 'approved',
        submittedAt: now,
        updatedAt: now,
      );

      final map = item.toMap();

      expect(map["name"], "Test Item");
      expect(map["description"], "Description");
      expect(map["category"], "Category");
      expect(map["subCategory"], "SubCategory");
      expect(map["ownerId"], "owner123");
      expect(map["ownerName"], "Owner Name");
      expect(map["images"], ["img1.jpg"]);
      expect(map["rentalPeriods"], {"daily": 50.0});
      expect(map["insurance"], insurance.toMap());
      expect(map["latitude"], 31.5);
      expect(map["longitude"], 35.0);
      expect(map["averageRating"], 4.5);
      expect(map["ratingCount"], 10);
      expect(map["status"], "approved");
      expect(map["submittedAt"], Timestamp.fromDate(now));
      expect(map["updatedAt"], Timestamp.fromDate(now));
      expect(map["searchKeywords"], isA<List<String>>());
    });

    test('Item.toMap with null optional fields', () {
      final insurance = Insurance(
        amount: 100.0,
        originalPrice: 1000.0,
        rate: 10.0,
      );

      final item = Item(
        id: 'test123',
        name: 'Test Item',
        description: 'Description',
        category: 'Category',
        subCategory: 'SubCategory',
        ownerId: 'owner123',
        ownerName: 'Owner Name',
        images: ['img1.jpg'],
        rentalPeriods: {'daily': 50.0},
        insurance: insurance,
        latitude: null,
        longitude: null,
        averageRating: 4.5,
        ratingCount: 10,
        status: 'approved',
        submittedAt: null,
        updatedAt: null,
      );

      final map = item.toMap();

      expect(map["latitude"], isNull);
      expect(map["longitude"], isNull);
      expect(map["submittedAt"], isNull);
      expect(map["updatedAt"], isNull);
    });
  });

  group('Item Model Tests - Edge Cases', () {
    test('Handles very long strings in buildSearchKeywords', () {
      final insurance = Insurance(
        amount: 100.0,
        originalPrice: 1000.0,
        rate: 10.0,
      );

      final longName = 'a' * 1000; 
      final item = Item(
        id: '1',
        name: longName,
        description: '',
        category: '',
        subCategory: '',
        ownerId: '',
        ownerName: '',
        images: [],
        rentalPeriods: {},
        insurance: insurance,
        latitude: null,
        longitude: null,
        averageRating: 0.0,
        ratingCount: 0,
        status: 'approved',
      );

      final keywords = item.buildSearchKeywords();


      expect(keywords.length, greaterThan(1));
      expect(keywords.first.length, 1);
    });

    test('Handles numeric values in text for search keywords', () {
      final insurance = Insurance(
        amount: 100.0,
        originalPrice: 1000.0,
        rate: 10.0,
      );

      final item = Item(
        id: '1',
        name: 'iPhone 15 Pro Max 256GB',
        description: '2024 model',
        category: '',
        subCategory: '',
        ownerId: '',
        ownerName: '',
        images: [],
        rentalPeriods: {},
        insurance: insurance,
        latitude: null,
        longitude: null,
        averageRating: 0.0,
        ratingCount: 0,
        status: 'approved',
      );

      final keywords = item.buildSearchKeywords();

      
      expect(keywords, contains('15'));
      expect(keywords, contains('256'));
      expect(keywords, contains('2024'));
    });

    test('Handles non-English characters', () {
      final insurance = Insurance(
        amount: 100.0,
        originalPrice: 1000.0,
        rate: 10.0,
      );

      final item = Item(
        id: '1',
        name: 'مرحبا بالعالم',
        description: 'اختبار',
        category: '',
        subCategory: '',
        ownerId: '',
        ownerName: '',
        images: [],
        rentalPeriods: {},
        insurance: insurance,
        latitude: null,
        longitude: null,
        averageRating: 0.0,
        ratingCount: 0,
        status: 'approved',
      );

      final keywords = item.buildSearchKeywords();

     
      expect(keywords, isEmpty);
    });
  });
}
