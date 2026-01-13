import 'package:flutter/material.dart';
import 'package:p2/Login_Page.dart';
import 'package:p2/services/auth_service.dart';

class RentlyApp extends StatefulWidget {
  const RentlyApp({super.key});

  @override
  State<RentlyApp> createState() => _RentlyAppState();
}

class _RentlyAppState extends State<RentlyApp> {
  bool _showSplash = true;
  bool _hasError = false;
  String? _initialRoute;
  String? _errorMessage;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Splash delay
      await Future.delayed(const Duration(seconds: 2));

      // Decide initial route
      await _determineInitialRoute();

      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    } catch (e) {
      debugPrint('App initialization error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to initialize the application';
          _showSplash = false;
        });
      }
    }
  }

  Future<void> _determineInitialRoute() async {
    try {
      final bool loggedIn = await _authService.isLoggedIn;
      _initialRoute = loggedIn ? '/category' : '/login';
    } catch (e) {
      debugPrint('Determine initial route error: $e');
      _initialRoute = '/login';
    }
  }

  // ---------------- Splash Screen ----------------
  Widget _buildSplashScreen() {
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
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Row(
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
              const SizedBox(height: 40),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.security, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      "Secure Connection",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Initializing secure application...",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Version 1.0.0",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Error Screen ----------------
  Widget _buildErrorScreen() {
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 80, color: Colors.white),
                const SizedBox(height: 20),
                const Text(
                  "Application Error",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  _errorMessage ?? "An unexpected error occurred",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _showSplash = true;
                    });
                    _initializeApp();
                  },
                  icon: const Icon(Icons.refresh,
                      color: Color(0xFF8A005D)),
                  label: const Text(
                    "Try Again",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8A005D)),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginPage()),
                    );
                  },
                  child: const Text(
                    "Continue to Login",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Main App ----------------
  Widget _buildMainApp() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rently',
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
      initialRoute: _initialRoute ?? '/login',
      routes: {
        '/login': (_) => const LoginPage(),
       
      },
      onUnknownRoute: (_) =>
          MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) return _buildSplashScreen();
    if (_hasError) return _buildErrorScreen();
    return _buildMainApp();
  }
}
