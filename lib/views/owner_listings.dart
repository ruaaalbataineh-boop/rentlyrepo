import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:p2/views/rate_product_page.dart';
import 'package:p2/services/auth_service.dart';
import 'package:p2/services/firestore_service.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/views/Equipment_Detail_Page.dart';
import 'package:provider/provider.dart';
import '../controllers/owner_listings_controller.dart';
import '../models/Item.dart';
import '../models/rental_request.dart';
import 'AddItemPage.dart';
import 'QrPage.dart';
import 'QrScannerPage.dart';
import 'UserProfilePage.dart';
import '../widgets/bottom_nav.dart';
import '../main_user.dart' as app;
import '../main_user.dart';

class OwnerItemsPage extends StatefulWidget {
  const OwnerItemsPage({super.key});

  @override
  State<OwnerItemsPage> createState() => OwnerItemsPageState();
}

class OwnerItemsPageState extends State<OwnerItemsPage> {
  int selectedTab = 0;
  bool _isLoading = true;

  late OwnerListingsController _controller;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final auth = context.read<AuthService>();
    final uid = auth.currentUid;

    if (uid == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
      });
      return;
    }

    _controller = OwnerListingsController(ownerUid: uid);
  }

  Item _mapToItem(Map<String, dynamic> data) {
    return Item.fromMap(data);
  }

  Widget myItemsCounter() {
    return StreamBuilder<int>(
      stream: _controller.myItemsCount(),
      builder: (c,s){
        if(!s.hasData || s.data==0) return SizedBox();
        return _counterBadge(s.data!);
      },
    );
  }

  Widget requestsCounter() {
    return StreamBuilder<int>(
      stream: _controller.pendingRequestsCount(),
      builder: (c,s){
        if(!s.hasData || s.data==0) return SizedBox();
        return _counterBadge(s.data!);
      },
    );
  }

  Widget _counterBadge(int count) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 154, 22, 81),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.isLoggedIn) {
      return const Scaffold(
        body: Center(child: Text('Please login to access this page')),
      );
    }

    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(size, isSmall),
          SizedBox(height: size.height * 0.02),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTab("My Items", 0, size.width),
              const SizedBox(width: 30),
              _buildTab("Requests", 1, size.width),
            ],
          ),

          SizedBox(height: size.height * 0.03),
          Expanded(child: _buildTabContent()),
        ],
      ),
      //bottomNavigationBar: const SharedBottomNav(currentIndex: 4),
    );
  }

  Widget _buildHeader(Size size, bool isSmall) {
    return ClipPath(
      clipper: SideCurveClipper(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          top: size.height * 0.06,
          bottom: size.height * 0.07,
          left: size.width * 0.05,
          right: size.width * 0.05,
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
              selectedTab == 0 ? "My Items" : "Requests",
              style: TextStyle(
                fontSize: isSmall ? 20 : 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            IconButton(
              key: const ValueKey('addItemButton'),
              icon: Icon(Icons.add,
                  color: Colors.white, size: isSmall ? 24 : 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddItemPage(key: ValueKey('addItemPage'))),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // TABS
  Widget _buildTab(String text, int index, double screenWidth) {
    bool active = selectedTab == index;
    bool isSmall = screenWidth < 380;

    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 12 : 18,
          vertical: isSmall ? 8 : 10,
        ),
        decoration: BoxDecoration(
          border: Border.all(
              color: active ? const Color(0xFF8A005D) : Colors.black, width: 1.2),
          borderRadius: BorderRadius.circular(25),
          color: active ? Colors.white : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: isSmall ? 12 : 14,
                color: active ? const Color(0xFF8A005D) : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (text == "My Items") myItemsCounter(),
            if (text == "Requests") requestsCounter(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (selectedTab == 0) {
      return _buildMyItems();
    } else {
      return _buildIncomingRequests();
    }
  }

  Widget _buildMyItems() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _controller.getMyItems(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final raw = snapshot.data!;
        if (raw.isEmpty) {
          return const Center(child: Text("No items yet"));
        }

        final items = raw.map(_mapToItem).toList();

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _buildMyItemTile(items[i]),
        );
      },
    );
  }

  Widget _buildIncomingRequests() {
    return StreamBuilder<List<RentalRequest>>(
      stream: _controller.getRequests(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data!;
        if (requests.isEmpty) {
          return const Center(child: Text("No requests"));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: requests.map(_buildRequestCard).toList(),
        );
      },
    );
  }

  Widget _buildRequestCard(RentalRequest req) {
    final status = req.status;
    final title = sanitizeString(req.itemTitle);
    final renter = sanitizeString(req.renterName);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Status: $status"),
                ),
              ),
              _buildActionButtons(req),
            ],
          ),
          _buildRequestDetails(req),
        ],
      ),
    );
  }

  Widget _buildActionButtons(RentalRequest req) {
    final id = req.id;
    final status = req.status;

    if (status == "pending") {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            iconSize: 32,
            onPressed: () async {
              final confirm = await showAcceptConfirmation(context);
              if (!confirm) return;

              await _controller.acceptRequest(id);
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            iconSize: 32,
            onPressed: () async {
              final confirm = await showRejectConfirmation(context);
              if (!confirm) return;

              await _controller.rejectRequest(id);
            },
          ),
        ],
      );
    }

    if (status == "accepted") {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.qr_code, size: 32),
            onPressed: () => _navigateToQrPage(id),
          ),
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.orange, size: 32),
            tooltip: "Force Active (Testing)",
            onPressed: () => _controller.forceActivate(id),
          ),
        ],
      );
    }

    if (status == "active") {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner,
                size: 32, color: Color(0xFF1F0F46)),
            tooltip: "Scan Return QR",
            onPressed: () => _navigateToQrScanner(id),
          ),
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.red, size: 32),
            tooltip: "Force ENDED (Testing)",
            onPressed: () => _controller.forceEnd(id),
          ),
        ],
      );
    }

    if (_controller.canReview(req)) {
      return _buildOwnerReviewButton(req.id, req);
    }

    if (req.reviewedByOwnerAt != null) {
      return _buildReviewedBadge();
    }

    return const SizedBox();
    }

  Widget _buildRequestDetails(RentalRequest req) {
    String formatTimestamp(DateTime? value) {
      if (value == null) return "-";
      return "${value.day}/${value.month}/${value.year}";
    }

    return ExpansionTile(
      title: const Text("View Details"),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: const Text(
              "Request Details",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfilePage(
                          userId: req.renterUid,
                          userName: req.renterName,
                          showReviewsFromRenters: false,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    "Renter name: ${req.renterName}",
                    style: const TextStyle(
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                      color: Color(0xFF8A005D),
                    ),
                  ),
                ),
                Text("Rental Type: ${req.rentalType}"),
                Text("Quantity: ${req.rentalQuantity}"),

                Text("Start: ${formatTimestamp(req.startDate)}"),
                Text("End: ${formatTimestamp(req.endDate)}"),

                if (req.pickupTime != null)
                  Text("Pickup: ${req.pickupTime}"),

                Text("Total Price: ${req.totalPrice}JD"),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<bool> showRejectConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Reject Rental Request",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to reject this rental request?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Reject", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<bool> showAcceptConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Accept Rental Request",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Are you sure you want to accept this rental request?",
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showPolicyDialog(context),
              child: const Text(
                "View agreement terms & policy",
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Back"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8A005D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Accept", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Agreement Terms & Policy"),
        content: const SingleChildScrollView(
          child: Text(
            "Here goes your rental agreement, responsibilities, penalties, and policies...",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildMyItemTile(Item item) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          EquipmentDetailPage.routeName,
          arguments: item,
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 3,
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
                child: item.images.isEmpty
                    ? Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, size: 50),
                )
                    : Image.network(
                  item.images.first,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.getPriceText(),
                    style: const TextStyle(
                      color: Color(0xFF8A005D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _navigateToQrPage(String requestId) {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QrPage(requestId: requestId),
        ),
      );
    } catch (e) {
      ErrorHandler.logError('Navigate to QR Page', e);
    }
  }

  void _navigateToQrScanner(String requestId) {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QrScannerPage(requestId: requestId, isReturnPhase: true),
        ),
      );
    } catch (e) {
      ErrorHandler.logError('Navigate to QR Scanner', e);
    }
  }

  Widget _buildOwnerReviewButton(String id, RentalRequest req) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RateProductPage(
              requestId: id,
              itemTitle: req.itemTitle,
              ownerName: req.ownerName,
              renterName: req.renterName,
              isRenter: false,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF8A005D),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text("Review",
            style: TextStyle(color: Colors.white, fontSize: 12)),
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

String sanitizeString(String input) {
    return input
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .trim();
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
