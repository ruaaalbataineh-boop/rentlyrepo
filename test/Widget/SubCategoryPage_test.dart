import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p2/views/ProductListPage.dart';
import 'package:p2/views/sub_category_page.dart';

void main() {

  testWidgets('SubCategoryPage UI loads correctly',
      (WidgetTester tester) async {

    await tester.pumpWidget(
      MaterialApp(
        home: const SubCategoryPage(
          categoryId: 'c2',
          categoryTitle: 'Computers & Mobiles',
        ),
      ),
    );

    expect(find.text('Computers & Mobiles'), findsOneWidget);

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    expect(find.byType(GridView), findsOneWidget);

    expect(find.text('Laptops'), findsOneWidget);
    expect(find.text('Mobiles'), findsOneWidget);
  });

  testWidgets('Back button pops the page',
      (WidgetTester tester) async {

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SubCategoryPage(
                    categoryId: 'c2',
                    categoryTitle: 'Computers & Mobiles',
                  ),
                ),
              );
            },
            child: const Text('Go'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();

    expect(find.byType(SubCategoryPage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.byType(SubCategoryPage), findsNothing);
  });

  testWidgets('Tap sub category navigates to ProductListPage',
      (WidgetTester tester) async {

    await tester.pumpWidget(
      MaterialApp(
        home: const SubCategoryPage(
          categoryId: 'c2',
          categoryTitle: 'Computers & Mobiles',
        ),
        routes: {
          ProductListPage.routeName: (_) =>
              const Scaffold(body: Text('Product List Page')),
        },
      ),
    );

    await tester.tap(find.text('Laptops'));
    await tester.pumpAndSettle();

    expect(find.text('Product List Page'), findsOneWidget);
  });
}
