// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:p2/services/firestore_service.dart';
import 'package:p2/services/storage_service.dart';
import 'app_locale.dart';

class PhonePage extends StatefulWidget {
  final String uid;
  final String email;

  const PhonePage({
    super.key,
    required this.uid,
    required this.email,
  });

  @override
  State<StatefulWidget> createState() => _PhonePageState();
}

class _PhonePageState extends State<PhonePage> {
  final TextEditingController phoneController = TextEditingController();
  //final TextEditingController firstNameController = TextEditingController();
  //final TextEditingController lastNameController = TextEditingController();
 // final TextEditingController birthDateController = TextEditingController();

  File? idImage;
  File? faceImage;
  bool faceDetected = false;

  Future pickID() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() {
        idImage = File(img.path);
      });
    }
  }

  Future pickFace() async {
    final img = await ImagePicker().pickImage(source: ImageSource.camera);
    if (img != null) {
      setState(() {
        faceImage = File(img.path);
        faceDetected = true;
      });
    }
  }

  void validateAndContinue() async {
    try {

      if (idImage == null) {
        showMsg("Please upload your ID photo");
        return;
      }

      if (faceImage == null || faceDetected == false) {
        showMsg("Please complete a valid face scan");
        return;
      }

      String idUrl = await StorageService.uploadUserImage(
        widget.uid,
        idImage!,
        "idPhoto.jpg",
      );

      String selfieUrl = await StorageService.uploadUserImage(
        widget.uid,
        faceImage!,
        "selfie.jpg",
      );

      await FirestoreService.submitUserForApproval(
        uid: widget.uid,
        email: widget.email,
        //firstName: firstNameController.text.trim(),
       // lastName: lastNameController.text.trim(),
        phone: phoneController.text.trim(),
        //birthDate: birthDateController.text.trim(),
        idPhotoUrl: idUrl,
        selfiePhotoUrl: selfieUrl,
      );

     /* Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PendingApprovalScreen()),
      );*/
    } catch (e) {
      print("Error submitting user: $e");
    }
    /*String phone = phoneController.text.trim();

    if (phone.isEmpty) {
      showMsg("Please enter your phone number");
      return;
    }

    Navigator.pushNamed(
      context,
      '/enterCode',
      arguments: {
        "phone": "+962$phone",
        "idImage": idImage,
        "faceImage": faceImage,
      },
    );*/

  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
                      SizedBox(height: 30),

                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black54),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              "+962",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: AppLocale.t('phone_number'),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 25),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(AppLocale.t('add_id_photo')),
                                SizedBox(height: 8),
                                GestureDetector(
                                  onTap: pickID,
                                  child: Container(
                                    height: 55,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black54),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Center(
                                      child: Icon(Icons.image, size: 28),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(AppLocale.t('face_scan')),
                                SizedBox(height: 8),
                                GestureDetector(
                                  onTap: pickFace,
                                  child: Container(
                                    height: 55,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black54),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Center(
                                      child: Icon(Icons.face, size: 28),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 40),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF8A005D),
                                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: validateAndContinue,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      AppLocale.t('continue'),
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, color: Colors.white),
                                  ],
                                ),
                              ),
                              SizedBox(height: 15),

                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(context, '/create');
                                },
                                child: Text(
                                  AppLocale.t('Back'),
                                  style: TextStyle(color: Colors.white),
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



