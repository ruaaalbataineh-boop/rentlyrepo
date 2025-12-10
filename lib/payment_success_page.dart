import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:p2/Categories_Page.dart';
import 'package:p2/WalletPage.dart';



class PaymentSuccessPage extends StatelessWidget {
  final double amount;
  final String? returnTo;

  const PaymentSuccessPage({
    super.key, 
    required this.amount,
    this.returnTo = 'wallet',
  });

  @override
  Widget build(BuildContext context) {
    final transactionId = 'TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Payment Successful',
          style: TextStyle(
            color: Color(0xFF1F0F46),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF1F0F46)),
            onPressed: () => _handleContinueShopping(context),
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 20,
          left: 20,
          right: 20,
          bottom: 0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F0F46),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Payment Successful',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'has been added to your wallet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildSuccessDetail('Transaction ID', transactionId),
                      _buildSuccessDetail('Date', _formatDate()),
                      _buildSuccessDetail('Time', _formatTime()),
                      _buildSuccessDetail('Status', 'Completed', isSuccess: true),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
          
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () => _handleContinueShopping(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F0F46),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag),
                    SizedBox(width: 12),
                    Text(
                      'Continue Shopping',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 15),
            
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton(
                onPressed: () => _handleBackToWallet(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF8A005D)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'View Wallet Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A005D),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 15),
            
            
            TextButton(
              onPressed: () => _showReceiptOptions(context, transactionId),
              child: const Text(
                'View Receipt',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 
                ? MediaQuery.of(context).viewInsets.bottom 
                : 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessDetail(String title, String value, {bool isSuccess = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isSuccess ? Colors.green : const Color(0xFF1F0F46),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  String _formatTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _handleBackToWallet(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    

  
    
   
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WalletHomePage()),
      (route) => false,
    );
    
  }

  void _handleContinueShopping(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    
  
   
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const CategoryPage()),
      (route) => false,
    );
  
  }

  void _showReceiptOptions(BuildContext context, String transactionId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Receipt Options',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildReceiptOption(
                context,
                icon: Icons.picture_as_pdf,
                title: 'Download PDF',
                message: 'PDF receipt downloaded',
              ),
              _buildReceiptOption(
                context,
                icon: Icons.share,
                title: 'Share Receipt',
                message: 'Receipt shared',
              ),
              _buildReceiptOption(
                context,
                icon: Icons.print,
                title: 'Print Receipt',
                message: 'Printing receipt...',
              ),
              _buildReceiptOption(
                context,
                icon: Icons.email,
                title: 'Email Receipt',
                message: 'Receipt sent to your email',
              ),
              const SizedBox(height: 20),
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
    required String message,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        _showSnackBar(context, message);
      },
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: Colors.green,
        showCloseIcon: true,
        closeIconColor: Colors.white,
      ),
    );
  }
}
