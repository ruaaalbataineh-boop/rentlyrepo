import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class RateProductPage extends StatefulWidget {
  final String requestId;
  final String itemTitle;
  final String? ownerName;
  final String? renterName;
  final bool isRenter;

  const RateProductPage({
    super.key,
    required this.requestId,
    required this.itemTitle,
    required this.ownerName,
    required this.renterName,
    required this.isRenter,
  });

  @override
  State<RateProductPage> createState() => _RateProductPageState();
}

class _RateProductPageState extends State<RateProductPage> {
  int rating = 0;
  final TextEditingController reviewController = TextEditingController();
  bool loading = false;

  late final String reviewedUserName;

  @override
  void initState() {
    super.initState();
    reviewedUserName =
    widget.isRenter
        ? (widget.ownerName ?? "Unknown user")
        : (widget.renterName ?? "Unknown user");
  }

  Future<void> submitReview() async {
    if (rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a rating")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseFunctions.instance
          .httpsCallable("submitReview")
          .call({
        "requestId": widget.requestId,
        "rating": rating,
        "comment": reviewController.text.trim(),
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "How was your experience?",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),

                // Stars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setState(() {
                          rating = index + 1;
                        });
                      },
                      icon: Icon(
                        Icons.star,
                        size: 38,
                        color: index < rating
                            ? Colors.orange
                            : Colors.grey.shade300,
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 12),

                // User name
                const Text("Reviewing"),
                const SizedBox(height: 6),
                TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: reviewedUserName,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Item name
                const Text("Item"),
                const SizedBox(height: 6),
                TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: widget.itemTitle,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Review
                const Text("Review (Optional)"),
                const SizedBox(height: 6),
                TextField(
                  controller: reviewController,
                  maxLength: 200,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Share your experience...",
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: loading
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: loading ? null : submitReview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8A005D),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: loading
                            ? const SizedBox(
                          height: 18,
                          width: 18,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
