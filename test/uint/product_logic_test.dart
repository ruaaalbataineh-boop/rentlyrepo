import 'package:flutter_test/flutter_test.dart';
import 'package:p2/controllers/item_controller.dart';
import 'package:p2/models/Item.dart';

void main() {
  group('ProductListPage Logic Unit Tests', () {
    late List<Item> items;

    setUp(() {
      items = [
        Item(
          id: '1',
          name: 'Electric Drill',
          description: 'Strong drill',
          category: 'Tools',
          subCategory: 'Electric',
          ownerId: 'o1',
          ownerName: 'Ahmad',
          images: ['img1'],
          rentalPeriods: {
            'day': 5,
          },
          insurance: Insurance(
            amount: 10,
            originalPrice: 100,
            rate: 10,
          ),
          averageRating: 4.5,
          ratingCount: 10,
          status: 'approved',
        ),
        Item(
          id: '2',
          name: 'Hammer',
          description: 'Steel hammer',
          category: 'Tools',
          subCategory: 'Manual',
          ownerId: 'o2',
          ownerName: 'Ali',
          images: ['img2'],
          rentalPeriods: {
            'day': 2,
          },
          insurance: Insurance(
            amount: 5,
            originalPrice: 50,
            rate: 10,
          ),
          averageRating: 4.0,
          ratingCount: 5,
          status: 'approved',
        ),
      ];
    });

   

    test('Filter returns all items when search is empty', () {
      final result = ItemController.filter(items, '');

      expect(result.length, 2);
    });

    test('Filter returns matching item by name', () {
      final result = ItemController.filter(items, 'drill');

      expect(result.length, 1);
      expect(result.first.name, 'Electric Drill');
    });

    test('Filter is case insensitive', () {
      final result = ItemController.filter(items, 'HAMMER');

      expect(result.length, 1);
      expect(result.first.name, 'Hammer');
    });

    test('Filter returns empty list when no match', () {
      final result = ItemController.filter(items, 'camera');

      expect(result.isEmpty, true);
    });

    

    test('getPriceText returns correct format', () {
      final text = items.first.getPriceText();

      expect(text.contains('From'), true);
      expect(text.contains('JD'), true);
    });

    test('getPriceText returns "No price" when rentalPeriods is empty', () {
  final itemWithoutPrice = Item(
    id: '3',
    name: 'Camera',
    description: 'Digital camera',
    category: 'Electronics',
    subCategory: 'Photography',
    ownerId: 'o3',
    ownerName: 'Sara',
    images: ['img3'],
    rentalPeriods: {}, 
    insurance: Insurance(
      amount: 5,
      originalPrice: 200,
      rate: 2.5,
    ),
    averageRating: 0,
    ratingCount: 0,
    status: 'approved',
  );

  expect(itemWithoutPrice.getPriceText(), 'No price');
});

  });
}
