import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/favourite_logic.dart';
import 'package:p2/FavouriteManager.dart';

void main() {
  late FavouriteLogic favouriteLogic;

  setUp(() {
    FavouriteManager.favouriteIds.clear();
    favouriteLogic = FavouriteLogic();
  });

  group('Add and Remove Favourites', () {
    test('should add a valid favourite', () {
      favouriteLogic.addFavourite("item1");

      expect(favouriteLogic.favouriteIds, contains("item1"));
      expect(FavouriteManager.isFavourite("item1"), true);
    });

    test('should not add an invalid favourite', () {
      favouriteLogic.addFavourite("!@#invalid");

      expect(favouriteLogic.favouriteIds, isEmpty);
    });

    test('should remove a favourite', () {
      favouriteLogic.addFavourite("item1");
      favouriteLogic.removeFavourite("item1");

      expect(favouriteLogic.favouriteIds, isEmpty);
      expect(FavouriteManager.isFavourite("item1"), false);
    });
  });

  group('Clear All Favourites', () {
    test('should clear all favourites', () async {
      favouriteLogic.addFavourite("item1");
      favouriteLogic.addFavourite("item2");

      await favouriteLogic.clearAllFavourites();

      expect(favouriteLogic.favouriteIds, isEmpty);
      expect(FavouriteManager.favouriteIds, isEmpty);
    });
  });

  group('Item Validation', () {
    test('should return valid favourite count', () {
      favouriteLogic.addFavourite("item1");
      favouriteLogic.addFavourite("item2");
      favouriteLogic.addFavourite("!@#"); 

      expect(favouriteLogic.getValidFavouriteCount(), 2);
    });

    test('should check if item is favourite', () {
      favouriteLogic.addFavourite("item1");
      expect(favouriteLogic.isItemFavourite("item1"), true);
      expect(favouriteLogic.isItemFavourite("invalid!"), false);
    });
  });
}
