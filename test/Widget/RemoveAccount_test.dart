import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {

  testWidgets('Page loads correctly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockRemoveAccountPage(),
        ),
      );

      expect(find.text("Are you sure you want to remove your account?"),
          findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.byKey(const Key('remove_btn')), findsOneWidget);
      expect(find.byKey(const Key('cancel_btn')), findsOneWidget);
    },
  );

  testWidgets('Remove button shows success SnackBar',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MockRemoveAccountPage(),
                    ),
                  );
                },
                child: const Text("Open"),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text("Open"));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('remove_btn')));
      await tester.pump();

      expect(find.text("Account removed successfully."), findsOneWidget);
    },
  );

  testWidgets(' Cancel button closes the page',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MockRemoveAccountPage(),
                    ),
                  );
                },
                child: const Text("Open"),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text("Open"));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cancel_btn')));
      await tester.pumpAndSettle();

      expect(find.text("Are you sure you want to remove your account?"),
          findsNothing);
    },
  );

  testWidgets(' Card widget is displayed',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockRemoveAccountPage(),
        ),
      );

      expect(find.byKey(const Key('remove_card')), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    },
  );

  testWidgets(' Both buttons are enabled',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockRemoveAccountPage(),
        ),
      );

      final removeBtn =
      tester.widget<ElevatedButton>(find.byKey(const Key('remove_btn')));
      final cancelBtn =
      tester.widget<ElevatedButton>(find.byKey(const Key('cancel_btn')));

      expect(removeBtn.onPressed, isNotNull);
      expect(cancelBtn.onPressed, isNotNull);
    },
  );
}













/// =======================
/// MOCK REMOVE ACCOUNT PAGE
/// =======================
class MockRemoveAccountPage extends StatelessWidget {
  const MockRemoveAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Card(
            key: const Key('remove_card'),
            color: Colors.grey,
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 80,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Are you sure you want to remove your account?",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          key: const Key('remove_btn'),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Account removed successfully."),
                              ),
                            );
                            Navigator.pop(context);
                          },
                          child: const Text("Remove"),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton(
                          key: const Key('cancel_btn'),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("Cancel"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

