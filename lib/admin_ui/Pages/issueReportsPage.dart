import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class AdminReportsPage extends StatelessWidget {
  const AdminReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [

          Container(
            height: 140,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.go('/dashboard'),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Rental Issue Reports",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          //LIST
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("rentalReports")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No reports yet"));
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();

                    final type = data["type"] ?? "";
                    final status = data["status"] ?? "pending";
                    final media = List<String>.from(data["media"] ?? []);

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: ExpansionTile(
                        title: Text(
                          type == "pickup_issue"
                              ? "Pickup Issue Report"
                              : "Return Issue Report",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "Request: ${data["requestId"]}\n"
                              "Against: ${data["against"]}\n"
                              "Status: $status",
                        ),
                        childrenPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                        children: [

                          // DETAILS
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Submitted By: ${data["submittedBy"]}",
                                    style: const TextStyle(fontSize: 14)),

                                if (data["severity"] != null)
                                  Text("Severity: ${data["severity"]}",
                                      style: const TextStyle(fontSize: 14)),

                                if (data["description"] != null &&
                                    data["description"].toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      "Description:\n${data["description"]}",
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // MEDIA
                          const Text(
                            "Media Evidence",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),

                          const SizedBox(height: 10),

                          if (media.isEmpty)
                            const Text("No media uploaded"),

                          if (media.isNotEmpty)
                            Wrap(
                              children: media
                                  .map(
                                    (url) => Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      url,
                                      width: 110,
                                      height: 110,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              )
                                  .toList(),
                            ),

                          const SizedBox(height: 14),

                          // ACTION BUTTONS
                          if (status == "pending")
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection("rentalReports")
                                        .doc(doc.id)
                                        .update({"status": "rejected"});

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Report Rejected"),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Reject",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  onPressed: () async {
                                    try {
                                      await FirebaseFunctions.instance
                                          .httpsCallable("approveIssueReport")
                                          .call({
                                        "reportId": doc.id,
                                      });

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Approved successfully")),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Failed: $e")),
                                      );
                                    }
                                  },
                                  child: const Text("Approve"),
                                ),
                              ],
                            ),

                          if (status != "pending")
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                "Already $status",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
