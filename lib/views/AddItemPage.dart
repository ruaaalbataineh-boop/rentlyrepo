import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LengthLimitingTextInputFormatter;
import 'package:image_picker/image_picker.dart';
import 'package:p2/pick_location_page.dart';
import 'package:p2/services/auth_service.dart';
import 'package:p2/services/firestore_service.dart';
import 'package:p2/services/storage_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../Security/error_handler.dart';
import '../Security/input_validator.dart';
import '../controllers/add_item_controller.dart';

class AddItemPage extends StatefulWidget {
  const AddItemPage({super.key, this.existingItem});

  final Map<String, dynamic>? existingItem;

  @override
  AddItemPageState createState() => AddItemPageState();
}

class AddItemPageState extends State<AddItemPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController OriginalPriceController = TextEditingController();

  bool _isAuthenticated = false;

  String? selectedCategory;
  String? selectedSubCategory;

  double? latitude;
  double? longitude;
  
  Map<String, dynamic> rentalPeriods = {};
  String? newRentalPeriod;
  
  List<File> pickedImages = [];
  List<String> existingImageUrls = [];
  
  final categories = [
    "Electronics",
    "Computers & Mobiles",
    "Video Games",
    "Sports & Hobbies",
    "Tools & Devices",
    "Home & Garden",
    "Fashion & Clothing",
  ];
  
  final subCategories = {
    "Electronics": ["Cameras & Photography", "Audio & Video"],
    "Computers & Mobiles": [
      "Mobiles",
      "Laptops",
      "Printers",
      "Projectors",
      "Servers"
    ],
    "Video Games": ["Gaming Devices"],
    "Sports & Hobbies": ["Bicycle", "Books", "Skates & Scooters", "Camping"],
    "Tools & Devices": [
      "Maintenance Tools",
      "Medical Devices",
      "Cleaning Equipment"
    ],
    "Home & Garden": ["Garden Equipment", "Home Supplies"],
    "Fashion & Clothing": ["Men", "Women", "Customs", "Baby Supplies"],
  };
  
  final availableRentalPeriods = [
    "Daily",
    "Weekly",
    "Monthly",
    "Yearly"
  ];

  
  bool _isLoading = false;
  int _imageUploadAttempts = 0;
  final int _maxImageUploadAttempts = 3;

  @override
  void initState() {
    super.initState();
    
    
    _checkAuthentication();
    
    if (widget.existingItem != null) {
      final data = widget.existingItem!;
      nameController.text = InputValidator.sanitizeInput(data["name"] ?? "");
      descController.text = InputValidator.sanitizeInput(data["description"] ?? "");
      selectedCategory = data["category"];
      selectedSubCategory = data["subCategory"];
      rentalPeriods = Map<String, dynamic>.from(data["rentalPeriods"] ?? {});
      existingImageUrls = List<String>.from(data["images"] ?? []);
      
      if (data["insurance"] != null) {
        final insuranceData = Map<String, dynamic>.from(data["insurance"]);
        OriginalPriceController.text = insuranceData["itemOriginalPrice"]?.toString() ?? "";
      }
    }
  }

  void _checkAuthentication() {
    _isAuthenticated = FirebaseAuth.instance.currentUser != null;

    if (!_isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      });
    }
  }

  double getInsuranceRate(double itemPrice) {
    if (itemPrice <= 50) {
      return 0.0; 
    } else if (itemPrice <= 100) {
      return 0.10;
    } else if (itemPrice <= 500) {
      return 0.15; 
    } else {
      return 0.30; 
    }
  }
  
  double calculateInsuranceAmount() {
    if (OriginalPriceController.text.isEmpty) {
      return 0.0;
    }
    
    final originalPrice = double.tryParse(OriginalPriceController.text) ?? 0.0;
    final rate = getInsuranceRate(originalPrice);
    
    return originalPrice * rate;
  }
  
  String getInsuranceRateText(double itemPrice) {
    if (itemPrice <= 50) {
      return "0% (No insurance required)";
    } else if (itemPrice <= 100) {
      return "10%";
    } else if (itemPrice <= 500) {
      return "15%";
    } else {
      return "30%";
    }
  }

  Future<void> pickImages() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        showError("Authentication required");
        return;
      }

    
      if (pickedImages.length + existingImageUrls.length >= 10) {
        showError("Maximum 10 images allowed");
        return;
      }

      final images = await ImagePicker().pickMultiImage(
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      
      if (images != null) {
    
        for (final image in images) {
          final file = File(image.path);

          final fileSize = await file.length();
          if (fileSize > 5 * 1024 * 1024) {
            showError("Image too large (max 5MB): ${image.name}");
            continue;
          }
         
          final extension = image.path.split('.').last.toLowerCase();
          if (!['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
            showError("Invalid image format: ${image.name}");
            continue;
          }
        }

        setState(() {
          pickedImages.addAll(images.map((i) => File(i.path)).toList());
        });
      }
    } catch (error) {
      ErrorHandler.logError('Image Picking', error);
      showError("Failed to pick images");
    }
  }
  
  void removeImage(int index) {
    setState(() => pickedImages.removeAt(index));
  }
  
  void removeExistingImage(String url) {
    setState(() => existingImageUrls.remove(url));
  }
 
  void addRentalPeriod() {
    try {
      if (newRentalPeriod == null || priceController.text.isEmpty) {
        showError("Please select a rental period and enter a price.");
        return;
      }

      if (!InputValidator.hasNoMaliciousCode(priceController.text)) {
        showError("Invalid price format");
        return;
      }

      final rentalPrice = double.tryParse(priceController.text);

      if (rentalPrice == null || rentalPrice <= 0) {
        showError("Enter a valid price");
        return;
      }

      if (rentalPrice > 10000) {
        showError("Price cannot exceed 10,000 JD");
        return;
      }

      rentalPeriods[newRentalPeriod!] = rentalPrice;
      newRentalPeriod = null;
      priceController.clear();
      setState(() {});
    } catch (error) {
      ErrorHandler.logError('Add Rental Period', error);
      showError("Failed to add rental period");
    }
  }
  
  Future<void> pickLocation() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        showError("Authentication required");
        return;
      }

      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PickLocationPage()),
      );
      
      if (result != null && result is LatLng) {
        setState(() {
          latitude = result.latitude;
          longitude = result.longitude;
        });
      }
    } catch (error) {
      ErrorHandler.logError('Location Picking', error);
      showError("Failed to pick location");
    }
  }

  Future<void> saveItem() async {
    try {
      setState(() => _isLoading = true);

      final authService = context.read<AuthService>();

      await AddItemController.submitItem(
        authService: authService,
        name: nameController.text,
        description: descController.text,
        category: selectedCategory!,
        subCategory: selectedSubCategory!,
        originalPrice: double.parse(OriginalPriceController.text),
        rentalPeriods: rentalPeriods,
        latitude: latitude!,
        longitude: longitude!,
        pickedImages: pickedImages,
        existingImages: existingImageUrls,
      );

      showSuccess("Item submitted for approval");

      if (Navigator.canPop(context)) Navigator.pop(context);

    } catch (e) {
      showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(msg),
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  void showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text(msg),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    
    nameController.dispose();
    descController.dispose();
    priceController.dispose();
    OriginalPriceController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final smallScreen = MediaQuery.of(context).size.width < 360;
    
    return Scaffold(
      body: Column(
        children: [
          buildHeader(smallScreen),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    buildPhotoSection(),
                    const SizedBox(height: 16),
                    buildBasicInfoSection(),
                    const SizedBox(height: 16),
                    buildRentalPeriodSection(),
                    const SizedBox(height: 16),
                    buildInsuranceSection(),
                    const SizedBox(height: 16),
                    buildLocationSection(),
                    const SizedBox(height: 25),
                    buildSubmitButton(),
                  ],
                ),
              ),
          ),
        ],
      ),
    );
  }
  
  Widget buildHeader(bool smallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
            
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.existingItem == null ? "Add New Item" : "Edit Item",
              style: TextStyle(
                fontSize: smallScreen ? 20 : 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget buildPhotoSection() {
    return card(
      title: "Photos",
      icon: Icons.photo,
      child: Column(
        children: [
          InkWell(
            onTap: pickImages,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF8A005D)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate, color: Color(0xFF8A005D)),
                    SizedBox(height: 5),
                    Text("Add Photos (Max 10)"),
                  ],
                ),
              ),
            ),
          ),
          
          if (existingImageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: existingImageUrls.map((url) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        url, 
                        width: 90, 
                        height: 90, 
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 90,
                            height: 90,
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => removeExistingImage(url),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          child: Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
          
          if (pickedImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: pickedImages.asMap().entries.map((entry) {
                final index = entry.key;
                final file = entry.value;
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        file, 
                        width: 90, 
                        height: 90, 
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => removeImage(index),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          child: Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ]
        ],
      ),
    );
  }
  
  Widget buildBasicInfoSection() {
    return card(
      title: "Basic Information",
      icon: Icons.info_outline,
      child: Column(
        children: [
          TextField(
            controller: nameController,
            maxLines: 1,
            decoration: InputDecoration(
              labelText: "Item Name *",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            inputFormatters: [
              LengthLimitingTextInputFormatter(100), // Security: limit length
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: "Description",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            inputFormatters: [
              LengthLimitingTextInputFormatter(500), // Security: limit length
            ],
          ),
          const SizedBox(height: 12),
          
          DropdownButtonFormField<String>(
            value: selectedCategory,
            decoration: dropdownDecoration("Category *"),
            items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (val) {
              setState(() {
                selectedCategory = val;
                selectedSubCategory = null;
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          DropdownButtonFormField<String>(
            value: selectedSubCategory,
            decoration: dropdownDecoration("Sub Category *"),
            items: selectedCategory == null
                ? []
                : subCategories[selectedCategory]!
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (val) => setState(() => selectedSubCategory = val),
          ),
        ],
      ),
    );
  }
  
  Widget buildInsuranceSection() {
    final insuranceAmount = calculateInsuranceAmount();
    final itemPriceText = OriginalPriceController.text;
    final itemPrice = double.tryParse(itemPriceText) ?? 0.0;
    final insuranceRateText = getInsuranceRateText(itemPrice);
    
    return card(
      title: "Insurance",
      icon: Icons.shield,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "For safety, insurance is required for all rentals.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          
          const SizedBox(height: 16),
          
          TextField(
            controller: OriginalPriceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Item Original Price (JD) *",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey[50],
              suffixText: "JD",
            ),
            inputFormatters: [
              LengthLimitingTextInputFormatter(10), // Security: limit length
            ],
            onChanged: (_) => setState(() {}),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Insurance Summary:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F0F46),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                if (itemPriceText.isNotEmpty) ...[
                  _buildInsuranceSummaryRow("Item Price:", 
                    "${itemPrice.toStringAsFixed(2)} JD"),
                  
                  _buildInsuranceSummaryRow("Insurance Rate:", 
                    insuranceRateText),
                  
                  _buildInsuranceSummaryRow("Insurance Amount:", 
                    "${insuranceAmount.toStringAsFixed(2)} JD"),
                ] else ...[
                  const Text(
                    "Enter item original price to calculate insurance",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInsuranceSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style:  TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget buildRentalPeriodSection() {
    return card(
      title: "Rental Periods",
      icon: Icons.access_time,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: newRentalPeriod,
            decoration: dropdownDecoration("Select Rental Period"),
            items: availableRentalPeriods
                .where((rp) => !rentalPeriods.containsKey(rp))
                .map((rp) => DropdownMenuItem(value: rp, child: Text(rp)))
                .toList(),
            onChanged: (val) => setState(() => newRentalPeriod = val),
          ),
          
          const SizedBox(height: 10),
          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Price (JD)",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey[50],
              suffixText: "JD",
            ),
            inputFormatters: [
              LengthLimitingTextInputFormatter(10), // Security: limit length
            ],
          ),
          const SizedBox(height: 10),
          
          ElevatedButton.icon(
            onPressed: addRentalPeriod,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Add Period",
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8A005D),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          
          const SizedBox(height: 10),
          
          Column(
            children: rentalPeriods.entries.map((e) {
              return ListTile(
                title: Text("${e.key}"),
                subtitle: Text("JD ${e.value}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() => rentalPeriods.remove(e.key));
                  },
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }
  
  Widget buildLocationSection() {
    return card(
      title: "Location",
      icon: Icons.location_on,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            latitude == null || longitude == null
                ? "No location selected"
                : "Lat: $latitude\nLng: $longitude",
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 10),
          
          ElevatedButton(
            onPressed: pickLocation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8A005D),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("Pick Location",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Widget buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : saveItem,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8A005D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                widget.existingItem == null ? "Submit Item" : "Update Item",
                style: const TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w600, 
                  color: Colors.white
                ),
              ),
      ),
    );
  }
  
  InputDecoration dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }
  
  Widget card({required String title, required IconData icon, required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF8A005D)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold, 
                    color: Color(0xFF1F0F46)
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
