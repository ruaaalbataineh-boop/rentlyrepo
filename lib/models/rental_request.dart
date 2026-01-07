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

  final String? startTime;
  final String? endTime;
  final String? pickupTime;

  final num rentalPrice;
  final num totalPrice;

  final num insuranceAmount;
  final num insuranceRate;
  final num insuranceOriginalPrice;
  final bool insuranceAccepted;

  final num penaltyHourlyRate;
  final num penaltyDailyRate;
  final num penaltyMaxHours;
  final num penaltyMaxDays;

  final String status;
  final String paymentStatus;

  final String? pickupQrToken;
  final DateTime? pickupQrGeneratedAt;
  final String? returnQrToken;
  final DateTime? returnQrGeneratedAt;

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
    this.startTime,
    this.endTime,
    this.pickupTime,
    required this.rentalPrice,
    required this.totalPrice,
    required this.insuranceAmount,
    required this.insuranceRate,
    required this.insuranceOriginalPrice,
    required this.insuranceAccepted,
    required this.penaltyHourlyRate,
    required this.penaltyDailyRate,
    required this.penaltyMaxHours,
    required this.penaltyMaxDays,
    required this.status,
    required this.paymentStatus,
    this.pickupQrToken,
    this.pickupQrGeneratedAt,
    this.returnQrToken,
    this.returnQrGeneratedAt,
    this.createdAt,
    this.updatedAt,
  });

  static DateTime _toDate(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      return DateTime.parse(value);
    }

    throw Exception("Invalid date format in RentalRequest");
  }

  factory RentalRequest.fromFirestore(String id, Map<String, dynamic> data) {
    final insurance = (data["insurance"] ?? {}) as Map<String, dynamic>;
    final penalty = (data["penalty"] ?? {}) as Map<String, dynamic>;

    return RentalRequest(
      id: id,
      itemId: data["itemId"] ?? "",
      itemTitle: data["itemTitle"] ?? "",
      itemOwnerUid: data["itemOwnerUid"] ?? "",
      ownerName: data["ownerName"],

      renterUid: data["renterUid"] ?? "",
      renterName: data["renterName"] ?? "",

      rentalType: data["rentalType"] ?? "",
      rentalQuantity: data["rentalQuantity"] ?? 0,

      startDate: _toDate(data["startDate"]),
      endDate: _toDate(data["endDate"]),

      startTime: data["startTime"],
      endTime: data["endTime"],
      pickupTime: data["pickupTime"],

      rentalPrice: data["rentalPrice"] ?? 0,
      totalPrice: data["totalPrice"] ?? 0,

      insuranceAmount: insurance["amount"] ?? 0,
      insuranceRate: insurance["ratePercentage"] ?? 0,
      insuranceOriginalPrice: insurance["itemOriginalPrice"] ?? 0,
      insuranceAccepted: insurance["accepted"] ?? false,

      penaltyHourlyRate: penalty["hourlyRate"] ?? 0,
      penaltyDailyRate: penalty["dailyRate"] ?? 0,
      penaltyMaxHours: penalty["maxHours"] ?? 0,
      penaltyMaxDays: penalty["maxDays"] ?? 0,

      status: data["status"] ?? "pending",
      paymentStatus: data["paymentStatus"] ?? "locked",

      pickupQrToken: data["pickupQrToken"],
      pickupQrGeneratedAt: data["pickupQrGeneratedAt"] != null
          ? (data["pickupQrGeneratedAt"] as Timestamp).toDate()
          : null,
      returnQrToken: data["returnQrToken"],
      returnQrGeneratedAt: data["returnQrGeneratedAt"] != null
          ? (data["returnQrGeneratedAt"] as Timestamp).toDate()
          : null,

      createdAt: data["createdAt"] != null
          ? (data["createdAt"] as Timestamp).toDate()
          : null,

      updatedAt: data["updatedAt"] != null
          ? (data["updatedAt"] as Timestamp).toDate()
          : null,
    );
  }
}
