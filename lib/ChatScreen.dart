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

  Map<String, dynamic>? personData;

  @override
  void initState() {
    super.initState();

    
    chatId = LoginUID.uid.compareTo(widget.personUid) > 0
        ? "${LoginUID.uid}-${widget.personUid}"
        : "${widget.personUid}-${LoginUID.uid}";

    
    database.ref("users/${widget.personUid}").onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          personData =
              Map<String, dynamic>.from(event.snapshot.value as Map);
        });
      }
    });
  }

  //  FORMAT TIME 
  String formatTime(int timestamp) {
    final t = DateTime.fromMillisecondsSinceEpoch(timestamp);

    int hour = t.hour;
    int minute = t.minute;

    String ampm = hour >= 12 ? "PM" : "AM";
    hour = hour % 12;
    if (hour == 0) hour = 12;

    String m = minute.toString().padLeft(2, '0');

    return "$hour:$m $ampm";
  }

  // SEND MESSAGE
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

        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: personData?["photoUrl"] != null
                  ? NetworkImage(personData!["photoUrl"])
                  : null,
              child: personData?["photoUrl"] == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  personData?["name"] ?? widget.personName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  personData?["status"] ?? "offline",
                  style: TextStyle(
                    color: (personData?["status"] == "online")
                        ? Colors.greenAccent
                        : Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

   
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: database
                  .ref("messages/$chatId")
                  .orderByChild("timestamp")
                  .onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rawData =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

           
                final messages = rawData.entries.map((e) {
                  return Map<String, dynamic>.from(e.value);
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
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color.fromARGB(255, 45, 34, 142)
                              : const Color.fromARGB(255, 142, 37, 81),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              msg["text"],
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              formatTime(msg["timestamp"]), 
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 10),
                            )
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
          )
        ],
      ),
    );
  }
}
