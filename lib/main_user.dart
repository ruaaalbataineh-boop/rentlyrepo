import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:overlay_support/overlay_support.dart';
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
import 'firebase_options.dart';
import 'MapPage.dart';
import 'AddItemPage .dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'fake_uid.dart';
import 'package:flutter_stripe/flutter_stripe.dart';



final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainPage();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Stripe.publishableKey =
  "pk_test_51SjRFIJqX4BeUhberrKmAnRG9IK2nvh6j5oHDKKpyuxOsJRXRRkRcMFbhKWGbrPWu91WRp5yZOurPPLkg0X28I4P00Z2hCDQr6";
  await Stripe.instance.applySettings();

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(
    OverlaySupport.global( 
      child: const MyApp(),
    ),
  );
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLocale.locale,
      builder: (context, locale, child) {
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
          home: const RentlyApp(),
          routes: {
            '/login': (context) => const LoginPage(),
            '/create': (context) => const CreateAccountPage(),
            '/phone': (context) => const PhonePage(uid: '', email: ''),
            '/Code': (context) => const EnterTheCode(),
            '/orders': (context) => const OrdersPage(),
            '/setting': (context) => const SettingPage(),
            '/category': (context) => const CategoryPage(),
            '/favorites': (context) => const FavouritePage(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == ProductListPage.routeName) {
              return MaterialPageRoute(
                builder: (context) => const ProductListPage(),
                settings: settings,
              );
            }

            if (settings.name == EquipmentDetailPage.routeName) {
              final item = settings.arguments as Item;
              return MaterialPageRoute(
                builder: (context) =>
                    const EquipmentDetailPage(),
                settings: settings,
              );
            }

            if (settings.name == '/add-item') {
              final data =
                  settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => AddItemPage(
                  existingItem: data?["item"],
                ),
                settings: settings,
              );
            }

            if (settings.name == '/map') {
              final position = settings.arguments as LatLng?;
              return MaterialPageRoute(
                builder: (context) =>
                    MapScreen(initialPosition: position),
                settings: settings,
              );
            }

            return null;
          },
        );
      },
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

  
    if (user != null) {
      LoginUID.uid = user.uid;
      return const CategoryPage();
    }

    
    return const LoginPage();
  }
}
