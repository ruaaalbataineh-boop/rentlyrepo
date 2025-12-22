import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:p2/services/firestore_service.dart';
import 'AddItemPage .dart';
import 'QrPage.dart';
import 'bottom_nav.dart';

class OwnerItemsPage extends StatefulWidget {
  const OwnerItemsPage({super.key});

  @override
  State<OwnerItemsPage> createState() => _OwnerItemsPageState();
}

class _OwnerItemsPageState extends State<OwnerItemsPage> {
  int selectedTab = 0;

  String get ownerUid => FirebaseAuth.instance.currentUser!.uid;

  // ===== COUNTERS =====

Widget myItemsCounter() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection("items")
        .where("ownerId", isEqualTo: ownerUid)
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const SizedBox();
      final count = snapshot.data!.docs.length;
      if (count == 0) return const SizedBox();

      return _counterBadge(count);
    },
  );
}

Widget requestsCounter() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection("rentalRequests")
        .where("itemOwnerUid", isEqualTo: ownerUid)
        .where("status", isEqualTo: "pending")
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const SizedBox();
      final count = snapshot.data!.docs.length;
      if (count == 0) return const SizedBox();

      return _counterBadge(count);
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
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(size, isSmall),
          SizedBox(height: size.height * 0.02),
          
          
          ///counter 
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

  // HEADER
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
                //change
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

  // MY ITEMS TAB
  Widget _buildMyItems() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("items")
          .where("ownerId", isEqualTo: ownerUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

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
            final data = doc.data() as Map<String, dynamic>;
            return _buildItemCard(data);
          }).toList(),
        );
      },
    );
  }

  // REQUESTS TAB
  Widget _buildIncomingRequests() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("rentalRequests")
          .where("itemOwnerUid", isEqualTo: ownerUid)
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Text("No requests yet.", style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _buildRequestCard(doc.id, data);
          }).toList(),
        );
      },
    );
  }

  // REQUEST CARD
  Widget _buildRequestCard(String requestId, Map<String, dynamic> data) {
    final status = data["status"] ?? "pending";
    final itemTitle = data["itemTitle"] ?? "Unknown Item";
    final renterId = data["customerUid"] ?? "Unknown User";

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: Column(
        children: [
          // TOP ROW WITH ACTION ICONS
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: Text(
                    itemTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text("Status: $status"),
                ),
              ),

              // Small ACCEPT / REJECT icons (only if pending)
              if (status == "pending") ...[
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  iconSize: 26,
                  onPressed: () async {
                    try {
                      await FirestoreService.updateRentalRequestStatus(
                        requestId,
                        "accepted",
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Request accepted")),
                      );
                    } on FirebaseFunctionsException catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.message ?? "Cannot accept this request",
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  iconSize: 26,
                  onPressed: () async {
                    await FirestoreService.updateRentalRequestStatus(
                      requestId,
                      "rejected",
                    );
                  },
                ),
              ],
              if (status == "accepted")
                IconButton(
                  icon: const Icon(Icons.qr_code, size: 28),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QrPage(qrToken: data["qrToken"]),
                      ),
                    );
                  },
                ),
              const SizedBox(width: 6),
            ],
          ),

          // EXPANSION SECTION
          ExpansionTile(
            title: const Text("View Details"),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Renter: $renterId"),
                    Text("Rental Type: ${data["rentalType"]}"),
                    Text("Quantity: ${data["rentalQuantity"]}"),
                    Text("Start: ${data["startDate"]}"),
                    Text("End: ${data["endDate"]}"),
                    if (data["pickupTime"] != null)
                      Text("Pickup: ${data["pickupTime"]}"),
                    Text("Total Price: JOD ${data["totalPrice"]}"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ACCEPT / REJECT BUTTONS
  Widget _buildAcceptRejectButtons(String requestId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, foregroundColor: Colors.white),
          onPressed: () {
            FirebaseFirestore.instance
                .collection("rentalRequests")
                .doc(requestId)
                .update({"status": "accepted"});
          },
          child: const Text("Accept"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () {
            FirebaseFirestore.instance
                .collection("rentalRequests")
                .doc(requestId)
                .update({"status": "rejected"});
          },
          child: const Text("Reject"),
        ),
      ],
    );
  }

  // ITEM CARD
  Widget _buildItemCard(Map<String, dynamic> data) {
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
        title: Text(data["name"] ?? "No name",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${data["category"]} → ${data["subCategory"]}"),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Description: ${data["description"] ?? ""}"),
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
                      : "⭐ $avgRating ($ratingCount reviews)",
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
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              url,
                              height: 110,
                              width: 110,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
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
                        (entry) =>
                        Text("• ${entry.key}: JOD ${entry.value}",
                            style: const TextStyle(fontSize: 14)),
                  ),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
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
