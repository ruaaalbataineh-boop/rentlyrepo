import 'package:flutter/material.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/rating_security.dart';

class UserRatePage extends StatefulWidget {
  final String userId;
  final String userName;
  
  const UserRatePage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserRatePage> createState() => _UserRatePageState();
}

class _UserRatePageState extends State<UserRatePage> {
  int rating = 4;
  bool anonymous = false;
  final TextEditingController reviewController = TextEditingController();
  bool _isLoading = true;
  bool _canRate = false;
  String? _errorMessage;
  Map<String, dynamic>? _userRatingSummary;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      
      if (widget.userId.isEmpty || widget.userName.isEmpty) {
        throw Exception('Invalid user data');
      }

      
      _canRate = await RatingSecurity.canRateUser(widget.userId);
      
      
      final isSpam = await RatingSecurity.isRatingSpam(widget.userId);
      if (isSpam) {
        _canRate = false;
        _errorMessage = 'You have submitted too many ratings recently. Please try again later.';
      }

      
      _userRatingSummary = await RatingSecurity.getRatingSummary(widget.userId);

      
      await _logPageAccess();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      ErrorHandler.logError('Initialize Rate Page', error);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = ErrorHandler.getSafeError(error);
        });
      }
    }
  }

  Future<void> _logPageAccess() async {
    try {
      ErrorHandler.logInfo('Rate Page Access', '''
User: ${widget.userId}
Name: ${widget.userName}
Can Rate: $_canRate
Timestamp: ${DateTime.now().toIso8601String()}
''');
    } catch (error) {
      ErrorHandler.logError('Log Page Access', error);
    }
  }

  Future<void> _submitRating() async {
    try {
      setState(() {
        _isLoading = true;
      });

    
      if (!RatingSecurity.isValidRating(rating)) {
        throw Exception('Please select a valid rating');
      }

      
      final review = reviewController.text.trim();
      if (!RatingSecurity.isValidReview(review)) {
        throw Exception('Review contains invalid content');
      }

      
      if (!_canRate) {
        throw Exception('You cannot rate this user at this time');
      }

      
      final result = await RatingSecurity.submitRating(
        ratedUserId: widget.userId,
        rating: rating,
        review: review,
        anonymous: anonymous,
      );

      if (result['success'] == true) {
        
        _showSuccessMessage();
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          Navigator.pop(context, result['data']);
        }
      } else {
        throw Exception(result['message'] ?? 'Failed to submit rating');
      }
    } catch (error) {
      ErrorHandler.logError('Submit Rating', error);
      _showErrorMessage(ErrorHandler.getSafeError(error));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Rating submitted successfully!',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1F0F46),
              Color(0xFF8A005D),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1F0F46),
              Color(0xFF8A005D),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'An error occurred',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8A005D),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text(
                    'Go Back',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccessDeniedScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1F0F46),
              Color(0xFF8A005D),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 60,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cannot Rate User',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You are not allowed to rate this user at this time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8A005D),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text(
                    'Go Back',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSummary() {
    if (_userRatingSummary == null || _userRatingSummary!['has_ratings'] != true) {
      return Container();
    }

    final avgRating = _userRatingSummary!['average_rating'] as double;
    final totalRatings = _userRatingSummary!['total_ratings'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 8),
        const Text(
          "User's Rating Summary",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.star,
              color: Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              avgRating.toStringAsFixed(1),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '($totalRatings ${totalRatings == 1 ? 'rating' : 'ratings'})',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: avgRating / 5.0,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            avgRating >= 4 ? Colors.green : 
            avgRating >= 3 ? Colors.orange : Colors.red,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    if (!_canRate) {
      return _buildAccessDeniedScreen();
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1F0F46),
              Color(0xFF8A005D),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 340,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8A005D).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          size: 26,
                          color: Color(0xFF8A005D),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Rate User",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.userName,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Rating
                  const Text(
                    "Your Rating",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            rating = index + 1;
                          });
                        },
                        icon: Icon(
                          Icons.star,
                          color: index < rating
                              ? Colors.orange
                              : Colors.grey.shade300,
                          size: 40,
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 10),

                  // User name
                  const Text(
                    "User",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: widget.userName,
                      suffixIcon: const Icon(Icons.info_outline),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Review
                  const Text(
                    "Review (Optional)",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reviewController,
                    maxLength: 200,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Write your feedback...",
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      counterText: '',
                    ),
                  ),
                  Text(
                    '${reviewController.text.length}/200 characters',
                    style: TextStyle(
                      fontSize: 12,
                      color: reviewController.text.length > 180 
                          ? Colors.orange 
                          : Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Anonymous toggle
                  Row(
                    children: [
                      Checkbox(
                        value: anonymous,
                        onChanged: (value) {
                          setState(() {
                            anonymous = value ?? false;
                          });
                        },
                      ),
                      const Text("Submit anonymously"),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.help_outline,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),

                  // Rating Summary
                  _buildRatingSummary(),

                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitRating,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8A005D),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Submit",
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }
}
