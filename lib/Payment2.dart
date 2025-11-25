import 'package:flutter/material.dart';
import 'withdraw_page.dart';

class CardPaymentPage extends StatefulWidget {
  const CardPaymentPage({super.key});

  @override
  State<CardPaymentPage> createState() => _CardPaymentPageState();
}

class _CardPaymentPageState extends State<CardPaymentPage> {
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();
  final TextEditingController holderController = TextEditingController();

  bool isLoading = false;

  Future<bool> backendPaymentCheck() async {
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }

  Future<void> saveCardPayment() async {
    String cardNumber = cardNumberController.text.trim();
    String expiry = expiryController.text.trim();
    String cvv = cvvController.text.trim();
    String holder = holderController.text.trim();

    if (cardNumber.isEmpty ||
        expiry.isEmpty ||
        cvv.isEmpty ||
        holder.isEmpty) {
      return showError("Please fill in all required fields");
    }

    if (cardNumber.length != 16 || !RegExp(r'^[0-9]{16}$').hasMatch(cardNumber)) {
      return showError("Card number must be 16 digits");
    }

    if (!RegExp(r'^(0[1-9]|1[0-2])\/[0-9]{2}$').hasMatch(expiry)) {
      return showError("Expiry date format must be MM/YY");
    }

    if (cvv.length != 3 || !RegExp(r'^[0-9]{3}$').hasMatch(cvv)) {
      return showError("CVV must be 3 digits");
    }

    if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(holder)) {
      return showError("Card holder name must contain letters only");
    }

    setState(() => isLoading = true);
    bool isValid = await backendPaymentCheck();
    setState(() => isLoading = false);

    if (!isValid) {
      return showError("Payment failed. Please check your card details.");
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment processed successfully")),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WithdrawPage()),
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
      body: Stack(
        children: [
          buildMainUI(),
          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildMainUI() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.diamond, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      "Rently",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 30),
            cardPreview(),
            const SizedBox(height: 25),
            buildInputField("Card Number *",
                controller: cardNumberController,
                hint: "XXXX XXXX XXXX XXXX",
                icon: Icons.credit_card),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: buildInputField("Expiry Date *",
                      controller: expiryController, hint: "MM/YY"),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: buildInputField("CVV *",
                      controller: cvvController, hint: "XXX"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            buildInputField("Card Holder Name *",
                controller: holderController,
                hint: "Card Holder First & Last Name"),
            const SizedBox(height: 30),
            payButton(),
            const Spacer(),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.credit_card, color: Colors.orange, size: 40),
                SizedBox(width: 20),
                Icon(Icons.credit_card, color: Colors.blue, size: 40),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget cardPreview() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("CARD NUMBER",
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          Text(
            cardNumberController.text.isEmpty
                ? "XXXX XXXX XXXX XXXX"
                : cardNumberController.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("CARD HOLDER",
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                    holderController.text.isEmpty
                        ? "Your Name"
                        : holderController.text,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("EXPIRY",
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                    expiryController.text.isEmpty
                        ? "MM/YY"
                        : expiryController.text,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget payButton() {
    return GestureDetector(
      onTap: saveCardPayment,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
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
          "Pay",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget buildInputField(String label,
      {String? hint, IconData? icon, TextEditingController? controller}) {
    return TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: label,
        hintText: hint,
        suffixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}




