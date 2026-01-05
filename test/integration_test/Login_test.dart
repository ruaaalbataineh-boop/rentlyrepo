import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:p2/Login_Page.dart';
import 'package:p2/Categories_Page.dart';

void main() {

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login Page Integration Test', () {

    testWidgets(
      'Successful login navigates to Category Page',
          (WidgetTester tester) async {

        await tester.pumpWidget(
          const MaterialApp(
            home: LoginPage(),
          ),
        );

        expect(find.byKey(const ValueKey('emailField')), findsOneWidget);
        expect(find.byKey(const ValueKey('passwordField')), findsOneWidget);
        expect(find.byKey(const ValueKey('loginButton')), findsOneWidget);

        final emailField = find.byKey(const ValueKey('emailField'));
        await tester.enterText(emailField,'test@test.com' );


        final passwordField = find.byKey(const ValueKey('passwordField'));
        await tester.enterText(passwordField,'123456' );


        final loginButton = find.byKey(const ValueKey('loginButton'));
        await tester.tap(loginButton );


        await tester.pumpAndSettle();

        expect(find.byType(CategoryPage), findsOneWidget);
      },
    );
  });
}
