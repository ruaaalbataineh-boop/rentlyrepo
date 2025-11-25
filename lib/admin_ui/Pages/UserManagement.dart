import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  context.pop(); 
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
              Tab(text: "Renter Requests"),
              Tab(text: "Owner Requests"),
              Tab(text: "Active Users"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            RenterRequestsTab(),
            OwnerRequestsTab(),
            ActiveUsersTab(),
          ],
        ),
      ),
    );
  }
}

class RenterRequestsTab extends StatelessWidget {
  const RenterRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final renters = [
      {"name": "A", "email": "a@mail.com"},
      {"name": "B", "email": "b@mail.com"},
    ];
    return ListView(
      children: renters.map((renter) {
        return Card(
          margin: const EdgeInsets.all(8),
          color: const Color(0xFFE3DFF3),
          child: ListTile(
            title: Text(renter['name']!),
            subtitle: Text(renter['email']!),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class OwnerRequestsTab extends StatelessWidget {
  const OwnerRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final owners = [
      {"name": "C", "email": "c@mail.com"},
      {"name": "D", "email": "d@mail.com"},
    ];
    return ListView(
      children: owners.map((owner) {
        return Card(
          margin: const EdgeInsets.all(8),
          color: const Color(0xFFDDEBF7),
          child: ListTile(
            title: Text(owner['name']!),
            subtitle: Text(owner['email']!),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class ActiveUsersTab extends StatelessWidget {
  const ActiveUsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final users = [
      {"name": "E", "email": "e@mail.com"},
      {"name": "F", "email": "f@mail.com"},
    ];
    return ListView(
      children: users.map((user) {
        return Card(
          margin: const EdgeInsets.all(8),
          color: const Color(0xFFFFE5E5),
          child: ListTile(
            title: Text(user['name']!),
            subtitle: Text(user['email']!),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {},
            ),
          ),
        );
      }).toList(),
    );
  }
}
