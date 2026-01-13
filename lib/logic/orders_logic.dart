import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:p2/models/rental_request.dart';
import 'package:p2/services/firestore_service.dart';
import 'package:p2/user_manager.dart';
import 'package:p2/security/secure_storage.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/input_validator.dart';
import 'package:p2/security/route_guard.dart';

class OrdersLogic {
  final FirestoreService firestoreService;
   

  // Security variables
  bool _isInitialized = false;
  DateTime? _lastDataFetch;
  final Duration _cacheDuration = const Duration(minutes: 2);
  Map<int, List<RentalRequest>> _cachedRequests = {};
  final int _maxRequestsPerFetch = 50;
  final Duration _fetchTimeout = const Duration(seconds: 30);
  
  OrdersLogic({FirestoreService? service})
      : firestoreService = service ?? FirestoreService() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Security: Validate route access
      if (!RouteGuard.isAuthenticated()) {
        throw Exception('User not authenticated');
      }

      // Security: Validate user ID
      if (!_isValidUserId(UserManager.uid)) {
        throw Exception('Invalid user ID');
      }

      _isInitialized = true;
      ErrorHandler.logInfo('OrdersLogic', 'Initialized successfully');
      
    } catch (error) {
      ErrorHandler.logError('OrdersLogic Initialization', error);
    }
  }

  String get renterUid => UserManager.uid ?? '';

  bool _isValidUserId(String? userId) {
    if (userId == null || userId.isEmpty || userId.length > 128) return false;
    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(userId);
  }

  Future<void> _validateUserAccess(String userId) async {
    try {
      // Security: Verify user is accessing their own data
      if (userId != UserManager.uid) {
        throw Exception('Unauthorized access attempt');
      }
    } catch (error) {
      ErrorHandler.logError('Validate User Access', error);
      rethrow;
    }
  }

  List<String> getStatusesForTab(int tabIndex) {
    try {
      // Security: Validate tab index
      if (tabIndex < 0 || tabIndex > 2) {
        ErrorHandler.logError('OrdersLogic', 'Invalid tab index: $tabIndex');
        return [];
      }

      switch (tabIndex) {
        case 0: 
          return ["pending", "accepted"];
        case 1: 
          return ["active"];
        case 2: 
          return ["ended", "rejected", "cancelled", "outdated"];
        default:
          return [];
      }
    } catch (error) {
      ErrorHandler.logError('Get Statuses For Tab', error);
      return [];
    }
  }

  String getEmptyTextForTab(int tabIndex, String Function(String) t) {
    try {
      if (!_isInitialized) {
        return "Loading...";
      }

      // Security: Validate tab index
      if (tabIndex < 0 || tabIndex > 2) {
        return t('error_loading');
      }

      switch (tabIndex) {
        case 0:
          return t('no_pending_orders');
        case 1:
          return t('no_active_orders');
        case 2:
          return t('no_previous_orders');
        default:
          return '';
      }
    } catch (error) {
      ErrorHandler.logError('Get Empty Text For Tab', error);
      return t('error_loading');
    }
  }

  String getTabTitle(int tabIndex, String Function(String) t) {
    try {
      if (!_isInitialized) {
        return "Loading...";
      }

      // Security: Validate tab index
      if (tabIndex < 0 || tabIndex > 2) {
        return t('error');
      }

      switch (tabIndex) {
        case 0:
          return t('pending_orders');
        case 1:
          return t('active_orders');
        case 2:
          return t('previous_orders');
        default:
          return '';
      }
    } catch (error) {
      ErrorHandler.logError('Get Tab Title', error);
      return t('error');
    }
  }

  Stream<List<RentalRequest>> getRequestsStream(int tabIndex) {
    try {
      if (!_isInitialized) {
        return Stream.value([]);
      }

      // Security: Validate tab index
      if (tabIndex < 0 || tabIndex > 2) {
        ErrorHandler.logError('OrdersLogic', 'Invalid tab index: $tabIndex');
        return Stream.value([]);
      }

      // Security: Validate user ID
      if (!_isValidUserId(renterUid)) {
        ErrorHandler.logError('OrdersLogic', 'Invalid user ID: $renterUid');
        return Stream.value([]);
      }

      // Check cache first
      if (_canUseCache(tabIndex)) {
        ErrorHandler.logInfo('OrdersLogic', 'Using cached data for tab $tabIndex');
        return Stream.value(_cachedRequests[tabIndex] ?? []);
      }

      final statuses = getStatusesForTab(tabIndex);
      
      // Security: Validate statuses
      if (statuses.isEmpty) {
        ErrorHandler.logError('OrdersLogic', 'No valid statuses for tab $tabIndex');
        return Stream.value([]);
      }

      // Create a stream controller for manual handling
      final controller = StreamController<List<RentalRequest>>();
      
      // Fetch data asynchronously
      _fetchRequestsForStream(controller, tabIndex, statuses);
      
      return controller.stream;

    } catch (error) {
      ErrorHandler.logError('Get Requests Stream', error);
      return Stream.value([]);
    }
  }

  Future<void> _fetchRequestsForStream(
    StreamController<List<RentalRequest>> controller,
    int tabIndex,
    List<String> statuses,
  ) async {
    try {
      final requests = await _getRequestsWithRetry(renterUid, statuses, tabIndex);
      controller.add(requests);
      controller.close();
    } catch (error) {
      ErrorHandler.logError('Fetch Requests For Stream', error);
      controller.add([]);
      controller.close();
    }
  }

  bool _canUseCache(int tabIndex) {
    try {
      if (_lastDataFetch == null) return false;
      if (!_cachedRequests.containsKey(tabIndex)) return false;
      
      final timeSinceFetch = DateTime.now().difference(_lastDataFetch!);
      return timeSinceFetch < _cacheDuration;
    } catch (e) {
      return false;
    }
  }

  Future<List<RentalRequest>> _getRequestsWithRetry(
    String userId, 
    List<String> statuses, 
    int tabIndex,
    {int maxRetries = 3}
  ) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await _validateUserAccess(userId);
        
        // Use the existing FirestoreService method
        final List<RentalRequest> requests =
           await FirestoreService.getRenterRequestsByStatusesOnce(userId, statuses);


        // Security: Validate and sanitize requests
        final validRequests = _validateAndSanitizeRequests(requests as List<RentalRequest>);

        // Cache the results
        _cachedRequests[tabIndex] = validRequests;
        _lastDataFetch = DateTime.now();

        // Store in secure storage for offline access
        await _cacheRequestsToStorage(tabIndex, validRequests);

        ErrorHandler.logInfo('OrdersLogic', 
            'Loaded ${validRequests.length} requests for tab $tabIndex (attempt $attempt)');
        
        return validRequests;

      } on TimeoutException {
        ErrorHandler.logError('OrdersLogic', 
            'Request timeout (attempt $attempt/$maxRetries)');
        
        if (attempt == maxRetries) {
          // Try to load from cache/storage on final failure
          final cached = await _getCachedRequestsFromStorage(tabIndex);
          if (cached.isNotEmpty) {
            return cached;
          }
          throw Exception('Request timeout after $maxRetries attempts');
        }
        
        await Future.delayed(Duration(seconds: attempt * 2));
        
      } catch (error) {
        ErrorHandler.logError('OrdersLogic Fetch Attempt', error);
        
        if (attempt == maxRetries) {
          // Try to load from cache/storage on final failure
          final cached = await _getCachedRequestsFromStorage(tabIndex);
          if (cached.isNotEmpty) {
            return cached;
          }
          rethrow;
        }
      }
    }
    
    return [];
  }

  List<RentalRequest> _validateAndSanitizeRequests(List<RentalRequest> requests) {
    final validRequests = <RentalRequest>[];
    
    for (var request in requests) {
      try {
        // Security: Basic validation
        if (_isValidRequest(request)) {
          // Security: Sanitize request data
          final sanitizedRequest = _sanitizeRequest(request);
          validRequests.add(sanitizedRequest);
        }
      } catch (e) {
        ErrorHandler.logError('Validate Request', e);
        // Skip invalid requests
      }
    }

    // Security: Limit number of returned requests
    if (validRequests.length > _maxRequestsPerFetch) {
      ErrorHandler.logInfo('OrdersLogic', 
          'Limited requests from ${validRequests.length} to $_maxRequestsPerFetch');
      return validRequests.sublist(0, _maxRequestsPerFetch);
    }

    return validRequests;
  }

  bool _isValidRequest(RentalRequest request) {
    try {
      // Validate required fields
      if (request.id.isEmpty || request.id.length > 100) return false;
      if (request.itemId.isEmpty || !_isValidItemId(request.itemId)) return false;
      if (request.itemTitle.isEmpty || request.itemTitle.length > 200) return false;
      if (request.renterUid != renterUid) return false; // Security: Ensure request belongs to user
      
      // Validate status
      final validStatuses = ['pending', 'accepted', 'active', 'ended', 'rejected', 'cancelled', 'outdated'];
      if (!validStatuses.contains(request.status)) return false;
      
      // Validate dates
      if (request.startDate.isAfter(request.endDate)) return false;
      
      // Validate prices
      if (request.totalPrice < 0 || request.totalPrice > 100000) return false;
      
      // Check for malicious content
      if (!InputValidator.hasNoMaliciousCode(request.itemTitle)) return false;
      
      return true;
    } catch (e) {
      ErrorHandler.logError('Is Valid Request', e);
      return false;
    }
  }

  bool _isValidItemId(String itemId) {
    if (itemId.isEmpty || itemId.length > 100) return false;
    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(itemId);
  }

  RentalRequest _sanitizeRequest(RentalRequest request) {
    try {
      return RentalRequest(
        id: request.id,
        itemId: request.itemId,
        itemTitle: InputValidator.sanitizeInput(request.itemTitle),
        itemOwnerUid: request.itemOwnerUid,
        ownerName: InputValidator.sanitizeInput(request.ownerName ?? ''),
        renterUid: request.renterUid,
        status: request.status,
        rentalType: InputValidator.sanitizeInput(request.rentalType),
        rentalQuantity: request.rentalQuantity,
        startDate: request.startDate,
        endDate: request.endDate,
        startTime: request.startTime != null 
            ? InputValidator.sanitizeInput(request.startTime!)
            : null,
        endTime: request.endTime != null 
            ? InputValidator.sanitizeInput(request.endTime!)
            : null,
        pickupTime: request.pickupTime != null 
            ? InputValidator.sanitizeInput(request.pickupTime!)
            : null,
        rentalPrice: request.rentalPrice,
        totalPrice: request.totalPrice,
        insurance: request.insurance,
        penalty: request.penalty,
        createdAt: request.createdAt, renterName: '', paymentStatus: '',
      );
    } catch (e) {
      ErrorHandler.logError('Sanitize Request', e);
      return request; // Return original on error
    }
  }

  Future<void> _cacheRequestsToStorage(int tabIndex, List<RentalRequest> requests) async {
    try {
      final cacheKey = 'orders_cache_${renterUid}_$tabIndex';
      final serializedRequests = requests.map((req) => req.toJson()).toList();
      
      await SecureStorage.saveData(
        cacheKey,
        ErrorHandler.safeJsonEncode(serializedRequests),
      );
    } catch (error) {
      ErrorHandler.logError('Cache Requests To Storage', error);
    }
  }

  Future<List<RentalRequest>> _getCachedRequestsFromStorage(int tabIndex) async {
    try {
      final cacheKey = 'orders_cache_${renterUid}_$tabIndex';
      final cachedData = await SecureStorage.getData(cacheKey);
      
      if (cachedData != null) {
        final decoded = ErrorHandler.safeJsonDecode(cachedData);
        if (decoded is List) {
          final requests = decoded
              .where((item) => item is Map<String, dynamic>)
              .map((item) => RentalRequest.fromJson(Map<String, dynamic>.from(item)))
              .where(_isValidRequest)
              .toList();
          
          ErrorHandler.logInfo('OrdersLogic', 
              'Loaded ${requests.length} requests from cache for tab $tabIndex');
          
          return requests;
        }
      }
    } catch (error) {
      ErrorHandler.logError('Get Cached Requests From Storage', error);
    }
    
    return [];
  }

  Map<String, String?> getRequestDetails(RentalRequest req) {
    try {
      if (!_isInitialized) {
        return {'Status': 'Loading...'};
      }

      // Security: Validate request belongs to user
      if (req.renterUid != renterUid) {
        ErrorHandler.logSecurity('OrdersLogic', 
            'User attempted to access request not belonging to them');
        return {'Error': 'Access denied'};
      }

      final details = <String, String?>{
        'Owner Name': req.ownerName,
        'Rental Type': req.rentalType,
        'Quantity': req.rentalQuantity.toString(),
        'Start Date': _formatDate(req.startDate),
        'End Date': _formatDate(req.endDate),
        'Total Price': '${req.totalPrice.toStringAsFixed(2)}JD',
      };

      if (req.startTime != null && req.startTime!.isNotEmpty) {
        details['Start Time'] = InputValidator.sanitizeInput(req.startTime!);
      }
      
      if (req.endTime != null && req.endTime!.isNotEmpty) {
        details['End Time'] = InputValidator.sanitizeInput(req.endTime!);
      }
      
      if (req.pickupTime != null && req.pickupTime!.isNotEmpty) {
        details['Pickup Time'] = InputValidator.sanitizeInput(req.pickupTime!);
      }
      
      return details;
    } catch (error) {
      ErrorHandler.logError('Get Request Details', error);
      return {'Error': 'Failed to load details'};
    }
  }

  String _formatDate(DateTime date) {
    try {
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      ErrorHandler.logError('Format Date', e);
      return 'Invalid date';
    }
  }

  // Security: Clear cache and stored data
  Future<void> clearCache() async {
    try {
      _cachedRequests.clear();
      _lastDataFetch = null;
      
      // Clear secure storage cache
      for (int i = 0; i < 3; i++) {
        final cacheKey = 'orders_cache_${renterUid}_$i';
        await SecureStorage.deleteData(cacheKey);
      }
      
      ErrorHandler.logInfo('OrdersLogic', 'Cache cleared');
    } catch (error) {
      ErrorHandler.logError('Clear Cache', error);
    }
  }

  // Security: Get orders statistics
  Future<Map<String, dynamic>> getOrdersStats() async {
    try {
      if (!_isInitialized) {
        throw Exception('Logic not initialized');
      }

      final stats = <String, dynamic>{
        'totalRequests': 0,
        'pendingRequests': 0,
        'activeRequests': 0,
        'completedRequests': 0,
        'lastFetch': _lastDataFetch?.toIso8601String(),
        'cacheSize': _cachedRequests.length,
      };

      // Fetch counts for each tab
      for (int i = 0; i < 3; i++) {
        try {
          final requests = await _getRequestsWithRetry(
            renterUid, 
            getStatusesForTab(i), 
            i,
            maxRetries: 1
          );
          
          switch (i) {
            case 0:
              stats['pendingRequests'] = requests.length;
              break;
            case 1:
              stats['activeRequests'] = requests.length;
              break;
            case 2:
              stats['completedRequests'] = requests.length;
              break;
          }
          
          stats['totalRequests'] = (stats['totalRequests'] as int) + requests.length;
        } catch (e) {
          ErrorHandler.logError('Get Stats for tab $i', e);
        }
      }

      return stats;
    } catch (error) {
      ErrorHandler.logError('Get Orders Stats', error);
      return {
        'error': ErrorHandler.getSafeError(error),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Security: Cleanup resources
  void cleanupResources() {
    try {
      _isInitialized = false;
      ErrorHandler.logInfo('OrdersLogic', 'Resources cleaned up');
    } catch (error) {
      ErrorHandler.logError('Cleanup Resources', error);
    }
  }
}
