import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:p2/app_theme.dart';
import 'package:p2/security/error_test_page.dart';
import 'package:p2/security/security_test_page.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'models/Item.dart';
import 'sub_category_page.dart';
import 'Categories_Page.dart';
import 'Rently_Logo.dart';
import 'Setting.dart';
import 'Orders.dart';
import 'Login_Page.dart';
import 'create_account.dart';
import 'Phone_Page.dart';
import 'Enter_The_Code.dart';
import 'app_locale.dart';
import 'ProductListPage.dart';
import 'Equipment_Detail_Page.dart';
import 'Favourite.dart';
import 'MapPage.dart';
import 'AddItemPage .dart';
import 'firebase_options.dart';
import 'fake_uid.dart';
import 'package:p2/services/auth_service.dart';



final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// =========================
//  MAIN (Secure Init)
// =========================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    
  
    if (details.exception is ArgumentError) {
      final argError = details.exception as ArgumentError;
      print(' FlutterError - ArgumentError caught: ${argError.message}');
    
      return;
    }
    
    print(' FlutterError: ${details.exception}');
  };

  try {
    //  Lock orientation
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    //  Firebase init
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
    );
    
    //  Stripe init
    Stripe.publishableKey =
        'pk_test_51SjRFIJqX4BeUhberrKmAnRG9IK2nvh6j5oHDKKpyuxOsJRXRRkRcMFbhKWGbrPWu91WRp5yZOurPPLkg0X28I4P00Z2hCDQr6';
    await Stripe.instance.applySettings();

    //  FCM permission
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

   
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    
    runZonedGuarded(() {
      runApp(
        MultiProvider(
          providers: [
           ChangeNotifierProvider<AuthService>(
            create: (_) => AuthService(),
            ),
          ],
          child: OverlaySupport.global(
            child: const MyApp(),
          ),
        ),
      );
    }, (error, stackTrace) {
    
      print(' Zone Error: $error');
      print(' Zone Stack Trace: $stackTrace');
      

      if (error is ArgumentError) {
        print(' Zone - ArgumentError handled: ${error.message}');
        
        return;
      }
      
      
    });

  } catch (e, s) {
    
    debugPrint(' INIT ERROR: $e');
    debugPrint(' INIT STACK: $s');
    
    dynamic safeError = e;
   
    if (e is ArgumentError) {
      debugPrint(' INIT ArgumentError: ${e.message}');
      
      safeError = Exception('Init Error: ${e.message}');
    }

    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'App Initialization Error',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      safeError.toString().length > 100  
                          ? '${safeError.toString().substring(0, 100)}...' 
                          : safeError.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        
                        main();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =========================
//  APP ROOT
// =========================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLocale.locale,
      builder: (context, locale, child) {

        // ⭐ ADDED (لفّينا MaterialApp فقط)
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: AppTheme.themeMode,
          builder: (context, themeMode, _) {

            return MaterialApp(
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,

              // ⭐ ADDED
              themeMode: themeMode,
              theme: ThemeData(brightness: Brightness.light),
              darkTheme: ThemeData(brightness: Brightness.dark),

              locale: locale,
              supportedLocales: const [
                Locale('en'),
                Locale('ar'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],

              home: const MainPage(),

              routes: {
                '/login': (context) => const LoginPage(),
                '/create': (context) => const CreateAccountPage(),
                '/phone': (context) => const PhonePage(uid: '', email: ''),
                '/Code': (context) => const EnterTheCode(),
                '/orders': (context) => const OrdersPage(),
                '/setting': (context) => const SettingPage(),
                '/category': (context) => const CategoryPage(),
                '/favorites': (context) => const FavouritePage(),
                '/test/security': (context) => SecurityTestPage(),
                '/test/errors': (context) => ErrorTestPage(),
              },

              onGenerateRoute: (settings) {
                try {
                  if (settings.name == ProductListPage.routeName) {
                    return MaterialPageRoute(
                      settings: settings,
                      builder: (_) => const ProductListPage(),
                    );
                  }

                  if (settings.name == EquipmentDetailPage.routeName) {
                    if (settings.arguments is! Item) return _errorRoute();
                    return MaterialPageRoute(
                      settings: settings,
                      builder: (_) => const EquipmentDetailPage(),
                    );
                  }

                  if (settings.name == '/add-item') {
                    final data = settings.arguments;
                    if (data is! Map<String, dynamic>) return _errorRoute();

                    return MaterialPageRoute(
                      builder: (_) => AddItemPage(
                        existingItem: data['item'],
                      ),
                    );
                  }

                  if (settings.name == '/map') {
                    final position = settings.arguments;
                    if (position is! LatLng?) return _errorRoute();

                    return MaterialPageRoute(
                      builder: (_) =>
                          MapScreen(initialPosition: position),
                    );
                  }

                  return null;
                } catch (error, stackTrace) {
                  print(' Route Generation Error: $error');
                  print(' Route Stack: $stackTrace');
                  return _safeErrorRoute('Navigation failed');
                }
              },

              builder: (context, widget) {
                if (widget == null) {
                  return const MaterialApp(
                    home: Scaffold(
                      body: Center(
                        child: Text(
                          'Widget is null',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  );
                }

                try {
                  return widget;
                } catch (error, stackTrace) {
                  print(' Widget Builder Error: $error');
                  print(' Widget Builder Stack: $stackTrace');

                  return MaterialApp(
                    home: Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error,
                                size: 50,
                                color: Colors.red),
                            const SizedBox(height: 20),
                            const Text(
                              'UI Error',
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.red),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Go Back'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}

// =========================
//  AUTH GUARD
// =========================
class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && user.uid.isNotEmpty) {
        LoginUID.uid = user.uid;
        return const CategoryPage();
      }

      return const LoginPage();
    } catch (error, stackTrace) {
      
      print(' Auth Guard Error: $error');
      print(' Auth Guard Stack: $stackTrace');
      
      if (error is ArgumentError) {
        print(' Auth Guard ArgumentError: ${error.message}');
      
        return _buildAuthErrorScreen();
      }
      
      
      return const LoginPage();
    }
  }

  
  Widget _buildAuthErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.security,
                  size: 80,
                  color: Colors.orange[400],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Authentication Error',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Unable to verify authentication status',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    
                    main();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                  child: const Text('Retry Authentication'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                   
                    navigatorKey.currentState?.pushReplacementNamed('/login');
                  },
                  child: const Text('Go to Login Page'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =========================
//  ERROR ROUTE
// =========================
MaterialPageRoute _errorRoute() {
  return MaterialPageRoute(
    builder: (_) => Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Invalid Navigation',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'The requested navigation is not valid',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    navigatorKey.currentState?.pop();
                  },
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}


MaterialPageRoute _safeErrorRoute(String message) {
  return MaterialPageRoute(
    builder: (_) => Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber,
                  size: 60,
                  color: Colors.amber[600],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Application Error',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    navigatorKey.currentState?.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
