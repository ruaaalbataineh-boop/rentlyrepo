
// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'Categories_Page.dart';
import 'PaymentPage.dart';
import 'Rently_Logo.dart';
import 'Setting.dart';
import 'Orders.dart';
import 'Login_Page.dart';
import 'create_account.dart';
import 'Phone_Page.dart';
import 'Enter_The_Code.dart';
import 'app_locale.dart';
import 'Category_Equipment_Page.dart';
import 'ProductListPage.dart';
import 'Equipment_Detail_Page.dart';
import 'Favourite.dart';
import 'firebase_options.dart';
import 'MapPage.dart';

// ignore: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart';

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

          home: RentlyApp(),
          routes: {
            '/login': (context) => const LoginPage(),
            '/create': (context) => const CreateAccountPage(),
            '/phone': (context) => const PhonePage(),
            '/Code': (context) => const EnterTheCode(),
            '/orders': (context) => const OrdersPage(),
            '/setting': (context) => const SettingPage(),
            '/payment': (context) => const PaymentPage(),
            '/category': (context) => const CategoryPage(),
            '/userHome': (context) => const UserHomePage(),
            '/favorites': (context) => const FavouritePage(),
          },
          onGenerateRoute: (settings) {
           
            if (settings.name == CategoryEquipmentPage.routeName) {
              return MaterialPageRoute(
                builder: (context) => const CategoryEquipmentPage(),
                settings: settings,
              );
            }

            if (settings.name == ProductListPage.routeName) {
              return MaterialPageRoute(
                builder: (context) => const ProductListPage(),
                settings: settings,
              );
            }

          
            if (settings.name == EquipmentDetailPage.routeName) {
              return MaterialPageRoute(
                builder: (context) => const EquipmentDetailPage(),
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

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    OrdersPage(),
    SettingPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1B2230),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.inventory_2_outlined),
            label: AppLocale.t('orders'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: AppLocale.t('settings'),
          ),
        ],
      ),
    );
  }
}




