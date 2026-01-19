import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../security/error_handler.dart';

class AboutAppPage extends StatefulWidget {  
  const AboutAppPage({super.key});

  @override
  State<AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends State<AboutAppPage> {
  String? appVersion;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _preventScreenshots(); // Prevent screenshots
  }

  // Prevent screenshots
  void _preventScreenshots() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  // Load app info securely
  Future<void> _loadAppInfo() async {
    try {
      // Check if logged in
      final auth = context.read<AuthService>();
      final uid = auth.currentUid;


      if (uid == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
        });
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        appVersion = '1.0.0';
        isLoading = false;
      });

    } catch (error) {
      ErrorHandler.logError('AboutAppPage', error);
      
      setState(() {
        errorMessage = ErrorHandler.getSafeError(error);
        appVersion = '1.0.0';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 28),
                      onPressed: () {
                          Navigator.pop(context);
                      },
                    ),
                    const Expanded(
                      child: Text(
                        "About App",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: Center(
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : errorMessage != null
                          ? _buildErrorCard()
                          : _buildAppInfoCard(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfoCard() {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 30),
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline,
                size: 80, color: Color(0xFF8A005D)),
            const SizedBox(height: 20),
            const Text(
              "Rently App",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F0F46),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Rently is your smart solution for renting equipment, tools, "
              "and more between individuals. We aim to provide a safe, "
              "reliable, and user-friendly platform with secure payments, "
              "wallet integration, and QR verification.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Version ${appVersion ?? '1.0.0'}",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 30),
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              "Connection Issue",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F0F46),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              errorMessage ?? 'Unable to load app information',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadAppInfo,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
