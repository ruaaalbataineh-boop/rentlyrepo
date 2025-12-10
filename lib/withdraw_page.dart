import 'package:flutter/material.dart';
import 'package:p2/Payment2.dart';

class WithdrawalService {
  List<Map<String, String>> withdrawals = [];

  String? validateAndSave({
    required String balanceText,
    required String amountText,
    required String name,
    required String bank,
    required String iban,
  }) {
    if (balanceText.isEmpty ||
        amountText.isEmpty ||
        name.isEmpty ||
        bank.isEmpty ||
        iban.isEmpty) {
      return "Please fill all fields";
    }

    double? balance = double.tryParse(balanceText);
    double? amount = double.tryParse(amountText);

    if (balance == null || balance < 0) return "Enter a valid balance";
    if (amount == null || amount <= 0) return "Enter a valid withdrawal amount";
    if (amount > balance) return "Withdrawal amount exceeds available balance";

    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) return "Name must contain letters only";
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(bank)) return "Bank name must contain letters only";
    if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(iban) || iban.length < 15) return "Enter a valid IBAN (min 15 characters)";

    withdrawals.add({
      'balance': balance.toString(),
      'amount': amount.toString(),
      'name': name,
      'bank': bank,
      'iban': iban,
      'timestamp': DateTime.now().toString(),
    });

    return null;
  }
}

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
  String? selectedBank;

  
  final List<String> banks = [
    "Select Bank",
    "Arab Bank",
    "Cairo Amman Bank",
    "Bank of Jordan",
    "Jordan Ahli Bank",
    "Union Bank",
    "Jordan Islamic Bank",
    "Investment Bank",
    "Jordan Kuwait Bank",
    "Jordan Commercial Bank",
    "Housing Bank for Trade and Finance",
    "Petra Bank",
    "National Bank of Jordan",
    "Alinma Bank",
    "Gulf Bank",
    "Mashreq Bank"
  ];

  void saveWithdrawal() {
    String? error = WithdrawalService().validateAndSave(
      balanceText: balanceController.text,
      amountText: amountController.text,
      name: nameController.text,
      bank: selectedBank ?? "",
      iban: ibanController.text,
    );

    if (error != null) {
      showError(error);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Withdrawal request submitted successfully"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const CardPaymentPage()),
    );
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
    
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 30,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1F0F46),
                  Color(0xFF8A005D),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, 
                          color: Colors.white, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    const Text(
                      "Withdraw Funds",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 20),
                
              
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_wallet_rounded, 
                              color: Colors.white70, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "TOTAL BALANCE",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: balanceController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter Balance",
                          hintStyle: TextStyle(
                            color: Colors.white54,
                            fontSize: 36,
                          ),
                          prefix: Text(
                            "\$ ",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              
                    const Text(
                      "Withdraw Amount",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F0F46),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8F9FF),
                        hintText: "Enter amount to withdraw",
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(
                          Icons.attach_money_rounded,
                          color: Color(0xFF8A005D),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xFF8A005D),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                
                    const SizedBox(height: 20),
                    const Text(
                      "Quick Amounts",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: ["50", "100", "200", "500", "1000"].map((amount) {
                        return GestureDetector(
                          onTap: () => amountController.text = amount,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              "\$$amount",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F0F46),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
            
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.account_balance_rounded,
                            color: Color(0xFF8A005D),
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Bank Account Information",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F0F46),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                  
                    _buildEnhancedTextField(
                      "Account Holder Name",
                      nameController,
                      icon: Icons.person_rounded,
                    ),
                    const SizedBox(height: 20),
                    
                  
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Select The Bank",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF555555),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FF),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedBank,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.expand_more_rounded,
                                color: Color(0xFF8A005D),
                              ),
                              hint: const Padding(
                                padding: EdgeInsets.only(left: 15),
                                child: Text(
                                  "Choose your bank",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              style: const TextStyle(
                                color: Color(0xFF1F0F46),
                                fontSize: 16,
                              ),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedBank = newValue;
                                });
                              },
                              items: banks.map((String bank) {
                                return DropdownMenuItem<String>(
                                  value: bank,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 15),
                                    child: Text(
                                      bank,
                                      style: TextStyle(
                                        color: bank == "Select Bank" 
                                            ? Colors.grey 
                                            : const Color(0xFF1F0F46),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
          
                    _buildEnhancedTextField(
                      "IBAN",
                      ibanController,
                      icon: Icons.credit_card_rounded,
                      hint: "Enter your IBAN number",
                    ),
                    const SizedBox(height: 25),
                    
                
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF8A005D).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFF8A005D),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Please ensure all bank details are correct. "
                              "Withdrawals may take 1-3 business days to process.",
                              style: TextStyle(
                                color: const Color(0xFF1F0F46).withOpacity(0.7),
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 35),
                    
          
                    _buildEnhancedWithdrawButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTextField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8F9FF),
            hintText: hint ?? "Enter $label",
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: icon != null
                ? Icon(icon, color: const Color(0xFF8A005D))
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: Color(0xFF8A005D),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedWithdrawButton() {
    return GestureDetector(
      onTapDown: (_) => setState(() => isWithdrawPressed = true),
      onTapUp: (_) {
        setState(() => isWithdrawPressed = false);
        saveWithdrawal();
      },
      onTapCancel: () => setState(() => isWithdrawPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: isWithdrawPressed
            ? Matrix4.translationValues(0, 4, 0)
            : Matrix4.identity(),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF1F0F46),
              Color(0xFF8A005D),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8A005D).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
            if (isWithdrawPressed)
              BoxShadow(
                color: const Color(0xFF8A005D).withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_circle_down_rounded,
              color: Colors.white,
              size: 26,
            ),
            SizedBox(width: 12),
            Text(
              "PROCEED TO WITHDRAW",
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


