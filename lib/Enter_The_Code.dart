import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/app_locale.dart';
import '../logic/code_logic.dart';


import 'security/route_guard.dart';
import 'security/error_handler.dart';

class EnterTheCode extends StatefulWidget {
  final String? userId;
  
  const EnterTheCode({super.key, this.userId});

  @override
  State<EnterTheCode> createState() => _EnterTheCodeState();
}

class _EnterTheCodeState extends State<EnterTheCode>  with TickerProviderStateMixin {
  
  late CodeLogic codeLogic;
  bool _isVerifying = false;
  bool _securityInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _initializeSecurity();
  }

  Future<void> _initializeSecurity() async {
    try {
      // Security: Prevent screenshots on this sensitive screen
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );

      // Security: Initialize CodeLogic with user ID
      codeLogic = CodeLogic(userId: widget.userId);
      
      setState(() {
        _securityInitialized = true;
      });

      _logSecurityEvent('EnterTheCode page initialized');

    } catch (error) {
      ErrorHandler.logError('EnterTheCode Initialization', error);
      // Fallback to basic initialization
      codeLogic = CodeLogic();
      setState(() {
        _securityInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    // Security: Restore system UI mode
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    
    // Security: Dispose CodeLogic
    codeLogic.dispose();
    
    _logSecurityEvent('EnterTheCode page disposed');
    
    super.dispose();
  }

  void _addDigit(String digit) {
    if (!_securityInitialized) return;
    
    final success = codeLogic.addDigit(digit);
    if (success) {
      setState(() {});
      
      // Security: Auto-verify when code is complete
      if (codeLogic.isCodeComplete()) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _verifyCode();
        });
      }
    }
  }

  void _removeDigit() {
    if (!_securityInitialized) return;
    
    setState(() {
      codeLogic.removeDigit();
    });
  }

  void _resendCode() {
    if (!_securityInitialized) return;
    
    // Security: Check if locked before resending
    if (codeLogic.isLocked) {
      final remaining = _getRemainingLockoutTime();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Too many attempts. Please try again in $remaining."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      codeLogic.resendCode();
    });

    // Security: Show secure message (don't show actual code)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("A new verification code has been sent."),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
    
    _logSecurityEvent('Code resend requested');
  }

  String _getRemainingLockoutTime() {
    final lockoutUntil = codeLogic.lockoutUntil;
    if (lockoutUntil == null) return "a moment";
    
    final remaining = lockoutUntil.difference(DateTime.now());
    if (remaining <= Duration.zero) return "a moment";
    
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    
    if (minutes > 0) {
      return "$minutes minute${minutes > 1 ? 's' : ''}";
    } else {
      return "$seconds second${seconds > 1 ? 's' : ''}";
    }
  }

  Future<void> _verifyCode() async {
    if (!_securityInitialized || _isVerifying) return;
    
    // Security: Check if locked
    if (codeLogic.isLocked) {
      final remaining = _getRemainingLockoutTime();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Too many attempts. Please try again in $remaining."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final validationError = codeLogic.validateCode();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    final enteredCode = codeLogic.getEnteredCode();
    
    // Security: Log verification attempt
    _logSecurityEvent('Verification attempt started');
    
    bool ok = await codeLogic.verifyCode(enteredCode);

    setState(() {
      _isVerifying = false;
    });

    if (ok) {
      // Security: Successful verification
      _logSecurityEvent('Code verification successful');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Verification successful!"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Security: Navigate securely
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pushReplacementNamed(context, '/category');
      
    } else {
      // Security: Failed verification
      final remainingAttempts = codeLogic.getRemainingAttempts();
      
      if (codeLogic.isLocked) {
        final remaining = _getRemainingLockoutTime();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Too many attempts. Account locked for $remaining."),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Invalid code. $remainingAttempts attempts remaining."),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      // Security: Clear code and shake animation
      _clearCodeWithAnimation();
    }
  }

  void _clearCodeWithAnimation() {
    // Visual feedback for wrong code
    final controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    final animation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.1, 0),
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );
    
    controller
      ..forward()
      ..reverse().whenComplete(() {
        controller.dispose();
        setState(() {
          codeLogic.clearCode();
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    if (!_securityInitialized) {
      return _buildSecurityLoadingScreen();
    }

    return ValueListenableBuilder<Locale>(
      valueListenable: AppLocale.locale,
      builder: (context, locale, child) {
        return Scaffold(
          backgroundColor: Colors.grey[200],
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Security badge
                      if (_securityInitialized)
                        _securityBadge(),
                      
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: Icon(Icons.close, color: Colors.grey[600]),
                          onPressed: () {
                            _logSecurityEvent('Page closed manually');
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      Container(
                        width: double.infinity,
                        child: Text(
                          AppLocale.t('enter_the_code') ?? 'Enter Verification Code',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Security message
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Enter the 4-digit code sent to your device",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      
                      _codeDisplay(),
                      const SizedBox(height: 20),

                      // Attempts counter
                      if (codeLogic.getRemainingAttempts() < 5)
                        Container(
                          width: double.infinity,
                          child: Text(
                            "${codeLogic.getRemainingAttempts()} attempts remaining",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      TextButton(
                        onPressed: _isVerifying ? null : _resendCode,
                        child: Text(
                          AppLocale.t('resend_code') ?? 'Resend Code',
                          style: TextStyle(
                            fontSize: 14,
                            color: _isVerifying ? Colors.grey : Colors.grey[600],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: _isVerifying ? null : _verifyCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8A005D),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 2,
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                AppLocale.t('verify') ?? 'Verify',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                      ),

                      const SizedBox(height: 30),

                      _numericKeypad(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecurityLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              child: const Text(
                "Initializing secure verification...",
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _securityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.security, color: Colors.green, size: 14),
          const SizedBox(width: 6),
          Text(
            "Secure Verification",
            style: TextStyle(
              fontSize: 12,
              color: Colors.green[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _codeDisplay() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            4,
            (index) => Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: codeLogic.code[index].isNotEmpty 
                      ? const Color(0xFF8A005D) 
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Text(
                codeLogic.code[index].isEmpty ? "•" : codeLogic.code[index],
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: codeLogic.code[index].isNotEmpty 
                      ? const Color(0xFF8A005D)
                      : Colors.grey[600],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          child: Text(
            codeLogic.isLocked 
                ? "Account locked. Please try again later."
                : "Enter each digit carefully",
            style: TextStyle(
              fontSize: 12,
              color: codeLogic.isLocked ? Colors.red : Colors.grey[600],
              fontWeight: codeLogic.isLocked ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _numericKeypad() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          if (index == 9) return const SizedBox();

          if (index == 11) {
            return ElevatedButton(
              onPressed: _isVerifying ? null : _removeDigit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 1,
              ),
              child: const Icon(Icons.backspace, size: 24),
            );
          }

          final digit = (index == 10 ? 0 : index + 1).toString();

          return ElevatedButton(
            onPressed: _isVerifying ? null : () => _addDigit(digit),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
            ),
            child: Text(
              digit,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }

  void _logSecurityEvent(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final userId = widget.userId ?? 'unknown';
    
    final logMessage = 'EnterTheCode[$timestamp][$userId]: $message';
    
    
    print(' VERIFICATION SECURITY: $logMessage');
  }
}
