import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:p2/admin_ui/routes.dart';
import '../firebase_options.dart';
import 'services/admin_fcm_service.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await AdminFcmService.init();
    
    runApp(const AdminApp());
  } else {
  
    runApp(Container(color: Colors.white));
  }
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: adminRouter,
    );
  }
}
