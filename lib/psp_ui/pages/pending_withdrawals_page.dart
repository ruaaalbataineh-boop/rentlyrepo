import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class PendingWithdrawalsPage extends StatelessWidget {
  const PendingWithdrawalsPage({super.key});

  Future<void> _approve(String id) async {
    await FirebaseFunctions.instance
        .httpsCallable('approveWithdrawal')
        .call({'withdrawalId': id});
  }

  Future<void> _reject(String id) async {
    await FirebaseFunctions.instance
        .httpsCallable('rejectWithdrawal')
        .call({'withdrawalId': id});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('withdrawalRequests')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Center(child: Text('No pending withdrawals'));
        }

        final docs = snap.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final doc = docs[i];
            final data = doc.data();

            final amount = data['amount'] ?? 0;
            final method = data['method'] ?? '';
            final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();

            Widget info;
            if (method == 'bank') {
              info = Text(
                  '${data['bankName'] ?? ''}\nIBAN: ${data['iban'] ?? ''}',
                  style: const TextStyle(fontSize: 13));
            } else {
              info = Text('Exchange Ref: ${data['referenceNumber'] ?? ''}',
                  style: const TextStyle(fontSize: 13));
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text('JD $amount • $method'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    info,
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
                      onPressed: () => _approve(doc.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      tooltip: 'Reject',
                      onPressed: () => _reject(doc.id),
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
