import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';

import 'logic/chat_logic.dart';
import 'notifications/active_chat_tracker.dart';
import 'notifications/chat_id_utils.dart';
import 'services/auth_service.dart';

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
  final messageController = TextEditingController();
  final scrollController = ScrollController();

  late ChatLogic logic;
  late String myUid;

  @override
  void initState() {
    super.initState();

    myUid = context.read<AuthService>().currentUid!;

    ActiveChatTracker.activeChatId =
        normalizeChatId(myUid, widget.personUid);

    // Presence: ONLINE
    FirebaseDatabase.instance.ref("users/$myUid/status").set("online");
    FirebaseDatabase.instance
        .ref("users/$myUid/lastSeen")
        .onDisconnect()
        .set(ServerValue.timestamp);

    logic = ChatLogic(
      personName: widget.personName,
      personUid: widget.personUid,
      myUid: myUid,
    );

    logic.initialize(onUserUpdated: () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    // Presence: OFFLINE
    FirebaseDatabase.instance.ref("users/$myUid/status").set("offline");
    FirebaseDatabase.instance
        .ref("users/$myUid/lastSeen")
        .set(DateTime.now().millisecondsSinceEpoch);

    ActiveChatTracker.activeChatId = null;

    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    logic.sendMessage(messageController.text);
    messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.personName,
                style: const TextStyle(color: Colors.white)),
            Text(
              logic.personData?["status"] == "online"
                  ? "Online"
                  : "Last seen ${logic.formatTime(logic.personData?["lastSeen"] ?? 0)}",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: logic.getMessagesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("No messages yet"));
                }

                final raw = snapshot.data!.snapshot.value as Map;
                final messages = raw.entries.map((e) {
                  final m = Map<String, dynamic>.from(e.value);
                  m["key"] = e.key;
                  return m;
                }).toList()
                  ..sort((a, b) =>
                      a["timestamp"].compareTo(b["timestamp"]));

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (scrollController.hasClients) {
                    scrollController.jumpTo(
                        scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isMe = msg["sender"] == myUid;

                    if (!isMe) {
                      FirebaseDatabase.instance
                          .ref("messages/${logic.chatId}/${msg["key"]}/readBy/$myUid")
                          .set(true);
                    }

                    final isRead =
                        msg["readBy"] != null &&
                            msg["readBy"][widget.personUid] == true;

                    return Align(
                      alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth:
                          MediaQuery.of(context).size.width * 0.75,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xFF3A1A78)
                              : const Color(0xFF8A005D),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (msg["replyTo"] != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  msg["replyTo"]["text"],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),

                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    msg["text"],
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 15),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  logic.formatTime(msg["timestamp"]),
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 10),
                                ),
                                if (isMe)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Icon(
                                      isRead ? Icons.done_all : Icons.done,
                                      size: 14,
                                      color: isRead
                                          ? Colors.blue
                                          : Colors.white70,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // INPUT BAR
          Container(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: messageController,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  suffixIcon: IconButton(
                    icon:
                    const Icon(Icons.send, color: Colors.purple),
                    onPressed: _sendMessage,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
