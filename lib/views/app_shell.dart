import 'package:flutter/material.dart';

import 'Categories_Page.dart';
import 'Orders.dart';
import '../Chats_Page.dart';
import '../Setting.dart';
import '../owner_listings.dart';

import '../widgets/bottom_nav.dart';

class AppShell extends StatefulWidget {
  final int initialIndex;

  const AppShell({super.key, this.initialIndex = 2});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _pages = const [
    SettingPage(),
    OrdersPage(),
    CategoryPage(),
    ChatsPage(),
    OwnerItemsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: SharedBottomNav(
          currentIndex: _currentIndex,
          onTabChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}
