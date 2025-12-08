import 'package:flutter/material.dart';
import 'package:p2/AddItemPage%20.dart';
import 'Category_Equipment_Page.dart';
import 'Chats_Page.dart';
import 'Orders.dart';
import 'Setting.dart';
import 'bottom_nav.dart';

class EquipmentCategory {
  final String id;
  final String title;
  final IconData icon;
  bool isFavorite;

  EquipmentCategory({
    required this.id,
    required this.title,
    required this.icon,
    this.isFavorite = false,
  });
}

final DUMMY_CATEGORIES = [
  EquipmentCategory(id: 'c1', title: 'Electronics', icon: Icons.electrical_services),
  EquipmentCategory(id: 'c2', title: 'Computers & Technology', icon: Icons.laptop),
  EquipmentCategory(id: 'c3', title: 'Sports & Camping', icon: Icons.directions_bike),
  EquipmentCategory(id: 'c4', title: 'Tools & Equipment', icon: Icons.build),
  EquipmentCategory(id: 'c5', title: 'Garden & Home', icon: Icons.grass),
  EquipmentCategory(id: 'c6', title: 'Clothing & Fashion', icon: Icons.checkroom),
];

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final filteredCategories = DUMMY_CATEGORIES.where((cat) {
      return cat.title.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          ClipPath(
            clipper: SideCurveClipper(),
            child: Container(
              height: 140,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Text(
                  "Categories",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search categories...",
                filled: true,
                fillColor: Colors.grey[200],
                prefixIcon: const Icon(Icons.search, color: Color(0xFF8A005D)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredCategories.length,
                    itemBuilder: (ctx, index) {
                      final category = filteredCategories[index];
                      return InkWell(
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            CategoryEquipmentPage.routeName,
                            arguments: {'id': category.id, 'title': category.title},
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 4,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(category.icon, size: 60, color: const Color(0xFF8A005D)),
                              const SizedBox(height: 10),
                              Text(
                                category.title,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const SharedBottomNav(currentIndex: 2),
    );
  }
}

class SideCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double radius = 40;
    Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height);
    path.arcToPoint(
      Offset(radius, size.height - radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    path.lineTo(size.width - radius, size.height - radius);
    path.arcToPoint(
      Offset(size.width, size.height),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
