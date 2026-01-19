import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/Item.dart';

class ItemController {
  static List<Item> mapToItems(List<QueryDocumentSnapshot> docs) {
    return docs.map((doc) => Item.fromFirestore(doc)).toList();
  }

  static List<Item> filter(List<Item> items, String query) {
    if (query.isEmpty) return items;

    final q = query.toLowerCase();

    return items.where((i) =>
    i.name.toLowerCase().contains(q) ||
        i.description.toLowerCase().contains(q) ||
        i.category.toLowerCase().contains(q) ||
        i.subCategory.toLowerCase().contains(q) ||
        i.ownerName.toLowerCase().contains(q)
    ).toList();
  }
}
