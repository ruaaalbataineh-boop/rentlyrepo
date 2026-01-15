
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:p2/models/Item.dart';
import 'package:p2/services/firestore_service.dart';
import 'package:p2/user_manager.dart';
import 'dart:convert';

// Add security imports
import 'package:p2/security/api_security.dart';
import 'package:p2/security/secure_storage.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/input_validator.dart';
import 'package:p2/security/route_guard.dart';

class EquipmentDetailLogic {
  
  late Item? _item;
  String ownerName = "Loading...";
  double renterWallet = 0.0;
  List<Map<String, dynamic>> topReviews = [];
  List<DateTimeRange> unavailableRanges = [];
  Map<String, dynamic>? itemInsuranceInfo;
  bool loadingAvailability = false;

  // Rental state
  String? selectedPeriod;
  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  int count = 1;
  String? pickupTime;
  bool insuranceAccepted = false;

  // Calculations
  double insuranceAmount = 0.0;
  double rentalPrice = 0.0;
  double totalRequired = 0.0;
  double totalPrice = 0.0;
  bool hasSufficientBalance = false;

  // Penalty info
  final double dailyPenaltyRate = 0.15;
  final double hourlyPenaltyRate = 0.05;
  final double maxPenaltyDays = 5;
  final double maxPenaltyHours = 24;
  String penaltyMessage = "";
  bool showPenaltyInfo = false;

  // Security variables - PUBLIC للوصول من UI
  int rentalAttempts = 0;
  final int maxRentalAttempts = 30;
  DateTime? lastRentalAttempt;
  final Duration rentalCooldown = const Duration(minutes: 2);
  bool isInitialized = false;
  String? userId;
  
  bool get isLocked => rentalAttempts >= maxRentalAttempts;
  bool get isOnCooldown => lastRentalAttempt != null && 
      DateTime.now().difference(lastRentalAttempt!) < rentalCooldown;

  // Getters
  Item? get item => _item;
  bool get isOwner => _item != null && _item!.ownerId == userId;

  EquipmentDetailLogic({String? userId}) {
    this.userId = userId ?? UserManager.uid;
  }

  Future<void> initialize() async {
    try {
      ErrorHandler.logInfo('EquipmentDetailLogic', 'Initializing...');
      
      // Security: Validate route access
      if (!RouteGuard.isAuthenticated()) {
  ErrorHandler.logSecurity(
    'EquipmentDetailLogic',
    'User not authenticated yet delaying init',
      );
      return;
    }

      // Security: Load rental attempt history
      await _loadRentalHistory();
      
      // Security: Validate user
      if (userId == null || !isValidUserId(userId!)) {
        throw Exception('Invalid user ID');
      }
      
      isInitialized = true;
      ErrorHandler.logSecurity('EquipmentDetailLogic', 'Initialized successfully');
      
    } catch (error) {
      ErrorHandler.logError('EquipmentDetailLogic Initialization', error);
      throw error;
    }
  }

  bool isValidUserId(String userId) {
    if (userId.isEmpty || userId.length > 128) return false;
    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(userId);
  }

  Future<void> _loadRentalHistory() async {
    try {
      final history = await SecureStorage.getData('rental_attempts_$userId');
      if (history != null) {
        rentalAttempts = int.tryParse(history) ?? 0;
      }
    } catch (error) {
      ErrorHandler.logError('Load Rental History', error);
    }
  }

  Future<void> _saveRentalHistory() async {
    try {
      await SecureStorage.saveData(
        'rental_attempts_$userId',
        rentalAttempts.toString(),
      );
    } catch (error) {
      ErrorHandler.logError('Save Rental History', error);
    }
  }

  Future<void> setItem(Item item) async {
    try {
      ErrorHandler.logInfo('EquipmentDetailLogic', 'Setting item: ${item.id}');
      
      // Security: Validate item data
      if (!_isValidItem(item)) {
        throw Exception('Invalid item data');
      }
      
      _item = item;
      
      // Security: Sanitize item data
      _sanitizeItemData();
      
      ErrorHandler.logSecurity('EquipmentDetailLogic', 'Item set successfully');
      
    } catch (error) {
      ErrorHandler.logError('Set Item', error);
      throw error;
    }
  }

  bool _isValidItem(Item item) {
    try {
      // Validate basic item properties
      if (item.id.isEmpty || item.id.length > 100) return false;
      if (item.name.isEmpty || item.name.length > 200) return false;
      if (item.description.length > 1000) return false;
      if (item.ownerId.isEmpty || !isValidUserId(item.ownerId)) return false;
      
      // Validate price ranges
      for (var price in item.rentalPeriods.values) {
        final priceValue = double.tryParse(price.toString());
        if (priceValue == null || priceValue < 0 || priceValue > 10000) {
          return false;
        }
      }
      
      // Security: Check for malicious code in name and description
      if (!InputValidator.hasNoMaliciousCode(item.name) ||
          !InputValidator.hasNoMaliciousCode(item.description)) {
        return false;
      }
      
      return true;
    } catch (e) {
      ErrorHandler.logError('Validate Item', e);
      return false;
    }
  }

  void _sanitizeItemData() {
    if (_item == null) return;
    
    try {
      // Sanitize item name and description
      final sanitizedName = InputValidator.sanitizeInput(_item!.name);
      final sanitizedDescription = InputValidator.sanitizeInput(_item!.description);
      
      // Create sanitized item
      _item = Item(
        id: _item!.id,
        name: sanitizedName,
        description: sanitizedDescription,
        category: _item!.category,
        subCategory: _item!.subCategory,
        images: _item!.images,
        rentalPeriods: _item!.rentalPeriods,
        averageRating: _item!.averageRating,
        ratingCount: _item!.ratingCount,
        ownerId: _item!.ownerId,
        ownerName: _item!.ownerName,
        latitude: _item!.latitude,
        longitude: _item!.longitude, 
        status: _item!.status ?? '', insurance: '',
      );
    } catch (error) {
      ErrorHandler.logError('Sanitize Item Data', error);
    }
  }

  Future<void> loadOwnerName(String uid) async {
    try {
      if (!isValidUserId(uid)) {
        ownerName = "Owner";
        return;
      }

      final snap = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (snap.exists) {
        final data = snap.data()!;

        final first = data["firstName"] ?? data["firstname"] ?? "";
        final last = data["lastName"] ?? data["lastname"] ?? "";

        final fullName = "$first $last".trim();

        if (fullName.isNotEmpty &&
            InputValidator.hasNoMaliciousCode(fullName)) {
          ownerName = InputValidator.sanitizeInput(fullName);
        } else {
          ownerName = "Owner";
        }
      } else {
        ownerName = "Owner";
      }

      ErrorHandler.logInfo('EquipmentDetailLogic', 'Owner name loaded: $ownerName');
    } catch (error) {
      ErrorHandler.logError('Load Owner Name (Firestore)', error);
      ownerName = "Owner";
    }
  }

  Future<void> loadItemInsuranceInfo(String itemId) async {
    try {
      // Security: Validate item ID
      if (!_isValidItemId(itemId)) {
        throw Exception('Invalid item ID');
      }

      // Secure API call for insurance info
      final snap = await FirebaseDatabase.instance
          .ref("items/$itemId/insurance")
          .get()
          .timeout(const Duration(seconds: 10));

      if (snap.exists && snap.value != null) {
        final data = Map<dynamic, dynamic>.from(snap.value as Map);
        
        // Security: Validate insurance data
        final originalPrice = _validatePrice(data['itemOriginalPrice'] ?? 1000.0);
        final rate = _validatePercentage(data['ratePercentage'] ?? 0.15);
        
        itemInsuranceInfo = {
          'itemOriginalPrice': originalPrice,
          'ratePercentage': rate,
        };
        
        calculateInsuranceAmount();
      } else {
        // Default values with security limits
        itemInsuranceInfo = {
          'itemOriginalPrice': 1000.0,
          'ratePercentage': 0.15,
        };
        insuranceAmount = 150.0;
      }
      
      ErrorHandler.logInfo('EquipmentDetailLogic', 'Insurance info loaded');
      
    } catch (error) {
      ErrorHandler.logError('Load Item Insurance Info', error);
      // Secure fallback values
      itemInsuranceInfo = {
        'itemOriginalPrice': 1000.0,
        'ratePercentage': 0.15,
      };
      insuranceAmount = 150.0;
    }
  }

  bool _isValidItemId(String itemId) {
    if (itemId.isEmpty || itemId.length > 100) return false;
    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(itemId);
  }

  double _validatePrice(dynamic price) {
    try {
      final priceValue = double.tryParse(price.toString()) ?? 1000.0;
      // Security: Limit price to reasonable range
      return priceValue.clamp(0.0, 100000.0);
    } catch (e) {
      return 1000.0;
    }
  }

  double _validatePercentage(dynamic percentage) {
    try {
      final rateValue = double.tryParse(percentage.toString()) ?? 0.15;
      // Security: Limit percentage to reasonable range
      return rateValue.clamp(0.0, 0.5); // Max 50%
    } catch (e) {
      return 0.15;
    }
  }

 /* Future<void> loadRenterWalletBalance() async {
    try {
      if (userId == null || !_isValidUserId(userId!)) {
        renterWallet = 0.0;
        _checkWalletBalance();
        return;
      }

      // Secure API call for wallet balance
      final snap = await FirebaseDatabase.instance
          .ref("users/$userId/wallet/balance")
          .get()
          .timeout(const Duration(seconds: 10));

      if (snap.exists && snap.value != null) {
        final balance = snap.value;
        final balanceValue = double.tryParse(balance.toString()) ?? 0.0;
        
        // Security: Limit balance display and store securely
        renterWallet = balanceValue.clamp(0.0, 100000.0);
        
        // Store balance securely for offline access
        await SecureStorage.saveData(
          'wallet_balance_$userId',
          renterWallet.toString(),
        );
      } else {
        // Security: Default balance from secure storage or fallback
        final cachedBalance = await SecureStorage.getData('wallet_balance_$userId');
        if (cachedBalance != null) {
          renterWallet = double.tryParse(cachedBalance) ?? 2000.0;
        } else {
          renterWallet = 2000.0;
        }
      }
      
      _checkWalletBalance();
      ErrorHandler.logInfo('EquipmentDetailLogic', 
          'Wallet balance loaded: JD ${renterWallet.toStringAsFixed(2)}');
      
    } catch (error) {
      ErrorHandler.logError('Load Renter Wallet Balance', error);
      // Try to load from secure storage on error
      final cachedBalance = await SecureStorage.getData('wallet_balance_$userId');
      renterWallet = cachedBalance != null ? double.tryParse(cachedBalance) ?? 0.0 : 0.0;
      _checkWalletBalance();
    }
  }
*/
 //new one for test 
 Future<void> loadRenterWalletBalance() async {
  try {
    final uid = userId ?? UserManager.uid;
    if (uid == null || uid.isEmpty) {
      renterWallet = 0.0;
      checkWalletBalance();
      return;
    }

    final stream = FirestoreService.combinedWalletStream(uid);

    final snapshot = await stream.first;

    renterWallet = snapshot['userBalance'] ?? 0.0;

    checkWalletBalance();
  } catch (e) {
    ErrorHandler.logError('Load Wallet Balance (EQ)', e);
    renterWallet = 0.0;
    checkWalletBalance();
  }
}

  Future<void> loadTopReviews(String itemId) async {
    try {
      if (!_isValidItemId(itemId)) {
        topReviews = [];
        return;
      }

      final snap = await FirebaseFirestore.instance
          .collection("reviews")
          .where("itemId", isEqualTo: itemId)
          .where("fromRole", isEqualTo: "renter")
          .orderBy("createdAt", descending: true)
          .limit(3)
          .get();

      topReviews = snap.docs.map((d) {
        final data = d.data();

        return {
          "rating": (data["rating"] ?? 0).toDouble(),
          "comment": data["comment"] ?? "",
          "createdAt": (data["createdAt"] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();

    } catch (error) {
      ErrorHandler.logError('Load Top Reviews (Firestore)', error);
      topReviews = [];
    }
  }

  Future<void> loadUnavailableRanges(String itemId) async {
    try {
      loadingAvailability = true;
      
      if (!_isValidItemId(itemId)) {
        unavailableRanges = [];
        loadingAvailability = false;
        return;
      }

      // Secure API call for rental requests
      final rentals = await FirestoreService.getAcceptedRequestsForItem(itemId);
      
      // Security: Validate and sanitize rental data
      unavailableRanges = rentals.map((r) {
        try {
          final startDateStr = r["startDate"]?.toString();
          final endDateStr = r["endDate"]?.toString();
          
          // Security: Validate date strings
          if (startDateStr == null || endDateStr == null) {
            throw Exception('Invalid date format');
          }
          
          final startDate = DateTime.parse(startDateStr);
          final endDate = DateTime.parse(endDateStr);
          
          // Security: Ensure valid date range
          if (endDate.isBefore(startDate)) {
            return DateTimeRange(start: startDate, end: startDate);
          }
          
          // Security: Limit date range to reasonable values
          final maxRange = startDate.add(const Duration(days: 365)); // Max 1 year rental
          final safeEndDate = endDate.isAfter(maxRange) ? maxRange : endDate;
          
          return DateTimeRange(start: startDate, end: safeEndDate);
        } catch (e) {
          // Skip invalid data
          ErrorHandler.logError('Parse Rental Date', e);
          return DateTimeRange(start: DateTime.now(), end: DateTime.now());
        }
      }).toList();
      
      // Security: Filter out invalid ranges
      unavailableRanges = unavailableRanges.where((range) => 
          range.duration.inDays >= 0 && range.duration.inDays <= 365).toList();
      
      loadingAvailability = false;
      ErrorHandler.logInfo('EquipmentDetailLogic', 
          'Loaded ${unavailableRanges.length} unavailable ranges');
      
    } catch (error) {
      ErrorHandler.logError('Load Unavailable Ranges', error);
      unavailableRanges = [];
      loadingAvailability = false;
    }
  }

  void calculateEndDate() {
    try {
      if (selectedPeriod == null) {
        endDate = null;
        return;
      }

      // Security: Sanitize and validate period
      final p = InputValidator.sanitizeInput(selectedPeriod!.toLowerCase());
      
      // Security: Validate period value
      if (!['daily', 'weekly', 'monthly', 'yearly'].contains(p)) {
        endDate = null;
        return;
      }

      if (p == "hourly") {
        if (startDate == null || startTime == null) {
          endDate = null;
          return;
        }
        
        // Security: Limit hours to reasonable amount
        final safeCount = count.clamp(1, 720); // Max 30 days in hours
        
        final startDateTime = DateTime(
          startDate!.year,
          startDate!.month,
          startDate!.day,
          startTime!.hour,
          startTime!.minute,
        );
        
        endDate = startDateTime.add(Duration(hours: safeCount));
      } else {
        if (startDate == null) {
          endDate = null;
          return;
        }
        
        // Security: Limit count to reasonable amounts
        int days = count;
        if (p == "daily") days = count.clamp(1, 365); // Max 1 year
        if (p == "weekly") days = (count.clamp(1, 52)) * 7; // Max 1 year
        if (p == "monthly") days = (count.clamp(1, 12)) * 30; // Max 1 year
        if (p == "yearly") days = (count.clamp(1, 1)) * 365; // Max 1 year
        
        endDate = startDate!.add(Duration(days: days));
      }
      
      calculateInsurance();
    } catch (error) {
      ErrorHandler.logError('Calculate End Date', error);
      endDate = null;
    }
  }

  double computeTotalPrice() {
    try {
      if (selectedPeriod == null || _item == null) return 0;
      
      final base = double.tryParse(_item!.rentalPeriods[selectedPeriod]?.toString() ?? '0') ?? 0;
      
      // Security: Validate and limit price
      final safeBase = base.clamp(0.0, 10000.0);
      final safeCount = count.clamp(1, 365);
      
      return safeBase * safeCount;
    } catch (error) {
      ErrorHandler.logError('Compute Total Price', error);
      return 0.0;
    }
  }

  void calculateInsurance() {
    try {
      if (_item == null || selectedPeriod == null || itemInsuranceInfo == null) return;
      
      rentalPrice = computeTotalPrice();
      calculateInsuranceAmount();
      totalPrice = rentalPrice + insuranceAmount;
      totalRequired = totalPrice;
      calculatePenalties();
      checkWalletBalance();
    } catch (error) {
      ErrorHandler.logError('Calculate Insurance', error);
    }
  }

  void calculateInsuranceAmount() {
    try {
      if (itemInsuranceInfo == null) return;
      
      final itemPrice = itemInsuranceInfo!['itemOriginalPrice'] ?? 0.0;
      final rate = itemInsuranceInfo!['ratePercentage'] ?? 0.0;
      insuranceAmount = itemPrice * rate;
      
      // Security: Round to nearest 5 and set minimum
      insuranceAmount = (insuranceAmount / 5).ceil() * 5.0;
      if (insuranceAmount < 5) insuranceAmount = 5.0;
      
      // Security: Cap insurance at reasonable amount
      insuranceAmount = insuranceAmount.clamp(5.0, 5000.0);
    } catch (error) {
      ErrorHandler.logError('Calculate Insurance Amount', error);
      insuranceAmount = 0.0;
    }
  }

  void calculatePenalties() {
    try {
      if (_item == null || selectedPeriod == null || itemInsuranceInfo == null) {
        penaltyMessage = "";
        showPenaltyInfo = false;
        return;
      }

      final isHourly = selectedPeriod!.toLowerCase() == "hourly";
      final itemOriginalPrice = itemInsuranceInfo!['itemOriginalPrice'] ?? 0.0;
      
      // Security: Calculate penalties with caps
      if (isHourly) {
        final penaltyPerHour = (itemOriginalPrice * hourlyPenaltyRate).clamp(0.0, 100.0);
        penaltyMessage = "⏰ Hourly rental: If late more than 24 hours:\n"
            "• 5% penalty per late hour (JD ${penaltyPerHour.toStringAsFixed(2)}/hour)\n"
            "• Maximum penalty: $maxPenaltyHours hours\n"
            "• Deducted from insurance\n";
      } else {
        final penaltyPerDay = (itemOriginalPrice * dailyPenaltyRate).clamp(0.0, 500.0);
        penaltyMessage = "📅 Daily/Weekly/Monthly: If late more than 5 days:\n"
            "• 15% penalty per late day (JD ${penaltyPerDay.toStringAsFixed(2)}/day)\n"
            "• Maximum penalty: $maxPenaltyDays days\n"
            "• Deducted from insurance\n";
      }
      
      showPenaltyInfo = true;
    } catch (error) {
      ErrorHandler.logError('Calculate Penalties', error);
      penaltyMessage = "";
      showPenaltyInfo = false;
    }
  }

  void checkWalletBalance() {
    try {
      hasSufficientBalance = renterWallet >= totalRequired;
    } catch (error) {
      ErrorHandler.logError('Check Wallet Balance', error);
      hasSufficientBalance = false;
    }
  }

  bool checkDateConflict() {
    try {
      if (startDate == null || endDate == null) return false;
      
      // Security: Ensure dates are valid
      if (endDate!.isBefore(startDate!)) return true;
      
      for (final range in unavailableRanges) {
        if ((startDate!.isBefore(range.end) || startDate!.isAtSameMomentAs(range.end)) &&
            (endDate!.isAfter(range.start) || endDate!.isAtSameMomentAs(range.start))) {
          return true;
        }
      }
      return false;
    } catch (error) {
      ErrorHandler.logError('Check Date Conflict', error);
      return true; // Return true on error to be safe
    }
  }

  // Security: Check if rental is allowed
  bool canRent() {
    if (!isInitialized) return false;
    if (isLocked) return false;
    if (isOnCooldown) return false;
    
    try {
      // Security: Validate all inputs
      if (selectedPeriod == null || !isValidPeriod(selectedPeriod!)) return false;
      if (startDate == null || !_isValidDate(startDate!)) return false;
      if (endDate == null || !_isValidDate(endDate!)) return false;
      if (pickupTime == null || !isValidPickupTime(pickupTime!)) return false;
      
      return insuranceAccepted &&
             hasSufficientBalance &&
             !checkDateConflict();
    } catch (error) {
      ErrorHandler.logError('Can Rent Check', error);
      return false;
    }
  }

  bool isValidPeriod(String period) {
    final validPeriods = ['daily', 'weekly', 'monthly', 'yearly'];
    final sanitized = InputValidator.sanitizeInput(period.toLowerCase());
    return validPeriods.contains(sanitized);
  }

  bool _isValidDate(DateTime date) {
    try {
      if (date.isBefore(DateTime.now())) return false;
      if (date.isAfter(DateTime.now().add(const Duration(days: 366)))) return false;
      return true;
    } catch (e) {
      return false;
    }
  }

  bool isValidPickupTime(String time) {
    try {
      if (time.isEmpty || time.length > 20) return false;
      return InputValidator.hasNoMaliciousCode(time);
    } catch (e) {
      return false;
    }
  }

  // Security: Get rental button text with security info
  String getRentButtonText() {
    try {
      if (!isInitialized) return "Loading...";
      if (isLocked) return "Too many attempts. Try later.";
      if (isOnCooldown) {
        final remaining = rentalCooldown - DateTime.now().difference(lastRentalAttempt!);
        final minutes = remaining.inMinutes;
        return "Please wait ${minutes > 0 ? '$minutes minutes' : 'a moment'}";
      }
      if (!hasSufficientBalance) return "Insufficient Wallet Balance";
      if (!insuranceAccepted) return "Accept Insurance Terms First";
      if (pickupTime == null) return "Select Pickup Time";
      if (startDate == null || endDate == null) return "Select Dates First";
      if (selectedPeriod == null) return "Select Rental Period";
      if (checkDateConflict()) return "Dates Not Available";
      
      // Security: Show remaining attempts
      final remainingAttempts = maxRentalAttempts - rentalAttempts;
      if (remainingAttempts <= 3) {
        return "Confirm & Rent ($remainingAttempts attempts left)";
      }
      
      return "Confirm & Rent Now";
    } catch (error) {
      ErrorHandler.logError('Get Rent Button Text', error);
      return "Error loading button text";
    }
  }

  // Security: Format end date safely
  String formatEndDate() {
    try {
      if (endDate == null) return "";
      final isHourly = selectedPeriod?.toLowerCase() == "hourly";
      
      return isHourly
          ? DateFormat('yyyy-MM-dd HH:mm').format(endDate!)
          : DateFormat('yyyy-MM-dd').format(endDate!);
    } catch (e) {
      ErrorHandler.logError('Format End Date', e);
      return "Invalid date";
    }
  }

  String getUnitLabel() {
    try {
      final p = selectedPeriod?.toLowerCase() ?? '';
      if (p == "hourly") return "Hours";
      if (p == "daily") return "Days";
      if (p == "weekly") return "Weeks";
      if (p == "monthly") return "Months";
      if (p == "yearly") return "Years";
      return "";
    } catch (e) {
      ErrorHandler.logError('Get Unit Label', e);
      return "";
    }
  }

  // Security: Record rental attempt
  Future<void> recordRentalAttempt() async {
    try {
      rentalAttempts++;
      lastRentalAttempt = DateTime.now();
      await _saveRentalHistory();
      
      ErrorHandler.logSecurity('EquipmentDetailLogic', 
          'Rental attempt recorded - Total: $rentalAttempts');
    } catch (error) {
      ErrorHandler.logError('Record Rental Attempt', error);
    }
  }

  // Security: Reset rental attempts
  Future<void> resetRentalAttempts() async {
    try {
      rentalAttempts = 0;
      lastRentalAttempt = null;
      await _saveRentalHistory();
      
      ErrorHandler.logSecurity('EquipmentDetailLogic', 'Rental attempts reset');
    } catch (error) {
      ErrorHandler.logError('Reset Rental Attempts', error);
    }
  }

  // Security: Get remaining cooldown time
  String getRemainingCooldown() {
    try {
      if (lastRentalAttempt == null || !isOnCooldown) return "";
      
      final remaining = rentalCooldown - DateTime.now().difference(lastRentalAttempt!);
      final minutes = remaining.inMinutes;
      final seconds = remaining.inSeconds % 60;
      
      if (minutes > 0) {
        return "$minutes minute${minutes > 1 ? 's' : ''}";
      } else {
        return "$seconds second${seconds > 1 ? 's' : ''}";
      }
    } catch (error) {
      ErrorHandler.logError('Get Remaining Cooldown', error);
      return "";
    }
  }

  // Security: Submit rental request with secure API call
 Future<Map<String, dynamic>> submitRentalRequest(Map<String, dynamic> requestData) async {
  if (requestData['rentalType']?.toString().toLowerCase() == 'hourly') {
  return {
    'success': false,
    'error': 'Hourly rentals are currently disabled',
    };
  }   
  try {
    // Security: Validate request data
    if (!_validateRentalRequest(requestData)) {
      throw Exception('Invalid rental request data');
    }

    // ✅ 1) Check lock/cooldown BEFORE recording attempt
    if (isLocked) {
      throw Exception('Too many rental attempts. Please try again later.');
    }

    if (isOnCooldown) {
      throw Exception('Please wait ${getRemainingCooldown()} before trying again.');
    }

    // ✅ 2) Record attempt ONLY when actually allowed to proceed
    await recordRentalAttempt();

    // Store request data securely (for offline retry)
    final requestId = 'rental_request_${DateTime.now().millisecondsSinceEpoch}';
    await SecureStorage.saveData(
      requestId,
      json.encode(requestData),
    );

    ErrorHandler.logSecurity('EquipmentDetailLogic',
        'Rental request submitted: $requestId');

    return {
      'success': true,
      'requestId': requestId,
      'message': 'Rental request submitted successfully'
    };

  } catch (error, stackTrace) {
    debugPrint("🔥 Submit Rental Request ERROR: $error");
    debugPrint("📌 STACKTRACE:\n$stackTrace");

    ErrorHandler.logError('Submit Rental Request', error);
    return {
      'success': false,
      'error': error.toString(), 
    };
  }
}

  bool _validateRentalRequest(Map<String, dynamic> data) {
    try {
      // Validate required fields
      final requiredFields = [
        'itemId', 'itemTitle', 'itemOwnerUid', 'renterUid',
        'rentalType', 'startDate', 'endDate', 'totalPrice'
      ];
      
      for (var field in requiredFields) {
        if (data[field] == null || data[field].toString().isEmpty) {
          return false;
        }
      }
      
      // Validate data types and ranges
      if (data['totalPrice'] is num) {
        final price = (data['totalPrice'] as num).toDouble();
        if (price <= 0 || price > 100000) return false;
      }
      
      // Check for malicious data
      for (var key in data.keys) {
        if (data[key] is String) {
          if (!InputValidator.hasNoMaliciousCode(data[key] as String)) {
            return false;
          }
        }
      }
      
      return true;
    } catch (e) {
      ErrorHandler.logError('Validate Rental Request', e);
      return false;
    }
  }

  // Security: Get user's rental attempt status
  Future<Map<String, dynamic>> getRentalAttemptStatus() async {
    try {
      return {
        'attempts': rentalAttempts,
        'maxAttempts': maxRentalAttempts,
        'remainingAttempts': maxRentalAttempts - rentalAttempts,
        'isLocked': isLocked,
        'isOnCooldown': isOnCooldown,
        'cooldownRemaining': getRemainingCooldown(),
        'lastAttempt': lastRentalAttempt?.toIso8601String(),
      };
    } catch (error) {
      ErrorHandler.logError('Get Rental Attempt Status', error);
      return {
        'attempts': 0,
        'maxAttempts': maxRentalAttempts,
        'remainingAttempts': maxRentalAttempts,
        'isLocked': false,
        'isOnCooldown': false,
        'cooldownRemaining': '',
        'lastAttempt': null,
      };
    }
  }

  // Security: Cleanup resources
  void cleanupResources() {
    try {
      ErrorHandler.logInfo('EquipmentDetailLogic', 'Cleaning up resources...');
      
      // Clear sensitive data
      selectedPeriod = null;
      startDate = null;
      endDate = null;
      startTime = null;
      pickupTime = null;
      insuranceAccepted = false;
      
      // Clear secure storage of temporary data
      SecureStorage.deleteData('temp_rental_data_$userId');
      
      ErrorHandler.logSecurity('EquipmentDetailLogic', 'Resources cleaned up');
      
    } catch (error) {
      ErrorHandler.logError('Cleanup Resources', error);
    }
  }
}
