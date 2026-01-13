import 'package:flutter/material.dart';
import 'package:p2/Categories_Page.dart';
import 'package:p2/WalletRechargePage.dart';
import 'package:p2/logic/payment_failed_logic.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/secure_storage.dart';

class PaymentFailedPage extends StatefulWidget {
  final String returnTo;
  final double amount;
  final String referenceNumber;
  final String clientSecret;

  const PaymentFailedPage({
    super.key,
    this.returnTo = 'payment',
    required this.amount,
    required this.referenceNumber,
    required this.clientSecret,
  });

  @override
  State<PaymentFailedPage> createState() => _PaymentFailedPageState();
}

class _PaymentFailedPageState extends State<PaymentFailedPage> {
  late PaymentFailedLogic _logic;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    try {
      _logic = PaymentFailedLogic(returnTo: widget.returnTo);
      _logic.setImmersiveMode();

      final failureData = {
        'timestamp': DateTime.now().toIso8601String(),
        'referenceNumber': widget.referenceNumber,
        'amount': widget.amount.toString(),
      };

      await SecureStorage.saveData(
        'payment_failure_${DateTime.now().millisecondsSinceEpoch}',
        ErrorHandler.safeJsonEncode(failureData),
      );

    } catch (error) {
      _errorMessage = 'Payment failed. Please try again.';
      print('🔥 Error in PaymentFailedPage: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Payment Failed',
          style: TextStyle(
            color: Color(0xFF1F0F46),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF1F0F46), size: 22),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.error_outline,
                        size: 60, color: Colors.red),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    _errorMessage != null ? 'Payment Failed' : 'Payment Failed',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    _errorMessage ?? 'We couldn\'t process your payment',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 20),


                  _buildFailureDetailsBox(),
                ],
              ),
            ),


            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Helpful Tips:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F0F46),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTipItem('Check your internet connection'),
                  _buildTipItem('Verify your payment method details'),
                  _buildTipItem('Ensure sufficient balance in your account'),
                  _buildTipItem('Contact your bank if issue persists'),
                  _buildTipItem('Try again in a few minutes'),
                ],
              ),
            ),


            const SizedBox(height: 80),
          ],
        ),
      ),


      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey[300]!, width: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _goToHome(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F0F46),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag, size: 20),
                      SizedBox(width: 10),
                      Text(
                        "Continue Shopping",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),


              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => _tryAgain(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    backgroundColor: Colors.red.withOpacity(0.05),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh, color: Colors.red, size: 18),
                      SizedBox(width: 10),
                      Text(
                        "Try Again",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),


              if (widget.returnTo == 'wallet') ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => _goToWallet(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF8A005D), width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      backgroundColor: const Color(0xFF8A005D).withOpacity(0.05),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet,
                            color: Color(0xFF8A005D), size: 18),
                        SizedBox(width: 10),
                        Text(
                          "Back to Wallet",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8A005D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],


              const SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFailureDetailsBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transaction Details:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F0F46),
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Amount', 'JD${widget.amount.toStringAsFixed(2)}'),
          _buildDetailRow('Reference', _formatReference(widget.referenceNumber)),
          _buildDetailRow('Status', 'Failed', isFailed: true),
          _buildDetailRow('Date', _getFormattedDate()),
          _buildDetailRow('Time', _getFormattedTime()),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isFailed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isFailed ? Colors.red : const Color(0xFF1F0F46),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Colors.green[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    return '$day/$month/$year';
  }

  String _getFormattedTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatReference(String ref) {
    if (ref.length <= 20) return ref;
    return '${ref.substring(0, 10)}...${ref.substring(ref.length - 6)}';
  }


  void _goToHome(BuildContext context) {
    try {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => CategoryPage()),
            (route) => false,
      );
    } catch (e) {
      print('🔥 Error going to home: $e');
      Navigator.pop(context);
    }
  }

  void _tryAgain(BuildContext context) {
    try {
      if (widget.returnTo == 'wallet') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WalletRechargePage()),
        );
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      print('🔥 Error trying again: $e');
      _showMessage(context, 'Please try again');
    }
  }

  void _goToWallet(BuildContext context) {
    try {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WalletRechargePage()),
      );
    } catch (e) {
      print('🔥 Error going to wallet: $e');
      _showMessage(context, 'Cannot open wallet');
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    try {
      _logic.enableFullSystemUI();
    } catch (e) {
      print('🔥 Error in dispose: $e');
    }
    super.dispose();
  }
}
