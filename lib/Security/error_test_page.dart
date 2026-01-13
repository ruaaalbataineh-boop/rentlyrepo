import 'package:flutter/material.dart';

/// صفحة لاختبار معالجة الأخطاء في UI
class ErrorTestPage extends StatefulWidget {
  const ErrorTestPage({super.key});

  @override
  State<ErrorTestPage> createState() => _ErrorTestPageState();
}

class _ErrorTestPageState extends State<ErrorTestPage> {
  int errorCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Handling Tests'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // إحصائية
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.bug_report, size: 50, color: Colors.orange),
                  const SizedBox(height: 10),
                  const Text(
                    'Error Simulation Tests',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Errors triggered: $errorCount',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // أزرار الاختبار
          _buildTestButton(
            title: 'Test UI Exception',
            description: 'Simulates a UI rendering error',
            icon: Icons.error_outline,
            onTap: _testUIException,
          ),

          _buildTestButton(
            title: 'Test Async Error',
            description: 'Simulates an async operation error',
            icon: Icons.timelapse,
            onTap: _testAsyncError,
          ),

          _buildTestButton(
            title: 'Test Null Error',
            description: 'Simulates null reference error',
            icon: Icons.not_interested,
            onTap: _testNullError,
          ),

          _buildTestButton(
            title: 'Test State Error',
            description: 'Simulates setState() error',
            icon: Icons.change_circle,
            onTap: _testStateError,
          ),

          _buildTestButton(
            title: 'Test ArgumentError',
            description: 'Test the actual problem',
            icon: Icons.warning,
            color: Colors.red,
            onTap: _testArgumentError,
          ),

          _buildTestButton(
            title: 'Test Multiple Errors',
            description: 'Trigger multiple errors at once',
            icon: Icons.waves,
            onTap: _testMultipleErrors,
          ),

          const SizedBox(height: 30),

          // زر تصفية
          OutlinedButton(
            onPressed: () => setState(() => errorCount = 0),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            child: const Text('Reset Error Counter'),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.blue,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.play_arrow),
        onTap: () {
          onTap();
          setState(() => errorCount++);
        },
      ),
    );
  }

void _testUIException() {
  try {
    // طريقة أخرى لتسبيب خطأ UI
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This will cause an error'),
              // استخدم FutureBuilder مع خطأ
              FutureBuilder<int>(
                future: Future<int>.error('Simulated UI error'),
                builder: (context, snapshot) {
                  return Text('Result: ${snapshot.data}'); // سيسبب خطأ
                },
              ),
            ],
          ),
        ),
      ),
    );
  } catch (e) {
    _showResult('UI Exception Test', e.toString());
  }
}
  Future<void> _testAsyncError() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      throw Exception('Simulated async error');
    } catch (e) {
      _showResult('Async Error Test', e.toString());
    }
  }

  void _testNullError() {
    try {
      String? nullString;
      print(nullString!.length); //  force null error
    } catch (e) {
      _showResult('Null Error Test', e.toString());
    }
  }

  void _testStateError() {
    try {
      // محاولة تحديث state بعد التخلص من الويدجت
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {});
        } else {
          throw StateError('Widget disposed');
        }
      });
      _showResult('State Error Test', 'Test scheduled (check in 3 seconds)');
    } catch (e) {
      _showResult('State Error Test', e.toString());
    }
  }

  void _testArgumentError() {
    try {
      // هذا هو الخطأ الأساسي الذي نحاول إصلاحه
      throw ArgumentError('Test ArgumentError for Flutter Web');
    } catch (e) {
      _showResult('ArgumentError Test', 
          '${e.runtimeType}: ${e.toString()}');
    }
  }

  void _testMultipleErrors() {
    try {
      throw ArgumentError('First error');
    } catch (e) {
      try {
        throw StateError('Second error after: $e');
      } catch (e2) {
        _showResult('Multiple Errors Test', 
            'Error chain:\n1. ${e.toString()}\n2. ${e2.toString()}');
      }
    }
  }

  void _showResult(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(message),
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
