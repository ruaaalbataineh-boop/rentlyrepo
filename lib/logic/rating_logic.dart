import 'package:p2/security/input_validator.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/api_security.dart';
import 'package:p2/security/secure_storage.dart';
import 'package:p2/security/route_guard.dart';

class RatingLogic {
  static Future<bool> validateRating({
    required int rating,
    required String productId,
    required String productName,
    String? review,
    bool anonymous = false,
  }) async {
    try {
      // التحقق من المصادقة أولاً
      if (!RouteGuard.isAuthenticated()) {
        ErrorHandler.logSecurity('Rating Validation', 'User not authenticated');
        return false;
      }

      // التحقق من الـ rate limiting
      final rateLimitOk = await _checkRateLimit();
      if (!rateLimitOk) {
        ErrorHandler.logSecurity('Rating Validation', 'Rate limit exceeded');
        return false;
      }

      // التحقق من التقييم (1-5)
      if (rating < 1 || rating > 5) {
        ErrorHandler.logError('Rating Validation', 'Invalid rating value: $rating');
        return false;
      }

      // تنظيف الـ productId
      final safeProductId = InputValidator.sanitizeInput(productId);
      if (safeProductId.isEmpty || !_isValidProductId(safeProductId)) {
        ErrorHandler.logError('Rating Validation', 'Invalid product ID');
        return false;
      }

      // تنظيف اسم المنتج
      final safeProductName = InputValidator.sanitizeInput(productName);
      if (safeProductName.isEmpty) {
        ErrorHandler.logError('Rating Validation', 'Invalid product name');
        return false;
      }

      // تنظيف المراجعة إذا كانت موجودة
      String? safeReview;
      if (review != null && review.isNotEmpty) {
        safeReview = InputValidator.sanitizeInput(review);
        
        // التحقق من طول المراجعة
        if (safeReview.length > 500) {
          ErrorHandler.logError('Rating Validation', 'Review too long');
          return false;
        }

        // التحقق من عدم وجود محتوى ضار
        if (!InputValidator.hasNoMaliciousCode(safeReview)) {
          ErrorHandler.logSecurity('Rating Validation', 
              'Malicious content detected in review');
          return false;
        }
      }

      // التحقق من أن المستخدم لم يقيم المنتج من قبل
      final hasRated = await _hasUserRatedProduct(safeProductId);
      if (hasRated) {
        ErrorHandler.logInfo('Rating Validation', 'User already rated this product');
        return false;
      }

      return true;
    } catch (error) {
      ErrorHandler.logError('Validate Rating', error);
      return false;
    }
  }

  static Future<bool> submitRating({
    required int rating,
    required String productId,
    required String productName,
    String? review,
    bool anonymous = false,
  }) async {
    try {
      // التحقق من صحة البيانات أولاً
      final validationResult = await validateRating(
        rating: rating,
        productId: productId,
        productName: productName,
        review: review,
        anonymous: anonymous,
      );

      if (!validationResult) {
        await _logRatingAttempt(productId, false, 'Validation failed');
        return false;
      }

      // جلب بيانات المستخدم
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      // تحضير البيانات الآمنة
      final safeProductId = InputValidator.sanitizeInput(productId);
      final safeProductName = InputValidator.sanitizeInput(productName);
      final safeReview = review != null ? InputValidator.sanitizeInput(review) : null;
      final userId = await _getCurrentUserId();

      // إرسال التقييم إلى الخادم
      final response = await ApiSecurity.securePost(
        endpoint: 'ratings/submit',
        data: {
          'product_id': safeProductId,
          'product_name': safeProductName,
          'rating': rating,
          'review': safeReview,
          'anonymous': anonymous,
          'user_id': userId,
          'timestamp': DateTime.now().toIso8601String(),
        },
        token: token,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        await _logRatingAttempt(productId, true, 'Rating submitted successfully');
        
        
        await _updateLocalRating(safeProductId, rating);
        
        return true;
      } else {
        await _logRatingAttempt(productId, false, 'Server rejected rating');
        return false;
      }
    } catch (error) {
      ErrorHandler.logError('Submit Rating', error);
      await _logRatingAttempt(productId, false, error.toString());
      return false;
    }
  }

  static Future<bool> _checkRateLimit() async {
    try {
      final token = await SecureStorage.getToken();
      
      final response = await ApiSecurity.secureGet(
        endpoint: 'ratings/rate_limit',
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

  static Future<bool> _hasUserRatedProduct(String productId) async {
    try {
      final token = await SecureStorage.getToken();
      
      final response = await ApiSecurity.secureGet(
        endpoint: 'ratings/user_rating',
        queryParams: {'product_id': productId},
        token: token,
        requiresAuth: true,
      );
      
      return response['success'] == true && 
             response['data']?['has_rated'] == true;
    } catch (e) {
      ErrorHandler.logError('Check User Rating', e);
      return false;
    }
  }

  static Future<String> _getCurrentUserId() async {
    try {
      
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }
      
      
      
      return 'user_${DateTime.now().millisecondsSinceEpoch}';
    } catch (error) {
      ErrorHandler.logError('Get Current User ID', error);
      return 'unknown_user';
    }
  }

  static Future<void> _logRatingAttempt(String productId, bool success, String details) async {
    try {
      final token = await SecureStorage.getToken();
      
      await ApiSecurity.securePost(
        endpoint: 'logs/rating_attempt',
        data: {
          'product_id': productId,
          'success': success,
          'details': details,
          'timestamp': DateTime.now().toIso8601String(),
        },
        token: token,
        requiresAuth: true,
      );
    } catch (e) {
      ErrorHandler.logInfo('Log Rating Attempt', 'Failed to log rating attempt');
    }
  }

  static Future<void> _updateLocalRating(String productId, int rating) async {
    try {
      
      await SecureStorage.saveData(
        'rated_${productId}_${DateTime.now().toIso8601String()}',
        rating.toString(),
      );
    } catch (error) {
      ErrorHandler.logError('Update Local Rating', error);
    }
  }

  static bool _isValidProductId(String productId) {
    if (productId.isEmpty || productId.length > 100) {
      return false;
    }
    
  
    if (!InputValidator.hasNoMaliciousCode(productId)) {
      return false;
    }
    
    
    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(productId);
  }

  static String getSuccessMessage() {
    return "Thank you for your rating! ✅\nYour feedback has been submitted successfully.";
  }

  static String getErrorMessage() {
    return "Failed to submit rating. Please try again.";
  }

  static String getValidationErrorMessage() {
    return "Please check your rating:\n• Rating must be between 1-5 stars\n• Review must be less than 500 characters";
  }

  static String getDuplicateRatingMessage() {
    return "You have already rated this product.";
  }

  static String getRateLimitMessage() {
    return "Too many rating attempts. Please try again later.";
  }

  static Future<Map<String, dynamic>> getProductRatingStats(String productId) async {
    try {
      final safeProductId = InputValidator.sanitizeInput(productId);
      
      final response = await ApiSecurity.secureGet(
        endpoint: 'ratings/stats',
        queryParams: {'product_id': safeProductId},
        requiresAuth: false,
      );
      
      if (response['success'] == true) {
        return response['data'] ?? {};
      } else {
        return {
          'average_rating': 0.0,
          'total_ratings': 0,
          'error': 'Failed to get rating stats',
        };
      }
    } catch (error) {
      ErrorHandler.logError('Get Product Rating Stats', error);
      return {
        'average_rating': 0.0,
        'total_ratings': 0,
        'error': ErrorHandler.getSafeError(error),
      };
    }
  }

  static Future<List<Map<String, dynamic>>> getRecentRatings(String productId, 
      {int limit = 5}) async {
    try {
      final safeProductId = InputValidator.sanitizeInput(productId);
      
      final response = await ApiSecurity.secureGet(
        endpoint: 'ratings/recent',
        queryParams: {
          'product_id': safeProductId,
          'limit': limit.toString(),
        },
        requiresAuth: false,
      );
      
      if (response['success'] == true) {
        final List<dynamic> ratings = response['data']?['ratings'] ?? [];
        return ratings.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (error) {
      ErrorHandler.logError('Get Recent Ratings', error);
      return [];
    }
  }
}
