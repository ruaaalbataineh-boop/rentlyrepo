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
  final String insurance; // تغيير من Map? إلى String
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
    required this.insurance, // required الآن
    this.latitude,
    this.longitude,
    required this.averageRating,
    required this.ratingCount,
    required this.status,
    this.submittedAt,
    this.updatedAt,
  });

  /// Create object from Firestore
  factory Item.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // تحويل insurance من dynamic إلى String
    String insuranceValue = "Not specified";
    if (data["insurance"] != null) {
      if (data["insurance"] is String) {
        insuranceValue = data["insurance"] as String;
      } else if (data["insurance"] is Map) {
        // إذا كان Map، تحويله إلى String
        final insuranceMap = data["insurance"] as Map<String, dynamic>;
        // محاولة استخراج قيمة مفيدة
        if (insuranceMap.containsKey("type")) {
          insuranceValue = insuranceMap["type"].toString();
        } else if (insuranceMap.containsKey("required")) {
          insuranceValue = insuranceMap["required"].toString();
        } else {
          insuranceValue = insuranceMap.toString();
        }
      } else {
        insuranceValue = data["insurance"].toString();
      }
    }

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
      insurance: insuranceValue,
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

  /// Create a safe copy with sanitized data
  factory Item.sanitized({
    required String id,
    required String name,
    required String description,
    required String category,
    required String subCategory,
    required String ownerId,
    required String ownerName,
    required List<String> images,
    required Map<String, dynamic> rentalPeriods,
    required String insurance,
    double? latitude,
    double? longitude,
    required double averageRating,
    required int ratingCount,
    required String status,
    DateTime? submittedAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id,
      name: name,
      description: description,
      category: category,
      subCategory: subCategory,
      ownerId: ownerId,
      ownerName: ownerName,
      images: images,
      rentalPeriods: rentalPeriods,
      insurance: insurance,
      latitude: latitude,
      longitude: longitude,
      averageRating: averageRating,
      ratingCount: ratingCount,
      status: status,
      submittedAt: submittedAt,
      updatedAt: updatedAt,
    );
  }

  /// Validate item data for security
  bool isValid() {
    return name.isNotEmpty &&
           category.isNotEmpty &&
           subCategory.isNotEmpty &&
           ownerId.isNotEmpty &&
           status.isNotEmpty &&
           images.isNotEmpty;
  }

  /// Get minimum rental price
  double? getMinRentalPrice() {
    if (rentalPeriods.isEmpty) return null;
    
    double? minPrice;
    rentalPeriods.values.forEach((price) {
      final doublePrice = double.tryParse(price.toString());
      if (doublePrice != null && (minPrice == null || doublePrice < minPrice!)) {
        minPrice = doublePrice;
      }
    });
    return minPrice;
  }

  /// Get formatted price text
  String getPriceText() {
    final minPrice = getMinRentalPrice();
    if (minPrice == null) return "No rental price";
    
    return "From JOD ${minPrice.toStringAsFixed(2)} / ${rentalPeriods.keys.first}";
  }

  /// Get formatted rental periods
  List<String> getFormattedRentalPeriods() {
    final formatted = <String>[];
    rentalPeriods.forEach((period, price) {
      formatted.add("$period: $price JOD");
    });
    return formatted.isEmpty ? ["Price information not available"] : formatted;
  }

  /// Check if item is approved
  bool get isApproved => status == "approved";
  
  /// Check if item is pending
  bool get isPending => status == "pending";
  
  /// Check if item is rejected
  bool get isRejected => status == "rejected";

  /// Create a copy with updated values
  Item copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? subCategory,
    String? ownerId,
    String? ownerName,
    List<String>? images,
    Map<String, dynamic>? rentalPeriods,
    String? insurance,
    double? latitude,
    double? longitude,
    double? averageRating,
    int? ratingCount,
    String? status,
    DateTime? submittedAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      images: images ?? this.images,
      rentalPeriods: rentalPeriods ?? this.rentalPeriods,
      insurance: insurance ?? this.insurance,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Item{id: $id, name: $name, category: $category, status: $status}';
  }
}
