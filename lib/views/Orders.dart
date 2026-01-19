import 'package:flutter/material.dart';
import 'package:p2/WalletPage.dart';
import 'package:p2/models/rental_request.dart';
import 'package:p2/views/rate_product_page.dart';
import 'package:p2/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'QrPage.dart';
import 'QrScannerPage.dart';
import '../controllers/orders_controller.dart';
import '../services/app_locale.dart';
import '../widgets/bottom_nav.dart';

class OrdersPage extends StatefulWidget {
  final int initialTab;
  const OrdersPage({super.key, this.initialTab = 0});

  static const routeName = '/orders';

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late int selectedTab;
  OrdersController? _controller;
  bool _inited = false;

  @override
void initState() {
  super.initState();
  selectedTab = widget.initialTab;
}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;

    final auth = context.read<AuthService>();
    final uid = auth.currentUid;

    if (uid == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
      });
      return;
    }

    _controller = OrdersController(renterUid: uid);
    _inited = true;
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
          //bottomNavigationBar: const SharedBottomNav(currentIndex: 1),
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
                Navigator.pushNamed(context, WalletHomePage.routeName);
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
        _buildTabWithCount(0, screenWidth),
        SizedBox(width: small ? 8 : 16),
        _buildTabWithCount(1, screenWidth),
        SizedBox(width: small ? 8 : 16),
        _buildTabWithCount(2, screenWidth),
      ],
    );
  }

  Widget _buildTabWithCount(int index, double screenWidth) {
    final title = _controller!.getTabTitle(index, AppLocale.t);
    bool active = selectedTab == index;
    bool isSmall = screenWidth < 380;

    return StreamBuilder<int>(
      stream: _controller!.getRequestsCountStream(index),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmall ? 11 : 14,
                    color: active
                        ? const Color(0xFF8A005D)
                        : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8A005D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildTabContent(double screenWidth) {
    return _buildRequestStream(screenWidth);
  }

  Widget _buildRequestStream(double screenWidth) {
    return StreamBuilder<List<RentalRequest>>(
      key: ValueKey(selectedTab),
      stream: _controller!.getRequestsStream(selectedTab),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data!;
        if (requests.isEmpty) {
          return Center(
            child: Text(
              _controller!.getEmptyTextForTab(selectedTab, AppLocale.t),
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

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text(
          "Are you sure you want to delete this rental request?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    ) ??
        false;
  }

  Widget _buildReviewButton(RentalRequest req) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RateProductPage(
              requestId: req.id,
              itemTitle: req.itemTitle,
              ownerName: req.ownerName,
              renterName: req.renterName,
              isRenter: true,
            ),
          ),
        );

        if (result == true) {
          setState(() {});
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF8A005D),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "Review",
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildReviewedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade600,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.check, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text(
            "Reviewed",
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestTile(RentalRequest req) {
    final requestDetails = _controller!.getRequestDetails(req);

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

                if (req.status == "pending") ...[
                  IconButton(
                    icon: const Icon(Icons.delete, size: 26, color: Colors.red),
                    tooltip: "Delete request",
                    onPressed: () async {
                      final confirmed = await _confirmDelete(context);
                      if (!confirmed) return;

                      await _controller!.deleteIfPending(req);
                    },
                  ),
                ],
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
                            requestId: req.id,
                            isReturnPhase: true,
                          ),
                        ),
                      );
                    },
                  ),
                ],
                if (req.status == "ended" || req.status == "cancelled") ...[
                  if (req.reviewedByRenterAt == null)
                    _buildReviewButton(req)
                  else
                    _buildReviewedBadge(),
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
