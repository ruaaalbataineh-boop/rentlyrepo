import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginPage Tests', () {
    // 1 UI loads
    testWidgets('LoginPage UI loads correctly',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(home: MockLoginPage()),
          );

          expect(find.text('Login'), findsWidgets);
          expect(find.byType(TextFormField), findsNWidgets(2));
          expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
        });

    // 2 empty fields
    testWidgets('Validation shows for empty fields',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(home: MockLoginPage()),
          );

          await tester.tap(find.byKey(const Key('login_button')));
          await tester.pump();

          expect(find.text("Please enter your email"), findsOneWidget);
          expect(find.text("Please enter your password"), findsOneWidget);
        });

    // 3 invalid email
    testWidgets('Invalid email format shows error',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(home: MockLoginPage()),
          );

          await tester.enterText(
              find.byKey(const Key('email_field')), "wrongEmail");
          await tester.enterText(
              find.byKey(const Key('password_field')), "123456");

          await tester.tap(find.byKey(const Key('login_button')));
          await tester.pump();

          expect(find.text("Enter a valid email"), findsOneWidget);
        });

    // 4 short password
    testWidgets('Short password',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(home: MockLoginPage()),
          );

          await tester.enterText(
              find.byKey(const Key('email_field')), "test@mail.com");
          await tester.enterText(
              find.byKey(const Key('password_field')), "123");

          await tester.tap(find.byKey(const Key('login_button')));
          await tester.pump();

          expect(find.byType(MockLoginPage), findsOneWidget);
        });

    // 5 password visibility
    testWidgets('Password visibility works',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(home: MockLoginPage()),
          );

          final button =
          find.byKey(const Key('password_visibility_button'));

          expect(find.byIcon(Icons.visibility_off), findsOneWidget);

          await tester.tap(button);
          await tester.pump();
          expect(find.byIcon(Icons.visibility), findsOneWidget);

          await tester.tap(button);
          await tester.pump();
          expect(find.byIcon(Icons.visibility_off), findsOneWidget);
        });

    // 6 navigation to signup
    testWidgets('Navigates to Sign Up page',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/create');
                    },
                    child: const Text("Sign up"),
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

    // 7 navigates to Category
    testWidgets('Valid input navigates to Category page',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(home: MockLoginPage()),
          );

          await tester.enterText(
              find.byKey(const Key('email_field')), "test@mail.com");
          await tester.enterText(
              find.byKey(const Key('password_field')), "123456");

          await tester.tap(find.byKey(const Key('login_button')));
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('category_page')), findsOneWidget);
          expect(find.text('Category Page'), findsOneWidget);
        });

    // 8 button exists
    testWidgets('Login button is clickable',
            (WidgetTester tester) async {
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
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text("Login",
                  style:
                  TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              TextFormField(
                key: const Key('email_field'),
                decoration: const InputDecoration(labelText: "Email"),
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

              const SizedBox(height: 30),

              ElevatedButton(
                key: const Key('login_button'),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MockCategoryPage(),
                      ),
                    );
                  }
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Login"),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class MockCategoryPage extends StatelessWidget {
  const MockCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Category Page',
          key: Key('category_page'),
        ),
      ),
    );
  }
}
