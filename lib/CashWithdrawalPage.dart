import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:p2/services/firestore_service.dart';
import 'package:p2/user_manager.dart';
import 'package:p2/withdrawalReferencePage.dart';
import 'logic/cash_withdrawal_logic.dart';

class CashWithdrawalPage extends StatefulWidget {
  const CashWithdrawalPage({super.key});

  @override
  State<CashWithdrawalPage> createState() => _CashWithdrawalPageState();
}

class _CashWithdrawalPageState extends State<CashWithdrawalPage> {
  final TextEditingController amountController = TextEditingController();

  // Bank Fields
  final ibanController = TextEditingController();
  final bankNameController = TextEditingController();
  final accountHolderNameController = TextEditingController();

  // Exchange Office Fields
  final pickupNameController = TextEditingController();
  final pickupPhoneController = TextEditingController();
  final pickupIdController = TextEditingController();

  String? selectedMethod;
  bool canSubmit = false;
  bool loading = false;

  late CashWithdrawalLogic logic = CashWithdrawalLogic(currentBalance: 0);

  double currentBalance = 0.0;

  @override
  void initState() {
    super.initState();
    logic = CashWithdrawalLogic(currentBalance: currentBalance);

    amountController.addListener(_updateSubmitState);
    ibanController.addListener(_updateSubmitState);
    bankNameController.addListener(_updateSubmitState);
    accountHolderNameController.addListener(_updateSubmitState);

    pickupNameController.addListener(_updateSubmitState);
    pickupPhoneController.addListener(_updateSubmitState);
    pickupIdController.addListener(_updateSubmitState);
  }

  void _updateSubmitState() {
    final amountValid = logic.validateAmount(amountController.text) == null;

    bool extraValid = false;

    if (selectedMethod == "bank") {
      extraValid =
          logic.validateIBAN(ibanController.text) == null &&
              logic.validateBankName(bankNameController.text) == null &&
              logic.validateAccountHolder(accountHolderNameController.text) == null;
    }

    if (selectedMethod == "exchange") {
      extraValid =
          logic.validatePickupName(pickupNameController.text) == null &&
              logic.validatePickupPhone(pickupPhoneController.text) == null &&
              logic.validatePickupId(pickupIdController.text) == null;
    }

    setState(() {
      canSubmit = selectedMethod != null && amountValid && extraValid;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, double>>(
        stream: FirestoreService.combinedWalletStream(UserManager.uid!),
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;

          final balances = snapshot.data ?? {"userBalance": 0.0, "holdingBalance": 0.0};
          final currentBalance = balances["userBalance"] ?? 0.0;
          final holdingBalance = balances["holdingBalance"] ?? 0.0;

          logic.currentBalance = currentBalance;

          return Scaffold(
            appBar: AppBar(
              title: const Text(
                "Withdraw Money",
                style: TextStyle(color: Colors.white),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              elevation: 0,
            ),

            body: AbsorbPointer(
              absorbing: loading,
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _balanceCard(currentBalance, holdingBalance),
                        const SizedBox(height: 25),
                        _amountInputCard(),
                        const SizedBox(height: 25),
                        _methodCard(),
                        const SizedBox(height: 25),

                        if (selectedMethod == "bank")
                          _bankFields(),

                        if (selectedMethod == "exchange")
                          _exchangeFields(),

                        const SizedBox(height: 25),
                        _withdrawButton(),
                      ],
                    ),
                  ),

                  if (loading)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          );
        }
    );
  }

  Widget _balanceCard(double currentBalance, double holdingBalance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8A005D).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_wallet,
                  color: Colors.white70, size: 22),
              SizedBox(width: 8),
              Text(
                'CURRENT BALANCE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "${currentBalance.toStringAsFixed(2)} JD",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Holding: ${holdingBalance.toStringAsFixed(2)}JD",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          )
        ],
      ),
    );
  }

  Widget _amountInputCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.money, color: Color(0xFF8A005D)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Enter the amount you want to withdraw',
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F0F46),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F0F46),
              ),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(
                  fontSize: 28,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance_wallet,
                    color: Color(0xFF8A005D)),
                SizedBox(width: 10),
                Text(
                  "Withdrawal Method",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F0F46),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            _methodTile(
              id: "bank",
              title: "Bank Transfer",
              description: "Withdraw to your bank account",
              icon: Icons.account_balance,
            ),

            const SizedBox(height: 12),

            _methodTile(
              id: "exchange",
              title: "Cash Pickup",
              description: "Receive cash at exchange office",
              icon: Icons.money,
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodTile({
    required String id,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final selected = selectedMethod == id;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMethod = id;
        });
        _updateSubmitState();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF8A005D).withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF8A005D)
                : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color:
                selected ? const Color(0xFF8A005D) : Colors.grey,
                size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF8A005D)
                            : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 4),
                  Text(description,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      )),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle,
                  color: Color(0xFF8A005D), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _bankFields() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            field("IBAN", ibanController),
            const SizedBox(height: 12),
            field("Bank Name", bankNameController),
            const SizedBox(height: 12),
            field("Account Holder Name", accountHolderNameController),
          ],
        ),
      ),
    );
  }

  Widget _exchangeFields() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            field("Full Name", pickupNameController),
            const SizedBox(height: 12),
            field("Phone Number", pickupPhoneController,
                keyboard: TextInputType.phone),
            const SizedBox(height: 12),
            field("National ID Number", pickupIdController,
                keyboard: TextInputType.number),
          ],
        ),
      ),
    );
  }

  Widget field(String label, TextEditingController c,
      {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _withdrawButton() {
    final isEnabled = canSubmit && !loading;

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isEnabled
              ? const LinearGradient(
            colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
          )
              : LinearGradient(
            colors: [
              Colors.grey.shade400,
              Colors.grey.shade500
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: isEnabled ? _submit : null,
          child: const Text(
            "Submit Withdrawal",
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // BUTTON ACTION
  Future<void> _submit() async {
    if (!canSubmit) return;

    setState(() => loading = true);

    try {
      final response = await FirestoreService.createWithdrawalRequest(
        amount: double.parse(amountController.text),
        userId: UserManager.uid!,
        method: selectedMethod!,
        iban: ibanController.text,
        bankName: bankNameController.text,
        accountHolderName: accountHolderNameController.text,
        pickupName: pickupNameController.text,
        pickupPhone: pickupPhoneController.text,
        pickupIdNumber: pickupIdController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Withdrawal request submitted successfully"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      setState(() => loading = false);

      final reference = response["referenceNumber"];

      if (selectedMethod == "bank") {
        Navigator.pop(context);
      }
      else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WithdrawalReferencePage(
              amount: double.parse(amountController.text),
              reference: reference,
            ),
          ),
        );
      }

    } catch (e) {
      setState(() => loading = false);
      print("WITHDRAW ERROR RAW: $e");

      String message = "Withdrawal failed";

      try {
        // Firebase callable functions wrap the error
        final err = e as FirebaseFunctionsException;
        message = err.message ?? message;
        print("WITHDRAW ERROR MESSAGE: ${err.message}");
        print("WITHDRAW ERROR DETAILS: ${err.details}");
        print("WITHDRAW ERROR CODE: ${err.code}");
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

}
