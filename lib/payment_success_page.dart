import 'package:flutter/material.dart';
import 'package:p2/Categories_Page.dart';
import 'package:p2/WalletPage.dart';
import 'package:p2/logic/payment_success_logic.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/secure_storage.dart';

class PaymentSuccessPage extends StatefulWidget {
  final double amount;
  final String? returnTo;
  final String transactionId;
  final String referenceNumber;

  const PaymentSuccessPage({
    super.key,
    required this.amount,
    this.returnTo = 'wallet',
    required this.transactionId,
    required this.referenceNumber,
  });

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  late PaymentSuccessLogic _logic;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    try {
      _logic = PaymentSuccessLogic(
        amount: widget.amount,
        returnTo: widget.returnTo,
        transactionId: widget.transactionId,
        referenceNumber: widget.referenceNumber,
      );
      _logic.setImmersiveMode();

      final successData = {
        'timestamp': DateTime.now().toIso8601String(),
        'transactionId': widget.transactionId,
        'referenceNumber': widget.referenceNumber,
        'amount': widget.amount.toStringAsFixed(2),
      };

      await SecureStorage.saveData(
        'payment_success_${widget.transactionId}',
        ErrorHandler.safeJsonEncode(successData),
      );

    } catch (error) {
      _errorMessage = 'Payment processed successfully';
      print('✅ Payment Success: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return _buildMainContent();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.green[400],
            ),
            const SizedBox(height: 20),
            const Text(
              'Processing...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Payment Successful',
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
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 60,
                      color: Colors.green,
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  
                  Text(
                    'JD${widget.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F0F46),
                    ),
                  ),
                  
                  const SizedBox(height: 8),

                
                  const Text(
                    'Payment Successful',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                  
                  const SizedBox(height: 8),

                  
                  const Text(
                    'has been added to your wallet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 30),

                 
                  Container(
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
                        _buildDetailRow('Transaction ID', _formatTransactionId(widget.transactionId)),
                        _buildDetailRow('Reference', _formatReference(widget.referenceNumber)),
                        _buildDetailRow('Date', _getFormattedDate()),
                        _buildDetailRow('Time', _getFormattedTime()),
                        _buildDetailRow('Status', 'Completed', isSuccess: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notes:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildNoteItem('Funds are available immediately'),
                        _buildNoteItem('Receipt saved for reference'),
                        _buildNoteItem('Contact support if needed'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 80),
                ],
              ),
            ),
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
                        "View Wallet",
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

              
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => _showReceiptOptions(context),
                child: const Text(
                  'View Receipt',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isSuccess = false}) {
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
                color: isSuccess ? Colors.green : const Color(0xFF1F0F46),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteItem(String text) {
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

  String _formatTransactionId(String id) {
    if (id.length <= 15) return id;
    return '${id.substring(0, 8)}...${id.substring(id.length - 6)}';
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

  void _goToWallet(BuildContext context) {
    try {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WalletHomePage()),
      );
    } catch (e) {
      print('🔥 Error going to wallet: $e');
      _showMessage(context, 'Cannot open wallet');
    }
  }

  void _showReceiptOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Receipt Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F0F46),
                ),
              ),
              const SizedBox(height: 15),
              _buildReceiptOption(
                context,
                icon: Icons.picture_as_pdf,
                title: 'Download PDF',
              ),
              _buildReceiptOption(
                context,
                icon: Icons.share,
                title: 'Share Receipt',
              ),
              _buildReceiptOption(
                context,
                icon: Icons.email,
                title: 'Email Receipt',
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceiptOption(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      onTap: () {
        Navigator.pop(context);
        _showMessage(context, '$title requested');
      },
    );
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
