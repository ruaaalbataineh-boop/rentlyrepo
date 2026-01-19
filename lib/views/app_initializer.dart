import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/user_service.dart';
import 'login_page.dart';
import 'app_shell.dart';
import '../services/auth_service.dart';
import '../services/app_init_service.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final auth = context.read<AuthService>();

    if (!auth.isLoggedIn || auth.currentUid == null) {
      _goToLogin();
      return;
    }

    final uid = auth.currentUid!;

    final approved = await UserService.isApproved(uid);

    if (!approved) {
      await auth.logout(); // important: prevent access with pending account
      _goToLogin();
      return;
    }

    await AppInitService.initialize();

    // approved + authenticated
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _goToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return const AppShell();
  }
}