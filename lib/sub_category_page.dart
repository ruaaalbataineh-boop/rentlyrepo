import 'package:flutter/material.dart';
import 'ProductListPage.dart';

class SubCategoryPage extends StatelessWidget {
  final String categoryId;
  final String categoryTitle;

  const SubCategoryPage({
    super.key,
    required this.categoryId,
    required this.categoryTitle,
  });

  static final Map<String, List<Map<String, dynamic>>> subCategories = {
    "c1": [
      {"title": "Camera & Photography", "icon": Icons.photo_camera},
      {"title": "Audio & Video", "icon": Icons.speaker},
    ],
    "c2": [
      {"title": "Mobiles", "icon": Icons.phone_android},
      {"title": "Laptops", "icon": Icons.laptop_mac},
      {"title": "Printers", "icon": Icons.print},
      {"title": "Projectors", "icon": Icons.video_camera_back},
      {"title": "Servers", "icon": Icons.dns},
    ],
    "c3": [
      {"title": "Gaming Devices", "icon": Icons.sports_esports},
    ],
    "c4": [
      {"title": "Bicycles", "icon": Icons.pedal_bike},
      {"title": "Books", "icon": Icons.menu_book},
      {"title": "Skates & Scooters", "icon": Icons.roller_skating_outlined},
      {"title": "Camping", "icon": Icons.park},
    ],
    "c5": [
      {"title": "Maintenance Tools", "icon": Icons.build},
      {"title": "Medical Devices", "icon": Icons.monitor_heart},
      {"title": "Cleaning Equipment", "icon": Icons.cleaning_services},
    ],
    "c6": [
      {"title": "Garden Equipment", "icon": Icons.yard_outlined},
      {"title": "Home Supplies", "icon": Icons.home},
    ],
    "c7": [
      {"title": "Men", "icon": Icons.man},
      {"title": "Women", "icon": Icons.woman},
      {"title": "Customs", "icon": Icons.checkroom},
      {"title": "Baby Supplies", "icon": Icons.child_friendly},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final subs = subCategories[categoryId] ?? [];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ClipPath(
              clipper: SideCurveClipper(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 50, bottom: 40),
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
                    Expanded(
                      child: Text(
                        categoryTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GridView.builder(
                  itemCount: subs.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final sub = subs[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          ProductListPage.routeName,
                          arguments: {
                            "subcategory": sub["title"],
                            "category": categoryTitle,
                          },
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(sub["icon"], size: 55, color: Color(0xFF8A005D)),
                            SizedBox(height: 10),
                            Text(
                              sub["title"],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            )
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
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
