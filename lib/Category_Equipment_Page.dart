import 'package:flutter/material.dart';
import 'Fake data.dart';
import 'EquipmentItem.dart';
import 'ProductListPage.dart';

class CategoryEquipmentPage extends StatefulWidget {
  const CategoryEquipmentPage({super.key});
  static const routeName = '/category-equipment';

  @override
  State<CategoryEquipmentPage> createState() => _CategoryEquipmentPageState();
}

class _CategoryEquipmentPageState extends State<CategoryEquipmentPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final routeArgs =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>?;

    if (routeArgs == null) return const SizedBox();

    final categoryId = routeArgs['id']!;
    final categoryTitle = routeArgs['title']!;

   
    final allItems = DUMMY_EQUIPMENT
        .where((eq) => eq.categories.contains(categoryId))
        .toList();

   
    final displayedItems = allItems
        .where((item) =>
            item.title.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
           
            ClipPath(
              clipper: SideCurveClipper(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                    top: 50, bottom: 40, left: 16, right: 16),
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
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        categoryTitle,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),

           
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search items...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() => searchQuery = value),
              ),
            ),

        
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: displayedItems.isEmpty
                    ? const Center(
                        child: Text(
                          'No items found!',
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: displayedItems.length,
                        itemBuilder: (ctx, index) {
                          final item = displayedItems[index];
                          return EquipmentCard(item: item);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EquipmentCard extends StatelessWidget {
  final EquipmentItem item;
  const EquipmentCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
       
        Navigator.pushNamed(
          context,
          ProductListPage.routeName,
          arguments: {
            'type': item.title,   
            'title': item.title, 
          },
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 60, color: const Color(0xFF8A005D)),
            const SizedBox(height: 10),
            Text(
              item.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
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


