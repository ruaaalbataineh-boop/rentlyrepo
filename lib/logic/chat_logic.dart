import 'dart:ui';
import 'package:firebase_database/firebase_database.dart';

import '../notifications/chat_id_utils.dart';

class ChatLogic {
  final String personName;
  final String personUid;
  final String myUid;
  final DatabaseReference db;

  late String chatId;

  Map<String, dynamic>? personData;
  Map<String, dynamic>? replyMessage;
  String? selectedMessageKey;

  ChatLogic({
    required this.personName,
    required this.personUid,
    required this.myUid,
    DatabaseReference? dbRef,
  }) : db = dbRef ?? FirebaseDatabase.instance.ref() {
    chatId = normalizeChatId(myUid, personUid);
  }

  void initialize({VoidCallback? onUserUpdated}) {
    // listen to other user profile
    db.child("users/$personUid").onValue.listen((event) {
      if (event.snapshot.value != null) {
        personData =
        Map<String, dynamic>.from(event.snapshot.value as Map);
        onUserUpdated?.call();
      }
    });

    // clear unread for me when opening chat
    db.child("chats/$chatId/unread/$myUid").remove();
  }

  bool canEditOrDelete(Map<String, dynamic> msg) {
    if (msg["sender"] != myUid) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now - msg["timestamp"] <= 10 * 60 * 1000;
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
    final chatRef = db.child("chats/$chatId");
    final snapshot = await chatRef.get();
    int now = DateTime.now().millisecondsSinceEpoch;

    String user1 =
    myUid.compareTo(personUid) > 0 ? myUid : personUid;
    String user2 =
    myUid.compareTo(personUid) > 0 ? personUid : myUid;

    if (!snapshot.exists) {
      await chatRef.set({
        "user1": user1,
        "user2": user2,
        "lastMessage": msg,
        "lastSender": myUid,
        "timestamp": now,
      });
    } else {
      await chatRef.update({
        "lastMessage": msg,
        "lastSender": myUid,
        "timestamp": now,
      });
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    await db.child("messages/$chatId").push().set({
      "sender": myUid,
      "text": text.trim(),
      "timestamp": now,
      "replyTo": replyMessage,
    });

    replyMessage = null;

    await createChatIfNotExists(text.trim());

    // mark unread for receiver
    await db.child("chats/$chatId/unread/$personUid").set(true);

    // clear unread for me
    await db.child("chats/$chatId/unread/$myUid").remove();
  }

  Future<void> editMessage(String key, String newText) async {
    if (newText.trim().isEmpty) return;

    await db.child("messages/$chatId/$key").update({
      "text": newText.trim(),
      "edited": true,
    });

    selectedMessageKey = null;
  }

  Future<void> deleteMessage(String key) async {
    await db.child("messages/$chatId/$key").remove();
    selectedMessageKey = null;
  }

  Stream<DatabaseEvent> getMessagesStream() {
    return db
        .child("messages/$chatId")
        .orderByChild("timestamp")
        .onValue;
  }

  void setReplyMessage(Map<String, dynamic> msg) {
    replyMessage = msg;
  }

  void clearReplyMessage() {
    replyMessage = null;
  }

  void setSelectedMessageKey(String? key) {
    selectedMessageKey = key;
  }
}
