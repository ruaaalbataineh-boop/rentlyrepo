import 'package:flutter/material.dart';
import 'package:p2/AddItemPage .dart';
import 'package:p2/EquipmentItem.dart';
import 'package:p2/app_locale.dart';
import 'bottom_nav.dart';

class OwnerItemsPage extends StatefulWidget {
  const OwnerItemsPage({super.key});

  @override
  State<OwnerItemsPage> createState() => _OwnerItemsPageState();
}

class _OwnerItemsPageState extends State<OwnerItemsPage> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          ClipPath(
            clipper: SideCurveClipper(),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: screenHeight * 0.06,
                bottom: screenHeight * 0.07,
                left: screenWidth * 0.05,
                right: screenWidth * 0.05,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 30),
                  Text(
                    "My Items",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 20 : 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: isSmallScreen ? 24 : 28,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddItemPage(item: null),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: screenHeight * 0.02),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildTab("My Items", 0, screenWidth),
              SizedBox(width: isSmallScreen ? 20 : 40),
              buildTab("Rental Requests", 1, screenWidth),
            ],
          ),

          SizedBox(height: screenHeight * 0.03),

          Expanded(child: buildTabContent(screenWidth)),
        ],
      ),
      bottomNavigationBar: const SharedBottomNav(currentIndex: 4),
    );
  }

  Widget buildTab(String text, int index, double screenWidth) {
    bool active = selectedTab == index;
    final isSmallScreen = screenWidth < 380;

    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 18,
          vertical: isSmallScreen ? 8 : 10,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: active ? const Color(0xFF8A005D) : Colors.black,
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(25),
          color: active ? Colors.white : Colors.transparent,
        ),
        child: FittedBox(
          child: Text(
            text,
            maxLines: 1,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: active ? const Color(0xFF8A005D) : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTabContent(double screenWidth) {
    List<EquipmentItem> items;
    String emptyText;

    if (selectedTab == 0) {
      items = OwnerItemsManager.myItems;
      emptyText = "You haven't listed any items yet.";
    } else {
      items = OwnerItemsManager.incomingRequests;
      emptyText = "No incoming requests.";
    }

    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: TextStyle(
            fontSize: screenWidth < 360 ? 14 : 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(screenWidth * 0.05),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return Card(
          margin: EdgeInsets.only(bottom: screenWidth * 0.04),
          elevation: 3,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: Icon(
              item.icon,
              color: const Color(0xFF8A005D),
              size: screenWidth < 360 ? 28 : 35,
            ),
            title: Text(
              item.title,
              style: TextStyle(
                fontSize: screenWidth < 360 ? 16 : 18,
              ),
            ),
            subtitle: Text(
              selectedTab == 0
                  ? "Listed • JOD ${item.pricePerDay ?? 0}"
                  : "Requested • Tap to Review",
              style: TextStyle(
                fontSize: screenWidth < 360 ? 12 : 14,
              ),
            ),
            trailing: selectedTab == 1
                ? const Icon(Icons.arrow_forward, color: Color(0xFF1F0F46))
                : null,
            onTap: () {
              /// For incoming requests → open details page if needed later
            },
          ),
        );
      },
    );
  }
}

class OwnerItemsManager {
  static final List<EquipmentItem> myItems = [];
  static final List<EquipmentItem> incomingRequests = [];

  static void addMyItem(EquipmentItem item) {
    if (!myItems.contains(item)) myItems.add(item);
  }

  static void addIncomingRequest(EquipmentItem item) {
    if (!incomingRequests.contains(item)) incomingRequests.add(item);
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
