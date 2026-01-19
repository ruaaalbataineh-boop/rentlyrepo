import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:p2/security/error_handler.dart';

class StorageService {

  static Future<String> uploadVerificationImage(
      String uid, File file, String fileName) async {

    try {
      final ref = FirebaseStorage.instance
          .ref("identity_docs")
          .child(uid)
          .child(fileName);

      await ref.putFile(file);
      return await ref.getDownloadURL();

    } catch (e) {
      ErrorHandler.logError("Upload Verification Image", e);
      throw Exception("Failed to upload verification image");
    }
  }

  static Future<String> uploadItemImage(
      String ownerId, String itemId, File file, String fileName) async {

    try {
      final ref = FirebaseStorage.instance
          .ref("rental_items")
          .child(itemId)
          .child(fileName);

      await ref.putFile(
        file,
        SettableMetadata(
          customMetadata: {"ownerUid": ownerId},
        ),
      );

      return await ref.getDownloadURL();

    } catch (e) {
      ErrorHandler.logError("Upload Item Image", e);
      throw Exception("Failed to upload item image");
    }
  }

  static Future<String> uploadReportMedia({
    required String requestId,
    required File file,
    required String fileName,
  }) async {
    try {
      final ref = FirebaseStorage.instance
          .ref("rental_reports")
          .child(requestId)
          .child(fileName);

      await ref.putFile(file);
      return await ref.getDownloadURL();

    } catch (e) {
      ErrorHandler.logError("Upload Report Media", e);
      throw Exception("Failed to upload report media");
    }
  }
}
