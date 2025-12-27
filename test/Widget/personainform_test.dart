import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {

  testWidgets('Page loads correctly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockPersonalInfoPage(),
        ),
      );

      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.byKey(const Key('avatar')), findsOneWidget);
    },
  );

  testWidgets('All input fields exist',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockPersonalInfoPage(),
        ),
      );

      expect(find.byKey(const Key('name_field')), findsOneWidget);
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.byKey(const Key('phone_field')), findsOneWidget);
    },
  );

  testWidgets('Buttons exist',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockPersonalInfoPage(),
        ),
      );

      expect(find.byKey(const Key('save_btn')), findsOneWidget);
      expect(find.byKey(const Key('rate_product_btn')), findsOneWidget);
      expect(find.byKey(const Key('user_rate_btn')), findsOneWidget);
    },
  );

  testWidgets('Enter text works',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockPersonalInfoPage(),
        ),
      );

      await tester.enterText(
          find.byKey(const Key('name_field')), 'Noor');
      await tester.enterText(
          find.byKey(const Key('email_field')), 'noor@test.com');

      expect(find.text('Noor'), findsOneWidget);
      expect(find.text('noor@test.com'), findsOneWidget);
    },
  );

  testWidgets('Save button shows SnackBar',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockPersonalInfoPage(),
        ),
      );

      await tester.tap(find.byKey(const Key('save_btn')));
      await tester.pump();

      expect(find.text('Information saved!'), findsOneWidget);
    },
  );
}
class MockPersonalInfoPage extends StatefulWidget {
  const MockPersonalInfoPage({super.key});

  @override
  State<MockPersonalInfoPage> createState() => _MockPersonalInfoPageState();
}

class _MockPersonalInfoPageState extends State<MockPersonalInfoPage> {
  String name = '';
  String email = '';
  String password = '';
  String phone = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Information'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// IMAGE PLACEHOLDER
            const CircleAvatar(
              key: Key('avatar'),
              radius: 60,
              child: Icon(Icons.camera_alt),
            ),

            const SizedBox(height: 20),

            _mockField(
              key: 'name_field',
              label: 'Name',
              icon: Icons.person,
              onChanged: (v) => name = v,
            ),
            const SizedBox(height: 15),

            _mockField(
              key: 'email_field',
              label: 'Email',
              icon: Icons.email,
              onChanged: (v) => email = v,
            ),
            const SizedBox(height: 15),

            _mockField(
              key: 'password_field',
              label: 'Password',
              icon: Icons.lock,
              obscure: true,
              onChanged: (v) => password = v,
            ),
            const SizedBox(height: 15),

            _mockField(
              key: 'phone_field',
              label: 'Phone Number',
              icon: Icons.phone,
              onChanged: (v) => phone = v,
            ),

            const SizedBox(height: 30),

            /// SAVE BUTTON
            ElevatedButton(
              key: const Key('save_btn'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Information saved!')),
                );
              },
              child: const Text('Save Information'),
            ),

            const SizedBox(height: 15),

            /// RATE PRODUCT
            ElevatedButton(
              key: const Key('rate_product_btn'),
              onPressed: () {},
              child: const Text('Rate Product'),
            ),

            const SizedBox(height: 12),

            /// USER RATE
            ElevatedButton(
              key: const Key('user_rate_btn'),
              onPressed: () {},
              child: const Text('User Rate'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mockField({
    required String key,
    required String label,
    required IconData icon,
    required Function(String) onChanged,
    bool obscure = false,
  }) {
    return TextField(
      key: Key(key),
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }
}

