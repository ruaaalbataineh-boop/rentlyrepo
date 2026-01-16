import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
   
    final rentalRecords = [
      {"name": "User A", "item": "Item X", "date": "2025-09-19"},
      {"name": "User B", "item": "Item Y", "date": "2025-09-18"},
    ];

    final paymentTransactions = [
      {"amount": "\$50", "method": "Credit Card", "date": "2025-09-19"},
      {"amount": "\$30", "method": "Cash", "date": "2025-09-18"},
    ];

    final profits = [
      {"item": "Item X", "profit": "\$20"},
      {"item": "Item Y", "profit": "\$15"},
    ];

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Column(
          children: [
            // Header
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
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          context.pop();
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Transactions",
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
                      Tab(text: "Rental Records"),
                      Tab(text: "Payments"),
                      Tab(text: "Profits"),
                    ],
                  ),
                ],
              ),
            ),

            
            Expanded(
              child: TabBarView(
                children: [
                  _buildList(rentalRecords, keys: ["name", "item", "date"]),
                  _buildList(paymentTransactions, keys: ["amount", "method", "date"]),
                  _buildList(profits, keys: ["item", "profit"]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, String>> items, {required List<String> keys}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: keys.map((k) {
                return Text(
                  "$k: ${item[k]}",
                  style: const TextStyle(fontSize: 16),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

