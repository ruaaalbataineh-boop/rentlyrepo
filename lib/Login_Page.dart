import 'package:flutter/material.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:provider/provider.dart';

import 'app_shell.dart';
import 'fake_uid.dart';
import 'package:p2/services/auth_service.dart';
import 'logic/login_logic.dart';
import 'main_user.dart';

class LoginPage extends StatefulWidget {
  LoginPage({super.key}); // not const for test rebuild safety

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    // Stop real login in integration test
    if (isIntegrationTest) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      final result = await authService.loginWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        rememberMe: _rememberMe,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        LoginUID.uid = result['uid'];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AppShell()),
        );
      } else {
        _showError(result['error'] ?? 'Login failed');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred';
      });
    }
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [

            ClipPath(
              clipper: WaveClipperOne(),
              child: Container(
                height: 180,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(30),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text("Login",
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),

                    const SizedBox(height: 30),

                    /// EMAIL
                    TextFormField(
                      key: const ValueKey('emailField'),
                      controller: emailController,
                      decoration: const InputDecoration(labelText: "Email"),
                      validator: AuthLogic.validateEmail,
                    ),

                    const SizedBox(height: 20),

                    /// PASSWORD
                    TextFormField(
                      key: const ValueKey('passwordField'),
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: AuthLogic.validatePassword,
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (v) {
                            setState(() {
                              _rememberMe = v ?? false;
                            });
                          },
                        ),
                        const Text('Remember me'),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// LOGIN BUTTON
                    ElevatedButton(
                      key: const ValueKey('loginButton'),
                      onPressed: _isLoading ? null : _login,
                      child: const Text("Login"),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
