import 'dart:io';

import '../services/pending_user_service.dart';
import '../services/storage_service.dart';

class ContinueCreateAccountController {
  Future<void> submit({
    required String uid,
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required String birthDate,
    required File idImage,
    required File faceImage,
  }) async {

    final idUrl = await StorageService.uploadVerificationImage(
      uid,
      idImage,
      "id.jpg",
    );

    final selfieUrl = await StorageService.uploadVerificationImage(
      uid,
      faceImage,
      "selfie.jpg",
    );

    await PendingUserService.submitUserForApproval({
      "userId": uid,
      "email": email,
      "firstName": firstName,
      "lastName": lastName,
      "phone": phone,
      "birthDate": birthDate,
      "idPhotoUrl": idUrl,
      "selfiePhotoUrl": selfieUrl,
    });
  }
}
