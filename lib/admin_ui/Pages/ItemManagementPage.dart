import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ItemManagementPage extends StatelessWidget {
  const ItemManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final additionRequests = [
      {"name": "Item A", "description": "New item to add"},
      {"name": "Item B", "description": "New item to add"},
    ];

    final editRequests = [
      {"name": "Item C", "description": "Request to edit details"},
      {"name": "Item D", "description": "Request to edit details"},
    ];

    final allItems = [
      {"name": "Item A", "description": "Existing item"},
      {"name": "Item B", "description": "Existing item"},
      {"name": "Item C", "description": "Existing item"},
    ];

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
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          context.pop(); 
                        },
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
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TabBar(
                      indicator: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      tabs: const [
                        Tab(text: "Addition Requests"),
                        Tab(text: "Edit Requests"),
                        Tab(text: "All Items"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildItemList(additionRequests, showApproveReject: true),
                  _buildItemList(editRequests, showEdit: true),
                  _buildItemList(allItems, showDelete: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemList(
    List<Map<String, String>> items, {
    bool showApproveReject = false,
    bool showEdit = false,
    bool showDelete = false,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: ListTile(
            title: Text(item['name'] ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text(item['description'] ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showApproveReject)
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () {},
                  ),
                if (showApproveReject)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {},
                  ),
                if (showEdit)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    onPressed: () {},
                  ),
                if (showDelete)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {},
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

