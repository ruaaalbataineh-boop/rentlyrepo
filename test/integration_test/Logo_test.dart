import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';




void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Test', () {

    testWidgets('Splash screen navigates to login after 3 sec',
            (WidgetTester tester) async {


      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.diamond), findsOneWidget);
      expect(find.text('Rently'), findsOneWidget);


      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

     expect(find.byKey(Key('loginButton')), findsOneWidget);
     expect(find.text('Login Page'), findsOneWidget);


    });
  });
}