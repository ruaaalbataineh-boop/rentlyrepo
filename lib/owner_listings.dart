import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:p2/security/route_guard.dart';
import 'package:p2/services/firestore_service.dart';
import 'package:p2/security/error_handler.dart';
import 'AddItemPage .dart';
import 'QrPage.dart';
import 'QrScannerPage.dart';
import 'bottom_nav.dart';

class OwnerItemsPage extends StatefulWidget {
  const OwnerItemsPage({super.key});

  @override
  State<OwnerItemsPage> createState() => _OwnerItemsPageState();
}

class _OwnerItemsPageState extends State<OwnerItemsPage> {
  int selectedTab = 0;
  bool _isLoading = true;
  bool _isAuthenticated = false;

  String? get ownerUid {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (e) {
      ErrorHandler.logError('Get Owner UID', e);
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      
      _isAuthenticated = RouteGuard.isAuthenticated();
      
      if (!_isAuthenticated) {
        ErrorHandler.logSecurity('OwnerItemsPage', 'Unauthorized access attempt');
        await _redirectToLogin();
        return;
      }

   
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _loadInitialData();
      });
      
    } catch (error) {
      ErrorHandler.logError('Authentication Check', error);
      await _redirectToLogin();
    }
  }

  Future<void> _loadInitialData() async {
    try {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['tab'] is int) {
        setState(() {
          selectedTab = args['tab'];
        });
      }
    } catch (error) {
      ErrorHandler.logError('Load Initial Data', error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _redirectToLogin() async {
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }


  Widget myItemsCounter() {
    if (ownerUid == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("items")
          .where("ownerId", isEqualTo: ownerUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          ErrorHandler.logError('My Items Counter Stream', snapshot.error);
          return const SizedBox();
        }

        if (!snapshot.hasData) return const SizedBox();
        
        try {
          final count = snapshot.data!.docs.length;
          if (count == 0) return const SizedBox();
          return _counterBadge(count);
        } catch (e) {
          ErrorHandler.logError('My Items Counter Processing', e);
          return const SizedBox();
        }
      },
    );
  }

  Widget requestsCounter() {
    if (ownerUid == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("rentalRequests")
          .where("itemOwnerUid", isEqualTo: ownerUid)
          .where("status", isEqualTo: "pending")
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          ErrorHandler.logError('Requests Counter Stream', snapshot.error);
          return const SizedBox();
        }

        if (!snapshot.hasData) return const SizedBox();
        
        try {
          final count = snapshot.data!.docs.length;
          if (count == 0) return const SizedBox();
          return _counterBadge(count);
        } catch (e) {
          ErrorHandler.logError('Requests Counter Processing', e);
          return const SizedBox();
        }
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAuthenticated) {
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
      bottomNavigationBar: const SharedBottomNav(currentIndex: 4),
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
              icon: Icon(Icons.add,
                  color: Colors.white, size: isSmall ? 24 : 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddItemPage()),
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
    if (ownerUid == null) {
      return Center(
        child: Text(ErrorHandler.getSafeError('Authentication error')),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("items")
          .where("ownerId", isEqualTo: ownerUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          ErrorHandler.logError('My Items Stream', snapshot.error);
          return Center(
            child: Text(ErrorHandler.getSafeError(snapshot.error)),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        try {
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text("You haven't listed any items yet.",
                  style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: docs.map((doc) {
              try {
                final data = doc.data() as Map<String, dynamic>;
                return _buildItemCard(data);
              } catch (e) {
                ErrorHandler.logError('Build Item Card', e);
                return Container();  
              }
            }).toList(),
          );
        } catch (e) {
          ErrorHandler.logError('Process My Items', e);
          return Center(
            child: Text(ErrorHandler.getSafeError(e)),
          );
        }
      },
    );
  }

  Widget _buildIncomingRequests() {
    if (ownerUid == null) {
      return Center(
        child: Text(ErrorHandler.getSafeError('Authentication error')),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("rentalRequests")
          .where("itemOwnerUid", isEqualTo: ownerUid)
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          ErrorHandler.logError('Incoming Requests Stream', snapshot.error);
          return Center(
            child: Text(ErrorHandler.getSafeError(snapshot.error)),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        try {
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text("No requests yet.", style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: docs.map((doc) {
              try {
                final data = doc.data() as Map<String, dynamic>;
                return _buildRequestCard(doc.id, data);
              } catch (e) {
                ErrorHandler.logError('Build Request Card', e);
                return Container();
              }
            }).toList(),
          );
        } catch (e) {
          ErrorHandler.logError('Process Incoming Requests', e);
          return Center(
            child: Text(ErrorHandler.getSafeError(e)),
          );
        }
      },
    );
  }

  
  Widget _buildRequestCard(String requestId, Map<String, dynamic> data) {
    try {
      final status = data["status"] ?? "pending";
      final itemTitle = data["itemTitle"]?.toString() ?? "Unknown Item";
      
      // معالجة آمنة للبيانات الحساسة
      final safeItemTitle = _sanitizeString(itemTitle);
      final renterName = _sanitizeString(data["renterName"]?.toString() ?? "");
      
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 3,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: Text(
                      safeItemTitle,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Text("Status: $status"),
                  ),
                ),
                _buildActionButtons(requestId, status, data),
              ],
            ),
            _buildRequestDetails(data, renterName),
          ],
        ),
      );
    } catch (e) {
      ErrorHandler.logError('Build Request Card UI', e);
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(ErrorHandler.getSafeError(e)),
        ),
      );
    }
  }

  Widget _buildActionButtons(String requestId, String status, Map<String, dynamic> data) {
    if (status == "pending") {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            iconSize: 32,
            onPressed: () => _handleAcceptRequest(requestId),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            iconSize: 32,
            onPressed: () => _handleRejectRequest(requestId),
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
            onPressed: () => _navigateToQrPage(requestId),
          ),
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.orange, size: 32),
            tooltip: "Force Active (Testing)",
            onPressed: () => _forceActivateRental(requestId),
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
            onPressed: () => _navigateToQrScanner(requestId),
          ),
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.red, size: 32),
            tooltip: "Force ENDED (Testing)",
            onPressed: () => _forceEndRental(requestId),
          ),
        ],
      );
    }

    return const SizedBox();
  }

  Widget _buildRequestDetails(Map<String, dynamic> data, String renterName) {
    String formatTimestamp(dynamic value) {
      if (value == null) return "-";
      if (value is Timestamp) {
        final date = value.toDate();
        return "${date.day}/${date.month}/${date.year}";
      }
      return value.toString();
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
                  Text("Renter name: $renterName"),
                  Text("Rental Type: ${data["rentalType"]}"),
                  Text("Quantity: ${data["rentalQuantity"]}"),

                  Text("Start: ${formatTimestamp(data["startDate"])}"),
                  Text("End: ${formatTimestamp(data["endDate"])}"),
          
                  if (data["pickupTime"] != null)
                    Text("Pickup: ${data["pickupTime"]}"),
                  Text("Total Price: JOD ${data["totalPrice"]}"),
              ],
            ),
          ),
        ),
      ],
    );
  }

  
  Widget _buildItemCard(Map<String, dynamic> data) {
    try {
      final name = _sanitizeString(data["name"]?.toString() ?? "No name");
      final category = _sanitizeString(data["category"]?.toString() ?? "");
      final subCategory = _sanitizeString(data["subCategory"]?.toString() ?? "");
      final description = _sanitizeString(data["description"]?.toString() ?? "");
      
      final images = List<String>.from(data["images"] ?? []);
      final rental = Map<String, dynamic>.from(data["rentalPeriods"] ?? {});
      final latitude = data["latitude"];
      final longitude = data["longitude"];
      final avgRating = data["averageRating"] ?? 0.0;
      final ratingCount = data["ratingCount"] ?? 0;

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 3,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(12),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("$category → $subCategory"),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Description: $description"),
                  const SizedBox(height: 12),

                  const Text("Location:",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                      (latitude != null && longitude != null)
                          ? "Lat: $latitude\nLng: $longitude"
                          : "No location set",
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 12),

                  const Text("Ratings:",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    ratingCount == 0
                        ? "No ratings yet"
                        : " $avgRating ($ratingCount reviews)",
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 15),

                  if (images.isNotEmpty) ...[
                    const Text("Images:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 110,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: images.map((url) {
                          try {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  url,
                                  height: 110,
                                  width: 110,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    ErrorHandler.logError('Load Image', error);
                                    return Container(
                                      width: 110,
                                      height: 110,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.broken_image),
                                    );
                                  },
                                ),
                              ),
                            );
                          } catch (e) {
                            ErrorHandler.logError('Build Image Widget', e);
                            return Container();
                          }
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],

                  if (rental.isNotEmpty) ...[
                    const Text("Rental Periods:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    ...rental.entries.map(
                      (entry) => Text(
                        "• ${_sanitizeString(entry.key)}: JOD ${entry.value}",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      ErrorHandler.logError('Build Item Card UI', e);
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(ErrorHandler.getSafeError(e)),
        ),
      );
    }
  }

  // ========== SECURE HANDLER METHODS ==========

  Future<void> _handleAcceptRequest(String requestId) async {
    try {
      await FirestoreService.updateRentalRequestStatus(
        requestId,
        "accepted",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request accepted")),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      ErrorHandler.logError('Accept Request', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ErrorHandler.getSafeError(e.message ?? "Cannot accept this request"),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ErrorHandler.logError('Accept Request General', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getSafeError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRejectRequest(String requestId) async {
    try {
      await FirestoreService.updateRentalRequestStatus(
        requestId,
        "rejected",
      );
    } catch (e) {
      ErrorHandler.logError('Reject Request', e);
    }
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

  Future<void> _forceActivateRental(String requestId) async {
    try {
      await FirestoreService.confirmPickup(
        requestId: requestId,
        qrToken: "DEV_FORCE",
        force: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Rental forced to ACTIVE"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ErrorHandler.logError('Force Activate Rental', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getSafeError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  Future<void> _forceEndRental(String requestId) async {
    try {
      await FirestoreService.confirmReturn(
        requestId: requestId,
        qrToken: "DEV_FORCE",
        force: true,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Rental forced to END"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ErrorHandler.logError('Force End Rental', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getSafeError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  
  String _sanitizeString(String input) {
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
