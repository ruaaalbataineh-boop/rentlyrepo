import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'pending_topups_page.dart';
import 'pending_withdrawals_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PSP Simulator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Center(
            child: ToggleButtons(
              isSelected: [_tabIndex == 0, _tabIndex == 1],
              onPressed: (i) => setState(() => _tabIndex = i),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Top-ups'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Withdrawals'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _tabIndex == 0
                ? const PendingTopupsPage()
                : const PendingWithdrawalsPage(),
          ),
        ],
      ),
    );
  }
}
