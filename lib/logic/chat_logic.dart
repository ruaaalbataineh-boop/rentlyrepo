import 'package:firebase_database/firebase_database.dart';
import 'package:p2/fake_uid.dart';

class ChatLogic {
  final String personName;
  final String personUid;
  final DatabaseReference db;

  late String chatId;
  Map<String, dynamic>? personData;
  Map<String, dynamic>? replyMessage;
  String? selectedMessageKey;

  ChatLogic({
    required this.personName,
    required this.personUid,
    DatabaseReference? dbRef, 
  }) : db = dbRef ?? FirebaseDatabase.instance.ref() {
    chatId = LoginUID.uid.compareTo(personUid) > 0
        ? "${LoginUID.uid}-$personUid"
        : "$personUid-${LoginUID.uid}";
  }

  void initialize() {
    db.child("users/$personUid").onValue.listen((event) {
      if (event.snapshot.value != null) {
        personData = Map<String, dynamic>.from(event.snapshot.value as Map);
      }
    });

    db.child("chats/$chatId/unread/${LoginUID.uid}").remove();
  }

  bool canEditOrDelete(Map<String, dynamic> msg) {
    if (msg["sender"] != LoginUID.uid) return false;
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

    String user1 = LoginUID.uid.compareTo(personUid) > 0
        ? LoginUID.uid
        : personUid;
    String user2 = LoginUID.uid.compareTo(personUid) > 0
        ? personUid
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

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    await db.child("messages/$chatId").push().set({
      "sender": LoginUID.uid,
      "text": text.trim(),
      "timestamp": now,
      "replyTo": replyMessage,
    });

    replyMessage = null;

    await createChatIfNotExists(text.trim());
    await db.child("chats/$chatId/unread/$personUid").set(true);
    await db.child("chats/$chatId/unread/${LoginUID.uid}").remove();
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
    return db.child("messages/$chatId").orderByChild("timestamp").onValue;
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
