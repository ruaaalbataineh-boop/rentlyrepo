import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:p2/Categories_Page.dart';
import 'package:p2/CreditCardPaymentPage.dart';

class PaymentFailedPage extends StatelessWidget {
  final String returnTo;

  const PaymentFailedPage({
    super.key,
    this.returnTo = 'payment',
  });

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Payment Failed',
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
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Payment Failed',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'We couldn\'t process your payment',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Possible Reasons:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F0F46),
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      _buildReason('Insufficient funds in your account'),
                      _buildReason('Incorrect card details'),
                      _buildReason('Network connection issues'),
                      _buildReason('Card expired or blocked'),
                      _buildReason('Daily transaction limit exceeded'),
                      const SizedBox(height: 10),
                      const Divider(color: Colors.grey, height: 1),
                      const SizedBox(height: 10),
                      _buildTip('Check your card balance'),
                      _buildTip('Verify card details are correct'),
                      _buildTip('Try a different payment method'),
                      _buildTip('Contact your bank if issues persist'),
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
                onPressed: () => _handleTryAgain(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Try Payment Again',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 15),
            
            
            TextButton(
              onPressed: () => _contactSupport(context),
              child: const Text(
                'Contact Support',
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

  Widget _buildReason(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: Colors.red[600],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: Colors.amber[700],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTryAgain(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    
    if (returnTo == 'payment') {
  
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const CreditCardPaymentPage(amount: 0.0),
        ),
      );
    
    } else {
      Navigator.pop(context);
    }
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

  void _contactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'For payment issues, contact our support team:\n',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              _buildContactInfo(Icons.phone, 'Phone:', '1-800-123-4567'),
              _buildContactInfo(Icons.email, 'Email:', 'support@rently.com'),
              _buildContactInfo(Icons.chat, 'Live Chat:', 'Available in app'),
              _buildContactInfo(Icons.access_time, 'Hours:', '24/7'),
              const SizedBox(height: 20),
              const Text(
                'We\'re here to help you!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar(context, 'Opening contact options...');
            },
            child: const Text('Contact Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        backgroundColor: Colors.red,
        showCloseIcon: true,
        closeIconColor: Colors.white,
      ),
    );
  }
}
