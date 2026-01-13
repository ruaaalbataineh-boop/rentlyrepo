import 'package:flutter/material.dart';
import 'package:p2/Categories_Page.dart';
import 'package:p2/WalletRechargePage.dart';
import 'package:p2/logic/payment_failed_logic.dart';
import 'package:p2/security/route_guard.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/secure_storage.dart';
import 'package:p2/security/validation_exception.dart';

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
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _isDataValid = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    try {
      // 1. التحقق من المصادقة
      _isAuthenticated = RouteGuard.isAuthenticated();
      
      if (!_isAuthenticated) {
        ErrorHandler.logSecurity('PaymentFailedPage', 'Unauthorized access attempt');
        return;
      }

      // 2. التحقق من صحة البيانات المدخلة
      _isDataValid = await _validateInputData();
      
      if (!_isDataValid) {
        ErrorHandler.logSecurity('PaymentFailedPage', 'Invalid input data');
        _errorMessage = 'Invalid payment data';
        return;
      }

      // 3. تهيئة المنطق مع معالجة الأخطاء
      try {
        _logic = PaymentFailedLogic(returnTo: widget.returnTo);
      } on PaymentValidationException catch (e) {
        _errorMessage = 'Validation error: ${e.message}';
        ErrorHandler.logError('PaymentFailedLogic Initialization', e);
        return;
      } catch (e) {
        _errorMessage = 'Failed to initialize payment logic';
        ErrorHandler.logError('PaymentFailedLogic Initialization', e);
        return;
      }

      _logic.setImmersiveMode();

      // 4. تسجيل حدث الفشل في التخزين الآمن
      await _logPaymentFailure();

    } catch (error) {
      _errorMessage = ErrorHandler.getSafeError(error);
      ErrorHandler.logError('Initialize PaymentFailedPage', error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _validateInputData() async {
    try {
      // التحقق من البيانات المطلوبة
      if (widget.referenceNumber.isEmpty || widget.clientSecret.isEmpty) {
        return false;
      }

      // التحقق من صيغة referenceNumber
      final refRegex = RegExp(r'^[A-Za-z0-9\-_]{8,50}$');
      if (!refRegex.hasMatch(widget.referenceNumber)) {
        ErrorHandler.logSecurity('PaymentFailedPage', 'Invalid reference number format');
        return false;
      }

      // التحقق من صيغة clientSecret (SHA256 hash like)
      final secretRegex = RegExp(r'^[A-Za-z0-9]{64}$');
      if (!secretRegex.hasMatch(widget.clientSecret)) {
        ErrorHandler.logSecurity('PaymentFailedPage', 'Invalid client secret format');
        return false;
      }

      // التحقق من قيمة المبلغ
      if (widget.amount <= 0 || widget.amount > 100000) {
        ErrorHandler.logSecurity('PaymentFailedPage', 'Invalid amount value');
        return false;
      }

      // التحقق من قيمة returnTo
      final validReturnTo = ['payment', 'wallet', 'checkout', 'subscription'];
      if (!validReturnTo.contains(widget.returnTo)) {
        ErrorHandler.logSecurity('PaymentFailedPage', 'Invalid returnTo value');
        return false;
      }

      return true;
    } catch (e) {
      ErrorHandler.logError('Validate Input Data', e);
      return false;
    }
  }

  Future<void> _logPaymentFailure() async {
    try {
      final failureData = {
        'timestamp': DateTime.now().toIso8601String(),
        'referenceNumber': widget.referenceNumber,
        'amount': widget.amount.toString(),
        'returnTo': widget.returnTo,
        'validated': _isDataValid,
      };

      // حفظ في التخزين الآمن
      await SecureStorage.saveData(
        'last_payment_failure_${DateTime.now().millisecondsSinceEpoch}',
        ErrorHandler.safeJsonEncode(failureData),
      );

      ErrorHandler.logInfo('PaymentFailedPage', 
          'Payment failure logged: ${widget.referenceNumber}');
    } catch (e) {
      ErrorHandler.logError('Log Payment Failure', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildMainContent(); 
    }

    return _buildMainContent();
  }

  Widget _buildMainContent() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _errorMessage != null ? 'Payment Failed' : _logic.getPageTitle(),
          style: const TextStyle(
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

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline,
                    size: 80, color: Colors.red),
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

              Text(
                _errorMessage != null 
                  ? 'We couldn\'t process your payment'
                  : _logic.getErrorMessage(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.orange, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 30),

              _buildScrollableFailureBox(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => _handleContinueShopping(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F0F46),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag),
                      SizedBox(width: 12),
                      Text("Continue Shopping",
                          style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: () => _handleTryAgain(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    "Try Again",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableFailureBox() {
    return Container(
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
          ...(_errorMessage != null 
            ? [
                'Invalid payment data',
                'Technical validation error',
                'Please contact support',
              ]
            : _logic.getPossibleReasons()
          ).map(_buildReason).toList(),
          const SizedBox(height: 10),
          const Divider(color: Colors.grey),
          const SizedBox(height: 10),
          ...(_errorMessage != null
            ? [
                'Contact customer support',
                'Try again later',
                'Verify your payment details',
              ]
            : _logic.getHelpfulTips()
          ).map(_buildTip).toList(),
        ],
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

  void _handleTryAgain(BuildContext context) async {
    try {
      if (_logic != null) {
        _logic.enableFullSystemUI();
      }

      // تسجيل محاولة إعادة الدفع
      await _logRetryAttempt();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const WalletRechargePage(),
        ),
      );
    } catch (error) {
      ErrorHandler.logError('Handle Try Again', error);
      _showSnackBar(context, ErrorHandler.getSafeError(error));
    }
  }

  Future<void> _logRetryAttempt() async {
    try {
      final retryData = {
        'timestamp': DateTime.now().toIso8601String(),
        'referenceNumber': widget.referenceNumber,
        'action': 'retry_payment',
        'returnTo': widget.returnTo,
      };

      await SecureStorage.saveData(
        'payment_retry_${DateTime.now().millisecondsSinceEpoch}',
        ErrorHandler.safeJsonEncode(retryData),
      );
    } catch (e) {
      ErrorHandler.logError('Log Retry Attempt', e);
    }
  }

  void _handleContinueShopping(BuildContext context) async {
    try {
      if (_logic != null) {
        _logic.enableFullSystemUI();
      }
      
      // تسجيل الخروج من صفحة الفشل
      await _logExitAction();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const CategoryPage()),
        (route) => false,
      );
    } catch (error) {
      ErrorHandler.logError('Handle Continue Shopping', error);
      _showSnackBar(context, ErrorHandler.getSafeError(error));
    }
  }

  Future<void> _logExitAction() async {
    try {
      final exitData = {
        'timestamp': DateTime.now().toIso8601String(),
        'referenceNumber': widget.referenceNumber,
        'action': 'continue_shopping',
        'screen': 'payment_failed',
      };

      await SecureStorage.saveData(
        'payment_failed_exit_${DateTime.now().millisecondsSinceEpoch}',
        ErrorHandler.safeJsonEncode(exitData),
      );
    } catch (e) {
      ErrorHandler.logError('Log Exit Action', e);
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    try {
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
    } catch (e) {
      ErrorHandler.logError('Show SnackBar', e);
    }
  }

  @override
  void dispose() {
    try {
      if (_logic != null) {
        _logic.enableFullSystemUI();
      }
    } catch (e) {
      ErrorHandler.logError('Dispose PaymentFailedPage', e);
    }
    super.dispose();
  }
}
