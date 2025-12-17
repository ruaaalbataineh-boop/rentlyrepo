import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p2/login_page.dart';
import 'package:p2/app_locale.dart';

void main() {
  setUp(() {
    AppLocale.locale.value = const Locale("en");
  });

  // 1 load login 
  testWidgets('LoginPage UI loads correctly',
   (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp
      (home: const LoginPage()),
    );

    expect(find.text('login'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); 
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    expect(find.text("don't have an account? "), findsOneWidget);
  });
// 2 login done navigater to category 
  testWidgets('Successful login navigates to Category page ',
    (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: const LoginPage(),
      routes: {
        '/category': (_) => const Scaffold(
          body: Text('Category Page'),
        ),
      },
    ),
  );

  await tester.enterText(
      find.byType(TextFormField).first, "test@mail.com");
  await tester.enterText(
      find.byType(TextFormField).last, "123456");

  await tester.tap(find.byIcon(Icons.arrow_forward));
  await tester.pumpAndSettle();

  expect(find.text('Category Page'), findsOneWidget);
});

// 3 chek if empty form
  testWidgets("Validation shows for empty fields", (WidgetTester tester) async {
    await tester.pumpWidget
    (MaterialApp
    (home: const LoginPage()));

    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pump();

    expect(find.text("Please enter your email"), findsOneWidget);
    expect(find.text("Please enter your password"), findsOneWidget);
  });
// 4 in valid emaill
  testWidgets("Invalid email format shows error", (WidgetTester tester) async {
    await tester.pumpWidget
    (MaterialApp
    (home: const LoginPage())
    );

    await tester.enterText(find.byType(TextFormField).first, "wrongEmail");
    await tester.enterText(find.byType(TextFormField).last, "123456");

    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pump();

    expect(find.text("Enter a valid email"), findsOneWidget);
  });
// 5 in valid pass 4 pass < 6 
  testWidgets('Short password shows error', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp
      (home: const LoginPage()));

    await tester.enterText(find.byType(TextFormField).first, "test@mail.com");
    await tester.enterText(find.byType(TextFormField).last, "123");

    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pump();

    expect(find.text("Password must be at least 6 characters"), findsOneWidget);
  });
// 6 chek if  visibility off or on (icons)
  testWidgets('Password visibility toggle works', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: const LoginPage()));

    final visibilityButton = find.byIcon(Icons.visibility_off);
    expect(visibilityButton, findsOneWidget);

    await tester.tap(visibilityButton);
    await tester.pump();

    expect(find.byIcon(Icons.visibility), findsOneWidget);
  });
// 7  link sign up navigates to create account
  testWidgets('Navigates to Sign Up page', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const LoginPage(),
        routes: {
          '/create': (_) => const Scaffold(
                body: Center(child: Text('Create Account Page')),
              ),
        },
      ),
    );

    await tester.tap(find.text('sign_up'));
    await tester.pumpAndSettle();
    expect(find.text('Create Account Page'), findsOneWidget);
  });
}
