import 'package:flutter/material.dart';
import 'app_locale.dart';
import '../logic/code_logic.dart';

class EnterTheCode extends StatefulWidget {
  const EnterTheCode({super.key});

  @override
  State<EnterTheCode> createState() => _EnterTheCodeState();
}

class _EnterTheCodeState extends State<EnterTheCode> {
  late CodeLogic codeLogic; 
  
  @override
  void initState() {
    super.initState();
    codeLogic = CodeLogic(); 
  }

  
void _addDigit(String digit) {
 
  final success = codeLogic.addDigit(digit);
  if (success) {
    setState(() {});
  }
}

  void _removeDigit() {
    setState(() {
      codeLogic.removeDigit(); 
    });
  }

  void _resendCode() {
    setState(() {
      codeLogic.resendCode(); 
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("A new code has been sent: ${codeLogic.serverCode}")),
    );
  }

  void _verifyCode() async {
    final validationError = codeLogic.validateCode();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    final enteredCode = codeLogic.getEnteredCode();
    bool ok = await codeLogic.verifyCode(enteredCode);

    if (ok) {
      Navigator.pushReplacementNamed(context, '/category');
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wrong code! Try again.")),
      );
      setState(() {
        codeLogic.clearCode(); 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: Icon(Icons.close, color: Colors.grey[600]),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppLocale.t('enter_the_code'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          4,
                          (index) => Container(
                            width: 55,
                            height: 55,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              codeLogic.code[index].isEmpty ? "-" : codeLogic.code[index], 
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: _resendCode,
                        child: Text(
                          AppLocale.t('resend_code'),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: _verifyCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8A005D),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          AppLocale.t('verify'),
                          style:
                              const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),

                      const SizedBox(height: 30),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
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
                                onPressed: _removeDigit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Icon(Icons.backspace, size: 24),
                              );
                            }

                            final digit =
                                (index == 10 ? 0 : index + 1).toString();

                            return ElevatedButton(
                              onPressed: () => _addDigit(digit),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                      ),
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
}
