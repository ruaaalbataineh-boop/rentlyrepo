import 'package:flutter/material.dart';

import 'Login_Page.dart';

class RentlyApp extends StatefulWidget {
  const RentlyApp({super.key});

  @override
  State<RentlyApp> createState() => _RentlyAppState();
}

class _RentlyAppState extends State<RentlyApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      // SPLASH UI ONLY
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.diamond, size: 80, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  "Rently",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // AFTER SPLASH — RETURN LOGIN DIRECTLY
    return const LoginPage();
  }
}
