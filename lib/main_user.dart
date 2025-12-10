import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2/AddItemPage%20.dart';
import 'package:p2/Categories_Page.dart';
import 'package:p2/Rently_Logo.dart';
import 'package:p2/Setting.dart';
import 'package:p2/Orders.dart';
import 'package:p2/Login_Page.dart';
import 'package:p2/create_account.dart';
import 'package:p2/Phone_Page.dart';
import 'package:p2/Enter_The_Code.dart';
import 'package:p2/ProductListPage.dart';
import 'package:p2/Equipment_Detail_Page.dart';
import 'package:p2/Favourite.dart';
import 'package:p2/MapPage.dart';
import 'package:p2/EquipmentItem.dart';
import 'package:p2/WalletPage.dart';
import 'package:p2/WalletRechargePage.dart';
import 'package:p2/mTransactionHistoryPage.dart';
import 'package:p2/CashWithdrawalPage.dart';
import 'package:p2/CreditCardPaymentPage.dart';
import 'package:p2/ClickPaymentPage.dart';
import 'package:p2/payment_success_page.dart';
import 'package:p2/payment_failed_page.dart';

import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app_locale.dart';

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
            '/code': (context) => const EnterTheCode(),
            '/orders': (context) => const OrdersPage(),
            '/setting': (context) => const SettingPage(),
            '/category': (context) => const CategoryPage(),
            '/favorites': (context) => const FavouritePage(),

        
            '/wallet': (context) => const WalletHomePage(),
            '/wallet-history': (context) => const TransactionHistoryPage(transactions: []),
            '/wallet-recharge': (context) => const WalletRechargePage(),
            '/wallet-withdrawal': (context) => const CashWithdrawalPage(),
            '/payment-credit-card': (context) => const CreditCardPaymentPage(amount: 0),
            '/payment-click': (context) => const ClickPaymentPage(amount: 0),
            '/payment-success': (context) => const PaymentSuccessPage(amount: 0),
            '/payment-failed': (context) => const PaymentFailedPage(),
          },

          onGenerateRoute: (settings) {
            if (settings.name == ProductListPage.routeName) {
              return MaterialPageRoute(
                builder: (context) => const ProductListPage(),
                settings: settings,
              );
            }

            if (settings.name == EquipmentDetailPage.routeName) {
              final equipment = settings.arguments as EquipmentItem?;
              return MaterialPageRoute(
                builder: (context) => EquipmentDetailPage(),
                settings: settings,
              );
            }

            if (settings.name == '/add-item') {
              final item = settings.arguments as EquipmentItem?;
              return MaterialPageRoute(
                builder: (context) => AddItemPage(item: item),
                settings: settings,
              );
            }

            if (settings.name == '/map') {
              final latLng = settings.arguments as LatLng?;
              if (latLng != null) {
                return MaterialPageRoute(
                  builder: (context) => MapScreen(initialPosition: latLng),
                  settings: settings,
                );
              } else {
                return MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: const Text('Map')),
                    body: const Center(child: Text('Map: location not provided')),
                  ),
                  settings: settings,
                );
              }
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
    return const CategoryPage();
  }
}
