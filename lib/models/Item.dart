import 'package:cloud_firestore/cloud_firestore.dart';

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

  final Map<String, dynamic>? insurance;

  final double? latitude;
  final double? longitude;

  final double averageRating;
  final int ratingCount;

  final String status; // pending, approved, rejected
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
    required this.status,
    this.insurance,
    required this.latitude,
    required this.longitude,
    required this.averageRating,
    required this.ratingCount,
    this.submittedAt,
    this.updatedAt,
  });

  /// Create object from Firestore
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

      insurance: data["insurance"],

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

  /// Convert to Firestore map
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

      "insurance": insurance,

      "latitude": latitude,
      "longitude": longitude,

      "averageRating": averageRating,
      "ratingCount": ratingCount,

      "status": status,
      "submittedAt": submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      "updatedAt": updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

}
