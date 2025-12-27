
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:p2/models/Item.dart';

class ProductLogic {
  static List<QueryDocumentSnapshot> filterProducts(
      List<QueryDocumentSnapshot> docs,
      String searchQuery) {
    if (searchQuery.isEmpty) return docs;

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final title = (data["name"] ?? "").toString().toLowerCase();
      return title.contains(searchQuery.toLowerCase());
    }).toList();
  }

  static bool hasProducts(List docs) {
    return docs.isNotEmpty;
  }

  static String formatCategoryTitle(String category, String subCategory) {
    return "$category - $subCategory";
  }

  static Item convertToItem(String id, Map<String, dynamic> data) {
    return Item(
      id: id,
      name: data["name"] ?? "",
      description: data["description"] ?? "",
      category: data["category"] ?? "",
      subCategory: data["subCategory"] ?? "",
      ownerId: data["ownerId"] ?? "",
      ownerName: data["ownerName"] ?? "",
      images: List<String>.from(data["images"] ?? []),
      rentalPeriods: Map<String, dynamic>.from(data["rentalPeriods"] ?? {}),
      insurance: data["insurance"],
      latitude: (data["latitude"] as num?)?.toDouble(),
      longitude: (data["longitude"] as num?)?.toDouble(),
      averageRating: (data["averageRating"] ?? 0).toDouble(),
      ratingCount: data["ratingCount"] ?? 0,
      status: data["status"] ?? "approved",
      submittedAt: null,
      updatedAt: null,
    );
  }

  static String getPriceText(Map<String, dynamic> rental) {
    if (rental.isEmpty) {
      return "No rental price";
    }
    final firstKey = rental.keys.first;
    final firstPrice = rental[firstKey];
    return "From JOD $firstPrice / $firstKey";
  }

  static List<String> formatRentalPeriods(Map<String, dynamic> rental) {
    return rental.entries.map((entry) {
      return "${entry.key}: ${entry.value} JOD";
    }).toList();
  }

  static bool validateItemData(Map<String, dynamic> data) {
    return data.containsKey("name") &&
        data.containsKey("category") &&
        data.containsKey("subCategory");
  }

  
  static List<Map<String, dynamic>> filterProductsSimple(
      List<Map<String, dynamic>> products,
      String searchQuery) {
    if (searchQuery.isEmpty) return products;

    return products.where((product) {
      final title = (product["name"] ?? "").toString().toLowerCase();
      return title.contains(searchQuery.toLowerCase());
    }).toList();
  }
}
