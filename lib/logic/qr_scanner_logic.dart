import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:p2/security/input_validator.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/api_security.dart';
import 'package:p2/security/secure_storage.dart';
import 'package:p2/security/route_guard.dart';
import 'dart:async';

class QrLogic {
  static Future<bool> validateQrToken(String? qrToken, String requestId) async {
    try {
      if (qrToken == null || qrToken.isEmpty) {
        ErrorHandler.logSecurity('QR Validation', 'Empty QR token');
        return false;
      }

      // تنظيف الـ QR token
      final safeToken = InputValidator.sanitizeInput(qrToken);
      final safeRequestId = InputValidator.sanitizeInput(requestId);

      // التحقق من تنسيق الـ QR token
      if (!_isValidQrFormat(safeToken)) {
        ErrorHandler.logSecurity('QR Validation', 'Invalid QR format: $safeToken');
        return false;
      }

      // التحقق من أن الـ QR token يطابق الـ requestId
      if (!safeToken.contains(safeRequestId)) {
        ErrorHandler.logSecurity('QR Validation', 
            'QR token mismatch: $safeToken for request: $safeRequestId');
        return false;
      }

      // التحقق من عدم وجود محتوى ضار
      if (!InputValidator.hasNoMaliciousCode(safeToken)) {
        ErrorHandler.logSecurity('QR Validation', 'Malicious content in QR token');
        return false;
      }

      return true;
    } catch (error) {
      ErrorHandler.logError('Validate QR Token', error);
      return false;
    }
  }

  static bool _isValidQrFormat(String qrToken) {
    // تنسيق متوقع: requestId_timestamp
    final parts = qrToken.split('_');
    if (parts.length != 2) return false;

    final requestId = parts[0];
    final timestamp = parts[1];

    // التحقق من أن الـ requestId ليس فارغاً
    if (requestId.isEmpty) return false;

    // التحقق من أن timestamp هو رقم
    final timestampNum = int.tryParse(timestamp);
    if (timestampNum == null) return false;

    // التحقق من أن timestamp ليس في المستقبل
    final now = DateTime.now().millisecondsSinceEpoch;
    if (timestampNum > now) return false;

    return true;
  }

  static Future<bool> verifyRequestDates(String requestId, bool isReturnPhase) async {
    try {
      final ref = FirebaseFirestore.instance
          .collection("rentalRequests")
          .doc(requestId);

      final doc = await ref.get();
      if (!doc.exists) {
        ErrorHandler.logError('Verify Request Dates', 'Request not found: $requestId');
        return false;
      }

      final data = doc.data()!;
      final today = DateTime.now();

      
      DateTime? safeToDate(dynamic v) {
        try {
          if (v is Timestamp) return v.toDate();
          if (v is String) return DateTime.parse(v);
          return null;
        } catch (e) {
          ErrorHandler.logError('Safe To Date Conversion', e);
          return null;
        }
      }

      final startDate = safeToDate(data["startDate"]);
      final endDate = safeToDate(data["endDate"]);

      if (startDate == null || endDate == null) {
        ErrorHandler.logError('Verify Request Dates', 'Invalid dates in request');
        return false;
      }

      // START PHASE
      if (!isReturnPhase) {
        final isTodayStart = today.year == startDate.year &&
            today.month == startDate.month &&
            today.day == startDate.day;

        if (!isTodayStart) {
          ErrorHandler.logSecurity('Verify Request Dates', 
              'QR access attempted before start date');
          return false;
        }
        return true;
      }

      // RETURN PHAS
      final expiredLimit = endDate.add(const Duration(days: 3));

      if (today.isBefore(endDate)) {
        ErrorHandler.logSecurity('Verify Request Dates', 
            'Return QR access attempted before end date');
        return false;
      }

      if (today.isAfter(expiredLimit)) {
        ErrorHandler.logSecurity('Verify Request Dates', 
            'Return QR access attempted after expiry limit');
        return false;
      }

      return true;
    } catch (error) {
      ErrorHandler.logError('Verify Request Dates', error);
      return false;
    }
  }

  static Future<bool> logQrScan(String requestId, String qrToken, 
      bool isReturnPhase, String scannerId) async {
    try {
      final token = await SecureStorage.getToken();
      
      await ApiSecurity.securePost(
        endpoint: 'logs/qr_scan',
        data: {
          'request_id': requestId,
          'qr_token': qrToken,
          'is_return_phase': isReturnPhase,
          'scanner_id': scannerId,
          'timestamp': DateTime.now().toIso8601String(),
          'ip_address': 'mobile_app',
        },
        token: token,
        requiresAuth: true,
      );
      
      return true;
    } catch (e) {
      ErrorHandler.logInfo('Log QR Scan', 'Failed to log QR scan');
      return false;
    }
  }

  static Future<bool> checkRateLimit(String scannerId) async {
    try {
      final token = await SecureStorage.getToken();
      
      final response = await ApiSecurity.secureGet(
        endpoint: 'qr/rate_limit',
        queryParams: {'scanner_id': scannerId},
        token: token,
        requiresAuth: true,
      );
      
      return response['success'] == true && 
             response['data']?['allowed'] == true;
    } catch (e) {
      ErrorHandler.logError('Check Rate Limit', e);
      return true; 
    }
  }

  static String getSafeMessage(String? message) {
    if (message == null) {
      return "QR unavailable";
    }
    
    final safeMessage = InputValidator.sanitizeInput(message);
    
    
    if (safeMessage.toLowerCase().contains('token') ||
        safeMessage.toLowerCase().contains('id') ||
        safeMessage.toLowerCase().contains('secret')) {
      return "QR code is currently unavailable. Please try again later.";
    }
    
    return safeMessage;
  }

  static Future<bool> validateUserPermission(String requestId, String userId) async {
    try {
      final ref = FirebaseFirestore.instance
          .collection("rentalRequests")
          .doc(requestId);

      final doc = await ref.get();
      if (!doc.exists) {
        return false;
      }

      final data = doc.data()!;
      
      
      final ownerId = data["ownerId"]?.toString() ?? '';
      final renterId = data["renterId"]?.toString() ?? '';
      
      final safeUserId = InputValidator.sanitizeInput(userId);
      final safeOwnerId = InputValidator.sanitizeInput(ownerId);
      final safeRenterId = InputValidator.sanitizeInput(renterId);
      
      return safeUserId == safeOwnerId || safeUserId == safeRenterId;
    } catch (error) {
      ErrorHandler.logError('Validate User Permission', error);
      return false;
    }
  }

  static Future<Map<String, dynamic>> getRequestSecureData(String requestId) async {
    try {
      final ref = FirebaseFirestore.instance
          .collection("rentalRequests")
          .doc(requestId);

      final doc = await ref.get();
      if (!doc.exists) {
        return {'error': 'Request not found', 'exists': false};
      }

      final data = doc.data()!;
      
      
      return {
        'exists': true,
        'requestId': doc.id,
        'ownerId': InputValidator.sanitizeInput(data["ownerId"]?.toString() ?? ''),
        'renterId': InputValidator.sanitizeInput(data["renterId"]?.toString() ?? ''),
        'status': InputValidator.sanitizeInput(data["status"]?.toString() ?? ''),
        'pickupQrToken': InputValidator.sanitizeInput(data["pickupQrToken"]?.toString() ?? ''),
        'returnQrToken': InputValidator.sanitizeInput(data["returnQrToken"]?.toString() ?? ''),
        'createdAt': data["createdAt"]?.toString(),
      };
    } catch (error) {
      ErrorHandler.logError('Get Request Secure Data', error);
      return {'error': 'Failed to get request data', 'exists': false};
    }
  }

  static Future<bool> validateScanRequest(String requestId, String qrToken, 
      bool isReturnPhase, String userId) async {
    try {
      
      if (!RouteGuard.isAuthenticated()) {
        throw Exception('User not authenticated for QR scan');
      }

    
      final rateLimitOk = await checkRateLimit(userId);
      if (!rateLimitOk) {
        ErrorHandler.logSecurity('Validate Scan Request', 
            'Rate limit exceeded for user: $userId');
        return false;
      }

      
      final hasPermission = await validateUserPermission(requestId, userId);
      if (!hasPermission) {
        ErrorHandler.logSecurity('Validate Scan Request', 
            'User $userId has no permission for request: $requestId');
        return false;
      }

      
      final datesValid = await verifyRequestDates(requestId, isReturnPhase);
      if (!datesValid) {
        return false;
      }

      
      final qrValid = await validateQrToken(qrToken, requestId);
      if (!qrValid) {
        return false;
      }

      
      await logQrScan(requestId, qrToken, isReturnPhase, userId);

      return true;
    } catch (error) {
      ErrorHandler.logError('Validate Scan Request', error);
      return false;
    }
  }

  static String getSuccessMessage(bool isReturnPhase) {
    return isReturnPhase 
        ? "Return confirmed successfully! ✅"
        : "Pickup confirmed successfully! ✅";
  }

  static String getErrorMessage(bool isReturnPhase) {
    return isReturnPhase
        ? "Failed to confirm return. Please try again."
        : "Failed to confirm pickup. Please try again.";
  }

  static String getInvalidQrMessage() {
    return "Invalid QR code. Please scan a valid code.";
  }

  static String getExpiredMessage() {
    return "QR code has expired. Please generate a new one.";
  }
}
