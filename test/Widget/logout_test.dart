import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logout_confirmation_page.dart';

void main() {
// 1 
  testWidgets('LogoutPage UI loads correctly',
      (WidgetTester tester) async {

    await tester.pumpWidget(
      const MaterialApp(
        home: LogoutConfirmationPage(),
      ),
    );

    expect(find.text('Oh No!\nAre you sure you want to logout?'), findsOneWidget);

    expect(find.byIcon(Icons.logout), findsOneWidget);

    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Yes, Logout'), findsOneWidget);
  });
// 2 
  testWidgets('Cancel button pops the page',
      (WidgetTester tester) async {

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LogoutConfirmationPage(),
                  ),
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(LogoutConfirmationPage), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(LogoutConfirmationPage), findsNothing);
  });
// 3
  testWidgets('Logout button navigates to Login page',
      (WidgetTester tester) async {

    await tester.pumpWidget(
      MaterialApp(
        home: const LogoutConfirmationPage(),
        routes: {
          '/login': (_) => const Scaffold(
            body: Center(child: Text('Login Page')),
          ),
        },
      ),
    );

    await tester.tap(find.text('Yes, Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Login Page'), findsOneWidget);
  });
}
