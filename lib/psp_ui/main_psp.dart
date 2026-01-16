import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../firebase_options.dart';
import 'views/login_page.dart';
import 'views/dashboard_page.dart';
import 'controllers/psp_auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PSPApp());
}

class PSPApp extends StatelessWidget {
  const PSPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PSP Simulator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = PspAuthController();

    return StreamBuilder<User?>(
      stream: authController.authState(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const LoginPage();
        }

        final user = snap.data!;
        // Check custom claims for psp_simulator role
        return FutureBuilder <IdTokenResult>(
          future: user.getIdTokenResult(true),
          builder: (context, tokenSnap) {
            if (!tokenSnap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final claims = tokenSnap.data!.claims ?? {};
            final role = claims['role'];

            if (role == 'psp_simulator') {
              return const DashboardPage();
            }

            // Access denied
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Access denied: not a PSP simulator user'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: authController.logout,
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
