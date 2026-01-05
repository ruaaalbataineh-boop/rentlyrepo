import 'package:flutter/material.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:p2/logic/login_logic.dart';
import 'Categories_Page.dart';
import 'app_locale.dart';
import 'fake_uid.dart';   

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isTestMode = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  late LoginLogic _loginLogic;

  @override
  void initState() {
    super.initState();
    if (isTestMode)
      _loginLogic = LoginLogic();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    if (isTestMode)
      return;
    super.dispose();
  }

  void login() async {
    if (isTestMode)
      return;
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    await _loginLogic.loginUser(
      email: emailController.text,
      password: passwordController.text,
      onSuccess: (uid) {
        if (!mounted) return;

        LoginUID.uid = uid;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CategoryPage()),
        );
      },
      onError: (error) {
        if (!mounted) return;

        setState(() => _errorMessage = error);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      },
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                ClipPath(
                  clipper: WaveClipperOne(),
                  child: Container(
                    height: 180,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  top: 50,
                  left: 30,
                  child: Row(
                    children: [
                      Icon(Icons.diamond, color: Colors.white, size: 40),
                      SizedBox(width: 8),
                      Text(
                        "Rently",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Login",
                      style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Text("Don't have an account? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/create');
                          },
                          child: const Text(
                            "Sign up",
                            style: TextStyle(
                              color: Colors.pink,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),


                    TextFormField(
                      key:const ValueKey('emailField'),
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      validator: LoginLogic.validateEmail,
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      key:const ValueKey('passwordField'),
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      validator: LoginLogic.validatePassword,
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _isLoading
                            ? const CircularProgressIndicator()
                            :
                           KeyedSubtree (

                              key: const ValueKey('loginButtom'),
                              child:
                                ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF8A005D),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(30),
                                  ),
                                ),

                                onPressed: login,
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("Login",
                                        style:
                                            TextStyle(color: Colors.white)),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward,
                                        color: Colors.white),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    ),


                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(_errorMessage!,
                          style:
                              const TextStyle(color: Colors.red)),
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
