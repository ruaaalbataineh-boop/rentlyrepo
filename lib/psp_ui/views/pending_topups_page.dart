import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../controllers/psp_dashboard_controller.dart';

class PendingTopupsPage extends StatelessWidget {
  const PendingTopupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = PspDashboardController();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: controller.getTopups(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Center(child: Text('No pending top-ups'));
        }

        final docs = snap.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final doc = docs[i];
            final data = doc.data();

            final amount = data['amount'] ?? 0;
            final method = data['method'] ?? '';
            final ref = data['referenceNumber'] ?? '';
            final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text('$amount JD • $method'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ref: $ref'),
                    if (expiresAt != null)
                      Text('Expires: $expiresAt',
                          style: const TextStyle(fontSize: 12)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      tooltip: 'Approve',
                      onPressed: () => controller.approveTopup(doc.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      tooltip: 'Reject',
                      onPressed: () => controller.rejectTopup(doc.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
