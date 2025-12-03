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

  late String chatId;
  final database = FirebaseDatabase.instance;

  @override
  void initState() {
    super.initState();

    // Unique Chat ID
    chatId = LoginUID.uid.compareTo(widget.personUid) > 0
        ? "${LoginUID.uid}-${widget.personUid}"
        : "${widget.personUid}-${LoginUID.uid}";
  }

  // ---------------- SEND MESSAGE ----------------
  void sendMessage() {
    if (messageController.text.trim().isEmpty) return;

    final msg = {
      "sender": LoginUID.uid,
      "text": messageController.text.trim(),
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    };

    database.ref("messages/$chatId").push().set(msg);

    messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: true,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1F0F46),
                Color(0xFF8A005D),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          widget.personName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ---------------- BODY ----------------
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: database
                  .ref("messages/$chatId")
                  .orderByChild("timestamp")
                  .onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting ||
                    !snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rawData =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                final messages = rawData.entries.map((e) {
                  final msg = Map<String, dynamic>.from(e.value);
                  return msg;
                }).toList();

                messages.sort(
                    (a, b) => a["timestamp"].compareTo(b["timestamp"]));

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var msg = messages[index];
                    bool isMe = msg["sender"] == LoginUID.uid;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color.fromARGB(255, 45, 34, 142)
                              : const Color.fromARGB(255, 142, 37, 81),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          msg["text"],
                          style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ---------------- INPUT FIELD ----------------
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
          )
        ],
      ),
    );
  }
}
