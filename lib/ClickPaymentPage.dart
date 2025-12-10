import 'package:flutter/material.dart';
import 'payment_success_page.dart';
import 'payment_failed_page.dart';

class ClickPaymentPage extends StatefulWidget {
  final double amount;

  const ClickPaymentPage({super.key, required this.amount});

  @override
  State<ClickPaymentPage> createState() => _ClickPaymentPageState();
}

class _ClickPaymentPageState extends State<ClickPaymentPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController nicknameController = TextEditingController();
  
  bool isProcessing = false;
  bool showOTPField = false;
  bool isValidPhoneFormat = false;
  String? userFullName;
  int? otpCode;
  int remainingOTPSeconds = 120;
  String? phoneValidationError;

  @override
  void initState() {
    super.initState();
    phoneController.addListener(_validateAndSearchUser);
  }

  @override
  void dispose() {
    phoneController.removeListener(_validateAndSearchUser);
    super.dispose();
  }

  void _validateAndSearchUser() {
    final phone = phoneController.text;
    
    if (phone.isEmpty) {
      setState(() {
        isValidPhoneFormat = false;
        phoneValidationError = null;
        userFullName = null;
      });
      return;
    }

    if (!RegExp(r'^[0-9]{0,10}$').hasMatch(phone)) {
      setState(() {
        isValidPhoneFormat = false;
        phoneValidationError = 'Must contain numbers only';
        userFullName = null;
      });
      return;
    }

    if (phone.length == 10) {
      final firstDigit = phone[0];
      final secondDigit = phone[1];
      final thirdDigit = phone[2];
      
      bool isValid = true;
      String? errorMessage;

      if (firstDigit != '0') {
        isValid = false;
        errorMessage = 'Must start with 0';
      }
      else if (secondDigit != '7') {
        isValid = false;
        errorMessage = 'Second digit must be 7';
      }
      else if (!['7', '8', '9'].contains(thirdDigit)) {
        isValid = false;
        errorMessage = 'Third digit must be 7, 8 or 9';
      }

      setState(() {
        isValidPhoneFormat = isValid;
        phoneValidationError = errorMessage;
      });

      if (isValid) {
        _searchUserByPhone(phone);
      } else {
        setState(() {
          userFullName = null;
        });
      }
    } else {
      setState(() {
        isValidPhoneFormat = false;
        phoneValidationError = phone.length > 10 
            ? 'Must be 10 digits only' 
            : null;
        userFullName = null;
      });
    }
  }

  Future<void> _searchUserByPhone(String phone) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final userDatabase = {
        '0771234567': {'name': 'Ali Hassan', 'nickname': 'Ali'},
        '0771111111': {'name': 'Mohammed Ahmed', 'nickname': 'Mohammed'},
        '0782222222': {'name': 'Sarah Khalid', 'nickname': 'Sarah'},
        '0793333333': {'name': 'Ahmed Ali', 'nickname': 'Ahmed'},
        '0774444444': {'name': 'Fatima Mohammed', 'nickname': 'Fatima'},
      };
      
      final userData = userDatabase[phone];
      
      if (mounted) {
        setState(() {
          userFullName = userData?['name'];
          nicknameController.text = userData?['nickname'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userFullName = null;
        });
      }
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    if (!RegExp(r'^[a-zA-Z\u0600-\u06FF\s]+$').hasMatch(value)) {
      return 'Name must contain letters only';
    }
    
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (value.length > 50) {
      return 'Name is too long';
    }
    
    return null;
  }

  Future<void> _sendOTP() async {
    if (!isValidPhoneFormat) return;
    
    setState(() {
      isProcessing = true;
      otpCode = null;
      showOTPField = false;
      otpController.clear();
    });
    
    await Future.delayed(const Duration(seconds: 2));
    
    final random = DateTime.now().millisecondsSinceEpoch;
    final generatedOTP = (random % 9000 + 1000).toInt();
    
    if (mounted) {
      setState(() {
        isProcessing = false;
        otpCode = generatedOTP;
        showOTPField = true;
        remainingOTPSeconds = 120;
      });
    }
    
    _startOTPTimer();
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('OTP Sent'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Verification code has been sent to your phone'),
              const SizedBox(height: 10),
              Text(
                'OTP: $generatedOTP',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 10),
              const Text('(For demo purposes only)'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _startOTPTimer() {
    const oneSec = Duration(seconds: 1);
    
    void updateTimer() {
      if (mounted) {
        setState(() {
          if (remainingOTPSeconds > 0) {
            remainingOTPSeconds--;
          } else {
            otpCode = null;
            showOTPField = false;
          }
        });
      }
    }
    
    Future.delayed(oneSec, () {
      if (remainingOTPSeconds > 0) {
        _startOTPTimer();
      }
      updateTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Click Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8A005D).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payment, color: Colors.white70, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'PAYMENT AMOUNT',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '\$${widget.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_wallet, color: Colors.white70, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Click Digital Wallet',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: Color(0xFF8A005D)),
                          SizedBox(width: 10),
                          Text(
                            'Click Account Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F0F46),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1),

                      const SizedBox(height: 20),
                      const Text(
                        'Phone Number *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF555555),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter phone number';
                                }
                                if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                                  return 'Phone number must be 10 digits';
                                }
                                if (value[0] != '0') {
                                  return 'Must start with 0';
                                }
                                if (value[1] != '7') {
                                  return 'Second digit must be 7';
                                }
                                if (!['7', '8', '9'].contains(value[2])) {
                                  return 'Third digit must be 7, 8 or 9';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: '77 123 4567',
                                prefixIcon: const Icon(
                                  Icons.phone_android,
                                  color: Color(0xFF8A005D),
                                ),
                                prefixText: '+962 ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                counterText: '',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                errorText: phoneValidationError,
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: isValidPhoneFormat && !isProcessing
                                  ? const LinearGradient(
                                      colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : LinearGradient(
                                      colors: [Colors.grey[300]!, Colors.grey[400]!],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isValidPhoneFormat && !isProcessing
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF8A005D).withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: isValidPhoneFormat && !isProcessing
                                    ? _sendOTP
                                    : null,
                                child: Center(
                                  child: isProcessing
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.send_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (userFullName != null) ...[
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_user, color: Colors.green, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Account Found:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                      ),
                                    ),
                                    Text(
                                      userFullName!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F0F46),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      const Text(
                        'Nickname (Optional)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF555555),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nicknameController,
                        validator: _validateName,
                        decoration: InputDecoration(
                          hintText: 'Enter your Click nickname',
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: Color(0xFF8A005D),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Text(
                        'Click PIN Code *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF555555),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: pinController,
                        obscureText: true,
                        maxLength: 4,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter PIN code';
                          }
                          if (!RegExp(r'^[0-9]{4}$').hasMatch(value)) {
                            return 'PIN must be 4 digits';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter 4-digit PIN',
                          prefixIcon: const Icon(
                            Icons.lock,
                            color: Color(0xFF8A005D),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 8,
                        ),
                      ),

                      if (showOTPField) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'OTP Verification *',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF555555),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: otpController,
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                validator: (value) {
                                  if (!showOTPField) return null;
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter OTP code';
                                  }
                                  if (value != otpCode?.toString()) {
                                    return 'Incorrect OTP code';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: 'Enter 4-digit OTP',
                                  prefixIcon: const Icon(
                                    Icons.sms,
                                    color: Color(0xFF8A005D),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  counterText: '',
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              children: [
                                Text(
                                  '${remainingOTPSeconds ~/ 60}:${(remainingOTPSeconds % 60).toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: remainingOTPSeconds > 30 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextButton(
                                  onPressed: remainingOTPSeconds <= 60 ? _sendOTP : null,
                                  style: TextButton.styleFrom(
                                    foregroundColor: remainingOTPSeconds <= 60
                                        ? const Color(0xFF8A005D)
                                        : Colors.grey[400],
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  child: const Text('Resend'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.phone_iphone,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 15),
                        const Expanded(
                          child: Text(
                            'How to Pay with Click',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F0F46),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildInstructionStep(1, 'Open Click app on your phone'),
                    _buildInstructionStep(2, 'Go to "Send Money" section'),
                    _buildInstructionStep(3, 'Enter recipient phone number'),
                    _buildInstructionStep(4, 'Enter the payment amount'),
                    _buildInstructionStep(5, 'Add reference (optional)'),
                    _buildInstructionStep(6, 'Confirm and complete payment'),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Details',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F0F46),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildPaymentDetail('Amount', '\$${widget.amount.toStringAsFixed(2)}'),
                    _buildPaymentDetail('Service', 'Click Wallet Transfer'),
                    _buildPaymentDetail('Processing Time', 'Instant'),
                    _buildPaymentDetail('Transaction Fee', 'Free'),
                    _buildPaymentDetail('Status', 'Pending Verification'),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Security Notes',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F0F46),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildSecurityNote('OTP is sent to your registered phone number'),
                    _buildSecurityNote('PIN code is required for all Click transactions'),
                    _buildSecurityNote('Never share your PIN or OTP with anyone'),
                    _buildSecurityNote('Transactions are secured with 256-bit encryption'),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: (showOTPField && otpController.text.isNotEmpty && !isProcessing)
                        ? const LinearGradient(
                            colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [Colors.grey[400]!, Colors.grey[500]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: (showOTPField && otpController.text.isNotEmpty && !isProcessing)
                        ? [
                            BoxShadow(
                              color: const Color(0xFF8A005D).withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: isProcessing ? null : _processPayment,
                      child: Center(
                        child: isProcessing
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send, color: Colors.white, size: 22),
                                  SizedBox(width: 10),
                                  Text(
                                    'Send via Click',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.security, size: 18, color: Colors.green),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your payment is 100% secure',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'By continuing, you agree to Click Terms of Service and Privacy Policy',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
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

  Widget _buildPaymentDetail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: title == 'Status' ? Colors.orange : const Color(0xFF1F0F46),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNote(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user,
            color: Colors.blue[600],
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (showOTPField && otpController.text != otpCode?.toString()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid OTP code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isProcessing = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isProcessing = false;
    });

    final isSuccess = DateTime.now().millisecond % 10 < 9;
    
    if (isSuccess) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentSuccessPage(amount: widget.amount),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PaymentFailedPage(),
        ),
      );
    }
  }
}
