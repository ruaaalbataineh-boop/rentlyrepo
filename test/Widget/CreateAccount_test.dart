import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {

  group('Create Account Page Tests', () {
// 1
    testWidgets('UI loads correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MockCreateAccountPage()),
      );

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Continue'), findsOneWidget);
    });
// 2
    testWidgets('Empty fields show validation errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MockCreateAccountPage()),
      );

      await tester.tap(find.byKey(const Key('continue_button')));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });
// 3
    testWidgets('Invalid email shows error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MockCreateAccountPage()),
      );

      await tester.enterText(
          find.byKey(const Key('email_field')), 'wrongEmail');
      await tester.enterText(
          find.byKey(const Key('password_field')), '123456');

      await tester.tap(find.byKey(const Key('continue_button')));
      await tester.pump();

      expect(find.text('Invalid email address'), findsOneWidget);
    });
// 4
    testWidgets('Short password shows error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MockCreateAccountPage()),
      );

      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@mail.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), '123');

      await tester.tap(find.byKey(const Key('continue_button')));
      await tester.pump();

      expect(find.text('Password must be at least 6 characters'),
          findsOneWidget);
    });
// 5
    testWidgets('Password visibility toggle works', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MockCreateAccountPage()),
      );

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      await tester.tap(find.byKey(const Key('toggle_password')));
      await tester.pump();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
//6
    testWidgets('Valid input shows no errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MockCreateAccountPage()),
      );

      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@mail.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), '123456');

      await tester.tap(find.byKey(const Key('continue_button')));
      await tester.pump();

      expect(find.text('Please enter your email'), findsNothing);
      expect(find.text('Invalid email address'), findsNothing);
      expect(find.text('Please enter your password'), findsNothing);
      expect(find.text('Password must be at least 6 characters'),
          findsNothing);
    });


    // 7
    testWidgets('Valid input navigates to phone page', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const MockCreateAccountPage(),
        ),
      );

      // إدخال بيانات صحيحة
      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@mail.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), '123456');

      // الضغط على زر Continue
      await tester.tap(find.byKey(const Key('continue_button')));

      // الانتظار حتى تنتهي حركة الانتقال
      await tester.pumpAndSettle();

      // التحقق من ظهور صفحة الهاتف
      expect(find.text('Phone Verification Page'), findsOneWidget);
      expect(find.byKey(const Key('phone page')), findsOneWidget);
    });
  });

}

class MockCreateAccountPage extends StatefulWidget {
  const MockCreateAccountPage({super.key});

  @override
  State<MockCreateAccountPage> createState() => _MockCreateAccountPageState();
}

class _MockCreateAccountPageState extends State<MockCreateAccountPage> {
  final _formKey = GlobalKey<FormState>();
  bool obscurePassword = true;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Create Account",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              /// EMAIL
              TextFormField(
                key: const Key('email_field'),
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your email";
                  }
                  if (!value.contains('@')) {
                    return "Invalid email address";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              /// PASSWORD
              TextFormField(
                key: const Key('password_field'),
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  suffixIcon: IconButton(
                    key: const Key('toggle_password'),
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your password";
                  }
                  if (value.length < 6) {
                    return "Password must be at least 6 characters";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              /// CONTINUE BUTTON
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  key: const Key('continue_button'),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MockPhonePage(),
                          ),
                        );
                      }
                    },

                  child: const Text("Continue"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class MockPhonePage extends StatelessWidget {
  const MockPhonePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Phone Verification Page',
          key: Key('phone page'),
        ),
      ),
    );
  }
}


