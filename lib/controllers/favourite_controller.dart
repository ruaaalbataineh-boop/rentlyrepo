import 'package:flutter/foundation.dart';

import '../services/favourite_service.dart';

class FavouriteController extends ChangeNotifier {
  final FavouriteService _service;

  FavouriteController(this._service);

  Set<String> favourites = {};
  List<Map<String, dynamic>> items = [];

  bool isLoading = true;

  late String _uid;

  void bind(String uid) {
    _uid = uid;

    _service.favouritesStream(uid).listen((ids) async {
      favourites = ids;
      await _loadItems();
    });
  }

  void bindIfNeeded(String uid) {
    if (_uid == uid) return;
    bind(uid);
  }

  Future<void> _loadItems() async {
    isLoading = true;
    notifyListeners();

    if (favourites.isEmpty) {
      items = [];
      isLoading = false;
      notifyListeners();
      return;
    }

    items = await _service.getFavouriteItems(favourites.toList());
    isLoading = false;
    notifyListeners();
  }

  bool get hasFavourites => favourites.isNotEmpty;

  String get emptyMessage => "Your favourite items will appear here.";
  String get noItemsMessage => "No favourite items found.";

  bool isFavourite(String itemId) {
    return favourites.contains(itemId);
  }

  Future<void> toggle(String itemId) async {
    if (isFavourite(itemId)) {
      favourites.remove(itemId);
      notifyListeners();
      await _service.removeFavourite(_uid, itemId);
    } else {
      favourites.add(itemId);
      notifyListeners();
      await _service.addFavourite(_uid, itemId);
    }
  }

  void remove(String itemId) {
    toggle(itemId);
  }

  // UI helpers
  String getItemId(Map<String, dynamic> d) => d["itemId"];
  String getItemName(Map<String, dynamic> d) => d["name"];
  String? getItemImage(Map<String, dynamic> d) {
    final imgs = d["images"];
    if (imgs is List && imgs.isNotEmpty) return imgs[0];
    return null;
  }
  String getItemPriceText(Map<String, dynamic> d) {
    final rental = d["rentalPeriods"];
    if (rental is Map && rental.isNotEmpty) {
      final key = rental.keys.first;
      return "From ${rental[key]}JD / $key";
    }
    return "Price not available";
  }

}
