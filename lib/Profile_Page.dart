
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:p2/logic/profile_logic_page.dart';


class ProfilePage extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String location;
  final String bank;

  const ProfilePage({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
    required this.bank,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late ProfileLogic _logic;

  @override
  void initState() {
    super.initState();
    _logic = ProfileLogic(
      fullName: widget.name,
      email: widget.email,
      phone: widget.phone,
      location: widget.location,
      bank: widget.bank,
    );
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _logic.profileImage = File(picked.path);
      });
    }
  }

  Future<void> fakeUpdate() async {
    await Future.delayed(const Duration(seconds: 1));
    print("====== User Updated ======");
    print("Name: ${_logic.fullName}");
    print("Email: ${_logic.email}");
    print("Phone: ${_logic.phone}");
    print("Image: ${_logic.hasImage() ? "Uploaded" : "Not changed"}");
    print("==========================");
  }

  Widget buildRow({required IconData icon, required Widget child}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: pickImage,
                            child: CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.blue,
                              backgroundImage: _logic.hasImage()
                                  ? FileImage(_logic.profileImage!)
                                  : null,
                              child: !_logic.hasImage()
                                  ? const Icon(Icons.person,
                                      size: 50, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text("Change Profile Image",
                              style: TextStyle(color: Colors.blue)),
                          const Divider(),

                          buildRow(
                            icon: Icons.person,
                            child: TextFormField(
                              initialValue: _logic.fullName,
                              decoration: const InputDecoration(labelText: "Full Name"),
                              onSaved: (v) => _logic.fullName = v ?? _logic.fullName,
                            ),
                          ),

                          buildRow(
                            icon: Icons.email,
                            child: TextFormField(
                              initialValue: _logic.email,
                              decoration: const InputDecoration(labelText: "Email"),
                              onSaved: (v) => _logic.email = v ?? _logic.email,
                            ),
                          ),

                          buildRow(
                            icon: Icons.phone,
                            child: TextFormField(
                              initialValue: _logic.phone,
                              decoration: const InputDecoration(labelText: "Phone Number"),
                              onSaved: (v) => _logic.phone = v ?? _logic.phone,
                            ),
                          ),

                          ListTile(
                            leading:
                                const Icon(Icons.location_on, color: Colors.black87),
                            title: const Text("My Location"),
                            subtitle: Text(_logic.location),
                          ),
                          ListTile(
                            leading:
                                const Icon(Icons.account_balance, color: Colors.black87),
                            title: const Text("Bank Information"),
                            subtitle: Text(_logic.bank),
                          ),
                          const ListTile(
                            leading:
                                Icon(Icons.verified_user, color: Colors.black87),
                            title: Text("Account verification"),
                          ),

                          const SizedBox(height: 20),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                _formKey.currentState!.save();
                                
                                if (_logic.validateForm(_logic.fullName, _logic.email, _logic.phone)) {
                                  await fakeUpdate();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(_logic.getUpdateSuccessMessage()),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(_logic.getUpdateErrorMessage()),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text(
                              "Save Changes",
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
