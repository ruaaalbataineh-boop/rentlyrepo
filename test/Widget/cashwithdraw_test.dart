import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  testWidgets('Page UI loads correctly', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MockCashWithdrawalPage()));
    expect(find.text('Mock Withdrawal'), findsOneWidget);
    expect(find.byKey(const Key('amountField')), findsOneWidget);
    expect(find.byKey(const Key('nameField')), findsOneWidget);
  });

  testWidgets('Quick Amount buttons update amount', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MockCashWithdrawalPage()));

    await tester.tap(find.byKey(const Key('quick50')));
    await tester.pump();
    expect(find.widgetWithText(TextField, '50'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quick100')));
    await tester.pump();
    expect(find.widgetWithText(TextField, '100'), findsOneWidget);
  });

  testWidgets('Validation shows errors for empty fields', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MockCashWithdrawalPage()));

    await tester.tap(find.byKey(const Key('generateBtn')));
    await tester.pump();

    expect(find.text('Enter amount'), findsOneWidget);
    expect(find.text('Enter name'), findsOneWidget);
    expect(find.text('Enter birth date'), findsOneWidget);
    expect(find.text('Enter phone'), findsOneWidget);
  });

  testWidgets('Generate code shows dialog when fields valid', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MockCashWithdrawalPage()));

    await tester.enterText(find.byKey(const Key('amountField')), '150');
    await tester.enterText(find.byKey(const Key('nameField')), 'John Doe');
    await tester.enterText(find.byKey(const Key('phoneField')), '0771234567');
    await tester.tap(find.byKey(const Key('birthDateField')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('generateBtn')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('Amount: 150'), findsOneWidget);
    expect(find.text('Withdrawal Code Generated'), findsOneWidget);
  });
}










class MockCashWithdrawalPage extends StatefulWidget {
  const MockCashWithdrawalPage({super.key});

  @override
  State<MockCashWithdrawalPage> createState() => _MockCashWithdrawalPageState();
}

class _MockCashWithdrawalPageState extends State<MockCashWithdrawalPage> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool _showErrors = false;
  String? _amountError;
  String? _fullNameError;
  String? _birthDateError;
  String? _phoneError;

  final List<String> quickAmounts = ['50', '100', '200'];

  void _validate() {
    setState(() {
      _showErrors = true;
      _amountError =
      amountController.text.isEmpty ? 'Enter amount' : null;
      _fullNameError =
      fullNameController.text.isEmpty ? 'Enter name' : null;
      _birthDateError =
      birthDateController.text.isEmpty ? 'Enter birth date' : null;
      _phoneError =
      phoneController.text.isEmpty ? 'Enter phone' : null;
    });
  }

  void _onQuickAmount(String amount) {
    setState(() {
      amountController.text = amount;
      _amountError = null;
    });
  }

  void _generateCode() {
    _validate();
    if (_amountError == null &&
        _fullNameError == null &&
        _birthDateError == null &&
        _phoneError == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Withdrawal Code Generated'),
          content: Text('Amount: ${amountController.text}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _selectBirthDate() async {
    final picked = DateTime.now().subtract(const Duration(days: 365 * 18));
    setState(() {
      birthDateController.text =
      '${picked.day.toString().padLeft(2, '0')}/'
          '${picked.month.toString().padLeft(2, '0')}/'
          '${picked.year}';
      _birthDateError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mock Withdrawal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              key: const Key('amountField'),
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                errorText: _showErrors ? _amountError : null,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: quickAmounts.map((amt) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ElevatedButton(
                    key: Key('quick$amt'),
                    onPressed: () => _onQuickAmount(amt),
                    child: Text('\$$amt'),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('nameField'),
              controller: fullNameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                errorText: _showErrors ? _fullNameError : null,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              key: const Key('birthDateField'),
              onTap: _selectBirthDate,
              child: AbsorbPointer(
                child: TextField(
                  controller: birthDateController,
                  decoration: InputDecoration(
                    labelText: 'Birth Date',
                    hintText: 'DD/MM/YYYY',
                    errorText: _showErrors ? _birthDateError : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('phoneField'),
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone',
                errorText: _showErrors ? _phoneError : null,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              key: const Key('generateBtn'),
              onPressed: _generateCode,
              child: const Text('Generate Withdrawal Code'),
            ),
          ],
        ),
      ),
    );
  }
}