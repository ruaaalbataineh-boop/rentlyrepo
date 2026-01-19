import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/continue_create_account_logic.dart';

void main() {
  group('Phone Page Tests', () {

    // 1
    testWidgets('Phone page loads', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MockPhonePage()));

      expect(find.byKey(const Key('first_name')), findsOneWidget);
      expect(find.byKey(const Key('last_name')), findsOneWidget);
      expect(find.byKey(const Key('birth_date')), findsOneWidget);
      expect(find.byKey(const Key('phone')), findsOneWidget);
    });
// 4
    testWidgets('Empty fields show error', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MockPhonePage()));

      await tester.tap(find.byKey(const Key('continue_button')));
      await tester.pump();

      expect(find.text("Please enter your first name"), findsOneWidget);
      expect(find.text("Please enter your last name"), findsOneWidget);
      expect(find.text("Please select your birth date"), findsOneWidget);  
      expect(find.text("Please enter your phone number"), findsOneWidget);
    });


// 2
    testWidgets('Invalid phone shows error', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MockPhonePage()));

      await tester.enterText(find.byKey(const Key('phone')), '123');
      await tester.tap(find.byKey(const Key('continue_button')));
      await tester.pump();

      expect(find.textContaining('Phone number must be 9 digits'), findsOneWidget);
    });
// 3
    testWidgets('Valid data shows success', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MockPhonePage()));

      await tester.enterText(find.byKey(const Key('first_name')), 'Ahmad');
      await tester.enterText(find.byKey(const Key('last_name')), 'Ali');
      await tester.enterText(find.byKey(const Key('birth_date')), '2000-01-01');
      await tester.enterText(find.byKey(const Key('phone')), '0779123456');

      await tester.tap(find.byKey(const Key('continue_button')));
      await tester.pump();

      expect(find.text('Success'), findsOneWidget);
    });
  });
}







class MockPhonePage extends StatefulWidget {
  const MockPhonePage({super.key});

  @override
  State<MockPhonePage> createState() => _MockPhonePageState();
}

class _MockPhonePageState extends State<MockPhonePage> {
  final _formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final birthDateController = TextEditingController();
  final phoneController = TextEditingController();

  String? resultText;

  void validateAndContinue() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        resultText = "Success";
      });
    } else {
      setState(() {
        resultText = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  key: const Key('first_name'),
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: ContinueCreateAccountLogic.validateFirstName,
                ),
                TextFormField(
                  key: const Key('last_name'),
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator: ContinueCreateAccountLogic.validateLastName,
                ),
                TextFormField(
                  key: const Key('birth_date'),
                  controller: birthDateController,
                  decoration: const InputDecoration(labelText: 'Birth Date'),
                  validator: ContinueCreateAccountLogic.validateBirthDate,
                ),
                TextFormField(
                  key: const Key('phone'),
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  validator: ContinueCreateAccountLogic.validatePhoneNumber,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  key: const Key('continue_button'),
                  onPressed: validateAndContinue,
                  child: const Text('Continue'),
                ),
                if (resultText != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(resultText!),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
