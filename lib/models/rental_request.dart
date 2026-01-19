import 'package:cloud_firestore/cloud_firestore.dart';

class RentalRequest {
  final String id;
  final String itemId;
  final String itemTitle;
  final String itemOwnerUid;
  final String? ownerName;
  final String renterUid;
  final String renterName;
  final String rentalType;
  final int rentalQuantity;
  final DateTime startDate;
  final DateTime endDate;
  final String? pickupTime;
  final num rentalPrice;
  final num totalPrice;

  // Insurance information
  final Map<String, dynamic>? insurance;

  final String status;
  final String paymentStatus;
  final String? pickupQrToken;
  final DateTime? pickupQrGeneratedAt;
  final String? returnQrToken;
  final DateTime? returnQrGeneratedAt;

  final DateTime? reviewedByRenterAt;
  final DateTime? reviewedByOwnerAt;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  RentalRequest({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.itemOwnerUid,
    this.ownerName,
    required this.renterUid,
    required this.renterName,
    required this.rentalType,
    required this.rentalQuantity,
    required this.startDate,
    required this.endDate,
    this.pickupTime,
    required this.rentalPrice,
    required this.totalPrice,
    this.insurance,
    required this.status,
    required this.paymentStatus,
    this.pickupQrToken,
    this.pickupQrGeneratedAt,
    this.returnQrToken,
    this.returnQrGeneratedAt,
    this.reviewedByRenterAt,
    this.reviewedByOwnerAt,
    this.createdAt,
    this.updatedAt,
  });

  // Helper method to convert dynamic to DateTime
  static DateTime _toDate(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is int || value is double) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }

    if (value is String) {
      return DateTime.parse(value);
    }

    return DateTime.now();
  }

  // Factory constructor from Firestore document
  factory RentalRequest.fromFirestore(String id, Map<String, dynamic> data) {
    return RentalRequest(
      id: id,
      itemId: data["itemId"]?.toString() ?? "",
      itemTitle: data["itemTitle"]?.toString() ?? "",
      itemOwnerUid: data["itemOwnerUid"]?.toString() ?? "",
      ownerName: data["ownerName"]?.toString(),
      renterUid: data["renterUid"]?.toString() ?? "",
      renterName: data["renterName"]?.toString() ?? "",
      rentalType: data["rentalType"]?.toString() ?? "",
      rentalQuantity: (data["rentalQuantity"] as num?)?.toInt() ?? 0,
      startDate: _toDate(data["startDate"]),
      endDate: _toDate(data["endDate"]),
      pickupTime: data["pickupTime"]?.toString(),
      rentalPrice: (data["rentalPrice"] as num?) ?? 0,
      totalPrice: (data["totalPrice"] as num?) ?? 0,
      insurance: data["insurance"] is Map ? 
          Map<String, dynamic>.from(data["insurance"] as Map) : null,
      status: data["status"]?.toString() ?? "pending",
      paymentStatus: data["paymentStatus"]?.toString() ?? "locked",
      pickupQrToken: data["pickupQrToken"]?.toString(),
      pickupQrGeneratedAt: data["pickupQrGeneratedAt"] != null ? 
          _toDate(data["pickupQrGeneratedAt"]) : null,
      returnQrToken: data["returnQrToken"]?.toString(),
      returnQrGeneratedAt: data["returnQrGeneratedAt"] != null ? 
          _toDate(data["returnQrGeneratedAt"]) : null,
      reviewedByRenterAt: data["reviewedByRenterAt"] != null ?
          _toDate(data["reviewedByRenterAt"]) : null,
      reviewedByOwnerAt: data["reviewedByOwnerAt"] != null ?
          _toDate(data["reviewedByOwnerAt"]) : null,
      createdAt: data["createdAt"] != null ? 
          _toDate(data["createdAt"]) : null,
      updatedAt: data["updatedAt"] != null ? 
          _toDate(data["updatedAt"]) : null,
    );
  }

  // Factory constructor from JSON (for cache/storage)
  factory RentalRequest.fromJson(Map<String, dynamic> json) {
    return RentalRequest(
      id: json["id"]?.toString() ?? "",
      itemId: json["itemId"]?.toString() ?? "",
      itemTitle: json["itemTitle"]?.toString() ?? "",
      itemOwnerUid: json["itemOwnerUid"]?.toString() ?? "",
      ownerName: json["ownerName"]?.toString(),
      renterUid: json["renterUid"]?.toString() ?? "",
      renterName: json["renterName"]?.toString() ?? "",
      rentalType: json["rentalType"]?.toString() ?? "",
      rentalQuantity: (json["rentalQuantity"] as num?)?.toInt() ?? 0,
      startDate: DateTime.parse(json["startDate"]?.toString() ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json["endDate"]?.toString() ?? DateTime.now().toIso8601String()),
      pickupTime: json["pickupTime"]?.toString(),
      rentalPrice: (json["rentalPrice"] as num?) ?? 0,
      totalPrice: (json["totalPrice"] as num?) ?? 0,
      insurance: json["insurance"] is Map ? 
          Map<String, dynamic>.from(json["insurance"] as Map) : null,
      status: json["status"]?.toString() ?? "pending",
      paymentStatus: json["paymentStatus"]?.toString() ?? "locked",
      pickupQrToken: json["pickupQrToken"]?.toString(),
      pickupQrGeneratedAt: json["pickupQrGeneratedAt"] != null ? 
          DateTime.parse(json["pickupQrGeneratedAt"].toString()) : null,
      returnQrToken: json["returnQrToken"]?.toString(),
      returnQrGeneratedAt: json["returnQrGeneratedAt"] != null ? 
          DateTime.parse(json["returnQrGeneratedAt"].toString()) : null,
      reviewedByRenterAt: json["reviewedByRenterAt"] != null ?
          DateTime.parse(json["reviewedByRenterAt"].toString()) : null,
      reviewedByOwnerAt: json["reviewedByOwnerAt"] != null ?
          DateTime.parse(json["reviewedByOwnerAt"].toString()) : null,
      createdAt: json["createdAt"] != null ? 
          DateTime.parse(json["createdAt"].toString()) : null,
      updatedAt: json["updatedAt"] != null ? 
          DateTime.parse(json["updatedAt"].toString()) : null,
    );
  }

  // Convert to JSON (for cache/storage)
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "itemId": itemId,
      "itemTitle": itemTitle,
      "itemOwnerUid": itemOwnerUid,
      "ownerName": ownerName,
      "renterUid": renterUid,
      "renterName": renterName,
      "rentalType": rentalType,
      "rentalQuantity": rentalQuantity,
      "startDate": startDate.toIso8601String(),
      "endDate": endDate.toIso8601String(),
      "pickupTime": pickupTime,
      "rentalPrice": rentalPrice,
      "totalPrice": totalPrice,
      "insurance": insurance,
      "status": status,
      "paymentStatus": paymentStatus,
      "pickupQrToken": pickupQrToken,
      "pickupQrGeneratedAt": pickupQrGeneratedAt?.toIso8601String(),
      "returnQrToken": returnQrToken,
      "returnQrGeneratedAt": returnQrGeneratedAt?.toIso8601String(),
      "reviewedByRenterAt": reviewedByRenterAt?.toIso8601String(),
      "reviewedByOwnerAt": reviewedByOwnerAt?.toIso8601String(),
      "createdAt": createdAt?.toIso8601String(),
      "updatedAt": updatedAt?.toIso8601String(),
    };
  }

  // Helper getters for insurance data
  num get insuranceAmount => insurance?["amount"] as num? ?? 0;
  num get insuranceRate => insurance?["ratePercentage"] as num? ?? 0;
  num get insuranceOriginalPrice => insurance?["itemOriginalPrice"] as num? ?? 0;
  bool get insuranceAccepted => insurance?["accepted"] as bool? ?? false;

  // Copy with method for immutability
  RentalRequest copyWith({
    String? id,
    String? itemId,
    String? itemTitle,
    String? itemOwnerUid,
    String? ownerName,
    String? renterUid,
    String? renterName,
    String? rentalType,
    int? rentalQuantity,
    DateTime? startDate,
    DateTime? endDate,
    String? pickupTime,
    num? rentalPrice,
    num? totalPrice,
    Map<String, dynamic>? insurance,
    String? status,
    String? paymentStatus,
    String? pickupQrToken,
    DateTime? pickupQrGeneratedAt,
    String? returnQrToken,
    DateTime? returnQrGeneratedAt,
    DateTime? reviewedByRenterAt,
    DateTime? reviewedByOwnerAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RentalRequest(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemTitle: itemTitle ?? this.itemTitle,
      itemOwnerUid: itemOwnerUid ?? this.itemOwnerUid,
      ownerName: ownerName ?? this.ownerName,
      renterUid: renterUid ?? this.renterUid,
      renterName: renterName ?? this.renterName,
      rentalType: rentalType ?? this.rentalType,
      rentalQuantity: rentalQuantity ?? this.rentalQuantity,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      pickupTime: pickupTime ?? this.pickupTime,
      rentalPrice: rentalPrice ?? this.rentalPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      insurance: insurance ?? this.insurance,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      pickupQrToken: pickupQrToken ?? this.pickupQrToken,
      pickupQrGeneratedAt: pickupQrGeneratedAt ?? this.pickupQrGeneratedAt,
      returnQrToken: returnQrToken ?? this.returnQrToken,
      returnQrGeneratedAt: returnQrGeneratedAt ?? this.returnQrGeneratedAt,
      reviewedByRenterAt: reviewedByRenterAt ?? this.reviewedByRenterAt,
      reviewedByOwnerAt: reviewedByOwnerAt ?? this.reviewedByOwnerAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Check if request is active
  bool get isActive {
    return status == "active" && 
           DateTime.now().isAfter(startDate) && 
           DateTime.now().isBefore(endDate);
  }

  // Check if request is upcoming
  bool get isUpcoming {
    return status == "accepted" && DateTime.now().isBefore(startDate);
  }

  // Check if request is completed
  bool get isCompleted {
    return status == "ended" || 
           status == "cancelled" || 
           status == "rejected" || 
           status == "outdated";
  }

  // Calculate remaining time for active rentals
  Duration? get remainingTime {
    if (!isActive) return null;
    return endDate.difference(DateTime.now());
  }

  // Calculate progress percentage for active rentals
  double get progressPercentage {
    if (!isActive) return 0.0;
    
    final totalDuration = endDate.difference(startDate).inSeconds;
    final elapsedDuration = DateTime.now().difference(startDate).inSeconds;
    
    if (totalDuration == 0) return 0.0;
    
    return (elapsedDuration / totalDuration).clamp(0.0, 1.0);
  }
}
