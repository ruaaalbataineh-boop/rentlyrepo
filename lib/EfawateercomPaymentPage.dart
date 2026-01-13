import 'package:flutter/material.dart';
import 'package:p2/services/firestore_service.dart';


import 'package:p2/security/route_guard.dart';
import 'package:p2/security/secure_storage.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/efawateercom_security.dart';

class EfawateercomPaymentPage extends StatefulWidget {
  final double amount;
  final String referenceNumber;

  const EfawateercomPaymentPage({
    super.key,
    required this.amount,
    required this.referenceNumber,
  });

  @override
  State<EfawateercomPaymentPage> createState() => _EfawateercomPaymentPageState();
}

class _EfawateercomPaymentPageState extends State<EfawateercomPaymentPage> {
  @override
  void initState() {
    super.initState();
    _initializeSecurity();
  }

  Future<void> _initializeSecurity() async {
    try {
      
      if (!RouteGuard.isAuthenticated()) {
        _redirectToLogin();
        return;
      }

      
      if (!EfawateercomSecurity.isValidAmount(widget.amount)) {
        _handleSecurityError('Invalid payment amount');
        return;
      }

      if (!EfawateercomSecurity.isValidReference(widget.referenceNumber)) {
        _handleSecurityError('Invalid reference number');
        return;
      }

      
      await EfawateercomSecurity.logPageAccess(
        amount: widget.amount,
        reference: widget.referenceNumber,
      );

    } catch (error) {
      ErrorHandler.logError('Efawateercom Page Init', error);
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    });
  }

  void _handleSecurityError(String message) {
    ErrorHandler.logSecurity('Efawateercom Security', message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Pay via eFawateercom",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
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

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              _amountCard(),
              const SizedBox(height: 22),
              _referenceCard(),
              const SizedBox(height: 25),
              _howToPay(),

              const SizedBox(height: 100),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F0F46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    
                    EfawateercomSecurity.logPageExit(
                      amount: widget.amount,
                      reference: widget.referenceNumber,
                    );
                    
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Done",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _amountCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(Icons.account_balance_wallet,
              color: Colors.white, size: 45),
          const SizedBox(height: 10),
          const Text("Payment Amount",
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          Text(
            "${widget.amount.toStringAsFixed(2)}JD",
            style: const TextStyle(
                fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
          )
        ],
      ),
    );
  }

  Widget _referenceCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          const Text(
            "Invoice Reference",
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          SelectableText(
            widget.referenceNumber,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8A005D),
            ),
          ),
          const SizedBox(height: 10),

          const Text(
            "Please screenshot or save this reference number.\n"
                "You will NOT be able to access it again after closing this page.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _howToPay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "How to Pay",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F0F46)),
          ),
        ),
        const SizedBox(height: 12),
        _step("Open eFawateercom"),
        _step("Choose your preferred payment provider"),
        _step("Enter the reference number and amount to be paid"),
        _step("Confirm payment"),
      ],
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
