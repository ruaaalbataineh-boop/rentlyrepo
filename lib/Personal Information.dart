import 'package:flutter/material.dart';
import 'package:p2/logic/personal_info_logic.dart';
import 'package:p2/rate_product_page.dart';
import 'package:p2/user_rate.dart';
import 'package:p2/security/route_guard.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/secure_storage.dart';
import 'package:p2/security/input_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  late PersonalInfoProvider _provider;
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    try {
      
      _isAuthenticated = RouteGuard.isAuthenticated();
      
      if (!_isAuthenticated) {
        ErrorHandler.logSecurity('PersonalInfoPage', 'Unauthorized access attempt');
        await _redirectToLogin();
        return;
      }

    
      _provider = PersonalInfoProvider();

      
      await _loadData();

    } catch (error) {
      ErrorHandler.logError('Initialize PersonalInfoPage', error);
      _showErrorScreen();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadData() async {
    try {
      await _provider.loadUserData();
    } catch (error) {
      ErrorHandler.logError('Load User Data', error);
      _showSnackBar('Failed to load user data');
    }
  }

  Future<void> _pickImage() async {
    try {
      await _provider.pickImage();
      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      ErrorHandler.logError('Pick Image', error);
      _showSnackBar(ErrorHandler.getSafeError(error));
    }
  }

  Future<void> _saveInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() => _isSaving = true);

      
      final validationResult = await _validateUserData();
      if (!validationResult.isValid) {
        _showSnackBar(validationResult.message);
        return;
      }

      
      await _logSaveAttempt();

      
      await _provider.saveUserData();

      
      await _saveProfileImage();

      
      await _logSaveSuccess();

      if (mounted) {
        _showSnackBar('Information saved successfully!');
      }

    } catch (error) {
      ErrorHandler.logError('Save User Info', error);
      _showSnackBar(ErrorHandler.getSafeError(error));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<ValidationResult> _validateUserData() async {
    try {
      
      if (_provider.name.trim().isEmpty || _provider.name.length < 2) {
        return ValidationResult(false, 'Please enter a valid name (minimum 2 characters)');
      }

      if (!InputValidator.hasNoMaliciousCode(_provider.name)) {
        return ValidationResult(false, 'Invalid characters in name');
      }

    
      if (!InputValidator.isValidEmail(_provider.email)) {
        return ValidationResult(false, 'Please enter a valid email address');
      }

      
      if (_provider.password.isNotEmpty && !InputValidator.isValidPassword(_provider.password)) {
        return ValidationResult(false, 
            'Password must be at least 8 characters with uppercase, lowercase, and numbers');
      }

      
      if (_provider.phone.isNotEmpty && !InputValidator.isValidPhone(_provider.phone)) {
        return ValidationResult(false, 'Please enter a valid phone number');
      }

      
      if (_provider.imageFile != null) {
        final fileSize = await _provider.imageFile!.length();
        const maxSize = 5 * 1024 * 1024; // 5MB
        if (fileSize > maxSize) {
          return ValidationResult(false, 'Image size should be less than 5MB');
        }
      }

      return ValidationResult(true, '');
    } catch (e) {
      ErrorHandler.logError('Validate User Data', e);
      return ValidationResult(false, ErrorHandler.getSafeError(e));
    }
  }

  Future<void> _saveProfileImage() async {
    try {
      if (_provider.imageFile != null) {
  
      
        final imageInfo = {
          'fileName': _provider.imageFile!.path.split('/').last,
          'fileSize': (await _provider.imageFile!.length()).toString(),
          'savedAt': DateTime.now().toIso8601String(),
        };

        await SecureStorage.saveData(
          'profile_image_info',
          ErrorHandler.safeJsonEncode(imageInfo),
        );
      }
    } catch (e) {
      ErrorHandler.logError('Save Profile Image', e);
    }
  }

  Future<void> _logSaveAttempt() async {
    try {
      final saveAttempt = {
        'timestamp': DateTime.now().toIso8601String(),
        'action': 'save_personal_info',
        'hasImage': _provider.imageFile != null,
      };

      await SecureStorage.saveData(
        'personal_info_save_attempt_${DateTime.now().millisecondsSinceEpoch}',
        ErrorHandler.safeJsonEncode(saveAttempt),
      );
    } catch (e) {
      ErrorHandler.logError('Log Save Attempt', e);
    }
  }

  Future<void> _logSaveSuccess() async {
    try {
      final saveSuccess = {
        'timestamp': DateTime.now().toIso8601String(),
        'action': 'personal_info_saved',
        'fieldsSaved': ['name', 'email', 'phone', 'image'].where((field) {
          if (field == 'image') return _provider.imageFile != null;
          return true;
        }).toList(),
      };

      await SecureStorage.saveData(
        'personal_info_save_success_${DateTime.now().millisecondsSinceEpoch}',
        ErrorHandler.safeJsonEncode(saveSuccess),
      );
    } catch (e) {
      ErrorHandler.logError('Log Save Success', e);
    }
  }

  void _showErrorScreen() {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _redirectToLogin() async {
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (!_isAuthenticated) {
      return _buildAuthErrorScreen();
    }

    return Container(
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Color(0xFF1F0F46), 
        Color(0xFF8A005D), 
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  child: Scaffold(
    backgroundColor: Colors
        .transparent, 
    appBar: AppBar(
      leading: const BackButton(
    color: Colors.white, 
  ),
      title: const Text(
        'Personal Information',
        style: TextStyle(
      color: Colors.white, 
      fontWeight: FontWeight.w600,
    ),
  ),
      backgroundColor: const Color.fromARGB(0, 255, 255, 255),
      elevation: 0,
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildProfileImage(),
              const SizedBox(height: 20),

              _buildNameField(),
              const SizedBox(height: 15),

              _buildEmailField(),
              const SizedBox(height: 15),

              _buildPasswordField(),
              const SizedBox(height: 15),

              _buildPhoneField(),
              const SizedBox(height: 30),

              _buildSaveButton(),
              const SizedBox(height: 15),

              _buildRateProductButton(),
            ],
          ),
        ),
      ),
    ),
  ),
);

  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Color(0xFF1F0F46),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 20),
            Text(
              'Loading profile...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthErrorScreen() {
    return Scaffold(
      backgroundColor: Color(0xFF1F0F46),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 20),
              Text(
                ErrorHandler.getSafeError('Authentication required'),
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _redirectToLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8A005D),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: Text(
                  'Go to Login',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          CircleAvatar(
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
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Color(0xFF8A005D),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      initialValue: _provider.name,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Name',
        labelStyle: const TextStyle(color: Colors.white),
        prefixIcon: Icon(Icons.person, color: Colors.white),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white70),
          borderRadius: BorderRadius.circular(15),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(15),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(15),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your name';
        }
        if (value.trim().length < 2) {
          return 'Name must be at least 2 characters';
        }
        if (!InputValidator.hasNoMaliciousCode(value)) {
          return 'Invalid characters in name';
        }
        return null;
      },
      onChanged: (v) => _provider.name = InputValidator.sanitizeInput(v),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      initialValue: _provider.email,
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email',
        labelStyle: const TextStyle(color: Colors.white),
        prefixIcon: Icon(Icons.email, color: Colors.white),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white70),
          borderRadius: BorderRadius.circular(15),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(15),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(15),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!InputValidator.isValidEmail(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
      onChanged: (v) => _provider.email = InputValidator.sanitizeInput(v),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      initialValue: _provider.password,
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Password (leave blank to keep current)',
        labelStyle: const TextStyle(color: Colors.white),
        prefixIcon: Icon(Icons.lock, color: Colors.white),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white70),
          borderRadius: BorderRadius.circular(15),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(15),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(15),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      validator: (value) {
        if (value != null && value.isNotEmpty && !InputValidator.isValidPassword(value)) {
          return 'Password must be at least 8 characters with uppercase, lowercase, and numbers';
        }
        return null;
      },
      onChanged: (v) => _provider.password = v,
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      initialValue: _provider.phone,
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        labelStyle: const TextStyle(color: Colors.white),
        prefixIcon: Icon(Icons.phone, color: Colors.white),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white70),
          borderRadius: BorderRadius.circular(15),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(15),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(15),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      validator: (value) {
        if (value != null && value.isNotEmpty && !InputValidator.isValidPhone(value)) {
          return 'Please enter a valid phone number';
        }
        return null;
      },
      onChanged: (v) => _provider.phone = InputValidator.sanitizeInput(v),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: EdgeInsets.zero,
          backgroundColor: _isSaving ? Colors.grey : null,
        ),
        onPressed: _isSaving ? null : _saveInfo,
        child: _isSaving
            ? SizedBox(
                height: 25,
                width: 25,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Ink(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: const Text(
                    'Save Information',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildRateProductButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        onPressed: () async {
          try {
            await _logNavigationAction('rate_product');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RateProductPage(productId: '', productName: '',),
              ),
            );
          } catch (error) {
            ErrorHandler.logError('Navigate to Rate Product', error);
            _showSnackBar(ErrorHandler.getSafeError(error));
          }
        },
        child: const Text(
          'Rate Product',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildUserRateButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        onPressed: () async {
          try {
            await _logNavigationAction('user_rate');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const UserRatePage(userId: '', userName: '',),
              ),
            );
          } catch (error) {
            ErrorHandler.logError('Navigate to User Rate', error);
            _showSnackBar(ErrorHandler.getSafeError(error));
          }
        },
        child: const Text(
          'User Rate',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _logNavigationAction(String action) async {
    try {
      final navData = {
        'timestamp': DateTime.now().toIso8601String(),
        'action': action,
        'screen': 'personal_info',
        'userId': await _getCurrentUserId(),
      };

      await SecureStorage.saveData(
        'nav_${action}_${DateTime.now().millisecondsSinceEpoch}',
        ErrorHandler.safeJsonEncode(navData),
      );
    } catch (e) {
      ErrorHandler.logError('Log Navigation Action', e);
    }
  }

  Future<String> _getCurrentUserId() async {
    try {
      final userId = await SecureStorage.getData('current_user_id');
      return userId ?? 'anonymous_user';
    } catch (e) {
      ErrorHandler.logError('Get Current User ID', e);
      return 'error_user';
    }
  }

  @override
  void dispose() {
    try {
    
    } catch (e) {
      ErrorHandler.logError('Dispose PersonalInfoPage', e);
    }
    super.dispose();
  }
}

class ValidationResult {
  final bool isValid;
  final String message;

  ValidationResult(this.isValid, this.message);
}
