import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Add security imports
import 'security/route_guard.dart';
import 'security/error_handler.dart';
import 'security/input_validator.dart';

class AllReviewsPage extends StatelessWidget {
  final String itemId;

  const AllReviewsPage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    // Security: Validate itemId
    if (itemId.isEmpty || !_isValidFirestoreId(itemId)) {
      return _buildErrorScreen(context, "Invalid item ID");
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8A005D),
        title: const Text("All Reviews"),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Secure back navigation
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _buildReviewsStream(context),
    );
  }

  Widget _buildReviewsStream(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getSecureReviewsStream(),
      builder: (context, snapshot) {
        // Security: Handle different states
        if (snapshot.hasError) {
          ErrorHandler.logError('Reviews Stream', snapshot.error);
          return _buildErrorScreen(context, "Failed to load reviews");
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        return _buildReviewsList(context, snapshot.data!.docs);
      },
    );
  }

  Stream<QuerySnapshot> _getSecureReviewsStream() {
    try {
      // Security: Validate and sanitize itemId
      if (!_isValidFirestoreId(itemId)) {
        throw Exception('Invalid item ID format');
      }

      return FirebaseFirestore.instance
          .collection("items")
          .doc(itemId)
          .collection("reviews")
          .where("isActive", isEqualTo: true) // Security: only active reviews
          .orderBy("createdAt", descending: true)
          .limit(100) // Security: limit results
          .snapshots();
    } catch (error) {
      ErrorHandler.logError('Get Reviews Stream', error);
      // Return empty stream to prevent crashes
      return const Stream.empty();
    }
  }

  Widget _buildReviewsList(BuildContext context, List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        try {
          final data = docs[index].data() as Map<String, dynamic>;
          
          // Security: Validate and sanitize data
          final rating = _validateRating(data["rating"] ?? 0);
          final reviewText = _sanitizeReviewText(data["review"] ?? "");
          final userId = _sanitizeUserId(data["userId"] ?? "Anonymous");
          final createdAt = _validateTimestamp(data["createdAt"]);
          
          if (reviewText.isEmpty) {
            return const SizedBox.shrink(); // Skip empty reviews
          }

          final formattedDate = DateFormat("yyyy-MM-dd  HH:mm").format(createdAt);

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ⭐ Rating stars
                _buildRatingStars(rating),
                const SizedBox(height: 10),
                
                // Review text
                _buildReviewText(reviewText),
                const SizedBox(height: 12),
                
                // User info and date
                _buildReviewFooter(userId, formattedDate),
              ],
            ),
          );
        } catch (error) {
          ErrorHandler.logError('Build Review Item', error);
          return const SizedBox.shrink(); // Skip problematic items
        }
      },
    );
  }

  Widget _buildRatingStars(double rating) {
    final clampedRating = rating.clamp(0.0, 5.0); // Security: clamp rating
    final fullStars = clampedRating.floor();
    final hasHalfStar = (clampedRating - fullStars) >= 0.5;

    return Row(
      children: [
        ...List.generate(
          5,
          (i) => Icon(
            Icons.star,
            color: i < fullStars 
              ? Colors.amber 
              : (i == fullStars && hasHalfStar ? Colors.amber : Colors.grey),
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          clampedRating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewText(String text) {
    // Security: Limit text length and prevent overflow
    final displayText = text.length > 500 
      ? '${text.substring(0, 500)}...' 
      : text;

    return Text(
      displayText,
      style: const TextStyle(fontSize: 15),
      maxLines: 10,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildReviewFooter(String userId, String date) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            "By: $userId",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        Text(
          date,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.reviews_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity, // FIX: Added container for text alignment
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Text(
              "No reviews yet.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity, // FIX: Added container for text alignment
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Text(
              "Be the first to leave a review!",
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, String message) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8A005D),
        title: const Text("All Reviews"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity, // FIX: Added container
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center, // Now this works
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: ElevatedButton(
                onPressed: () {
                  // Retry or go back
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8A005D),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  "Go Back",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Security validation methods
  bool _isValidFirestoreId(String id) {
    if (id.isEmpty || id.length > 100) return false;
    // Basic validation for Firestore document IDs
    final regex = RegExp(r'^[a-zA-Z0-9_-]+$');
    return regex.hasMatch(id);
  }

  double _validateRating(dynamic rating) {
    try {
      if (rating is int) return rating.toDouble();
      if (rating is double) return rating;
      if (rating is String) return double.tryParse(rating) ?? 0.0;
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  String _sanitizeReviewText(String text) {
    if (text.isEmpty) return "";
    
    // Remove malicious content
    if (!InputValidator.hasNoMaliciousCode(text)) {
      return "[Content moderated]";
    }
    
    // Sanitize and trim
    return InputValidator.sanitizeInput(text);
  }

  String _sanitizeUserId(String userId) {
    if (userId.isEmpty) return "Anonymous";
    
    // Basic sanitization for display
    final sanitized = InputValidator.sanitizeInput(userId);
    
    // Truncate if too long
    if (sanitized.length > 30) {
      return "${sanitized.substring(0, 27)}...";
    }
    
    return sanitized;
  }

  DateTime _validateTimestamp(dynamic timestamp) {
    try {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
      
      if (timestamp is DateTime) {
        return timestamp;
      }
      
      // Default to current date if invalid
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }
}
