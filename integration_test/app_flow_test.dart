import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';

import 'package:p2/main_user.dart' as app;
import 'package:p2/main_user.dart' show navigatorKey;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Wait until login page widgets appear
  Future<void> waitForLogin(WidgetTester tester) async {
    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find.byKey(const ValueKey('loginButton')).evaluate().isNotEmpty) {
        return;
      }
    }
    throw Exception('Login page not loaded');
  }

  testWidgets('Full login validation flow', (tester) async {
    // START APP
    app.main(testMode: true);
    await tester.pumpAndSettle(const Duration(seconds: 8));

    // FORCE NAVIGATION TO LOGIN
    await tester.runAsync(() async {
      navigatorKey.currentState?.pushReplacementNamed('/login');
    });

    await tester.pumpAndSettle(const Duration(seconds: 3));

    await waitForLogin(tester);

// EMPTY LOGIN

    await tester.tap(find.byKey(const ValueKey('loginButton')));
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);

    // INVALID EMAIL
    await tester.enterText(find.byKey(const ValueKey('emailField')), 'abc');
    await tester.enterText(find.byKey(const ValueKey('passwordField')), '123456');

    await tester.tap(find.byKey(const ValueKey('loginButton')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email'), findsOneWidget);

    // VALID FORMAT
    await tester.enterText(find.byKey(const ValueKey('emailField')), 'test@test.com');
    await tester.enterText(find.byKey(const ValueKey('passwordField')), '123456');

    await tester.tap(find.byKey(const ValueKey('loginButton')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Enter a valid email'), findsNothing);
    expect(find.text('Password must be at least 6 characters'), findsNothing);
  });
}
