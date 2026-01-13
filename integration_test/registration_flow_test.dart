import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';

import 'package:p2/main_user.dart' as app;
import 'package:p2/main_user.dart' show navigatorKey;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> goToCreate(WidgetTester tester) async {
    await tester.runAsync(() async {
      navigatorKey.currentState?.pushReplacementNamed('/create');
    });
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  testWidgets('Full registration flow until phone page validation', (tester) async {
    app.main(testMode: true);
    await tester.pumpAndSettle(const Duration(seconds: 8));

    await goToCreate(tester);

    // Create account
    await tester.enterText(find.byKey(const ValueKey('createEmailField')), 'test@test.com');
    await tester.enterText(find.byKey(const ValueKey('createPasswordField')), '123456');

    await tester.tap(find.byKey(const ValueKey('createAccountButton')));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Phone page loaded
    expect(find.text('First Name'), findsOneWidget);
    expect(find.text('Last Name'), findsOneWidget);

    // Submit empty phone form
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Should still stay on phone page
    expect(find.text('First Name'), findsOneWidget);

    // Fill minimal fields
    await tester.enterText(find.byType(TextField).at(0), 'John');
    await tester.enterText(find.byType(TextField).at(1), 'Doe');

    // Still not complete → should not navigate
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('First Name'), findsOneWidget);
  });
}
