import 'package:cloud_firestore/cloud_firestore.dart';

class ItemService {
  static final _db = FirebaseFirestore.instance;

  static Stream<QuerySnapshot> getProducts(String category, String subCategory) {
    return _db
        .collection("items")
        .where("category", isEqualTo: category)
        .where("subCategory", isEqualTo: subCategory)
        .where("status", isEqualTo: "approved")
        .snapshots();
  }

  static Stream<QuerySnapshot> searchProducts(
      String category,
      String subCategory,
      String query,
      ) {
    if (query.isEmpty) {
      return getProducts(category, subCategory);
    }

    return _db
        .collection("items")
        .where("category", isEqualTo: category)
        .where("subCategory", isEqualTo: subCategory)
        .where("status", isEqualTo: "approved")
        .where("searchKeywords", arrayContains: query.toLowerCase())
        .snapshots();
  }

  static Stream<QuerySnapshot> searchItems(String query) {
    return _db
        .collection("items")
        .where("status", isEqualTo: "approved")
        .where("searchKeywords", arrayContains: query.toLowerCase())
        .snapshots();
  }

}
