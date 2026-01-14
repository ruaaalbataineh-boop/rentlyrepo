import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';

import 'package:p2/main_user.dart' as app;
import 'package:p2/main_user.dart' show navigatorKey;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> goToSettings(WidgetTester tester) async {
    await tester.runAsync(() async {
      navigatorKey.currentState?.pushNamed('/setting');
    });
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  testWidgets('Logout flow works correctly', (tester) async {
    app.main(testMode: true);
    await tester.pumpAndSettle(const Duration(seconds: 8));

    // Go to settings
    await goToSettings(tester);

    // Tap logout in settings
    await tester.tap(find.byKey(const ValueKey('settingsLogoutTile')));
    await tester.pumpAndSettle();

    // Select logout option
    await tester.tap(find.byKey(const ValueKey('logoutNormalOption')));
    await tester.pumpAndSettle();

    // Confirm logout
    await tester.tap(find.byKey(const ValueKey('logoutConfirmButton')));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify we are back on login page
    expect(find.byKey(const ValueKey('emailField')), findsOneWidget);
    expect(find.byKey(const ValueKey('passwordField')), findsOneWidget);
  });
}
