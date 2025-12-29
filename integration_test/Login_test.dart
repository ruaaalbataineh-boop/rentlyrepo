import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:p2/main_user.dart';


void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();


    FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  });

  testWidgets('Login success navigates to CategoryPage',
          (WidgetTester tester) async {

        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();


        final emailField = find.byType(TextFormField).at(0);
        await tester.enterText(emailField, 'test@test.com');


        final passwordField = find.byType(TextFormField).at(1);
        await tester.enterText(passwordField, '123456');


        final loginButton = find.text('Login');
        await tester.tap(loginButton);

        await tester.pumpAndSettle(const Duration(seconds: 5));

        expect(find.text('Categories'), findsOneWidget);
      });

  testWidgets('Login fails with wrong password',
          (WidgetTester tester) async {
        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();

        await tester.enterText(
            find.byType(TextFormField).at(0), 'test@test.com');
        await tester.enterText(
            find.byType(TextFormField).at(1), 'wrongpass');

        await tester.tap(find.text('Login'));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        expect(find.textContaining('failed'), findsOneWidget);
      });
}
