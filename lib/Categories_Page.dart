import 'package:flutter/material.dart';
import 'package:p2/AddItemPage%20.dart';
import 'Category_Equipment_Page.dart';
import 'Chats_Page.dart';
import 'Orders.dart';
import 'Setting.dart';


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

// ignore: non_constant_identifier_names
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
  int selectedBottom = -1;

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
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),

          Expanded(
            child: filteredCategories.isEmpty
                ? const Center(
                    child: Text(
                      "No categories found",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
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

      bottomNavigationBar: Container(
        height: 70,
        decoration: const BoxDecoration(
          color: Color(0xFF1B2230),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildBottomIcon(Icons.settings, 0),
            buildBottomIcon(Icons.inventory_2_outlined, 1),
            buildBottomIcon(Icons.add, 2),
            buildBottomIcon(Icons.chat_bubble_outline, 3),
            buildBottomIcon(Icons.home_outlined, 4),
          ],
        ),
      ),
    );
  }

  Widget buildBottomIcon(IconData icon, int index) {
    bool active = selectedBottom == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedBottom = index;
        });

        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SettingPage()),
          );
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OrdersPage()),
          );
        } else if (index == 2) {
        
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddItemPage()),
          );
        } else if (index == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ChatsPage()),
          );
        } else if (index == 4) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CategoryPage()),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: EdgeInsets.only(bottom: active ? 8 : 0),
        padding: const EdgeInsets.all(12),
        decoration: active
            ? BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              )
            : null,
        child: Icon(
          icon,
          size: active ? 32 : 26,
          color: active ? Colors.black : Colors.white70,
        ),
      ),
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

