import 'package:flutter/material.dart';

class EfawateercomInvoicePage extends StatelessWidget {
  final double amount;
  final String referenceNumber;

  const EfawateercomInvoicePage({
    super.key,
    required this.amount,
    required this.referenceNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pay via eFawateercom"),
        backgroundColor: const Color(0xFF1F0F46),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet,
                size: 60, color: Color(0xFF8A005D)),
            const SizedBox(height: 20),

            Text(
              "Payment Amount",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),

            Text(
              "$amount JOD",
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F0F46),
              ),
            ),

            const SizedBox(height: 25),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  const Text(
                    "Invoice / Reference Number",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    referenceNumber,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8A005D),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "How to Pay:",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F0F46),
                ),
              ),
            ),

            const SizedBox(height: 12),

            _step("Open any eFawateercom enabled wallet / app"),
            _step("Go to 'Pay Bills' or 'eFawateercom Services'"),
            _step("Choose our company name"),
            _step("Enter the Reference Number above"),
            _step("Confirm payment"),

            const Spacer(),

            const Text(
              "Once payment is completed, your wallet will be automatically updated.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F0F46),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Done",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF8A005D), size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
