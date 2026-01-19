import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ChatScreen.dart';
import 'notifications/active_chat_tracker.dart';
import 'services/auth_service.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  late String myUid;

  @override
  void initState() {
    super.initState();
    ActiveChatTracker.isOnChatPage = true;
  }

  @override
  void dispose() {
    ActiveChatTracker.isOnChatPage = false;
    super.dispose();
  }

  String formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    int hour = date.hour;
    int minute = date.minute;
    String ampm = hour >= 12 ? "PM" : "AM";
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return "$hour:${minute.toString().padLeft(2, '0')} $ampm";
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        if (auth.currentUid == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        myUid = auth.currentUid!;

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              _header(),
              const SizedBox(height: 20),
              _searchBar(),
              const SizedBox(height: 10),
              Expanded(child: _chatList()),
            ],
          ),
        );
      },
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, bottom: 60),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
        ),
      ),
      child: const Center(
        child: Text("Chats",
            style: TextStyle(fontSize: 22, color: Colors.white)),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search name",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey.shade200,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
/*
  Widget _chatList() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref("chats").onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: Text("No snapshot yet"));
        }

        final value = snapshot.data!.snapshot.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Text(
            value == null ? "NULL DATA" : value.toString(),
            style: const TextStyle(fontSize: 12),
          ),
        );
      },
    );
  }

 */

  Widget _chatList() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref("chats").onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(child: Text("No conversations yet"));
        }

        final raw = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

        final myChats = raw.entries.map((e) {
          final data = Map<String, dynamic>.from(e.value as Map);
          data["chatId"] = e.key;

          // 🔹 FALLBACK: extract user1/user2 from chatId if missing
          if (!data.containsKey("user1") || !data.containsKey("user2")) {
            final parts = e.key.toString().split("-");
            if (parts.length >= 2) {
              data["user1"] = parts[0];
              data["user2"] = parts[1];
            }
          }

          return data;
        }).where((c) =>
        c["user1"]?.toString() == myUid ||
            c["user2"]?.toString() == myUid)
            .toList()
          ..sort((a, b) =>
              (b["timestamp"] ?? 0).compareTo(a["timestamp"] ?? 0));

        if (myChats.isEmpty) {
          return const Center(child: Text("No conversations yet"));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: myChats.length,
          itemBuilder: (context, index) {
            final chat = myChats[index];

            final unreadMap = chat["unread"] as Map?;
            final isUnread = unreadMap != null && unreadMap[myUid] == true;

            final otherUid =
            chat["user1"] == myUid ? chat["user2"] : chat["user1"];

            return FutureBuilder(
              future: FirebaseDatabase.instance.ref("users/$otherUid").get(),
              builder: (context, snap) {
                if (!snap.hasData || snap.data!.value == null) {
                  return const SizedBox();
                }

                final user =
                Map<String, dynamic>.from(snap.data!.value as Map);

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          personName: user["name"] ?? "User",
                          personUid: otherUid,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 26,
                          child: Icon(Icons.person),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user["name"] ?? "",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      chat["lastMessage"] ?? "",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: isUnread
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (isUnread)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 6),
                                      child: CircleAvatar(
                                        radius: 5,
                                        backgroundColor: Colors.red,
                                      ),
                                    ),
                                  Text(
                                    formatTime(chat["timestamp"]),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
