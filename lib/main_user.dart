import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'Item.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLocale.locale,
      builder: (context, locale, child) {
        return MaterialApp(
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
            //'/payment': (context) => const PaymentPage(),
            '/category': (context) => const CategoryPage(),
            '/favorites': (context) => const FavouritePage(),
            //'/cardPayment': (context) => const CardPaymentPage(),
            //'/wallet': (context) => const WalletPage(),
          },

          onGenerateRoute: (settings) {
            // Product Listing
            if (settings.name == ProductListPage.routeName) {
              return MaterialPageRoute(
                builder: (context) => const ProductListPage(),
                settings: settings,
              );
            }

            // Equipment Detail Page
            if (settings.name == EquipmentDetailPage.routeName) {
              final item = settings.arguments as Item;

              return MaterialPageRoute(
                builder: (context) => const EquipmentDetailPage(),
                settings: settings,
              );
            }

            // Add Item Page
            if (settings.name == '/add-item') {
              final data = settings.arguments as Map<String, dynamic>?;

              return MaterialPageRoute(
                builder: (context) => AddItemPage(
                  existingItem: data?["item"],
                ),
                settings: settings,
              );
            }

            // Map Page
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
