import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentSharingPage extends StatefulWidget {
  @override

  _PaymentSharingPageState createState() => _PaymentSharingPageState();
}

class _PaymentSharingPageState extends State<PaymentSharingPage> {
  
  static const  Color primaryColor = Color(0xFF1F0F46); 
  static const  Color secondaryColor = Color(0xFF8A005D); 
  static const  Color lightBgColor = Color(0xFFF8F3FF);
  static const Color darkTextColor = Color(0xFF2D1B5A);
  
  String paymentCode = '10000011660'; 
  double balance = 500.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentCode();
  }

  Future<void> _loadPaymentCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
    
      int lastUserNumber = prefs.getInt('lastUserNumber') ?? 100000;
      

      int newUserNumber = lastUserNumber + 1;
      
    
      await prefs.setInt('lastUserNumber', newUserNumber);
      
      await prefs.setInt('currentUserNumber', newUserNumber);
      
      setState(() {
        paymentCode = newUserNumber.toString();
        isLoading = false;
      });
      
    } catch (e) {
      print('Error loading payment code: $e');
      setState(() {
        paymentCode = '100001';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Receive Payment',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: lightBgColor,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
               const SizedBox(height: 40),
                
          
                Container(
                  padding:const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.fingerprint, size: 60, color: primaryColor),
                      SizedBox(height: 20),
                      const Text(
                        'Your Unique Payment Number',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: darkTextColor,
                        ),
                      ),
                      SizedBox(height: 15),
                      
                  
                      isLoading
                          ? CircularProgressIndicator(color: primaryColor)
                          : Container(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                 const Icon(Icons.lock, color: Colors.white, size: 22),
                                 const SizedBox(width: 10),
                                  Text(
                                    paymentCode,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                      color: Colors.white,
                                    ),
                                  ),
                                 const SizedBox(width: 10),
                                const  Icon(Icons.verified, color: Color(0xFF4CAF50), size: 22),
                                ],
                              ),
                            ),
                     const SizedBox(height: 15),
                      Text(
                        'This number is unique to your account',
                        style: TextStyle(
                          fontSize: 14,
                          color: darkTextColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
               const SizedBox(height: 30),
                
            
                Container(
                  padding:const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor.withOpacity(0.1), secondaryColor.withOpacity(0.1)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding:const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: secondaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.account_balance_wallet, color: secondaryColor, size: 22),
                      ),
                    const  SizedBox(width: 12),
                      Text(
                        'Balance: ',
                        style: TextStyle(fontSize: 16, color: darkTextColor),
                      ),
                      Text(
                        '\$${balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
               const SizedBox(height: 40),
                
    
                Container(
                  padding:const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.08),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.security, color: primaryColor, size: 24),
                         SizedBox(width: 10),
                          Text(
                            'Secure Payment Number',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: darkTextColor,
                            ),
                          ),
                        ],
                      ),
                     const SizedBox(height: 15),
                      _buildFeature('Unique number for each user'),
                      _buildFeature('No sharing needed'),
                      _buildFeature('Automatically generated'),
                      _buildFeature('Easy to remember'),
                    ],
                  ),
                ),
                
               const SizedBox(height: 30),
                
          
                Container(
                  padding:const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, color: secondaryColor, size: 18),
                         SizedBox(width: 6),
                          Text(
                            'How to use your payment number:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: darkTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildInstruction('1. Give this number to anyone who wants to pay you'),
                      _buildInstruction('2. Enter it in any payment app/service'),
                      _buildInstruction('3. Receiver uses this number to send you money'),
                      _buildInstruction('4. Every user gets a unique increasing number'),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                
               
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: secondaryColor, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: darkTextColor.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 14, color: secondaryColor)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: darkTextColor.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
