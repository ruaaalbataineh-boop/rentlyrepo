import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final chats = [
      {"user": "User A", "lastMessage": "Hello, I need help"},
      {"user": "User B", "lastMessage": "My ticket was canceled"},
      {"user": "User C", "lastMessage": "Thank you for your support"},
    ];

    return Scaffold(
      body: Column(
        children: [
          Stack(
            children: [
              ClipPath(
                clipper: SideCurveClipper(),
                child: Container(
                  height: 140,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 50,
                left: 16,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        context.go('/dashboard');
                      },
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Chats",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: ListTile(
                    title: Text(chat['user']!,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text(chat['lastMessage']!),
                    onTap: () {
                      context.push('/chatDetail/${chat['user']}');
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ChatDetailPage extends StatelessWidget {
  final String user;
  const ChatDetailPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final messages = [
      {"from": "User", "text": "Hello, I need help"},
      {"from": "Admin", "text": "Sure, how can I assist you?"},
      {"from": "User", "text": "I want to cancel my booking"},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F0F46),
        title: Text("Chat with $user"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(), 
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final msg = messages[index];
          return Align(
            alignment: msg['from'] == 'Admin'
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: msg['from'] == 'Admin'
                    ? Colors.purple[300]
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(msg['text']!),
            ),
          );
        },
      ),
    );
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


