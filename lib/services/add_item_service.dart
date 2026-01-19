import 'dart:io';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';

class AddItemService {

  static Future<List<String>> uploadImages({
    required String ownerId,
    required String itemId,
    required List<File> images,
  }) async {
    List<String> urls = [];

    for (int i = 0; i < images.length; i++) {
      final url = await StorageService.uploadItemImage(
        ownerId,
        itemId,
        images[i],
        "photo_$i.jpg",
      );
      urls.add(url);
    }

    return urls;
  }

  static Future<void> submitForApproval(Map<String, dynamic> payload) async {
    await FirestoreService.submitItemForApproval(payload);
  }
}
