import 'package:flutter/material.dart';
import 'package:p2/security/route_guard.dart';
import 'package:p2/security/secure_storage.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/logic/payment_failed_logic.dart';
import 'package:p2/logic/payment_success_logic.dart';

/// صفحة اختبار مكونات الأمان
class SecurityTestPage extends StatefulWidget {
  const SecurityTestPage({super.key});

  @override
  State<SecurityTestPage> createState() => _SecurityTestPageState();
}

class _SecurityTestPageState extends State<SecurityTestPage> {
  List<String> testResults = [];
  bool isTesting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Tests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runAllTests,
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () => setState(() => testResults.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          // زر تشغيل جميع الاختبارات
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _runAllTests,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: isTesting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Run All Security Tests'),
            ),
          ),

          // نتائج الاختبارات
          Expanded(
            child: ListView.builder(
              itemCount: testResults.length,
              itemBuilder: (context, index) {
                final result = testResults[index];
                final isError = result.startsWith('❌');
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  color: isError ? Colors.red[50] : Colors.green[50],
                  child: ListTile(
                    leading: Icon(
                      isError ? Icons.error : Icons.check_circle,
                      color: isError ? Colors.red : Colors.green,
                    ),
                    title: Text(
                      result,
                      style: TextStyle(
                        color: isError ? Colors.red[700] : Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addResult(String result) {
    setState(() {
      testResults.add('${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second} - $result');
    });
  }

  Future<void> _runAllTests() async {
    if (isTesting) return;
    
    setState(() {
      isTesting = true;
      testResults.clear();
    });

    _addResult(' Starting security tests...');

    await Future.delayed(const Duration(milliseconds: 500));

    // 1. اختبار RouteGuard
    await _testRouteGuard();

    // 2. اختبار SecureStorage
    await _testSecureStorage();

    // 3. اختبار ErrorHandler
    await _testErrorHandler();

    // 4. اختبار PaymentFailedLogic
    await _testPaymentFailedLogic();

    // 5. اختبار PaymentSuccessLogic
    await _testPaymentSuccessLogic();

    // 6. اختبار ArgumentError مباشر
    await _testDirectArgumentError();

    _addResult(' All tests completed!');
    
    setState(() => isTesting = false);
  }

  Future<void> _testRouteGuard() async {
    try {
      _addResult('1. Testing RouteGuard.isAuthenticated()...');
      final result = RouteGuard.isAuthenticated();
      _addResult(' RouteGuard: $result');
    } catch (e) {
      _addResult(' RouteGuard Error: ${e.toString()}');
      if (e is ArgumentError) {
        _addResult(' ArgumentError detected in RouteGuard!');
      }
    }
  }

  Future<void> _testSecureStorage() async {
    try {
      _addResult('2. Testing SecureStorage.getToken()...');
      final token = await SecureStorage.getToken();
      _addResult(' SecureStorage Token: ${token ?? "null"}');
    } catch (e) {
      _addResult(' SecureStorage Error: ${e.toString()}');
      if (e is ArgumentError) {
        _addResult(' ArgumentError detected in SecureStorage!');
      }
    }
  }

  Future<void> _testErrorHandler() async {
    try {
      _addResult('3. Testing ErrorHandler with ArgumentError...');
      ErrorHandler.logError('Test', ArgumentError('Test ArgumentError'));
      _addResult(' ErrorHandler handled ArgumentError');
    } catch (e) {
      _addResult(' ErrorHandler Error: ${e.toString()}');
      if (e is ArgumentError) {
        _addResult(' ArgumentError NOT handled by ErrorHandler!');
      }
    }
  }

  Future<void> _testPaymentFailedLogic() async {
    try {
      _addResult('4. Testing PaymentFailedLogic constructor...');
      
      // Test 1: قيمة صالحة
      final logic1 = PaymentFailedLogic(returnTo: 'payment');
      _addResult(' PaymentFailedLogic (valid): OK');
      
      // Test 2: قيمة غير صالحة
      try {
        final logic2 = PaymentFailedLogic(returnTo: 'invalid_value');
        _addResult(' PaymentFailedLogic accepted invalid value');
      } catch (e) {
        _addResult(' PaymentFailedLogic rejected invalid value');
        if (e is ArgumentError) {
          _addResult(' PaymentFailedLogic throws ArgumentError!');
        }
      }
    } catch (e) {
      _addResult(' PaymentFailedLogic Error: ${e.toString()}');
    }
  }

  Future<void> _testPaymentSuccessLogic() async {
    try {
      _addResult('5. Testing PaymentSuccessLogic...');
      
      // Test 1: بيانات صالحة
      final logic1 = PaymentSuccessLogic(
        amount: 50.0,
        transactionId: 'TXN1234567890',
        referenceNumber: 'REF12345',
      );
      _addResult(' PaymentSuccessLogic (valid): OK');
      
      // Test 2: بيانات غير صالحة
      try {
        final logic2 = PaymentSuccessLogic(
          amount: -50.0, // قيمة غير صالحة
          transactionId: 'INVALID',
          referenceNumber: 'REF12345',
        );
        _addResult(' PaymentSuccessLogic accepted invalid amount');
      } catch (e) {
        _addResult(' PaymentSuccessLogic rejected invalid amount');
        if (e is ArgumentError) {
          _addResult(' PaymentSuccessLogic throws ArgumentError!');
        }
      }
    } catch (e) {
      _addResult(' PaymentSuccessLogic Error: ${e.toString()}');
    }
  }

  Future<void> _testDirectArgumentError() async {
    try {
      _addResult('6. Testing direct ArgumentError throw...');
      throw ArgumentError('Direct test error');
    } catch (e) {
      if (e is ArgumentError) {
        _addResult(' Direct ArgumentError caught successfully');
      } else {
        _addResult(' Wrong exception type: ${e.runtimeType}');
      }
    }
  }
}
