import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {

  final mockReviews = [
    {
      "rating": 4.5,
      "review": "Great item, very useful!",
      "userId": "user123",
      "createdAt": DateTime(2024, 12, 1, 14, 30),
    },
    {
      "rating": 3.0,
      "review": "It was okay.",
      "userId": "user456",
      "createdAt": DateTime(2024, 12, 2, 10, 0),
    },
  ];


  testWidgets('Page UI loads and title is shown',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MockAllReviewsPage(mockReviews: mockReviews),
        ),
      );

      expect(find.text("All Reviews"), findsOneWidget);
    },
  );


  testWidgets('Reviews list is displayed',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MockAllReviewsPage(mockReviews: mockReviews),
        ),
      );

      expect(find.text("Great item, very useful!"), findsOneWidget);
      expect(find.text("It was okay."), findsOneWidget);
      expect(find.text("By: user123"), findsOneWidget);
      expect(find.text("By: user456"), findsOneWidget);
    },
  );


  testWidgets('Rating stars are shown',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MockAllReviewsPage(mockReviews: mockReviews),
        ),
      );

      expect(find.byIcon(Icons.star), findsWidgets);
    },
  );


  testWidgets('Empty reviews shows message',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockAllReviewsPage(mockReviews: []),
        ),
      );

      expect(find.text("No reviews yet."), findsOneWidget);
    },
  );
}



class MockAllReviewsPage extends StatelessWidget {
  final List<Map<String, dynamic>> mockReviews;

  const MockAllReviewsPage({
    super.key,
    required this.mockReviews,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Reviews"),
      ),
      body: mockReviews.isEmpty
          ? const Center(
        child: Text(
          "No reviews yet.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockReviews.length,
        itemBuilder: (context, index) {
          final data = mockReviews[index];

          double rating = (data["rating"] ?? 0).toDouble();
          String reviewText = data["review"] ?? "";
          String userId = data["userId"] ?? "Unknown user";
          DateTime createdAt = data["createdAt"];

          String formattedDate =
          DateFormat("yyyy-MM-dd  HH:mm").format(createdAt);

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ...List.generate(
                      5,
                          (i) => Icon(
                        Icons.star,
                        color:
                        i < rating ? Colors.amber : Colors.grey,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  reviewText,
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "By: $userId",
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600),
                    ),
                    Text(
                      formattedDate,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}