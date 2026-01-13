import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:p2/logic/profile_logic_page.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/input_validator.dart';
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
  bool _isLoading = false;
  String _errorMessage = '';

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
    _validateInitialData();
  }

  Future<void> _validateInitialData() async {
    try {
      final isValid = await _logic.validateCurrentProfile();
      if (!isValid) {
        _logic.sanitizeProfileData();
        setState(() {});
      }
    } catch (error) {
      ErrorHandler.logError('Validate Initial Data', error);
    }
  }

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked != null) {
        final imageFile = File(picked.path);
        
      
        final isSafe = await _logic.validateImageSafety(imageFile);
        
        if (isSafe) {
          setState(() {
            _logic.profileImage = imageFile;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Image is not valid. Please choose another.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      ErrorHandler.logError('Pick Image', error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.getSafeError(error)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();
        
        final validationResult = await _logic.validateForm(
          _logic.fullName, 
          _logic.email, 
          _logic.phone
        );
        
        if (validationResult) {
          final updateSuccess = await _logic.updateProfile(
            name: _logic.fullName,
            email: _logic.email,
            phone: _logic.phone,
            image: _logic.profileImage,
          );
          
          if (updateSuccess) {
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
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_logic.getValidationErrorMessage()),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (error) {
      ErrorHandler.logError('Update Profile', error);
      setState(() {
        _errorMessage = ErrorHandler.getSafeError(error);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget buildRow({required IconData icon, required Widget child}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: child,
    );
  }

  Widget _buildSecureTextField({
    required String label,
    required String initialValue,
    required IconData icon,
    required Function(String?) onSaved,
    bool isEmail = false,
    bool isPhone = false,
  }) {
    return buildRow(
      icon: icon,
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          
          final safeValue = value.trim();
          
          if (isEmail && !InputValidator.isValidEmail(safeValue)) {
            return 'Please enter a valid email';
          }
          
          if (isPhone && !InputValidator.isValidPhone(safeValue)) {
            return 'Please enter a valid phone number';
          }
          
          if (!InputValidator.hasNoMaliciousCode(safeValue)) {
            return 'Invalid characters detected';
          }
          
          return null;
        },
        onSaved: onSaved,
      ),
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

                          _buildSecureTextField(
                            label: "Full Name",
                            initialValue: _logic.fullName,
                            icon: Icons.person,
                            onSaved: (v) => _logic.fullName = v ?? _logic.fullName,
                          ),

                          _buildSecureTextField(
                            label: "Email",
                            initialValue: _logic.email,
                            icon: Icons.email,
                            onSaved: (v) => _logic.email = v ?? _logic.email,
                            isEmail: true,
                          ),

                          _buildSecureTextField(
                            label: "Phone Number",
                            initialValue: _logic.phone,
                            icon: Icons.phone,
                            onSaved: (v) => _logic.phone = v ?? _logic.phone,
                            isPhone: true,
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

                          if (_isLoading)
                            const CircularProgressIndicator()
                          else
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: _updateProfile,
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
