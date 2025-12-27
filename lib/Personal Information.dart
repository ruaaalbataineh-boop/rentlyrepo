
import 'package:flutter/material.dart';
import 'package:p2/logic/personal_info_provider.dart';
import 'rate_product_page.dart';
import 'user_rate.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  late PersonalInfoProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = PersonalInfoProvider();
    _loadData();
  }

  Future<void> _loadData() async {
    await _provider.loadUserData();
    setState(() {});
  }

  Future<void> _pickImage() async {
    await _provider.pickImage();
    setState(() {});
  }

  Future<void> _saveInfo() async {
    await _provider.saveUserData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Information saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white54,
                      backgroundImage: _provider.imageFile != null
                          ? FileImage(_provider.imageFile!)
                          : null,
                      child: _provider.imageFile == null
                          ? const Icon(Icons.camera_alt,
                              size: 40, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildField(
                    label: 'Name',
                    icon: Icons.person,
                    initialValue: _provider.name,
                    onChanged: (v) => _provider.name = v,
                  ),
                  const SizedBox(height: 15),
                  _buildField(
                    label: 'Email',
                    icon: Icons.email,
                    initialValue: _provider.email,
                    onChanged: (v) => _provider.email = v,
                  ),
                  const SizedBox(height: 15),
                  _buildField(
                    label: 'Password',
                    icon: Icons.lock,
                    initialValue: _provider.password,
                    obscure: true,
                    onChanged: (v) => _provider.password = v,
                  ),
                  const SizedBox(height: 15),
                  _buildField(
                    label: 'Phone Number',
                    icon: Icons.phone,
                    initialValue: _provider.phone,
                    keyboard: TextInputType.phone,
                    onChanged: (v) => _provider.phone = v,
                  ),

                  const SizedBox(height: 30),

                 
                  _gradientButton(
                    text: 'Save Information',
                    onPressed: _saveInfo,
                  ),

                  const SizedBox(height: 15),
                  
                  _simpleButton(
                    text: 'Rate Product',
                    color: Colors.orange,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RateProductPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  
                  _simpleButton(
                    text: 'User Rate',
                    color: Colors.green,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserRatePage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text('Personal Information'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    required String initialValue,
    required Function(String) onChanged,
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      initialValue: initialValue,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        prefixIcon: Icon(icon, color: Colors.white),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white70),
          borderRadius: BorderRadius.circular(15),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _gradientButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: EdgeInsets.zero,
        ),
        onPressed: onPressed,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
            ),
            borderRadius: BorderRadius.all(Radius.circular(25)),
          ),
          child: Container(
            alignment: Alignment.center,
            child: Text(
              text,
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _simpleButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}
