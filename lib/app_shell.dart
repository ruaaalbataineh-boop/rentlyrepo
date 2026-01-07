import 'package:flutter/material.dart';
import 'Categories_Page.dart';
import 'notifications/notification_init.dart';
import 'services/fcm_service.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    
    // FCM Global 
    NotificationInit.start();
    FcmService.init();        // FCM token 
  }

  @override
  Widget build(BuildContext context) {
    //  أول صفحة حقيقية بعد اللوجين
    return const CategoryPage();
  }
}

