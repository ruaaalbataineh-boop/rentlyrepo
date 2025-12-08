import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'fake_uid.dart';

class ChatScreen extends StatefulWidget {
  final String personName;
  final String personUid;

  const ChatScreen({
    super.key,
    required this.personName,
    required this.personUid,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final db = FirebaseDatabase.instance;

  late String chatId;
  Map<String, dynamic>? personData;

  @override
  void initState() {
    super.initState();

    chatId = LoginUID.uid.compareTo(widget.personUid) > 0
        ? "${LoginUID.uid}-${widget.personUid}"
        : "${widget.personUid}-${LoginUID.uid}";

    
    db.ref("users/${widget.personUid}").onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          personData = Map<String, dynamic>.from(event.snapshot.value as Map);
        });
      }
    });
  }

  String formatTime(int timestamp) {
    final t = DateTime.fromMillisecondsSinceEpoch(timestamp);
    int h = t.hour;
    int m = t.minute;
    String ampm = h >= 12 ? "PM" : "AM";
    h = h % 12;
    if (h == 0) h = 12;
    return "$h:${m.toString().padLeft(2, '0')} $ampm";
  }

  Future<void> createChatIfNotExists(String msg) async {
    final chatRef = db.ref("chats/$chatId");

    final snapshot = await chatRef.get();
    int now = DateTime.now().millisecondsSinceEpoch;

    String user1 = LoginUID.uid.compareTo(widget.personUid) > 0
        ? LoginUID.uid
        : widget.personUid;

    String user2 = LoginUID.uid.compareTo(widget.personUid) > 0
        ? widget.personUid
        : LoginUID.uid;

    if (!snapshot.exists) {
      await chatRef.set({
        "user1": user1,
        "user2": user2,
        "lastMessage": msg,
        "timestamp": now,
      });
    } else {
      await chatRef.update({
        "lastMessage": msg,
        "timestamp": now,
      });
    }
  }

  void sendMessage() async {
    if (messageController.text.trim().isEmpty) return;

    String text = messageController.text.trim();
    int now = DateTime.now().millisecondsSinceEpoch;

    await db.ref("messages/$chatId").push().set({
      "sender": LoginUID.uid,
      "text": text,
      "timestamp": now,
    });

    await createChatIfNotExists(text);

    messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
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
            CircleAvatar(
              radius: 20,
              child: personData?["photoUrl"] == null
                  ? const Icon(Icons.person)
                  : null,
              backgroundImage: personData?["photoUrl"] != null
                  ? NetworkImage(personData!["photoUrl"])
                  : null,
            ),
            const SizedBox(width: 12),

          
            Text(
              personData?["name"] ?? "User",
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: db.ref("messages/$chatId").orderByChild("timestamp").onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("No messages yet"));
                }

                final raw = snapshot.data!.snapshot.value as Map;
                final messages = raw.entries
                    .map((e) => Map<String, dynamic>.from(e.value))
                    .toList()
                  ..sort((a, b) => a["timestamp"].compareTo(b["timestamp"]));

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    bool isMe = msg["sender"] == LoginUID.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.deepPurple : Colors.pink.shade600,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(msg["text"], style: const TextStyle(color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(formatTime(msg["timestamp"]),
                                style: const TextStyle(color: Colors.white70, fontSize: 10)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.purple),
                  onPressed: sendMessage,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
