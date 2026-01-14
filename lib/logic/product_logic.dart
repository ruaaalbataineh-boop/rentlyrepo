import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:p2/models/Item.dart';
import 'package:p2/security/input_validator.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/api_security.dart';
import 'package:p2/security/secure_storage.dart';

class ProductLogic {
  
  static Future<List<QueryDocumentSnapshot>> secureFilterProducts(
      List<QueryDocumentSnapshot> docs,
      String searchQuery) async {
    try {
      if (searchQuery.isEmpty) return docs;

      final safeSearchQuery = InputValidator.sanitizeInput(searchQuery.toLowerCase());
      
      final filteredDocs = docs.where((doc) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final title = (data["name"] ?? "").toString().toLowerCase();
          final safeTitle = InputValidator.sanitizeInput(title);
          
          
          if (!_validateProductSafety(data)) {
            ErrorHandler.logSecurity('Product Filter', 'Unsafe product detected: ${doc.id}');
            return false;
          }
          
          return safeTitle.contains(safeSearchQuery);
        } catch (e) {
          ErrorHandler.logError('Product Filter', e);
          return false;
        }
      }).toList();
      
      await _logFilterActivity(searchQuery, filteredDocs.length);
      return filteredDocs;
      
    } catch (error) {
      ErrorHandler.logError('Secure Filter Products', error);
      return docs;
    }
  }

  static bool _validateProductSafety(Map<String, dynamic> data) {
    try {
     
      final requiredFields = ['name', 'category', 'subCategory', 'ownerId'];
      for (var field in requiredFields) {
        if (data[field] == null || data[field].toString().isEmpty) {
          return false;
        }
      }

     
      final contentFields = ['name', 'description', 'category', 'subCategory'];
      for (var field in contentFields) {
        if (data[field] != null && !InputValidator.hasNoMaliciousCode(data[field].toString())) {
          return false;
        }
      }

     
      if (data['images'] is List) {
        for (var img in data['images'] as List) {
          if (img is String && !isValidImageUrl(img)) {
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static bool hasProducts(List docs) {
    return docs.isNotEmpty;
  }

  static String formatCategoryTitle(String category, String subCategory) {
    try {
      final safeCategory = InputValidator.sanitizeInput(category);
      final safeSubCategory = InputValidator.sanitizeInput(subCategory);
      
      
      final maxLength = 50;
      final formatted = "$safeCategory - $safeSubCategory";
      
      return formatted.length > maxLength 
          ? formatted.substring(0, maxLength) + '...'
          : formatted;
    } catch (e) {
      ErrorHandler.logError('Format Category Title', e);
      return "Products";
    }
  }

  static Item secureConvertToItem(String id, Map<String, dynamic> data) {
    try {
     
      if (!_isValidId(id)) {
        throw Exception('Invalid item ID');
      }

     
      final safeName = InputValidator.sanitizeInput(data["name"]?.toString() ?? "");
      final safeDescription = InputValidator.sanitizeInput(data["description"]?.toString() ?? "");
      final safeCategory = InputValidator.sanitizeInput(data["category"]?.toString() ?? "");
      final safeSubCategory = InputValidator.sanitizeInput(data["subCategory"]?.toString() ?? "");
      final safeOwnerId = InputValidator.sanitizeInput(data["ownerId"]?.toString() ?? "");
      final safeOwnerName = InputValidator.sanitizeInput(data["ownerName"]?.toString() ?? "");
      final safeStatus = InputValidator.sanitizeInput(data["status"]?.toString() ?? "approved");

    
      if (safeName.isEmpty || safeCategory.isEmpty || safeSubCategory.isEmpty) {
        throw Exception('Missing required fields');
      }

     
      final List<String> safeImages = [];
      if (data["images"] is List) {
        for (var img in data["images"] as List) {
          if (img is String) {
            final safeImg = InputValidator.sanitizeInput(img);
            if (safeImg.isNotEmpty && isValidImageUrl(safeImg)) {
              safeImages.add(safeImg);
            }
          }
        }
      }

      final Map<String, dynamic> safeRental = {};
      if (data["rentalPeriods"] is Map) {
        final rental = data["rentalPeriods"] as Map<String, dynamic>;
        rental.forEach((key, value) {
          final safeKey = InputValidator.sanitizeInput(key);
          if (safeKey.isNotEmpty && (value is num || value is String)) {
          
            final price = double.tryParse(value.toString());
            if (price != null && price >= 0) {
              safeRental[safeKey] = price;
            }
          }
        });
      }

     
      double? safeLatitude;
      double? safeLongitude;
      if (data["latitude"] != null && data["longitude"] != null) {
        final lat = (data["latitude"] as num?)?.toDouble();
        final lng = (data["longitude"] as num?)?.toDouble();
        

        if (lat != null && lng != null && 
            lat >= -90 && lat <= 90 && 
            lng >= -180 && lng <= 180) {
          safeLatitude = lat;
          safeLongitude = lng;
        }
      }

      
      return Item.sanitized(
        id: id,
        name: safeName,
        description: safeDescription,
        category: safeCategory,
        subCategory: safeSubCategory,
        ownerId: safeOwnerId,
        ownerName: safeOwnerName,
        images: safeImages,
        rentalPeriods: safeRental,
        insurance: _sanitizeInsurance(data["insurance"]),
        latitude: safeLatitude,
        longitude: safeLongitude,
        averageRating: _sanitizeRating((data["averageRating"] ?? 0).toDouble()),
        ratingCount: (data["ratingCount"] as int?) ?? 0,
        status: safeStatus,
        submittedAt: null,
        updatedAt: null,
      );
    } catch (error) {
      ErrorHandler.logError('Secure Convert To Item', error);
      
      return Item.sanitized(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        name: "Invalid Product",
        description: "Product data is corrupted",
        category: "unknown",
        subCategory: "unknown",
        ownerId: "",
        ownerName: "",
        images: [],
        rentalPeriods: {},
        insurance: "Not specified",
        latitude: null,
        longitude: null,
        averageRating: 0.0,
        ratingCount: 0,
        status: "error",
        submittedAt: null,
        updatedAt: null,
      );
    }
  }

  static String getPriceText(Map<String, dynamic> rental) {
    try {
      if (rental.isEmpty) {
        return "No rental price";
      }
      
      
      double? minPrice;
      String? minPeriod;
      
      rental.forEach((period, price) {
        final doublePrice = double.tryParse(price.toString());
        if (doublePrice != null && (minPrice == null || doublePrice < minPrice!)) {
          minPrice = doublePrice;
          minPeriod = period;
        }
      });
      
      if (minPrice != null && minPeriod != null) {
        final safeKey = InputValidator.sanitizeInput(minPeriod!);
        final safePrice = minPrice?.toStringAsFixed(2);
        return "From JOD $safePrice / $safeKey";
      }
      
      return "Price not available";
    } catch (e) {
      ErrorHandler.logError('Get Price Text', e);
      return "Price not available";
    }
  }

  static List<String> formatRentalPeriods(Map<String, dynamic> rental) {
    try {
      final formatted = <String>[];
      rental.entries.forEach((entry) {
        final safeKey = InputValidator.sanitizeInput(entry.key);
        final safeValue = entry.value?.toString() ?? "0";
        formatted.add("$safeKey: $safeValue JOD");
      });
      
      return formatted.isEmpty ? ["Price information not available"] : formatted;
    } catch (e) {
      ErrorHandler.logError('Format Rental Periods', e);
      return ["Price information not available"];
    }
  }

  static bool validateItemData(Map<String, dynamic> data) {
    try {
     
      final requiredFields = ['name', 'category', 'subCategory', 'ownerId'];
      for (var field in requiredFields) {
        if (data[field] == null || data[field].toString().isEmpty) {
          return false;
        }
      }

    
      final contentFields = ['name', 'category', 'subCategory', 'description'];
      for (var field in contentFields) {
        if (data[field] != null && !InputValidator.hasNoMaliciousCode(data[field].toString())) {
          return false;
        }
      }

      final status = data["status"]?.toString();
      if (status != null && status != "approved") {
        return false;
      }

     
      if (data['images'] is List) {
        for (var img in data['images'] as List) {
          if (img is String && !isValidImageUrl(img)) {
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

  static Future<List<Map<String, dynamic>>> secureFilterProductsSimple(
      List<Map<String, dynamic>> products,
      String searchQuery) async {
    try {
      if (searchQuery.isEmpty) return products;

      final safeSearchQuery = InputValidator.sanitizeInput(searchQuery.toLowerCase());
      
      final filtered = products.where((product) {
        try {
      
          if (!validateItemData(product)) {
            return false;
          }
          
          final title = (product["name"] ?? "").toString().toLowerCase();
          final safeTitle = InputValidator.sanitizeInput(title);
          return safeTitle.contains(safeSearchQuery);
        } catch (e) {
          ErrorHandler.logError('Filter Products Simple', e);
          return false;
        }
      }).toList();
      
      await _logFilterActivity(searchQuery, filtered.length);
      return filtered;
      
    } catch (error) {
      ErrorHandler.logError('Secure Filter Products Simple', error);
      return products;
    }
  }

  static bool isValidImageUrl(String url) {
    try {
      if (url.isEmpty) return false;
      
      final uri = Uri.tryParse(url);
      if (uri == null) return false;
      
     
      if (uri.scheme != 'http' && uri.scheme != 'https') return false;
      if (uri.host.isEmpty) return false;
      
      
      if (!InputValidator.hasNoMaliciousCode(url)) return false;
      
   
      final lowerUrl = url.toLowerCase();
      if (lowerUrl.contains('javascript:') || 
          lowerUrl.contains('data:') ||
          lowerUrl.contains('vbscript:')) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  static List<QueryDocumentSnapshot> secureFilterByOwner(
      List<QueryDocumentSnapshot> docs,
      String ownerId) {
    try {
      final safeOwnerId = InputValidator.sanitizeInput(ownerId);
      
      
      if (!_isValidId(safeOwnerId)) {
        return [];
      }
      
      return docs.where((doc) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final docOwnerId = data["ownerId"]?.toString() ?? "";
          
         
          if (!_validateProductSafety(data)) {
            return false;
          }
          
          return docOwnerId == safeOwnerId;
        } catch (e) {
          ErrorHandler.logError('Secure Filter By Owner', e);
          return false;
        }
      }).toList();
    } catch (error) {
      ErrorHandler.logError('Secure Filter By Owner', error);
      return [];
    }
  }

  static List<QueryDocumentSnapshot> secureSortByPrice(
      List<QueryDocumentSnapshot> docs,
      bool ascending) {
    try {
      docs.sort((a, b) {
        try {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          
          
          if (!_validateProductSafety(dataA) || !_validateProductSafety(dataB)) {
            return 0;
          }
          
          final rentalA = Map<String, dynamic>.from(dataA["rentalPeriods"] ?? {});
          final rentalB = Map<String, dynamic>.from(dataB["rentalPeriods"] ?? {});
          
          double priceA = double.infinity;
          double priceB = double.infinity;
          
          if (rentalA.isNotEmpty) {
            final firstValue = rentalA.values.first;
            priceA = double.tryParse(firstValue.toString()) ?? double.infinity;
          }
          
          if (rentalB.isNotEmpty) {
            final firstValue = rentalB.values.first;
            priceB = double.tryParse(firstValue.toString()) ?? double.infinity;
          }
          
          return ascending ? priceA.compareTo(priceB) : priceB.compareTo(priceA);
        } catch (e) {
          ErrorHandler.logError('Secure Sort By Price', e);
          return 0;
        }
      });
      return docs;
    } catch (error) {
      ErrorHandler.logError('Secure Sort By Price', error);
      return docs;
    }
  }

  static String _sanitizeInsurance(dynamic insurance) {
    if (insurance == null) {
      return "Not specified";
    }
    
    final safeInsurance = InputValidator.sanitizeInput(insurance.toString());
    final allowedValues = ["required", "not required", "optional", "not specified"];
    
    final lowerInsurance = safeInsurance.toLowerCase();
    return allowedValues.contains(lowerInsurance) 
        ? safeInsurance 
        : "Not specified";
  }

  static double _sanitizeRating(double rating) {
    if (rating < 0) return 0.0;
    if (rating > 5) return 5.0;
    return rating;
  }

  static bool _isValidId(String id) {
    if (id.isEmpty) return false;
    if (id.length > 100) return false;
    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id);
  }

  static Future<void> _logFilterActivity(String query, int resultCount) async {
    try {
      await ApiSecurity.securePost(
        endpoint: 'logs/filter',
        data: {
          'action': 'product_filter',
          'query': query,
          'result_count': resultCount,
          'timestamp': DateTime.now().toIso8601String(),
          'device_info': 'mobile_app',
        },
        requiresAuth: false,
      );
    } catch (e) {
      ErrorHandler.logInfo('Log Filter Activity', 'Failed to log filter activity');
    }
  }

  
  static Future<bool> checkProductSafety(String itemId) async {
    try {
      final token = await SecureStorage.getToken();
      
      final response = await ApiSecurity.secureGet(
        endpoint: 'products/validate',
        queryParams: {'itemId': itemId},
        token: token,
        requiresAuth: true,
      );
      
      return response['success'] == true && 
             response['data']?['isSafe'] == true;
    } catch (e) {
      ErrorHandler.logError('Check Product Safety', e);
      return false;
    }
  }

  
  static Item createItemFromDoc(QueryDocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      return secureConvertToItem(doc.id, data);
    } catch (error) {
      ErrorHandler.logError('Create Item From Doc', error);
      return Item.sanitized(
        id: doc.id,
        name: "Error Loading",
        description: "Failed to load product data",
        category: "error",
        subCategory: "error",
        ownerId: "",
        ownerName: "",
        images: [],
        rentalPeriods: {},
        insurance: "Not specified",
        latitude: null,
        longitude: null,
        averageRating: 0.0,
        ratingCount: 0,
        status: "error",
        submittedAt: null,
        updatedAt: null,
      );
    }
  }
}
