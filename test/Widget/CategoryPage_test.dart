import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p2/category_page.dart';
import 'package:p2/sub_category_page.dart';

void main() {
  Widget createPage() {
    return const MaterialApp(
      home: CategoryPage(),
    );
  }

 // categoryPage loads
  testWidgets('CategoryPage loads UI correctly ',
      (WidgetTester tester) async {
    await tester.pumpWidget(createPage());

    expect(find.text('Categories'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
  });

// 2 categories show
  testWidgets('Shows categories in grid',
      (WidgetTester tester) async {
    await tester.pumpWidget(createPage());

    expect(find.text('Electronics'), findsOneWidget);
    expect(find.text('Computers & Mobiles'), findsOneWidget);
    expect(find.byIcon(Icons.headphones), findsOneWidget);
  });

// 3 search filters 
  testWidgets('Search filters categories',
      (WidgetTester tester) async {
    await tester.pumpWidget(createPage());

    await tester.enterText(
        find.byType(TextField), 'Electronics');
    await tester.pump();

    expect(find.text('Electronics'), findsOneWidget);
    expect(find.text('Sports and hobbies'), findsNothing);
  });

// 4 category navigates to subcategory
testWidgets('category navigates to SubCategoryPage',
    (WidgetTester tester) async {

  await tester.pumpWidget(
    const MaterialApp(
      home: CategoryPage(),
    ),
  );

  await tester.tap(find.text('Electronics'));
  await tester.pumpAndSettle();
  expect(find.byType(SubCategoryPage), findsOneWidget);
});

}
