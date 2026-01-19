import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/Item.dart';
import '../services/equipment_detail_service.dart';

class EquipmentDetailController extends ChangeNotifier {
  final EquipmentDetailService _service;

  EquipmentDetailController(this._service);

  bool isLoading = true;

  late Item item;
  String ownerName = "Loading...";
  double renterWallet = 0.0;
  List<Map<String, dynamic>> topReviews = [];
  List<DateTimeRange> unavailableRanges = [];
  Map<String, dynamic>? insuranceInfo;

  // Rental state
  String? selectedPeriod; // daily/weekly/monthly/yearly only
  DateTime? startDate;
  DateTime? endDate;
  int count = 1;
  String? pickupTime;
  bool insuranceAccepted = false;

  // Pricing
  double insuranceAmount = 0.0;
  double rentalPrice = 0.0;
  double totalPrice = 0.0;

  String? currentUserId;

  static const int bufferDays = 5;

  bool get isOwner => currentUserId != null && item.ownerId == currentUserId;

  bool get hasSufficientBalance => renterWallet >= totalPrice;

  bool isRentalBlockedUser = false;

  Future<void> load({
    required Item item,
    required String currentUserId,
  }) async {
    try {
      this.item = item;
      this.currentUserId = currentUserId;

      isLoading = true;
      notifyListeners();

      ownerName = await _service.getOwnerName(item.ownerId);
      renterWallet = await _service.getWalletBalance(currentUserId);
      isRentalBlockedUser = await _service.isUserRentalBlocked(currentUserId);
      insuranceInfo = await _service.getItemInsurance(item.id);
      topReviews = await _service.getTopReviews(item.id);

      final raw = await _service.getUnavailableRanges(item.id);
      unavailableRanges = _applyBuffer(raw);

      _recalculate();
    } catch (e) {
      debugPrint("Equipment load failed: $e");
      unavailableRanges = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<DateTimeRange> _applyBuffer(List<DateTimeRange> raw) {
    return raw.map((r) {
      return DateTimeRange(
        start: r.start.subtract(const Duration(days: bufferDays)),
        end: r.end.add(const Duration(days: bufferDays)),
      );
    }).toList();
  }

  static List<DateTime> buildBlockedDays(List<DateTimeRange> rentals) {
    final blocked = <DateTime>[];

    for (final r in rentals) {
      final start = r.start;
      final end = r.end;

      DateTime d = start;
      while (!d.isAfter(end)) {
        blocked.add(DateTime(d.year, d.month, d.day));
        d = d.add(const Duration(days: 1));
      }
    }

    return blocked;
  }

  void selectPeriod(String period) {
    selectedPeriod = period;
    startDate = null;
    endDate = null;
    count = 1;
    pickupTime = null;
    insuranceAccepted = false;
    _recalculate();
    notifyListeners();
  }

  void setStartDate(DateTime d) {
    startDate = d;
    calculateEndDate();
    _recalculate();
    notifyListeners();
  }

  void incrementCount() {
    count++;
    calculateEndDate();
    _recalculate();
    notifyListeners();
  }

  void decrementCount() {
    if (count <= 1) return;
    count--;
    calculateEndDate();
    _recalculate();
    notifyListeners();
  }

  void setPickupTime(String time) {
    pickupTime = time;
    notifyListeners();
  }

  void setInsuranceAccepted(bool v) {
    insuranceAccepted = v;
    notifyListeners();
  }

  void calculateEndDate() {
    if (selectedPeriod == null || startDate == null) {
      endDate = null;
      return;
    }

    final p = selectedPeriod!.toLowerCase();

    int days = 0;
    if (p == "daily") days = count;
    if (p == "weekly") days = count * 7;
    if (p == "monthly") days = count * 30;
    if (p == "yearly") days = count * 365;

    endDate = startDate!.add(Duration(days: days));
  }

  void _recalculate() {
    rentalPrice = _computeRentalPrice();
    insuranceAmount = _computeInsuranceAmount();
    totalPrice = rentalPrice + insuranceAmount;
  }

  double _computeRentalPrice() {
    if (selectedPeriod == null) return 0;
    final base = (item.rentalPeriods[selectedPeriod] as num?)?.toDouble() ?? 0;
    return base * count;
  }

  double _computeInsuranceAmount() {
    if (insuranceInfo == null) return 0;
    final original = (insuranceInfo!["itemOriginalPrice"] as num?)?.toDouble() ?? 0;
    final rate = (insuranceInfo!["ratePercentage"] as num?)?.toDouble() ?? 0;
    return original * rate;
  }

  bool checkDateConflict() {
    if (startDate == null || endDate == null) return false;

    for (final range in unavailableRanges) {
      final overlap = startDate!.isBefore(range.end) && endDate!.isAfter(range.start);
      if (overlap) return true;
    }
    return false;
  }

  bool canRent() {
    if (isRentalBlockedUser) return false;
    if (selectedPeriod == null) return false;
    if (startDate == null || endDate == null) return false;
    if (pickupTime == null) return false;
    if (!insuranceAccepted) return false;
    if (checkDateConflict()) return false;
    if (!hasSufficientBalance) return false;
    return true;
  }

  String getUnitLabel() {
    if (selectedPeriod == null) return "";
    switch (selectedPeriod!.toLowerCase()) {
      case "daily":
        return "Days";
      case "weekly":
        return "Weeks";
      case "monthly":
        return "Months";
      case "yearly":
        return "Years";
      default:
        return "";
    }
  }

  String formatEndDate() {
    if (endDate == null) return "";
    return DateFormat("yyyy-MM-dd").format(endDate!);
  }

  String getRentButtonText() {
    if (isRentalBlockedUser) return "You Are Blocked From Renting Items";
    if (selectedPeriod == null) return "Select Rental Period";
    if (startDate == null || endDate == null) return "Select Dates First";
    if (checkDateConflict()) return "Unavailable Date Ranges";
    if (!insuranceAccepted) return "Accept Insurance Terms First";
    if (pickupTime == null) return "Select Pickup Time";
    if (!hasSufficientBalance) return "Insufficient Balance";

    return "Rent Now";
  }

  String get penaltyMessage =>
      "Late return will result in penalties based on daily rate.";

  Future<void> createRentalRequest() async {
    if (!canRent()) throw Exception("Incomplete rental data");

    await FirebaseAuth.instance.currentUser?.getIdToken(true);

    final payload = {
      "itemId": item.id,
      "itemTitle": item.name,
      "itemOwnerUid": item.ownerId,
      "ownerName": ownerName,
      "renterUid": currentUserId,
      "status": "pending",
      "rentalType": selectedPeriod,
      "rentalQuantity": count,
      "startDate": startDate!.millisecondsSinceEpoch,
      "endDate": endDate!.millisecondsSinceEpoch,
      "pickupTime": pickupTime,
      "rentalPrice": rentalPrice,
      "totalPrice": totalPrice,
      "insurance": {
        "itemOriginalPrice": insuranceInfo?["itemOriginalPrice"] ?? 0,
        "ratePercentage": insuranceInfo?["ratePercentage"] ?? 0,
        "amount": insuranceAmount,
        "accepted": insuranceAccepted,
      },
      "createdAt": DateTime.now().toIso8601String(),
    };

    await _service.createRentalRequest(payload);
  }
}
