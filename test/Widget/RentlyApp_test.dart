import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 1
  testWidgets('RentlyApp shows splash and then login', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MockRentlyApp()));


    expect(find.text('Rently'), findsOneWidget);
    expect(find.byIcon(Icons.diamond), findsOneWidget);


    await tester.pumpAndSettle();

    expect(find.byType(MockLoginPage), findsOneWidget);
    expect(find.byKey(const Key('email_field')), findsOneWidget);
    expect(find.byKey(const Key('password_field')), findsOneWidget);
  });
// 2
  testWidgets('LoginPage fields validation works', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MockLoginPage()));

    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pump();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
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
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Text("Login", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('email_field'),
                decoration: const InputDecoration(labelText: "Email"),
                validator: (v) => (v == null || v.isEmpty) ? 'Please enter your email' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const Key('password_field'),
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  suffixIcon: IconButton(
                    key: const Key('password_visibility_button'),
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Please enter your password' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                key: const Key('login_button'),
                onPressed: () {
                  _formKey.currentState?.validate();
                },
                child: const Text("Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class MockRentlyApp extends StatefulWidget {
  const MockRentlyApp({super.key});

  @override
  State<MockRentlyApp> createState() => _MockRentlyAppState();
}

class _MockRentlyAppState extends State<MockRentlyApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.diamond, size: 80, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  "Rently",
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return const MockLoginPage();
  }
}

