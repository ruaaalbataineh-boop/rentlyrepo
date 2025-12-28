import 'package:flutter/material.dart';
import 'package:p2/logic/withdrawal_logic.dart';


class CashWithdrawalPage extends StatefulWidget {
  const CashWithdrawalPage({super.key});

  @override
  State<CashWithdrawalPage> createState() => _CashWithdrawalPageState();
}

class _CashWithdrawalPageState extends State<CashWithdrawalPage> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController nationalIdController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  double currentBalance = 1250.75;

  late CashWithdrawalLogic logic;

  String? _amountError;
  String? _fullNameError;
  String? _nationalIdError;
  String? _birthDateError;
  String? _phoneError;

  bool _showErrors = false;

  final List<String> quickAmounts = ['50', '100', '200', '500', '1000'];

  @override
  void initState() {
    super.initState();
    logic = CashWithdrawalLogic(currentBalance: currentBalance);

    amountController.addListener(() {
      _amountError = logic.validateAmount(amountController.text);
      setState(() {});
    });

    fullNameController.addListener(() {
      _fullNameError = logic.validateFullName(fullNameController.text);
      setState(() {});
    });

    nationalIdController.addListener(() {
      _nationalIdError = logic.validateNationalID(nationalIdController.text);
      setState(() {});
    });

    birthDateController.addListener(() {
      _birthDateError = logic.validateBirthDate(birthDateController.text);
      setState(() {});
    });

    phoneController.addListener(() {
      _phoneError = logic.validatePhone(phoneController.text);
      setState(() {});
    });
  }

  void _validateAll() {
    setState(() {
      _showErrors = true;
      _amountError = logic.validateAmount(amountController.text);
      _fullNameError = logic.validateFullName(fullNameController.text);
      _nationalIdError = logic.validateNationalID(nationalIdController.text);
      _birthDateError = logic.validateBirthDate(birthDateController.text);
      _phoneError = logic.validatePhone(phoneController.text);
    });
  }

  void _processWithdrawal() {
    _validateAll();

    final hasErrors =
        _amountError != null ||
        _fullNameError != null ||
        _nationalIdError != null ||
        _birthDateError != null ||
        _phoneError != null;

    if (hasErrors) return;

    final code = logic.generateWithdrawalCode();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Withdrawal Code Generated'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_2, size: 60),
            const SizedBox(height: 20),
            Text(code, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Amount: \$${amountController.text}'),
            const SizedBox(height: 10),
            Text(fullNameController.text),
            const SizedBox(height: 10),
            Text(phoneController.text),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, String? error,
      {TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: type,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        if (_showErrors && error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(error, style: const TextStyle(color: Colors.red)),
          )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cash Withdrawal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('\$${currentBalance.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),

            const SizedBox(height: 20),

            _field('Amount', amountController, _amountError,
                type: const TextInputType.numberWithOptions(decimal: true)),

            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              children: quickAmounts.map((e) {
                return ElevatedButton(
                  onPressed: () {
                    amountController.text = e;
                  },
                  child: Text('\$$e'),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            _field('Full Name', fullNameController, _fullNameError),
            const SizedBox(height: 15),
            _field('National ID', nationalIdController, _nationalIdError,
                type: TextInputType.number),
            const SizedBox(height: 15),
            _field('Birth Date (DD/MM/YYYY)', birthDateController, _birthDateError),
            const SizedBox(height: 15),
            _field('Phone Number', phoneController, _phoneError,
                type: TextInputType.phone),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _processWithdrawal,
                child: const Text('Generate Withdrawal Code'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
