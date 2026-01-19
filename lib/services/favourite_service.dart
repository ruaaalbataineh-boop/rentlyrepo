import 'package:cloud_firestore/cloud_firestore.dart';

class FavouriteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addFavourite(String uid, String itemId) {
    return _db
        .collection("users")
        .doc(uid)
        .collection("favourites")
        .doc(itemId)
        .set({"createdAt": FieldValue.serverTimestamp()});
  }

  Future<void> removeFavourite(String uid, String itemId) {
    return _db
        .collection("users")
        .doc(uid)
        .collection("favourites")
        .doc(itemId)
        .delete();
  }

  Future<List<Map<String, dynamic>>> getFavouriteItems(List<String> ids) async {
    if (ids.isEmpty) return [];

    final snap = await _db
        .collection("items")
        .where("itemId", whereIn: ids)
        .get();

    return snap.docs.map((d) {
      final data = d.data();
      data["itemId"] = d.id;
      return data;
    }).toList();
  }

  Future<bool> isFavourite(String uid, String itemId) async {
    final doc = await _db
        .collection("users")
        .doc(uid)
        .collection("favourites")
        .doc(itemId)
        .get();
    return doc.exists;
  }

  Stream<Set<String>> favouritesStream(String uid) {
    return _db
        .collection("users")
        .doc(uid)
        .collection("favourites")
        .snapshots()
        .map((s) => s.docs.map((d) => d.id).toSet());
  }
}
