import 'package:flutter/material.dart';
import '../controllers/sub_category_controller.dart';
import 'ProductListPage.dart';

class SubCategoryPage extends StatelessWidget {
  final String categoryId;
  final String categoryTitle;

  const SubCategoryPage({
    super.key,
    required this.categoryId,
    required this.categoryTitle,
  });

  @override
  Widget build(BuildContext context) {
    final subs = SubCategoryController.getSubCategories(categoryId);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: subs.isEmpty
                  ? _empty()
                  : Padding(
                padding: const EdgeInsets.all(12),
                child: GridView.builder(
                  itemCount: subs.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemBuilder: (_, i) {
                    final sub = subs[i];

                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          ProductListPage.routeName,
                          arguments: {
                            "category": categoryTitle,
                            "subCategory": sub["title"],
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
                            Icon(sub["icon"],
                                size: 55,
                                color: const Color(0xFF8A005D)),
                            const SizedBox(height: 10),
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                sub["title"],
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return ClipPath(
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
    );
  }

  Widget _empty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text("No sub-categories available",
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}

class SideCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const radius = 40.0;
    final path = Path();

    path.moveTo(0, 0);
    path.lineTo(0, size.height);

    path.arcToPoint(
      Offset(radius, size.height - radius),
      radius: const Radius.circular(radius),
      clockwise: true,
    );

    path.lineTo(size.width - radius, size.height - radius);

    path.arcToPoint(
      Offset(size.width, size.height),
      radius: const Radius.circular(radius),
      clockwise: true,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}