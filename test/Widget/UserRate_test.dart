import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';



void main() {
  testWidgets('Page UI loads correctly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MockUserRatePage()),
    );

    expect(find.byKey(const Key('rate_container')), findsOneWidget);
    expect(find.byKey(const Key('title')), findsOneWidget);
    expect(find.text('Rate User'), findsOneWidget);
  });

  testWidgets('Stars are visible', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MockUserRatePage()),
    );

    for (int i = 0; i < 5; i++) {
      expect(find.byKey(Key('star_$i')), findsOneWidget);
    }
  });

  testWidgets('Rating changes when star tapped', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MockUserRatePage()),
    );

    await tester.tap(find.byKey(const Key('star_4')));
    await tester.pump();

    expect(find.text('Rating: 5'), findsOneWidget);
  });

  testWidgets('Review text can be entered', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MockUserRatePage()),
    );

    await tester.enterText(
        find.byKey(const Key('review_field')), 'Great user!');
    await tester.pump();

    expect(find.text('Great user!'), findsOneWidget);
  });

  testWidgets('Buttons exist', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MockUserRatePage()),
    );

    expect(find.byKey(const Key('cancel_btn')), findsOneWidget);
    expect(find.byKey(const Key('submit_btn')), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Submit'), findsOneWidget);
  });
}







class MockUserRatePage extends StatefulWidget {
  const MockUserRatePage({super.key});

  @override
  State<MockUserRatePage> createState() => _MockUserRatePageState();
}

class _MockUserRatePageState extends State<MockUserRatePage> {
  int rating = 3;
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          key: const Key('rate_container'),
          padding: const EdgeInsets.all(20),
          width: 320,
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Rate User",
                key: Key('title'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              /// STARS
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    key: Key('star_$index'),
                    onPressed: () {
                      setState(() {
                        rating = index + 1;
                      });
                    },
                    icon: Icon(
                      Icons.star,
                      color:
                      index < rating ? Colors.orange : Colors.grey,
                    ),
                  );
                }),
              ),

              Text(
                'Rating: $rating',
                key: const Key('rating_text'),
              ),

              const SizedBox(height: 12),

              /// REVIEW
              TextField(
                key: const Key('review_field'),
                controller: controller,
                decoration:
                const InputDecoration(hintText: 'Write review'),
              ),

              const SizedBox(height: 16),

              /// BUTTONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('cancel_btn'),
                      onPressed: () {},
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      key: const Key('submit_btn'),
                      onPressed: () {},
                      child: const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}




