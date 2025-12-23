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
  final ScrollController _scrollController = ScrollController();
  final db = FirebaseDatabase.instance;

  late String chatId;
  Map<String, dynamic>? personData;
  Map<String, dynamic>? replyMessage;

  String? selectedMessageKey;

  static const Color senderColor = Color(0xFF5E2B97);

  @override
  void initState() {
    super.initState();

    chatId = LoginUID.uid.compareTo(widget.personUid) > 0
        ? "${LoginUID.uid}-${widget.personUid}"
        : "${widget.personUid}-${LoginUID.uid}";

    db.ref("users/${widget.personUid}").onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          personData =
              Map<String, dynamic>.from(event.snapshot.value as Map);
        });
      }
    });

    db.ref("chats/$chatId/unread/${LoginUID.uid}").remove();
  }

  bool canEditOrDelete(Map<String, dynamic> msg) {
    if (msg["sender"] != LoginUID.uid) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now - msg["timestamp"] <= 10 * 60 * 1000;
  }

  void editMessage(String key, String oldText) {
    final controller = TextEditingController(text: oldText);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit message"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              db.ref("messages/$chatId/$key").update({
                "text": controller.text.trim(),
                "edited": true,
              });
              Navigator.pop(context);
              setState(() => selectedMessageKey = null);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void deleteMessage(String key) {
    db.ref("messages/$chatId/$key").remove();
    setState(() => selectedMessageKey = null);
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

  String messageDateLabel(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) return "Today";

    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) return "Yesterday";

    return "${date.year}/${date.month}/${date.day}";
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
        "lastSender": LoginUID.uid,
        "timestamp": now,
      });
    } else {
      await chatRef.update({
        "lastMessage": msg,
        "lastSender": LoginUID.uid,
        "timestamp": now,
      });
    }
  }

  void sendMessage() async {
    if (messageController.text.trim().isEmpty) return;

    final text = messageController.text.trim();
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.ref("messages/$chatId").push().set({
      "sender": LoginUID.uid,
      "text": text,
      "timestamp": now,
      "replyTo": replyMessage,
    });

    replyMessage = null;

    await createChatIfNotExists(text);
    await db.ref("chats/$chatId/unread/${widget.personUid}").set(true);
    await db.ref("chats/$chatId/unread/${LoginUID.uid}").remove();

    messageController.clear();
    setState(() {});
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
            ),
          ),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: personData?["photoUrl"] != null
                  ? NetworkImage(personData!["photoUrl"])
                  : null,
              child: personData?["photoUrl"] == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(personData?["name"] ?? "User",
                    style: const TextStyle(color: Colors.white)),
                Text(
                  personData?["status"] == "online"
                      ? "Online"
                      : "Last seen ${formatTime(personData?["lastSeen"] ?? 0)}",
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (selectedMessageKey != null) {
            setState(() {
              selectedMessageKey = null;
            });
          }
        },
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: db
                    .ref("messages/$chatId")
                    .orderByChild("timestamp")
                    .onValue,
                builder: (context, snapshot) {
                  if (!snapshot.hasData ||
                      snapshot.data!.snapshot.value == null) {
                    return const Center(child: Text("No messages yet"));
                  }

                  final raw = snapshot.data!.snapshot.value as Map;
                  final messages = raw.entries.map((e) {
                    final msg = Map<String, dynamic>.from(e.value);
                    msg["key"] = e.key;
                    return msg;
                  }).toList()
                    ..sort((a, b) =>
                        a["timestamp"].compareTo(b["timestamp"]));

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(
                          _scrollController.position.maxScrollExtent);
                    }
                  });

                  String? lastDate;

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg["sender"] == LoginUID.uid;
                      final showOptions =
                          selectedMessageKey == msg["key"];
                      final canModify = canEditOrDelete(msg);

                      final dateLabel =
                          messageDateLabel(msg["timestamp"]);
                      final showDate = lastDate != dateLabel;
                      lastDate = dateLabel;

                      return Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (showDate)
                            Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8),
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(dateLabel,
                                    style: const TextStyle(
                                        fontSize: 12)),
                              ),
                            ),

                          GestureDetector(
                            onLongPress: () {
                              setState(() {
                                selectedMessageKey = msg["key"];
                              });
                            },
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context)
                                            .size
                                            .width *
                                        0.75,
                              ),
                              padding:
                                  const EdgeInsets.all(12),
                              margin:
                                  const EdgeInsets.symmetric(
                                      vertical: 4),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? const Color.fromARGB(
                                        230, 38, 10, 91)
                                    : const Color.fromARGB(
                                        234, 122, 4, 73),
                                borderRadius:
                                    BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if (msg["replyTo"] != null)
                                    Container(
                                      margin: const EdgeInsets.only(
                                          bottom: 6),
                                      padding:
                                          const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.black26,
                                        borderRadius:
                                            BorderRadius.circular(
                                                8),
                                      ),
                                      child: Text(
                                        msg["replyTo"]["text"],
                                        maxLines: 1,
                                        overflow: TextOverflow
                                            .ellipsis,
                                        style: const TextStyle(
                                            color:
                                                Colors.white70),
                                      ),
                                    ),
                                  Row(
                                    mainAxisSize:
                                        MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          msg["text"],
                                          style: const TextStyle(
                                              color:
                                                  Colors.white,
                                              fontSize: 15),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        formatTime(
                                            msg["timestamp"]),
                                        style: const TextStyle(
                                            color:
                                                Colors.white70,
                                            fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (showOptions)
                            IntrinsicWidth(
                              child: Container(
                                margin: const EdgeInsets.only(
                                    bottom: 6),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.grey.shade200,
                                  borderRadius:
                                      BorderRadius.circular(
                                          12),
                                ),
                                child: Column(
                                  mainAxisSize:
                                      MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      dense: true,
                                      leading: const Icon(
                                          Icons.reply),
                                      title:
                                          const Text("Reply"),
                                      onTap: () {
                                        setState(() {
                                          replyMessage = msg;
                                          selectedMessageKey =
                                              null;
                                        });
                                      },
                                    ),
                                    if (canModify)
                                      ListTile(
                                        dense: true,
                                        leading: const Icon(
                                            Icons.edit),
                                        title:
                                            const Text("Edit"),
                                        onTap: () =>
                                            editMessage(
                                                msg["key"],
                                                msg["text"]),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            if (replyMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey.shade200,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(replyMessage!["text"],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(
                          () => replyMessage = null),
                    )
                  ],
                ),
              ),

            Container(
              padding: const EdgeInsets.all(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius:
                      BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send,
                          color: Colors.purple),
                      onPressed: sendMessage,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
