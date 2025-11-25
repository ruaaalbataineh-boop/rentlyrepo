import 'package:flutter/material.dart';
import 'Last Activity.dart';

class WithdrawPage extends StatefulWidget {
  const WithdrawPage({super.key});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final TextEditingController balanceController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bankController = TextEditingController();
  final TextEditingController ibanController = TextEditingController();

  bool isWithdrawPressed = false;

  List<Map<String, String>> fakeWithdrawals = [];

  void saveWithdrawal() {
    String balanceText = balanceController.text.trim();
    String amountText = amountController.text.trim();
    String name = nameController.text.trim();
    String bank = bankController.text.trim();
    String iban = ibanController.text.trim();

    if (balanceText.isEmpty ||
        amountText.isEmpty ||
        name.isEmpty ||
        bank.isEmpty ||
        iban.isEmpty) {
      showError("Please fill all fields");
      return;
    }
    double? balance = double.tryParse(balanceText);
    double? amount = double.tryParse(amountText);

    if (balance == null || balance < 0) {
      showError("Enter a valid balance");
      return;
    }

    if (amount == null || amount <= 0) {
      showError("Enter a valid withdrawal amount");
      return;
    }

    if (amount > balance) {
      showError("Withdrawal amount exceeds available balance");
      return;
    }

    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
      showError("Name must contain letters only");
      return;
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(bank)) {
      showError("Bank name must contain letters only");
      return;
    }

    if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(iban) || iban.length < 15) {
      showError("Enter a valid IBAN (min 15 characters)");
      return;
    }
    final withdrawal = {
      'balance': balance.toString(),
      'amount': amount.toString(),
      'name': name,
      'bank': bank,
      'iban': iban,
      'timestamp': DateTime.now().toString(),
    };

    fakeWithdrawals.add(withdrawal);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Withdrawal successful (fake backend)"),
        duration: Duration(seconds: 2),
      ),
    );

    print("Fake Withdrawals: $fakeWithdrawals");

   
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WalletPage()),
    );
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: const Text("Withdraw", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: Column(
          children: [
            const SizedBox(height: 20),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text("Total Balance",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 10),

                  TextField(
                    controller: balanceController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Enter Balance",
                      hintStyle: TextStyle(color: Colors.white70),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),

                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildTextField("Withdraw Amount", amountController,
                          keyboard: TextInputType.number),

                      const SizedBox(height: 20),
                      const Text(
                        "Bank account information for Withdraw",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      _buildTextField("Account Holder Name", nameController),
                      const SizedBox(height: 20),

                      _buildTextField("Select The Bank", bankController),
                      const SizedBox(height: 20),

                      _buildTextField("IBAN", ibanController),
                      const SizedBox(height: 30),

                     
                      GestureDetector(
                        onTapDown: (_) => setState(() => isWithdrawPressed = true),
                        onTapUp: (_) {
                          setState(() => isWithdrawPressed = false);
                          saveWithdrawal();
                        },
                        onTapCancel: () => setState(() => isWithdrawPressed = false),

                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          transform: isWithdrawPressed
                              ? Matrix4.translationValues(0, 3, 0)
                              : Matrix4.identity(),
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 40),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            "Withdraw",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

