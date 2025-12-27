import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {


  testWidgets('Favourite page shows items correctly',
          (WidgetTester tester) async {

        await tester.pumpWidget(
          const MaterialApp(home: MockFavouritePage()),
        );

        expect(find.text("Favourite"), findsOneWidget);

        expect(find.text("Camera"), findsOneWidget);
        expect(find.text("Laptop"), findsOneWidget);

        expect(find.text("Tap to remove"), findsNWidgets(2));
      });


  testWidgets('Favourite item is removed on tap',
          (WidgetTester tester) async {

        await tester.pumpWidget(
          const MaterialApp(home: MockFavouritePage()),
        );

        expect(find.text("Camera"), findsOneWidget);

        await tester.tap(find.text("Camera"));
        await tester.pump();

        expect(find.text("Camera"), findsNothing);
        expect(find.text("Laptop"), findsOneWidget);
      });

  testWidgets('All favourite items can be removed',
          (WidgetTester tester) async {

        await tester.pumpWidget(
          const MaterialApp(home: MockFavouritePage()),
        );

        await tester.tap(find.text("Camera"));
        await tester.pump();

        await tester.tap(find.text("Laptop"));
        await tester.pump();

        expect(find.text("Camera"), findsNothing);
        expect(find.text("Laptop"), findsNothing);
      });


  testWidgets('Empty message appears when list is empty',
          (WidgetTester tester) async {

        await tester.pumpWidget(
          const MaterialApp(home: MockFavouritePage()),
        );

        await tester.tap(find.text("Camera"));
        await tester.pump();

        await tester.tap(find.text("Laptop"));
        await tester.pump();

        expect(
          find.text("Your favourite items will appear here."),
          findsOneWidget,
        );
      });


  testWidgets('Hourly prices are displayed',
          (WidgetTester tester) async {

        await tester.pumpWidget(
          const MaterialApp(home: MockFavouritePage()),
        );

        expect(find.text("JOD 5 / hour"), findsOneWidget);
        expect(find.text("JOD 10 / hour"), findsOneWidget);
      });
}

/// =========================
/// MOCK PAGE
/// =========================
class MockFavouritePage extends StatefulWidget {
  const MockFavouritePage({super.key});

  @override
  State<MockFavouritePage> createState() => _MockFavouritePageState();
}

class _MockFavouritePageState extends State<MockFavouritePage> {
  List<Map<String, dynamic>> items = [
    {
      "name": "Camera",
      "hourly": "5",
    },
    {
      "name": "Laptop",
      "hourly": "10",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Favourite")),
      body: items.isEmpty
          ? const Center(
        child: Text("Your favourite items will appear here."),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                items.removeAt(index);
              });
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.image, size: 60),
                Text(items[index]["name"]),
                Text("JOD ${items[index]["hourly"]} / hour"),
                const Text(
                  "Tap to remove",
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
