import 'package:flutter/material.dart';
import 'package:p2/logic/rating_logic.dart';
import 'package:p2/security/error_handler.dart';

class RateProductPage extends StatefulWidget {
  final String productId;
  final String productName;
  
  const RateProductPage({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<RateProductPage> createState() => _RateProductPageState();
}

class _RateProductPageState extends State<RateProductPage> {
  int rating = 4;
  bool anonymous = false;
  bool _isSubmitting = false;
  final TextEditingController reviewController = TextEditingController();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExistingRating();
  }

  Future<void> _loadExistingRating() async {
    try {
      
    } catch (error) {
      ErrorHandler.logError('Load Existing Rating', error);
    }
  }

  Future<void> _submitRating() async {
    try {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });

      final submissionResult = await RatingLogic.submitRating(
        rating: rating,
        productId: widget.productId,
        productName: widget.productName,
        review: reviewController.text.isNotEmpty ? reviewController.text : null,
        anonymous: anonymous,
      );

      if (submissionResult) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(RatingLogic.getSuccessMessage()),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          
          
          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted) Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _errorMessage = RatingLogic.getErrorMessage();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(RatingLogic.getErrorMessage()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      ErrorHandler.logError('Submit Rating', error);
      setState(() {
        _errorMessage = ErrorHandler.getSafeError(error);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getSafeError(error)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<bool> _validateBeforeSubmit() async {
    final validationResult = await RatingLogic.validateRating(
      rating: rating,
      productId: widget.productId,
      productName: widget.productName,
      review: reviewController.text.isNotEmpty ? reviewController.text : null,
      anonymous: anonymous,
    );

    if (!validationResult) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(RatingLogic.getValidationErrorMessage()),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return false;
    }

    return true;
  }

  Widget _buildRatingStars() {
    return Row(
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
    );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Product Name",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: widget.productName,
            suffixIcon: const Icon(Icons.info_outline),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Product Review (Optional)",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: reviewController,
          maxLength: 200,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Provide a detailed review...",
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            counterText: "${reviewController.text.length}/200",
          ),
        ),
      ],
    );
  }

  Widget _buildAnonymousOption() {
    return Row(
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
        const SizedBox(width: 8),
        const Icon(Icons.visibility_off, size: 16, color: Colors.grey),
      ],
    );
  }

  Widget _buildErrorDisplay() {
    if (_errorMessage == null) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting ? null : () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : () async {
              final isValid = await _validateBeforeSubmit();
              if (isValid) {
                await _submitRating();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              disabledBackgroundColor: Colors.blue.shade200,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
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
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Rate & Review Product",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Provide us with feedback for the product.",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
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
                  _buildRatingStars(),

                  const SizedBox(height: 10),

                  // Product name
                  _buildProductInfo(),

                  const SizedBox(height: 12),

                  // Review
                  _buildReviewField(),

                  const SizedBox(height: 8),

                  // Anonymous option
                  _buildAnonymousOption(),

                  const SizedBox(height: 16),

                  // Error display
                  _buildErrorDisplay(),

                  // Buttons
                  _buildActionButtons(),
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
