import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:p2/services/firestore_service.dart';
import 'package:p2/services/storage_service.dart';
import 'EquipmentItem.dart';
import 'package:image_picker/image_picker.dart';

class AddItemPage extends StatefulWidget {
  const AddItemPage({super.key});

  @override
  _AddItemPageState createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  String? selectedCategory;
  File? pickedImage;
  Condition? selectedCondition = Condition.good;
  RentalType? selectedRentalType = RentalType.daily;

  final List<String> categories = [
    "Electronics",
    "Computers & Technology",
    "Sports & Camping",
    "Tools & Equipment",
    "Garden & Home",
    "Clothing & Fashion",
    "Others"
  ];

  Future pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> addItem() async {
    if (nameController.text.isEmpty ||
        descController.text.isEmpty ||
        priceController.text.isEmpty ||
        selectedCategory == null ||
        pickedImage == null ||
        selectedCondition == null ||
        selectedRentalType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    try {

      final ownerId = FirebaseAuth.instance.currentUser!.uid;

      String imageUrl = await StorageService.uploadUserImage(
        ownerId,
        pickedImage!,
        "${DateTime.now().millisecondsSinceEpoch}.jpg",
      );

      await FirestoreService.submitItemForApproval(
        ownerId: ownerId,
        name: nameController.text.trim(),
        description: descController.text.trim(),
        price: double.parse(priceController.text.trim()),
        category: selectedCategory!,
        imageUrls: [imageUrl],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item submitted for approval")),
      );

      Navigator.pop(context);

    } catch (e) {
      print("Error submitting item: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Item"),
        backgroundColor: const Color(0xFF8A005D),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InkWell(
              onTap: pickImage,
              child: Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: pickedImage == null
                    ? const Icon(Icons.camera_alt, size: 40)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(pickedImage!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Item Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Price / day (JD)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(),
              ),
              value: selectedCategory,
              items: categories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<Condition>(
              decoration: const InputDecoration(
                labelText: "Condition",
                border: OutlineInputBorder(),
              ),
              value: selectedCondition,
              items: Condition.values
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c == Condition.newCondition
                            ? "New"
                            : c == Condition.good
                                ? "Good"
                                : "Used"),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedCondition = val;
                });
              },
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<RentalType>(
              decoration: const InputDecoration(
                labelText: "Rental Type",
                border: OutlineInputBorder(),
              ),
              value: selectedRentalType,
              items: RentalType.values
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(r == RentalType.daily
                            ? "Daily"
                            : r == RentalType.weekly
                                ? "Weekly"
                                : "Monthly"),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedRentalType = val;
                });
              },
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: addItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8A005D),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  "Add Item",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
