import 'package:cloud_firestore/cloud_firestore.dart';

//  INSURANCE MODEL
class Insurance {
  final double amount;
  final double originalPrice;
  final double rate;

  Insurance({
    required this.amount,
    required this.originalPrice,
    required this.rate,
  });

  factory Insurance.fromMap(Map<String, dynamic> map) {
    return Insurance(
      amount: (map["insuranceAmount"] ?? 0).toDouble(),
      originalPrice: (map["itemOriginalPrice"] ?? 0).toDouble(),
      rate: (map["ratePercentage"] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "insuranceAmount": amount,
      "itemOriginalPrice": originalPrice,
      "ratePercentage": rate,
    };
  }
}

//  ITEM MODEL
class Item {
  final String id;
  final String name;
  final String description;
  final String category;
  final String subCategory;

  final String ownerId;
  final String ownerName;

  final List<String> images;
  final Map<String, dynamic> rentalPeriods;

  final Insurance insurance;

  final double? latitude;
  final double? longitude;

  final double averageRating;
  final int ratingCount;
  final String status;

  final DateTime? submittedAt;
  final DateTime? updatedAt;

  Item({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.subCategory,
    required this.ownerId,
    required this.ownerName,
    required this.images,
    required this.rentalPeriods,
    required this.insurance,
    this.latitude,
    this.longitude,
    required this.averageRating,
    required this.ratingCount,
    required this.status,
    this.submittedAt,
    this.updatedAt,
  });

  List<String> buildSearchKeywords() {
    final text =
        "$name $description $category $subCategory $ownerName";

    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .split(" ");

    final Set<String> result = {};

    for (final word in words) {
      for (int i = 1; i <= word.length; i++) {
        result.add(word.substring(0, i));
      }
    }

    return result.toList();
  }

  factory Item.fromMap(Map<String, dynamic> data) {
    return Item(
      id: data["itemId"] ?? "",
      name: data["name"] ?? "",
      description: data["description"] ?? "",
      category: data["category"] ?? "",
      subCategory: data["subCategory"] ?? "",
      ownerId: data["ownerId"] ?? "",
      ownerName: data["ownerName"] ?? "",
      images: List<String>.from(data["images"] ?? []),
      rentalPeriods: Map<String, dynamic>.from(data["rentalPeriods"] ?? {}),
      insurance: Insurance.fromMap(data["insurance"] ?? {}),
      latitude: (data["latitude"] as num?)?.toDouble(),
      longitude: (data["longitude"] as num?)?.toDouble(),
      averageRating: (data["averageRating"] ?? 0).toDouble(),
      ratingCount: data["ratingCount"] ?? 0,
      status: data["status"] ?? "approved",
      submittedAt: data["submittedAt"] is Timestamp
          ? (data["submittedAt"] as Timestamp).toDate()
          : null,
      updatedAt: data["updatedAt"] is Timestamp
          ? (data["updatedAt"] as Timestamp).toDate()
          : null,
    );
  }

  // Create from Firestore
  factory Item.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Item(
      id: doc.id,
      name: data["name"] ?? "",
      description: data["description"] ?? "",
      category: data["category"] ?? "",
      subCategory: data["subCategory"] ?? "",
      ownerId: data["ownerId"] ?? "",
      ownerName: data["ownerName"] ?? "",
      images: List<String>.from(data["images"] ?? []),
      rentalPeriods: Map<String, dynamic>.from(data["rentalPeriods"] ?? {}),
      insurance: Insurance.fromMap(data["insurance"] ?? {}),
      latitude: (data["latitude"] as num?)?.toDouble(),
      longitude: (data["longitude"] as num?)?.toDouble(),
      averageRating: (data["averageRating"] ?? 0).toDouble(),
      ratingCount: data["ratingCount"] ?? 0,
      status: data["status"] ?? "pending",
      submittedAt: data["submittedAt"] != null
          ? (data["submittedAt"] as Timestamp).toDate()
          : null,
      updatedAt: (data["updatedAt"] as Timestamp?)?.toDate(),
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "description": description,
      "category": category,
      "subCategory": subCategory,
      "ownerId": ownerId,
      "ownerName": ownerName,
      "images": images,
      "rentalPeriods": rentalPeriods,
      "insurance": insurance.toMap(),
      "latitude": latitude,
      "longitude": longitude,
      "averageRating": averageRating,
      "ratingCount": ratingCount,
      "status": status,
      "searchKeywords": buildSearchKeywords(),
      "submittedAt": submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      "updatedAt": updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  bool get isApproved => status == "approved";

  String getPriceText() {
    if (rentalPeriods.isEmpty) return "No price";
    final first = rentalPeriods.values.first;
    return "From $first JD ${rentalPeriods.keys.first}";
  }
}
