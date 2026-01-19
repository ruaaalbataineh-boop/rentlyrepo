import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:p2/logic/continue_create_account_logic.dart';
import 'package:p2/services/app_locale.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/input_validator.dart';

import '../controllers/continue_create_account_controller.dart';

class ContinueCreateAccountPage extends StatefulWidget {
  final String uid;
  final String email;

  const ContinueCreateAccountPage({super.key, required this.uid, required this.email});

  @override
  State<ContinueCreateAccountPage> createState() => _ContinueCreateAccountPageState();
}

class _ContinueCreateAccountPageState extends State<ContinueCreateAccountPage> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();

  File? idImage;
  File? faceImage;
  bool faceDetected = false;
  bool isLoading = false;
  bool agreedToPolicy = false;

  late ContinueCreateAccountController controller;

  @override
  void initState() {
    super.initState();
    controller = ContinueCreateAccountController();
  }

  Future<void> pickID() async {
    try {
      final img = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (img != null) {
        setState(() {
          idImage = File(img.path);
        });
      }
    } catch (error) {
      ErrorHandler.logError('Pick ID', error);
      _showMessage(ErrorHandler.getSafeError(error));
    }
  }

  Future<void> pickFace() async {
    try {
      final img = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (img != null) {
        setState(() {
          faceImage = File(img.path);
          faceDetected = true;
        });
      }
    } catch (error) {
      ErrorHandler.logError('Pick Face', error);
      _showMessage(ErrorHandler.getSafeError(error));
    }
  }

  void validateAndContinue() async {
    if (isLoading) return;

    if (!agreedToPolicy) {
      _showMessage("You must agree to the Terms and Privacy Policy first.");
      return;
    }

    final firstName = InputValidator.sanitizeInput(firstNameController.text.trim());
    final lastName = InputValidator.sanitizeInput(lastNameController.text.trim());
    final phone = InputValidator.sanitizeInput(phoneController.text.trim());
    final birthDate = birthDateController.text.trim();

    final errors = ContinueCreateAccountLogic.validateAllFields(
      firstName: firstName,
      lastName: lastName,
      birthDate: birthDate,
      phone: phone,
      idImage: idImage,
      faceImage: faceImage,
      faceDetected: faceDetected,
    );

    if (errors.isNotEmpty) {
      _showMessage(errors.first);
      return;
    }

    setState(() => isLoading = true);

    try {
      _showMessage("Submitting for approval...");

      await controller.submit(
        uid: widget.uid,
        email: widget.email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        birthDate: birthDate,
        idImage: idImage!,
        faceImage: faceImage!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You are submitted for approval")),
      );
      Navigator.pushNamed(context, '/login');

    } catch (e) {
      ErrorHandler.logError('Submit Approval', e);
      _showMessage(ErrorHandler.getSafeError(e));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showMessage(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  void _showPolicyDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Terms & Privacy Policy"),
        content: const SingleChildScrollView(
          child: Text(
            "Here goes our full terms and privacy policy text...\n\n"
                "Our data usage, storage, responsibility, etc.",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLocale.locale,
      builder: (context, locale, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 30),

                      // First Name
                      TextField(
                        controller: firstNameController,
                        decoration: InputDecoration(
                          labelText: "First Name",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Last Name
                      TextField(
                        controller: lastNameController,
                        decoration: InputDecoration(
                          labelText: "Last Name",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Birth Date
                      TextField(
                        controller: birthDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: "Birth Date",
                          hintText: "Select your birth date",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime(2000),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );

                          if (pickedDate != null) {
                            birthDateController.text = ContinueCreateAccountLogic.formatDate(pickedDate);
                            setState(() {});
                          }
                        },
                      ),

                      const SizedBox(height: 25),

                      // Phone Number
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black54),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text(
                              "+962",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: "Phone Number",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // Images
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(AppLocale.t('add_id_photo')),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: pickID,
                                  child: Container(
                                    height: 55,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black54),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Center(
                                      child: idImage != null
                                          ? const Icon(Icons.check_circle, 
                                              color: Colors.green, size: 28)
                                          : const Icon(Icons.image, size: 28),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(AppLocale.t('face_scan')),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: pickFace,
                                  child: Container(
                                    height: 55,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black54),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Center(
                                      child: faceDetected
                                          ? const Icon(Icons.face, 
                                              color: Colors.green, size: 28)
                                          : const Icon(Icons.face, size: 28),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      Row(
                        children: [
                          Checkbox(
                            value: agreedToPolicy,
                            onChanged: (v) {
                              setState(() {
                                agreedToPolicy = v ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: _showPolicyDialog,
                              child: const Text(
                                "I agree to the Terms & Privacy Policy",
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8A005D),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: isLoading ? null : validateAndContinue,
                                child: isLoading
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            AppLocale.t('continue'),
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.arrow_forward, 
                                              color: Colors.white),
                                        ],
                                      ),
                              ),
                              const SizedBox(height: 15),

                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 50, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(context, '/create');
                                },
                                child: Text(
                                  AppLocale.t('Back'),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
