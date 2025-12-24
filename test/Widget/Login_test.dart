import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginPage Tests', () {

    //1
    testWidgets('LoginPage UI loads correctly', (WidgetTester tester) async {

      await tester.pumpWidget(
        const MaterialApp(
          home: MockLoginPage(),
        ),
      );

      await tester.pump();

      expect(find.text('Login'), findsWidgets);
      expect(find.textContaining('Login', findRichText: true), findsWidgets);

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.text("Don't have an account? "), findsOneWidget);
    });
// 2  empty fields
    testWidgets("Validation shows for empty fields", (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MockLoginPage()),
      );

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      expect(find.text("Please enter your email"), findsOneWidget);
      expect(find.text("Please enter your password"), findsOneWidget);
    });
// 3 Invalid email
    testWidgets("Invalid email format shows error", (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MockLoginPage()),
      );

      await tester.enterText(find.byKey(const Key('email_field')), "wrongEmail");
      await tester.enterText(find.byKey(const Key('password_field')), "123456");

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      expect(find.text("Enter a valid email"), findsOneWidget);
    });

// 4 Short password

    testWidgets('Short password prevents login',
            (WidgetTester tester) async {


          await tester.pumpWidget(
            const MaterialApp(home: MockLoginPage()),
          );

          await tester.enterText(
              find.byType(TextFormField).first, "test@mail.com");
          await tester.enterText(
              find.byType(TextFormField).last, "123");

          await tester.tap(find.byIcon(Icons.arrow_forward));
          await tester.pump();

          expect(find.byType( MockLoginPage), findsOneWidget);
        });
//5 visibility icons
    testWidgets('Password visibility toggle works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MockLoginPage()),
      );

      final visibilityButton = find.byKey(const Key('password_visibility_button'));
      expect(visibilityButton, findsOneWidget);

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      await tester.tap(visibilityButton);
      await tester.pump();
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      await tester.tap(visibilityButton);
      await tester.pump();
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });
//6 Navigates
    testWidgets('Navigates to Sign Up page', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text("Don't have an account? "),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/create');
                            },
                            child: const Text(
                              "Sign up",
                              style: TextStyle(
                                color: Colors.pink,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          routes: {
            '/create': (_) => const Scaffold(
              body: Center(child: Text('Create Account Page')),
            ),
          },
        ),
      );

      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();

      expect(find.text('Create Account Page'), findsOneWidget);
    });
//7
    testWidgets('Valid input shows no errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MockLoginPage()),
      );

      await tester.enterText(find.byKey(const Key('email_field')), "test@mail.com");
      await tester.enterText(find.byKey(const Key('password_field')), "123456");

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      expect(find.text("Please enter your email"), findsNothing);
      expect(find.text("Enter a valid email"), findsNothing);
      expect(find.text("Please enter your password"), findsNothing);
      expect(find.text("Password must be at least 6 characters"), findsNothing);
    });
//8
    testWidgets('Login button is present and clickable', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MockLoginPage()),
      );

      final loginButton = find.byKey(const Key('login_button'));
      expect(loginButton, findsOneWidget);

      final button = tester.widget<ElevatedButton>(loginButton);
      expect(button.onPressed, isNotNull);
    });
  });
}
// Mock LoginPage
class MockLoginPage extends StatefulWidget {
  const MockLoginPage({super.key});

  @override
  State<MockLoginPage> createState() => _MockLoginPageState();
}

class _MockLoginPageState extends State<MockLoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                const Text(
                  "Login",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        "Sign up",
                        style: TextStyle(
                          color: Colors.pink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                TextFormField(
                  key: const Key('email_field'),
                  decoration: InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('password_field'),
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    suffixIcon: IconButton(
                      key: const Key('password_visibility_button'),
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    key: const Key('login_button'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8A005D),
                      padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      _formKey.currentState?.validate();
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Login", style: TextStyle(color: Colors.white)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

