import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:p2/models/rental_request.dart';
import 'package:p2/services/firestore_service.dart';
import 'package:p2/QrPage.dart';
import 'package:p2/WalletPage.dart';
import 'QrScannerPage.dart';
import 'app_locale.dart';
import 'bottom_nav.dart';
import 'package:p2/user_manager.dart';

class OrdersPage extends StatefulWidget {
  final int initialTab;
  const OrdersPage({super.key, this.initialTab = 0});


  static const routeName = '/orders';

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late int selectedTab;

  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    final isSmallScreen = screenWidth < 360;
    final renterUid = UserManager.uid!;

    return ValueListenableBuilder<Locale>(
      valueListenable: AppLocale.locale,
      builder: (context, locale, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              _buildHeader(screenHeight, screenWidth, isSmallScreen),
              SizedBox(height: screenHeight * 0.02),
              _buildTabs(screenWidth, isSmallScreen),
              SizedBox(height: screenHeight * 0.03),
              Expanded(child: _buildTabContent(renterUid, screenWidth)),
            ],
          ),
          bottomNavigationBar: const SharedBottomNav(currentIndex: 1),
        );
      },
    );
  }

  // HEADER
  Widget _buildHeader(double screenHeight, double screenWidth, bool small) {
    return ClipPath(
      clipper: SideCurveClipper(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          top: screenHeight * 0.06,
          bottom: screenHeight * 0.07,
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
            SizedBox(width: screenWidth * 0.1),
            Text(
              AppLocale.t('orders'),
              style: TextStyle(
                fontSize: small ? 20 : 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            IconButton(
              icon: Icon(
                  Icons.payment, color: Colors.white, size: small ? 24 : 28),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const WalletHomePage()));
              },
            ),
          ],
        ),
      ),
    );
  }

  // TABS
  Widget _buildTabs(double screenWidth, bool small) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildTab(AppLocale.t('pending_orders'), 0, screenWidth),
        SizedBox(width: small ? 20 : 40),
        buildTab(AppLocale.t('active_orders'), 1, screenWidth),
        SizedBox(width: small ? 20 : 40),
        buildTab(AppLocale.t('previous_orders'), 2, screenWidth),
      ],
    );
  }

  Widget buildTab(String text, int index, double screenWidth) {
    bool active = selectedTab == index;
    bool isSmall = screenWidth < 380;

    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 10 : 18,
          vertical: isSmall ? 8 : 10,
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
              fontSize: isSmall ? 11 : 14,
              color: active ? const Color(0xFF8A005D) : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // TAB CONTENT
  Widget _buildTabContent(String renterUid, double screenWidth) {
    if (selectedTab == 0) {
      // PENDING (pending + accepted)
      return _buildRequestStream(
        renterUid,
        ["pending", "accepted"],
        AppLocale.t('no_pending_orders'),
        screenWidth,
      );
    } else if (selectedTab == 1) {
      // ACTIVE
      return _buildRequestStream(
        renterUid,
        ["active"],
        AppLocale.t('no_active_orders'),
        screenWidth,
      );
    } else {
      // PREVIOUS (ended + rejected)
      return _buildRequestStream(
        renterUid,
        ["ended", "rejected"],
        AppLocale.t('no_previous_orders'),
        screenWidth,
      );
    }
  }

  // STREAM BUILDER FOR EACH TAB
  Widget _buildRequestStream(String renterUid, List<String> statuses,
      String emptyText, double screenWidth) {
    return StreamBuilder<List<RentalRequest>>(
      stream: FirestoreService.getRenterRequestsByStatuses(renterUid, statuses),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Failed to load orders",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data!;
        if (requests.isEmpty) {
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

        return ListView(
          padding: EdgeInsets.all(screenWidth * 0.05),
          children: requests.map(_buildRequestTile).toList(),
        );
      },
    );
  }

  // EXPANSION TILE FOR EACH ORDER
  Widget _buildRequestTile(RentalRequest req) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            //  TITLE ROW
            Row(
              children: [
                const Icon(Icons.shopping_bag, color: Color(0xFF8A005D)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    req.itemTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            //  STATUS ROW WITH QR ICON ON RIGHT
            Row(
              children: [
                Text(
                  "Status: ${req.status}",
                  style: const TextStyle(fontSize: 14),
                ),

                const Spacer(),

                if (req.status == "accepted")
                  IconButton(
                    icon: const Icon(
                        Icons.qr_code_scanner, size: 28, color: Color(0xFF1F0F46)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QrScannerPage(requestId: req.id),
                        ),
                      );
                    },
                  ),
              ],
            ),

            const SizedBox(height: 8),

            //  EXPANSION TILE
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text("View Details"),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: const Text(
                      "Rental Details",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Owner name: ${req.ownerName}"),
                        Text("Rental Type: ${req.rentalType}"),
                        Text("Quantity: ${req.rentalQuantity}"),
                        Text("Start Date: ${req.startDate}"),
                        Text("End Date: ${req.endDate}"),
                        if (req.startTime != null)
                          Text("Start Time: ${req.startTime}"),
                        if (req.endTime != null)
                          Text("End Time: ${req.endTime}"),
                        Text("Pickup Time: ${req.pickupTime}"),
                        Text("Total Price: JOD ${req.totalPrice}"),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// CLIPPER
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
