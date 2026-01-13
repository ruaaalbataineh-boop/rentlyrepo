import 'package:p2/security/error_handler.dart';
import 'package:p2/security/secure_storage.dart';
import 'package:p2/security/input_validator.dart';

class RatingSecurity {
  // القيم الدنيا والقصوى للتقييم
  static const int minRating = 1;
  static const int maxRating = 5;
  
  // الحد الأقصى لطول المراجعة
  static const int maxReviewLength = 500;
  
  // الحد الأدنى لطول المراجعة (إذا أراد المستخدم كتابة مراجعة)
  static const int minReviewLength = 10;

  // التحقق من صحة التقييم
  static bool isValidRating(int rating) {
    try {
      return rating >= minRating && rating <= maxRating;
    } catch (error) {
      ErrorHandler.logError('Validate Rating', error);
      return false;
    }
  }

  // التحقق من صحة المراجعة
  static bool isValidReview(String review) {
    try {
      if (review.isEmpty) {
        return true; // المراجعة اختيارية
      }

      // التحقق من الطول
      if (review.length < minReviewLength) {
        ErrorHandler.logWarning('Review Validation', 
            'Review too short: ${review.length} characters');
        return false;
      }

      if (review.length > maxReviewLength) {
        ErrorHandler.logWarning('Review Validation', 
            'Review too long: ${review.length} characters');
        return false;
      }

      // التحقق من عدم وجود محتوى ضار
      if (!InputValidator.hasNoMaliciousCode(review)) {
        ErrorHandler.logSecurity('Review Validation', 
            'Malicious content detected in review');
        return false;
      }

      // التحقق من عدم وجود كلمات غير لائقة
      if (_containsInappropriateContent(review)) {
        ErrorHandler.logSecurity('Review Validation', 
            'Inappropriate content detected in review');
        return false;
      }

      return true;
    } catch (error) {
      ErrorHandler.logError('Validate Review', error);
      return false;
    }
  }

  // التحقق من المحتوى غير اللائق
  static bool _containsInappropriateContent(String text) {
    try {
      final inappropriateWords = [
        'badword1', 'badword2', 'badword3', // أضف الكلمات المناسبة هنا
        'سب', 'شتيمة', 'إهانة', 'بذيء',
      ];

      final lowerText = text.toLowerCase();
      
      for (final word in inappropriateWords) {
        if (lowerText.contains(word.toLowerCase())) {
          return true;
        }
      }

      return false;
    } catch (error) {
      ErrorHandler.logError('Check Inappropriate Content', error);
      return false;
    }
  }

  // تنظيف المراجعة
  static String sanitizeReview(String review) {
    try {
      if (review.isEmpty) {
        return review;
      }

      // تنظيف النص
      var cleaned = InputValidator.sanitizeInput(review);
      
      // تقليم الطول الزائد
      if (cleaned.length > maxReviewLength) {
        cleaned = cleaned.substring(0, maxReviewLength);
      }

      // إزالة المسافات الزائدة
      cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

      return cleaned;
    } catch (error) {
      ErrorHandler.logError('Sanitize Review', error);
      return '';
    }
  }

  // التحقق من أن المستخدم يمكنه التقييم
  static Future<bool> canRateUser(String userId) async {
    try {
      final currentUserId = await _getCurrentUserId();
      
      // لا يمكن للمستخدم تقييم نفسه
      if (currentUserId == userId) {
        ErrorHandler.logWarning('Rate User', 'User attempted to rate themselves');
        return false;
      }

      // التحقق من أن المستخدم لم يقم بتقييم هذا المستخدم من قبل
      final hasRatedBefore = await _hasUserRatedBefore(userId);
      if (hasRatedBefore) {
        ErrorHandler.logWarning('Rate User', 'User attempted to rate the same user again');
        return false;
      }

      // يمكن إضافة المزيد من التحقق هنا (مثل: هل تفاعل مع المستخدم من قبل؟)

      return true;
    } catch (error) {
      ErrorHandler.logError('Can Rate User', error);
      return false;
    }
  }

  // إرسال التقييم بشكل آمن
  static Future<Map<String, dynamic>> submitRating({
    required String ratedUserId,
    required int rating,
    required String review,
    required bool anonymous,
  }) async {
    try {
      // التحقق من صحة البيانات
      if (!isValidRating(rating)) {
        throw Exception('Invalid rating value');
      }

      if (!isValidReview(review)) {
        throw Exception('Invalid review content');
      }

      final currentUserId = await _getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // التحقق من الإذن
      final canRate = await canRateUser(ratedUserId);
      if (!canRate) {
        throw Exception('Cannot rate this user');
      }

      // تنظيف المراجعة
      final sanitizedReview = sanitizeReview(review);

      // إنشاء بيانات التقييم الآمنة
      final ratingData = {
        'id': _generateRatingId(),
        'rater_id': anonymous ? 'anonymous' : currentUserId,
        'rated_user_id': ratedUserId,
        'rating': rating,
        'review': sanitizedReview,
        'anonymous': anonymous,
        'timestamp': DateTime.now().toIso8601String(),
        'is_validated': true,
      };

      // تسجيل عملية التقييم
      await _logRatingSubmission(ratingData);

      // حفظ محلياً
      await _saveRatingLocally(ratingData);

      ErrorHandler.logSuccess('Submit Rating', 
          'Rating submitted successfully for user: $ratedUserId');

      return {
        'success': true,
        'data': ratingData,
        'message': 'Rating submitted successfully',
      };
    } catch (error) {
      ErrorHandler.logError('Submit Rating', error);
      return {
        'success': false,
        'error': ErrorHandler.getSafeError(error),
        'message': 'Failed to submit rating',
      };
    }
  }

  // إنشاء ID فريد للتقييم
  static String _generateRatingId() {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = DateTime.now().microsecondsSinceEpoch % 10000;
      return 'rating_${timestamp}_${random}';
    } catch (error) {
      return 'rating_${DateTime.now().microsecondsSinceEpoch}';
    }
  }

  // تسجيل عملية التقييم
  static Future<void> _logRatingSubmission(Map<String, dynamic> ratingData) async {
    try {
      final token = await SecureStorage.getToken();
      final currentUserId = await _getCurrentUserId();

      ErrorHandler.logInfo('Rating Submission', '''
Rating ID: ${ratingData['id']}
Rater: ${ratingData['rater_id']}
Rated User: ${ratingData['rated_user_id']}
Rating: ${ratingData['rating']}
Anonymous: ${ratingData['anonymous']}
Timestamp: ${ratingData['timestamp']}
''');

      // حفظ في التخزين المحلي
      await SecureStorage.saveData(
        'rating_submission_${DateTime.now().millisecondsSinceEpoch}',
        '${ratingData['id']} - ${ratingData['rated_user_id']} - ${ratingData['rating']}',
      );
    } catch (error) {
      ErrorHandler.logError('Log Rating Submission', error);
    }
  }

  // حفظ التقييم محلياً
  static Future<void> _saveRatingLocally(Map<String, dynamic> ratingData) async {
    try {
      final ratingsJson = await SecureStorage.getData('user_ratings') ?? '[]';
      final ratingsList = ErrorHandler.safeJsonDecode(ratingsJson) as List? ?? [];
      
      ratingsList.add(ratingData);
      
      await SecureStorage.saveData(
        'user_ratings',
        ErrorHandler.safeJsonEncode(ratingsList),
      );
    } catch (error) {
      ErrorHandler.logError('Save Rating Locally', error);
    }
  }

  // التحقق مما إذا قام المستخدم بالتقييم من قبل
  static Future<bool> _hasUserRatedBefore(String ratedUserId) async {
    try {
      final currentUserId = await _getCurrentUserId();
      if (currentUserId == null) {
        return false;
      }

      final ratingsJson = await SecureStorage.getData('user_ratings') ?? '[]';
      final ratingsList = ErrorHandler.safeJsonDecode(ratingsJson) as List? ?? [];

      for (final rating in ratingsList) {
        if (rating is Map<String, dynamic>) {
          final raterId = rating['rater_id'] as String?;
          final ratedId = rating['rated_user_id'] as String?;
          
          if (raterId == currentUserId && ratedId == ratedUserId) {
            return true;
          }
        }
      }

      return false;
    } catch (error) {
      ErrorHandler.logError('Check User Rated Before', error);
      return false;
    }
  }

  // الحصول على ID المستخدم الحالي
  static Future<String?> _getCurrentUserId() async {
    try {
      final token = await SecureStorage.getToken();
      if (token != null && token.isNotEmpty) {
        // يمكنك استخراج userId من التوكن أو الحصول عليه من مكان آخر
        return 'user_${token.substring(0, min(8, token.length))}...';
      }
      return null;
    } catch (error) {
      ErrorHandler.logError('Get Current User ID', error);
      return null;
    }
  }

  static int min(int a, int b) => a < b ? a : b;

  // الحصول على ملخص التقييمات
  static Future<Map<String, dynamic>> getRatingSummary(String userId) async {
    try {
      final ratingsJson = await SecureStorage.getData('user_ratings') ?? '[]';
      final ratingsList = ErrorHandler.safeJsonDecode(ratingsJson) as List? ?? [];

      final userRatings = ratingsList.where((rating) {
        if (rating is Map<String, dynamic>) {
          return rating['rated_user_id'] == userId;
        }
        return false;
      }).toList();

      if (userRatings.isEmpty) {
        return {
          'total_ratings': 0,
          'average_rating': 0,
          'has_ratings': false,
        };
      }

      double totalScore = 0;
      for (final rating in userRatings) {
        if (rating is Map<String, dynamic>) {
          totalScore += (rating['rating'] as int).toDouble();
        }
      }

      final averageRating = totalScore / userRatings.length;

      return {
        'total_ratings': userRatings.length,
        'average_rating': averageRating,
        'has_ratings': true,
        'rating_distribution': _calculateRatingDistribution(userRatings),
        'last_rating_date': _getLastRatingDate(userRatings),
      };
    } catch (error) {
      ErrorHandler.logError('Get Rating Summary', error);
      return {
        'total_ratings': 0,
        'average_rating': 0,
        'has_ratings': false,
        'error': ErrorHandler.getSafeError(error),
      };
    }
  }

  // حساب توزيع التقييمات
  static Map<int, int> _calculateRatingDistribution(List<dynamic> ratings) {
    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (final rating in ratings) {
      if (rating is Map<String, dynamic>) {
        final ratingValue = rating['rating'] as int?;
        if (ratingValue != null && ratingValue >= 1 && ratingValue <= 5) {
          distribution[ratingValue] = (distribution[ratingValue] ?? 0) + 1;
        }
      }
    }

    return distribution;
  }

  // الحصول على تاريخ آخر تقييم
  static String? _getLastRatingDate(List<dynamic> ratings) {
    try {
      if (ratings.isEmpty) {
        return null;
      }

      DateTime? lastDate;
      for (final rating in ratings) {
        if (rating is Map<String, dynamic>) {
          final timestamp = rating['timestamp'] as String?;
          if (timestamp != null) {
            final date = DateTime.tryParse(timestamp);
            if (date != null && (lastDate == null || date.isAfter(lastDate))) {
              lastDate = date;
            }
          }
        }
      }

      return lastDate?.toIso8601String();
    } catch (error) {
      return null;
    }
  }

  // التحقق من تكرار التقييمات (لمنع spam)
  static Future<bool> isRatingSpam(String userId) async {
    try {
      final currentUserId = await _getCurrentUserId();
      if (currentUserId == null) {
        return false;
      }

      final ratingsJson = await SecureStorage.getData('user_ratings') ?? '[]';
      final ratingsList = ErrorHandler.safeJsonDecode(ratingsJson) as List? ?? [];

      // حساب عدد التقييمات في آخر 24 ساعة
      final twentyFourHoursAgo = DateTime.now().subtract(const Duration(hours: 24));
      int recentRatings = 0;

      for (final rating in ratingsList) {
        if (rating is Map<String, dynamic>) {
          final raterId = rating['rater_id'] as String?;
          final timestamp = rating['timestamp'] as String?;
          
          if (raterId == currentUserId && timestamp != null) {
            final ratingDate = DateTime.tryParse(timestamp);
            if (ratingDate != null && ratingDate.isAfter(twentyFourHoursAgo)) {
              recentRatings++;
            }
          }
        }
      }

      // إذا قام بأكثر من 10 تقييمات في 24 ساعة، يعتبر spam
      if (recentRatings > 10) {
        ErrorHandler.logSecurity('Rating Spam Detection', 
            'User $currentUserId submitted $recentRatings ratings in 24 hours');
        return true;
      }

      return false;
    } catch (error) {
      ErrorHandler.logError('Check Rating Spam', error);
      return false;
    }
  }
}
