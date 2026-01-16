import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ItemManagementPage extends StatelessWidget {
  const ItemManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Column(
          children: [
            Container(
              height: 180,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 28),
                        onPressed: () => context.go('/dashboard'),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Item Management",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  TabBar(
                    indicator: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Pending Items"),
                            SizedBox(width: 6),
                            PendingItemsCounter(),
                          ],
                        ),
                      ),
                      Tab(text: "Rejected Items"),
                      Tab(text: "Approved Items"),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                children: [
                  PendingItemsTab(),
                  RejectedItemsTab(),
                  ApprovedItemsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// COUNTER
class PendingItemsCounter extends StatelessWidget {
  const PendingItemsCounter({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("pending_items")
          .where("status", isEqualTo: "pending")
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final count = snapshot.data!.docs.length;
        if (count == 0) return const SizedBox();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.red,
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
      },
    );
  }
}

/// SHARED EXPANSION CARD FOR ALL ITEM TYPES

class ItemExpansionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String itemId;
  final Widget actions;

  const ItemExpansionCard({
    super.key,
    required this.data,
    required this.itemId,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final images = List<String>.from(data["images"] ?? []);
    final rental = Map<String, dynamic>.from(data["rentalPeriods"] ?? {});
    final latitude = data["latitude"];
    final longitude = data["longitude"];
    final rating = data["rating"] ?? 0.0;
    final reviews = List<Map<String, dynamic>>.from(data["reviews"] ?? []);

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 3,
      color: const Color(0xFFF5F1FF),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data["name"] ?? "No Title",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${data["category"] ?? ""} • ${data["subCategory"] ?? ""}",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            actions,
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Description: ${data["description"] ?? ""}",
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 10),
                Text("Owner ID: ${data["ownerId"] ?? ""}",
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 10),

                if (latitude != null && longitude != null) ...[
                  const Text("Location:",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text("• Latitude: $latitude"),
                  Text("• Longitude: $longitude"),
                  const SizedBox(height: 12),
                ],

                if (images.isNotEmpty) ...[
                  const Text("Images:",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            images[index],
                            height: 120,
                            width: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                ],

                if (rental.isNotEmpty) ...[
                  const Text("Rental Periods:",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: rental.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          "• ${entry.key}: JOD ${entry.value}",
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                if (data["status"] == "approved") ...[
                  const Divider(),
                  const Text("Rating:",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text("⭐ ${rating.toStringAsFixed(1)} / 5.0"),
                  const SizedBox(height: 10),
                  const Text("Reviews:",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  if (reviews.isEmpty)
                    const Text("No reviews yet."),
                  ...reviews.map((r) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text("• ${r["review"]} (⭐ ${r["rating"]})"),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// TABS
class PendingItemsTab extends StatelessWidget {
  const PendingItemsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("pending_items")
          .where("status", isEqualTo: "pending")
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No pending items"));

        return ListView(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ItemExpansionCard(
              data: data,
              itemId: doc.id,
              actions: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseFunctions.instance
                          .httpsCallable("approveItem")
                          .call({"itemId": doc.id});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Item Approved")),
                      );
                    },
                    icon: const Icon(Icons.check),
                    label: const Text("Approve"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseFunctions.instance
                          .httpsCallable("rejectItem")
                          .call({"itemId": doc.id});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Item Rejected")),
                      );
                    },
                    icon: const Icon(Icons.close),
                    label: const Text("Reject"),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class RejectedItemsTab extends StatelessWidget {
  const RejectedItemsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("pending_items")
          .where("status", isEqualTo: "rejected")
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No rejected items"));

        return ListView(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ItemExpansionCard(
              data: data,
              itemId: doc.id,
              actions: const Text("Rejected",
                  style: TextStyle(color: Colors.red, fontSize: 16)),
            );
          }).toList(),
        );
      },
    );
  }
}

class ApprovedItemsTab extends StatelessWidget {
  const ApprovedItemsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("items")
          .where("status", isEqualTo: "approved")
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return const Center(child: Text("No approved items"));

        return ListView(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ItemExpansionCard(
              data: data,
              itemId: doc.id,
              actions: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  FirebaseFirestore.instance
                      .collection("items")
                      .doc(doc.id)
                      .delete();
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
