import 'package:flutter/material.dart';
import 'package:p2/logic/orders_logic.dart';
import 'package:p2/WalletPage.dart';
import 'package:p2/models/rental_request.dart';
import 'QrPage.dart';
import 'QrScannerPage.dart';
import 'app_locale.dart';
import 'bottom_nav.dart';

class OrdersPage extends StatefulWidget {
  final int initialTab;
  const OrdersPage({super.key, this.initialTab = 0});

  static const routeName = '/orders';

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late int selectedTab;
  late OrdersLogic _logic;

  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialTab;
    _logic = OrdersLogic();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;

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
              Expanded(child: _buildTabContent(screenWidth)),
            ],
          ),
          bottomNavigationBar: const SharedBottomNav(currentIndex: 1),
        );
      },
    );
  }

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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletHomePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _buildTabs(double screenWidth, bool small) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildTab(_logic.getTabTitle(0, AppLocale.t), 0, screenWidth),
        SizedBox(width: small ? 20 : 40),
        buildTab(_logic.getTabTitle(1, AppLocale.t), 1, screenWidth),
        SizedBox(width: small ? 20 : 40),
        buildTab(_logic.getTabTitle(2, AppLocale.t), 2, screenWidth),
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
  
  Widget _buildTabContent(double screenWidth) {
    return _buildRequestStream(screenWidth);
  }

  Widget _buildRequestStream(double screenWidth) {
    return StreamBuilder<List<RentalRequest>>(
      stream: _logic.getRequestsStream(selectedTab),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data!;
        if (requests.isEmpty) {
          return Center(
            child: Text(
              _logic.getEmptyTextForTab(selectedTab, AppLocale.t),
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

  Widget _buildRequestTile(RentalRequest req) {
    final requestDetails = _logic.getRequestDetails(req);

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

            Row(
              children: [
                Text(
                  "Status: ${req.status}",
                  style: const TextStyle(fontSize: 14),
                ),

                const Spacer(),

                if (req.status == "accepted") ...[
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner,
                        size: 28, color: Color(0xFF1F0F46)),
                    tooltip: "Scan Pickup QR",
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
                if (req.status == "active") ...[
                  IconButton(
                    icon: const Icon(Icons.qr_code,
                        size: 28, color: Color(0xFF1F0F46)),
                    tooltip: "Show Return QR",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QrPage(
                            qrToken: req.qrToken!,
                            requestId: req.id,
                            isReturnPhase: true,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),

            const SizedBox(height: 8),

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
                       
                        ...requestDetails.entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text("${entry.key}: ${entry.value}"),
                          ),
                        ).toList(),
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
