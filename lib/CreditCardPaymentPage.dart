import 'package:flutter/material.dart';
import 'package:p2/security/CreditCardPaymentSecurity.dart';
import '../logic/credit_card_logic.dart';
import 'package:p2/payment_success_page.dart';
import 'package:p2/payment_failed_page.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;


import 'package:p2/security/route_guard.dart';
import 'package:p2/security/secure_storage.dart';
import 'package:p2/security/error_handler.dart';


class CreditCardPaymentPage extends StatefulWidget {
  final double amount;
  final String referenceNumber;
  final String clientSecret;

   CreditCardPaymentPage({
    super.key,
    required this.amount,
    required this.referenceNumber,
    required this.clientSecret,
  }) {
    
    CreditCardPaymentSecurity.logPaymentPageAccess(amount, referenceNumber);
  }

  @override
  State<CreditCardPaymentPage> createState() => _CreditCardPaymentPageState();
}

class _CreditCardPaymentPageState extends State<CreditCardPaymentPage> {
  late CreditCardLogic _logic;
  bool _securityInitialized = false;
  DateTime _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _logic = CreditCardLogic(amount: widget.amount);
    _initializeSecurity();
  }

  Future<void> _initializeSecurity() async {
    try {
      
      if (!CreditCardPaymentSecurity.isValidAmount(widget.amount)) {
        _handleSecurityError('Invalid amount');
        return;
      }

      if (!CreditCardPaymentSecurity.isValidReference(widget.referenceNumber)) {
        _handleSecurityError('Invalid reference number');
        return;
      }

  
      if (widget.clientSecret.isEmpty || widget.clientSecret.length < 10) {
        _handleSecurityError('Invalid payment session');
        return;
      }

      
      await CreditCardPaymentSecurity.logPaymentSessionStart(
        amount: widget.amount,
        reference: widget.referenceNumber,
      );

      setState(() {
        _securityInitialized = true;
      });

    } catch (error) {
      ErrorHandler.logError('Payment Security Init', error);
      _handleSecurityError('Security initialization failed');
    }
  }

  void _handleSecurityError(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    });
  }

  void _processPayment() async {
    if (!_securityInitialized) return;

    
    await CreditCardPaymentSecurity.logPaymentAttempt(widget.amount);

    setState(() => _logic.isProcessing = true);

    try {
  
      if (!CreditCardPaymentSecurity.isWithinPaymentLimits(widget.amount)) {
        throw Exception('Payment amount exceeds limits');
      }

      
      await stripe.Stripe.instance.confirmPayment(
        paymentIntentClientSecret: widget.clientSecret,
        data: stripe.PaymentMethodParams.card(
          paymentMethodData: const stripe.PaymentMethodData(),
        ),
      );

      setState(() => _logic.isProcessing = false);

      
      final duration = DateTime.now().difference(_startTime);
      await CreditCardPaymentSecurity.logPaymentSuccess(
        amount: widget.amount,
        reference: widget.referenceNumber,
        duration: duration.inMilliseconds,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessPage(
            amount: widget.amount,
            transactionId: CreditCardPaymentSecurity.generateTransactionId(),
            referenceNumber: widget.referenceNumber,
          ),
        ),
      );
      
    } catch (e, s) {
      setState(() => _logic.isProcessing = false);

      
      await CreditCardPaymentSecurity.logPaymentFailure(
        amount: widget.amount,
        reference: widget.referenceNumber,
        error: e.toString(),
      );

      print("STRIPE ERROR: $e");
      print(s);

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
    if (!_securityInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Credit Card Payment"),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
