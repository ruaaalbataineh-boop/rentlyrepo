import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'ChatScreen.dart';
import 'Categories_Page.dart';
import 'Orders.dart';
import 'Setting.dart';
import 'bottom_nav.dart';
//import 'user_manager.dart';
import 'fake_uid.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {

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
      bottomNavigationBar: const SharedBottomNav(currentIndex: 3),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, bottom: 60),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Center(
        child: Text(
          "Chats",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
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
          contentPadding: const EdgeInsets.all(12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // CHAT LIST
  Widget _chatList() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance
          .ref("chats")
          .onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData ||
            snapshot.data!.snapshot.value == null) {
          return const Center(child: Text("No conversations yet"));
        }

        final raw = snapshot.data!.snapshot.value as Map;
        final chats = Map<String, dynamic>.from(raw);

        List<Map<String, dynamic>> myChats = chats.entries.map((e) {
          final data = Map<String, dynamic>.from(e.value);
          data["chatId"] = e.key;
          return data;
        }).where((chat) =>
        chat["user1"] == LoginUID.uid ||
            chat["user2"] == LoginUID.uid).toList();

        if (myChats.isEmpty) {
          return const Center(child: Text("No conversations yet"));
        }

        myChats.sort((a, b) => b["timestamp"].compareTo(a["timestamp"]));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: myChats.length,
          itemBuilder: (context, index) {
            var chat = myChats[index];
            String otherUid =
            chat["user1"] == LoginUID.uid ? chat["user2"] : chat["user1"];

            return FutureBuilder(
              future: FirebaseDatabase.instance.ref("users/$otherUid").get(),
              builder: (context, snap) {
                if (!snap.hasData || snap.data!.value == null) {
                  return const SizedBox();
                }

                final rawUser = snap.data!.value as Map;
                final user = Map<String, dynamic>.from(rawUser);

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ChatScreen(
                              personName: user["name"],
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
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white),
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
                                          fontSize: 13,
                                          color: Colors.grey.shade700),
                                    ),
                                  ),
                                  Text(
                                    formatTime(chat["timestamp"]),
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600),
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
