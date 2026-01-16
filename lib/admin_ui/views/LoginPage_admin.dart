import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  
  void login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      //  
      final uid = userCredential.user!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists || userDoc.data()?['role'] != 'ADMIN') {
        await FirebaseAuth.instance.signOut();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access denied: Admins only'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    

      //  go to dashboard
      context.go('/dashboard');

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Login failed"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
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
                      Icon(Icons.admin_panel_settings,
                          color: Colors.white, size: 40),
                      SizedBox(width: 8),
                      Text(
                        "Admin Panel",
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
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F3FA),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text(
                        "Admin Login",
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 30),

                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: "Admin Email",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "Enter admin email" : null,
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
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
                              setState(
                                  () => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "Enter password" : null,
                      ),

                      const SizedBox(height: 35),

                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8A005D),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 60, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
