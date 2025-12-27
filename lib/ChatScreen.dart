import 'package:flutter/material.dart';
import 'package:p2/fake_uid.dart';
import 'package:p2/logic/chat_logic.dart';


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
  
  late ChatLogic logic;

  @override
  void initState() {
    super.initState();
    logic = ChatLogic(
      personName: widget.personName,
      personUid: widget.personUid,
    );
    logic.initialize();
  }

  void _sendMessage() {
    logic.sendMessage(messageController.text);
    messageController.clear();
    setState(() {});
  }

  void _editMessage(String key, String oldText) {
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
              logic.editMessage(key, controller.text);
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _deleteMessage(String key) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Message"),
        content: const Text("Are you sure you want to delete this message?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              logic.deleteMessage(key);
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
              backgroundImage: logic.personData?["photoUrl"] != null
                  ? NetworkImage(logic.personData!["photoUrl"])
                  : null,
              child: logic.personData?["photoUrl"] == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(logic.personData?["name"] ?? "User",
                    style: const TextStyle(color: Colors.white)),
                Text(
                  logic.personData?["status"] == "online"
                      ? "Online"
                      : "Last seen ${logic.formatTime(logic.personData?["lastSeen"] ?? 0)}",
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
          if (logic.selectedMessageKey != null) {
            setState(() {
              logic.setSelectedMessageKey(null);
            });
          }
        },
        child: Column(
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
                          logic.selectedMessageKey == msg["key"];
                      final canModify = logic.canEditOrDelete(msg);

                      final dateLabel =
                          logic.messageDateLabel(msg["timestamp"]);
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
                                logic.setSelectedMessageKey(msg["key"]);
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
                                        logic.formatTime(
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
                                          logic.setReplyMessage(msg);
                                          logic.setSelectedMessageKey(
                                              null);
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
                                            _editMessage(
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

            if (logic.replyMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey.shade200,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(logic.replyMessage!["text"],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(
                          () => logic.clearReplyMessage()),
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
                      onPressed: _sendMessage,
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
