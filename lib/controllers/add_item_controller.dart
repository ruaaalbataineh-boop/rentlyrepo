import 'dart:io';
import '../services/add_item_service.dart';
import '../security/input_validator.dart';
import '../services/auth_service.dart';

class AddItemController {

  static Future<void> submitItem({
    required AuthService authService,

    required String name,
    required String description,
    required String category,
    required String subCategory,
    required double originalPrice,
    required Map<String, dynamic> rentalPeriods,
    required double latitude,
    required double longitude,
    required List<File> pickedImages,
    required List<String> existingImages,
  }) async {

    if (!authService.isLoggedIn || authService.currentUid == null) {
      throw Exception("Authentication required");
    }

    final ownerId = authService.currentUid!;
    final itemId = DateTime.now().millisecondsSinceEpoch.toString();

    final uploadedUrls = await AddItemService.uploadImages(
      ownerId: ownerId,
      itemId: itemId,
      images: pickedImages,
    );

    final allImages = [...existingImages, ...uploadedUrls];

    if (allImages.isEmpty) {
      throw Exception("Please add at least one image");
    }

    if (allImages.length > 10) {
      throw Exception("Maximum 10 images allowed");
    }

    final insuranceRate = _getInsuranceRate(originalPrice);
    final insuranceAmount = originalPrice * insuranceRate;

    final payload = {
      "itemId": itemId,
      "ownerId": ownerId,
      "name": InputValidator.sanitizeInput(name.trim()),
      "description": InputValidator.sanitizeInput(description.trim()),
      "category": category,
      "subCategory": subCategory,
      "images": allImages,
      "rentalPeriods": rentalPeriods,
      "insurance": {
        "itemOriginalPrice": originalPrice,
        "ratePercentage": insuranceRate,
        "insuranceAmount": insuranceAmount,
      },
      "latitude": latitude,
      "longitude": longitude,
      "status": "pending",
      "createdAt": DateTime.now().millisecondsSinceEpoch,
      "updatedAt": DateTime.now().millisecondsSinceEpoch,
    };

    await AddItemService.submitForApproval(payload);
  }

  static double _getInsuranceRate(double itemPrice) {
    if (itemPrice <= 50) return 0.0;
    if (itemPrice <= 100) return 0.10;
    if (itemPrice <= 500) return 0.15;
    return 0.30;
  }
}
