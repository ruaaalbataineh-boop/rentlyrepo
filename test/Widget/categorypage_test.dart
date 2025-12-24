import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p2/Categories_Page.dart';


void main() {

  group('CategoryPage Tests', () {

    // 1
    testWidgets('CategoryPage shows title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CategoryPage(enableFirebase: false, testMode: true),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Categories'), findsOneWidget);
    });



// 2
    testWidgets('Category card is tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CategoryPage(enableFirebase: false, testMode: true),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.text('Electronics').first);
      await tester.pumpAndSettle();

      expect(find.byType(InkWell), findsWidgets);
    });
// 3
    testWidgets('Search field accepts input', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CategoryPage(enableFirebase: false, testMode: true),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Test Search');
      await tester.pump();

      expect(find.text('Test Search'), findsOneWidget);
    });

// 4
    testWidgets('BottomNavigationBar does not appear when testMode is true',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: CategoryPage(enableFirebase: false, testMode: true),
            ),
          );

          await tester.pumpAndSettle(const Duration(seconds: 2));

          expect(find.byType(BottomNavigationBar), findsNothing);
        });
  });
}
