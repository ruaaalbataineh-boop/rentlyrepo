import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:p2/Categories_Page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Categories full navigation flow', (tester) async {

    await tester.pumpWidget(
      const MaterialApp(
        home: CategoryPage(testMode: true),
      ),
    );

    await tester.pumpAndSettle();

    // ---- CATEGORY PAGE ----
    expect(find.text('Categories'), findsOneWidget);

    final searchField = find.byKey(const ValueKey('searchField'));
    await tester.enterText(searchField, 'Electronics');
    await tester.pumpAndSettle();

    final categoryTile = find.byKey(const ValueKey('category_c1'));
    expect(categoryTile, findsOneWidget);
    await tester.tap(categoryTile);
    await tester.pumpAndSettle();

    // ---- SUB CATEGORY PAGE ----
    expect(find.text('Electronics'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));

    final subCategory = find.byType(GestureDetector).first;
    await tester.tap(subCategory);
    await tester.pumpAndSettle();

    // ---- PRODUCT LIST PAGE ----
    expect(find.byType(GridView), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));

    final productTiles = find.byType(Card);
    expect(productTiles, findsWidgets);

  });
}
