import 'package:flutter/material.dart';
import '../logic/credit_card_logic.dart';
import 'payment_success_page.dart';
import 'payment_failed_page.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

class CreditCardPaymentPage extends StatefulWidget {
  final double amount;
  final String referenceNumber;
  final String clientSecret;

  const CreditCardPaymentPage({
    super.key,
    required this.amount,
    required this.referenceNumber,
    required this.clientSecret,
  });

  @override
  State<CreditCardPaymentPage> createState() => _CreditCardPaymentPageState();
}

class _CreditCardPaymentPageState extends State<CreditCardPaymentPage> {
  late CreditCardLogic _logic;

  @override
  void initState() {
    super.initState();
    _logic = CreditCardLogic(amount: widget.amount);
  }

  @override
  void dispose() {
    stripe.Stripe.instance.dangerouslyUpdateCardDetails(
      stripe.CardDetails(
        number: '',
        cvc: '',
        expirationMonth: 0,
        expirationYear: 0,
      ),
    );
    super.dispose();
  }

  void _processPayment() async {
    setState(() => _logic.isProcessing = true);

    try {
      await stripe.Stripe.instance.confirmPayment(
        paymentIntentClientSecret: widget.clientSecret,
        data: stripe.PaymentMethodParams.card(
          paymentMethodData: const stripe.PaymentMethodData(),
        ),
      );

      setState(() => _logic.isProcessing = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessPage(amount: widget.amount),
        ),
      );
    } catch (e, s) {
      print("STRIPE ERROR: $e");
      print(s);

      setState(() => _logic.isProcessing = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentFailedPage(
            amount: widget.amount,
            referenceNumber: widget.referenceNumber,
            clientSecret: widget.clientSecret,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Credit Card Payment"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Enter Card Details",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 12),

                  stripe.CardField(
                    decoration: InputDecoration(
                      hintText: "Card number",
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            //AMOUNT CARD
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Amount to be paid:",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      "JD${widget.amount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            //PAY BUTTON
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8A005D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _logic.isProcessing ? null : _processPayment,
                child: _logic.isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Confirm Payment",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Row(
              children: [
                Icon(Icons.verified_user, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  "Secure Stripe Payment",
                  style: TextStyle(fontSize: 14),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
