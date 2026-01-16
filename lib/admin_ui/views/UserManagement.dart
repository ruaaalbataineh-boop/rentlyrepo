import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:p2/services/firestore_service.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () {
                  context.go('/dashboard');
                },
              ),
              const SizedBox(width: 8),
              const Text(
                "User Management",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Pending Users"),
              Tab(text: "Rejected Users"),
              Tab(text: "Active Users"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            PendingUsersTab(),
            RejectedUsersTab(),
            ActiveUsersTab(),
          ],
        ),
      ),
    );
  }
}

class UserExpansionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String userId;
  final Widget actions; // Approve / Reject / Delete

  const UserExpansionCard({
    super.key,
    required this.data,
    required this.userId,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
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
                    "${data['firstName']} ${data['lastName']}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data["email"] ?? "",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),

            actions, // Buttons appear here
          ],
        ),

        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _info("Phone", data["phone"]),
                _info("Birth Date", data["birthDate"]),
                const SizedBox(height: 10),

                if (data["idPhotoUrl"] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("ID Photo",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          )),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          data["idPhotoUrl"],
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),

                if (data["selfiePhotoUrl"] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Selfie",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          )),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          data["selfiePhotoUrl"],
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        "$label: ${value ?? ''}",
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}

class PendingUsersTab extends StatelessWidget {
  const PendingUsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("pending_users")
          .where("status", isEqualTo: "pending")
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!.docs;
        if (users.isEmpty) return const Center(child: Text("No pending users"));

        return ListView(
          children: users.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return UserExpansionCard(
              data: data,
              userId: doc.id,
              actions: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseFunctions.instance
                          .httpsCallable("approveUser")
                          .call({"uid": doc.id});
                    },
                    icon: const Icon(Icons.check),
                    label: const Text("Approve"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseFunctions.instance
                          .httpsCallable("rejectUser")
                          .call({"uid": doc.id});
                    },
                    icon: const Icon(Icons.close),
                    label: const Text("Reject"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

  Widget _userInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value ?? ""),
        ],
      ),
    );
  }

class RejectedUsersTab extends StatelessWidget {
  const RejectedUsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("pending_users")
          .where("status", isEqualTo: "rejected")
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!.docs;
        if (users.isEmpty) return const Center(child: Text("No rejected users"));

        return ListView(
          children: users.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return UserExpansionCard(
              data: data,
              userId: doc.id,
              actions: const SizedBox.shrink(), // No buttons
            );
          }).toList(),
        );
      },
    );
  }
}

class ActiveUsersTab extends StatelessWidget {
  const ActiveUsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("users").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!.docs;
        if (users.isEmpty) return const Center(child: Text("No active users"));

        return ListView(
          children: users.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return UserExpansionCard(
              data: data,
              userId: doc.id,
              actions: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  FirebaseFirestore.instance.collection("users").doc(doc.id).delete();
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
