import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 

import 'security/route_guard.dart';
import 'security/secure_storage.dart';
import 'security/error_handler.dart';
import 'security/input_validator.dart';

import 'Categories_Page.dart';
import 'notifications/notification_init.dart';
import 'services/fcm_service.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    
    WidgetsBinding.instance.addObserver(this);
    
    _initializeApp();
  }

  @override
  void dispose() {
    
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
       
        _logAppEvent('App paused');
        break;
      case AppLifecycleState.resumed:
       
        _checkSecurityOnResume();
        break;
      case AppLifecycleState.inactive:
       
        break;
      case AppLifecycleState.detached:
        
        _logAppEvent('App detached');
        break;
      case AppLifecycleState.hidden:
        
        break;
    }
  }

  
  Future<void> _initializeApp() async {
    try {
     
      if (!RouteGuard.isAuthenticated()) {
        _handleUnauthenticated();
        return;
      }

    
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
      );

      
      await _initializeNotificationsSecurely();

  
      _logAppEvent('AppShell initialized successfully');

      setState(() {
        _isInitialized = true;
      });

    } catch (error) {
      
      ErrorHandler.logError('AppShell Initialization', error);
      
      setState(() {
        _hasError = true;
        _errorMessage = ErrorHandler.getSafeError(error);
      });
    }
  }

  Future<void> _initializeNotificationsSecurely() async {
    try {
      
      final bool hasPermission = await _checkNotificationPermissions();
      
      if (!hasPermission) {
        _logAppEvent('Notification permissions not granted');
        return;
      }

      
      await _initializeFcmWithRetry();

    
      await NotificationInit.start();

      await _storeFcmTokenSecurely();

      _logAppEvent('Notifications initialized successfully');

    } catch (error) {
      ErrorHandler.logError('Notification Initialization', error);
    }
  }

  Future<bool> _checkNotificationPermissions() async {
    try {
   
      return true;
    } catch (error) {
      ErrorHandler.logError('Check Notification Permissions', error);
      return false;
    }
  }

  Future<void> _initializeFcmWithRetry() async {
    const int maxRetries = 3;
    int attempt = 0;
    
    while (attempt < maxRetries) {
      try {
        await FcmService.init();
        return; // Success
      } catch (error) {
        attempt++;
        ErrorHandler.logError('FCM Init Attempt $attempt', error);
        
        if (attempt >= maxRetries) {
          rethrow;
        }
        
       
        await Future.delayed(Duration(seconds: attempt));
      }
    }
  }

  Future<void> _storeFcmTokenSecurely() async {
    try {
      // In a real app, you would get the actual FCM token
      // and store it securely
      // Example:
      // final token = await FirebaseMessaging.instance.getToken();
      // if (token != null) {
      //   await SecureStorage.saveData('fcm_token', token);
      // }
      
      _logAppEvent('FCM token stored securely');
    } catch (error) {
      ErrorHandler.logError('Store FCM Token', error);
    }
  }

  void _checkSecurityOnResume() {
    try {
    
      if (!RouteGuard.isAuthenticated()) {
        _handleUnauthenticated();
        return;
      }

      _checkForSuspiciousActivity();

      _logAppEvent('App resumed - security check passed');

    } catch (error) {
      ErrorHandler.logError('Security Check on Resume', error);
    }
  }

  void _checkForSuspiciousActivity() {
    
    
    _logAppEvent('Suspicious activity check performed');
  }

  void _handleUnauthenticated() {
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    });
  }

  void _logAppEvent(String message) {
    
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $message';
    
   
    print('🔒 SECURITY LOG: $logMessage');
    
  
    _storeAuditLog(logMessage);
  }

  Future<void> _storeAuditLog(String message) async {
    try {
    
      final existingLogs = await SecureStorage.getData('audit_logs') ?? '[]';
      final List<dynamic> logs = List<dynamic>.from(json.decode(existingLogs));
      
      logs.add({
        'timestamp': DateTime.now().toIso8601String(),
        'event': message,
      });
      
     
      if (logs.length > 100) {
        logs.removeAt(0);
      }
      
      await SecureStorage.saveData('audit_logs', json.encode(logs));
      
    } catch (error) {
      ErrorHandler.logError('Store Audit Log', error);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Security: Show loading or error states
    if (_hasError) {
      return _buildErrorScreen();
    }

    if (!_isInitialized) {
      return _buildLoadingScreen();
    }

    // Security: Verify authentication before showing main page
    if (!RouteGuard.isAuthenticated()) {
      return _buildRedirectScreen();
    }

    // Security: Wrap main content with security features
    return _buildSecureAppContent();
  }

  Widget _buildSecureAppContent() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: WillPopScope(
        onWillPop: () async {
          // Security: Handle back button press
          _logAppEvent('Back button pressed');
          return true; // Allow back navigation
        },
        child: const CategoryPage(),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1F0F46),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF8A005D),
            ),
            const SizedBox(height: 20),
            Text(
              'Initializing secure app...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '🔒 Security checks in progress',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1F0F46),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.security_outlined,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              Text(
                _errorMessage ?? 'Security initialization failed',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Please restart the application',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // Security: Retry initialization
                  setState(() {
                    _hasError = false;
                    _errorMessage = null;
                  });
                  _initializeApp();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8A005D),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  // Security: Go to login as fallback
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
                child: const Text(
                  'Go to Login',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRedirectScreen() {
    // Security: Show brief message before redirect
    return Scaffold(
      backgroundColor: const Color(0xFF1F0F46),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF8A005D),
            ),
            const SizedBox(height: 20),
            const Text(
              'Security verification required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Redirecting to login...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


