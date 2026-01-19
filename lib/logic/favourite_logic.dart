import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:p2/security/secure_storage.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/input_validator.dart';
import 'package:p2/security/route_guard.dart';

class FavouriteLogic {
  //List<String> get favouriteIds => FavouriteManager.favouriteIds;
  //bool get hasFavourites => FavouriteManager.favouriteIds.isNotEmpty;
  String get emptyMessage => "Your favourite items will appear here.";
  String get noItemsMessage => "No favourite items found.";

  // Security variables
  bool _isInitialized = false;
  int _maxRequestRetries = 3;
  final Duration _requestTimeout = Duration(seconds: 15);

  Future<void> initialize() async {
    try {
      // Security: Validate route access
      if (!RouteGuard.isAuthenticated()) {
        throw Exception('User not authenticated');
      }

      // Load favourite IDs from secure storage
      await _loadFavouritesFromStorage();
      
      _isInitialized = true;
      ErrorHandler.logInfo('FavouriteLogic', 'Initialized successfully');
      
    } catch (error) {
      ErrorHandler.logError('FavouriteLogic Initialization', error);
    }
  }

  Future<void> _loadFavouritesFromStorage() async {
    try {
      final storedFavourites = await SecureStorage.getData('user_favourites');
      if (storedFavourites != null) {
        final decoded = ErrorHandler.safeJsonDecode(storedFavourites);
        if (decoded is List) {
          // Security: Validate and sanitize stored IDs
          //FavouriteManager.favouriteIds = decoded
             // .where((id) => id is String && _isValidItemId(id))
          //    .map((id) => InputValidator.sanitizeInput(id.toString()))
           //   .toList()
            //  .cast<String>();
        }
      }
    } catch (error) {
      ErrorHandler.logError('Load Favourites From Storage', error);
    }
  }

  Future<void> _saveFavouritesToStorage() async {
    try {
      // Security: Validate favourite IDs before saving
      //final validFavourites = favouriteIds.where((id) => _isValidItemId(id)).toList();

    } catch (error) {
      ErrorHandler.logError('Save Favourites To Storage', error);
    }
  }

  bool _isValidItemId(String itemId) {
    if (itemId.isEmpty || itemId.length > 100) return false;
    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(itemId);
  }

  bool _isValidItemData(Map<String, dynamic> data) {
    try {
      // Validate required fields
      final itemId = data["itemId"]?.toString();
      if (itemId == null || itemId.isEmpty || !_isValidItemId(itemId)) {
        return false;
      }

      final name = data["name"]?.toString();
      if (name == null || name.isEmpty || name.length > 200) {
        return false;
      }

      // Security: Check for malicious code
      if (!InputValidator.hasNoMaliciousCode(name)) {
        return false;
      }

      // Validate images array
      final images = data["images"];
      if (images is List) {
        for (var image in images) {
          if (image != null && !_isValidImageUrl(image.toString())) {
            return false;
          }
        }
      }

      // Validate rental periods
      final rental = data["rentalPeriods"];
      if (rental is Map) {
        for (var price in rental.values) {
          final priceValue = double.tryParse(price.toString());
          if (priceValue == null || priceValue < 0 || priceValue > 10000) {
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      ErrorHandler.logError('Validate Item Data', e);
      return false;
    }
  }

  bool _isValidImageUrl(String url) {
    if (url.isEmpty || url.length > 1000) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  Map<String, dynamic> _sanitizeItemData(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);
    
    try {
      // Sanitize name
      if (sanitized.containsKey("name")) {
        sanitized["name"] = InputValidator.sanitizeInput(
            sanitized["name"].toString());
      }

      // Sanitize description if exists
      if (sanitized.containsKey("description")) {
        sanitized["description"] = InputValidator.sanitizeInput(
            sanitized["description"].toString());
      }

      // Sanitize category if exists
      if (sanitized.containsKey("category")) {
        sanitized["category"] = InputValidator.sanitizeInput(
            sanitized["category"].toString());
      }

      return sanitized;
    } catch (e) {
      ErrorHandler.logError('Sanitize Item Data', e);
      return data; // Return original data on error
    }
  }

  String getItemName(Map<String, dynamic> data) {
    try {
      final name = data["name"]?.toString() ?? "Item";
      return InputValidator.sanitizeInput(name);
    } catch (e) {
      ErrorHandler.logError('Get Item Name', e);
      return "Item";
    }
  }

  String? getItemImage(Map<String, dynamic> data) {
    try {
      final images = data["images"];
      if (images is List && images.isNotEmpty) {
        final imageUrl = images[0]?.toString();
        if (imageUrl != null && _isValidImageUrl(imageUrl)) {
          return imageUrl;
        }
      }
      return null;
    } catch (e) {
      ErrorHandler.logError('Get Item Image', e);
      return null;
    }
  }

  String getItemPriceText(Map<String, dynamic> data) {
    try {
      final rental = data["rentalPeriods"];
      if (rental is Map) {
        // Try to get hourly price first
        if (rental.containsKey("Hourly")) {
          final price = rental["Hourly"];
          final priceValue = double.tryParse(price.toString()) ?? 0.0;
          // Security: Validate price range
          final safePrice = priceValue.clamp(0.0, 1000.0);
          return "JOD ${safePrice.toStringAsFixed(2)} / hour";
        }
        
        // Or get the first available price
        final firstKey = rental.keys.firstOrNull;
        if (firstKey != null) {
          final firstPrice = rental[firstKey];
          final priceValue = double.tryParse(firstPrice.toString()) ?? 0.0;
          final safePrice = priceValue.clamp(0.0, 1000.0);
          return "JOD ${safePrice.toStringAsFixed(2)} / $firstKey";
        }
      }
      return "Price not available";
    } catch (e) {
      ErrorHandler.logError('Get Item Price Text', e);
      return "Price error";
    }
  }

  String getItemId(Map<String, dynamic> data) {
    try {
      final itemId = data["itemId"]?.toString() ?? "";
      if (_isValidItemId(itemId)) {
        return itemId;
      }
      return "";
    } catch (e) {
      ErrorHandler.logError('Get Item ID', e);
      return "";
    }
  }

  void removeFavourite(String itemId) {
    try {
      // Security: Validate item ID
      if (!_isValidItemId(itemId)) {
        ErrorHandler.logError('Remove Favourite', 'Invalid item ID: $itemId');
        return;
      }

      final sanitizedId = InputValidator.sanitizeInput(itemId);
      //FavouriteManager.remove(sanitizedId);
      
      // Save to secure storage
      _saveFavouritesToStorage();
      
      ErrorHandler.logInfo('FavouriteLogic', 
          'Removed favourite item: $sanitizedId');
          
    } catch (error) {
      ErrorHandler.logError('Remove Favourite', error);
    }
  }
}
