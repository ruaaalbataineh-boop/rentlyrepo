import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:p2/services/favourite_service.dart';
import 'package:p2/views/splash_page.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'WalletPage.dart';
import 'WalletRechargePage.dart';
import 'controllers/favourite_controller.dart';
import 'firebase_options.dart';
import 'services/app_locale.dart';

import 'services/auth_service.dart';
import 'controllers/app_start_controller.dart';

import 'views/Login_Page.dart';
import 'views/app_shell.dart';

import 'views/create_account.dart';
import 'views/continue_create_account.dart';
import 'Enter_The_Code.dart';
import 'views/Orders.dart';
import 'Setting.dart';
import 'views/Favourite.dart';
import 'owner_listings.dart';
import 'views/ProductListPage.dart';
import 'views/Equipment_Detail_Page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

bool isIntegrationTest = const bool.fromEnvironment('INTEGRATION_TEST');

Future<void> main({bool testMode = false}) async {
  isIntegrationTest = testMode;

  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  try {
    // Safe even if background isolate already initialized Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
    webProvider: ReCaptchaV3Provider('dummy'),
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
        ChangeNotifierProvider<FavouriteController>(
          create: (_) => FavouriteController(FavouriteService()),
        ),
      ],
      child: OverlaySupport.global(child: const MyApp()),
    ),
  );
}

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
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SplashPage(),
          routes: {
            '/login': (_) => LoginPage(),
            '/create': (_) => const CreateAccountPage(),
            '/phone': (_) => const ContinueCreateAccountPage(uid: '', email: ''),
            '/code': (_) => const EnterTheCode(),
            '/orders': (_) => const OrdersPage(),
            '/setting': (_) => const SettingPage(),
            '/favorites': (_) => const FavouritePage(),
            '/ownerItems': (_) => const OwnerItemsPage(),
            ProductListPage.routeName: (_) => const ProductListPage(),
            EquipmentDetailPage.routeName: (_) => const EquipmentDetailPage(),
            WalletRechargePage.routeName: (_) => const WalletRechargePage(),
            WalletHomePage.routeName: (context) => const WalletHomePage(),
          },
        );
      },
    );
  }
}