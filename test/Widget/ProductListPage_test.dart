import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p2/ProductListPage.dart';

void main() {
  // 1
  testWidgets('ProductListPage UI loads correctly',
      (WidgetTester tester) async {

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ProductListPage();
          },
        ),
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            settings: RouteSettings(
              arguments: {
                "category": "Electronics",
                "subCategory": "Laptops",
              },
            ),
            builder: (_) => const ProductListPage(),
          );
        },
      ),
    );

    await tester.pump();

    expect(find.text('Electronics - Laptops'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    expect(find.byType(TextField), findsOneWidget);

    expect(find.byType(GridView), findsOneWidget);
  });
// 2 back 
  testWidgets('Back button pops page', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(
                        arguments: {
                          "category": "Electronics",
                          "subCategory": "Laptops",
                        },
                      ),
                      builder: (_) => const ProductListPage(),
                    ),
                  );
                },
                child: const Text('Go'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductListPage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.byType(ProductListPage), findsNothing);
  });
// 3 
  testWidgets('Typing in search field works',
      (WidgetTester tester) async {

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ProductListPage();
          },
        ),
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            settings: const RouteSettings(
              arguments: {
                "category": "Electronics",
                "subCategory": "Laptops",
              },
            ),
            builder: (_) => const ProductListPage(),
          );
        },
      ),
    );

    await tester.pump();

    await tester.enterText(find.byType(TextField), 'lap');
    await tester.pump();

    expect(find.text('lap'), findsOneWidget);
  });
}
