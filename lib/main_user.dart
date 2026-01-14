import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'package:flutter_stripe/flutter_stripe.dart';

import 'Equipment_Detail_Page.dart';
import 'ProductListPage.dart';
import 'firebase_options.dart';
import 'fake_uid.dart';
import 'Login_Page.dart';
import 'Categories_Page.dart';
import 'create_account.dart';
import 'Phone_Page.dart';
import 'Enter_The_Code.dart';
import 'Orders.dart';
import 'Setting.dart';
import 'Favourite.dart';
import 'app_locale.dart';
import 'package:p2/services/auth_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

bool isIntegrationTest = const bool.fromEnvironment('INTEGRATION_TEST');

Future<void> main({bool testMode = false}) async {
  isIntegrationTest = testMode;

  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  Stripe.publishableKey =
  'pk_test_51SjRFIJqX4BeUhberrKmAnRG9IK2nvh6j5oHDKKpyuxOsJRXRRkRcMFbhKWGbrPWu91WRp5yZOurPPLkg0X28I4P00Z2hCDQr6';
  await Stripe.instance.applySettings();

  await FirebaseMessaging.instance.requestPermission();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),
      ],
      child: OverlaySupport.global(child: const MyApp()),
    ),
  );
}

// ================= APP ROOT =================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLocale.locale,
      builder: (context, locale, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
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
            '/login': (_) => LoginPage(),
            '/create': (_) => const CreateAccountPage(),
            '/phone': (_) => const PhonePage(uid: '', email: ''),
            '/Code': (_) => const EnterTheCode(),
            '/orders': (_) => const OrdersPage(),
            '/setting': (_) => const SettingPage(),
            '/category': (_) => const CategoryPage(),
            '/favorites': (_) => const FavouritePage(),
            ProductListPage.routeName: (context) => const ProductListPage(),
            EquipmentDetailPage.routeName: (context) => const EquipmentDetailPage(),
          },
        );
      },
    );
  }
}

// ================= AUTH GUARD =================

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TEST MODE: always Login
    if (isIntegrationTest) {
      return LoginPage();
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user != null && user.uid.isNotEmpty) {
      LoginUID.uid = user.uid;
      return const CategoryPage();
    }

    return LoginPage();
  }
}
