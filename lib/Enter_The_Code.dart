import 'package:flutter/material.dart';
import 'app_locale.dart';

class EnterTheCode extends StatefulWidget {
  const EnterTheCode({super.key});

  @override
  State<EnterTheCode> createState() => _EnterTheCodeState();
}

class _EnterTheCodeState extends State<EnterTheCode> {
  List<String> code = ["", "", "", ""];
  String mockServerCode = "1234"; 
 
  Future<bool> mockVerifyCode(String input) async {
    await Future.delayed(const Duration(seconds: 1)); 

    return input == mockServerCode;
  }

 
  void _resendCode() {
    setState(() {
      mockServerCode = "4321";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("A new code has been sent: $mockServerCode")),
    );
  }

  void _addDigit(String digit) {
    for (int i = 0; i < code.length; i++) {
      if (code[i].isEmpty) {
        setState(() {
          code[i] = digit;
        });
        break;
      }
    }
  }

  void _removeDigit() {
    for (int i = code.length - 1; i >= 0; i--) {
      if (code[i].isNotEmpty) {
        setState(() {
          code[i] = "";
        });
        break;
      }
    }
  }

 
  void _verifyCode() async {
    final enteredCode = code.join();

    if (enteredCode.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocale.t('enter_4_digits'))),
      );
      return;
    }

    bool ok = await mockVerifyCode(enteredCode);

    if (ok) {
      Navigator.pushReplacementNamed(context, '/category');
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(" Wrong code! Try again.")),
      );
      setState(() {
        code = ["", "", "", ""];
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
                              code[index].isEmpty ? "-" : code[index],
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
