import 'dart:async';

import 'package:flutter/material.dart';
import 'package:p2/AddItemPage .dart';
import 'package:p2/sub_category_page.dart';
import 'bottom_nav.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:overlay_support/overlay_support.dart';


// ===============================
// CATEGORY MODEL
// ===============================
class EquipmentCategory {
  final String id;
  final String title;
  final IconData icon;
  bool isFavorite;

  EquipmentCategory({
    required this.id,
    required this.title,
    required this.icon,
    this.isFavorite = false,
  });
}

final CATEGORY_LIST = [
  EquipmentCategory(id: 'c1', title: 'Electronics', icon: Icons.headphones),
  EquipmentCategory(id: 'c2', title: 'Computers & Mobiles', icon: Icons.devices_other),
  EquipmentCategory(id: 'c3', title: 'Video Games', icon: Icons.sports_esports),
  EquipmentCategory(id: 'c4', title: 'Sports and hobbies', icon: Icons.directions_bike),
  EquipmentCategory(id: 'c5', title: 'Tools & Devices', icon: Icons.handyman),
  EquipmentCategory(id: 'c6', title: 'Home & Garden', icon: Icons.grass),
  EquipmentCategory(id: 'c7', title: 'Fashion & Clothing', icon: Icons.checkroom),
];


// ===============================
// CATEGORY PAGE
// ===============================
class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {


    final Map<String, String> _lastItemStatus = {};


  //  CHAT NOTIFICATIONS
  StreamSubscription<DatabaseEvent>? chatSubscription;

  //  ADMIN → USER ITEM STATUS
  StreamSubscription<QuerySnapshot>? itemStatusSubscription;
  


  String? myUid;
  String searchQuery = "";

  // ===============================
  // INIT
  // ===============================
  @override
  void initState() {
    super.initState();

    myUid = FirebaseAuth.instance.currentUser?.uid;

    saveFcmToken();

    listenForChatNotifications();        //  chat banner
    listenForItemStatusUpdates();        //  admin → user banner
  }

  // ===============================
  // DISPOSE
  // ===============================
  @override
  void dispose() {
    chatSubscription?.cancel();
    itemStatusSubscription?.cancel();
    super.dispose();
  }

  // ===============================
  // CHAT BANNER (Realtime DB)
  // ===============================
  void listenForChatNotifications() {
    if (myUid == null) return;

    chatSubscription = FirebaseDatabase.instance
        .ref('chats')
        .onChildChanged
        .listen((event) async {

      final data = event.snapshot.value;
      if (data == null || data is! Map) return;

      final chat = Map<String, dynamic>.from(data);

      final user1 = chat['user1'];
      final user2 = chat['user2'];

      if (user1 != myUid && user2 != myUid) return;

      final lastMessage = chat['lastMessage'];
      final lastSender = chat['lastSender'];

      if (lastSender == myUid) return;
      if (lastMessage == null) return;

      String senderName = 'New message';

      if (lastSender != null) {
        final snap = await FirebaseDatabase.instance
            .ref('users/$lastSender/name')
            .get();

        if (snap.exists) senderName = snap.value.toString();
      }

      showSimpleNotification(
        _chatBanner(senderName, lastMessage.toString()),
        background: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 4),
      );
    });
  }

  Widget _chatBanner(String sender, String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 42, 18, 98),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color.fromARGB(255, 100, 97, 99),
            child: Icon(Icons.chat, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sender,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // ADMIN → USER ITEM STATUS BANNER
  // ===============================
  void listenForItemStatusUpdates() {
  if (myUid == null) return;

  itemStatusSubscription = FirebaseFirestore.instance
      .collection("pending_items") 
      .where("ownerId", isEqualTo: myUid)
      .snapshots()
      .listen((snapshot) {
    for (final doc in snapshot.docs) {

      final data = doc.data() as Map<String, dynamic>;
      final itemId = doc.id;

      final currentStatus = data["status"];
      final itemName = data["name"] ?? "Your item";

        
      if (!_lastItemStatus.containsKey(itemId)) {
        _lastItemStatus[itemId] = currentStatus;
        continue;
      }

      final previousStatus = _lastItemStatus[itemId];

      
      if (previousStatus == currentStatus) continue;

      
      _lastItemStatus[itemId] = currentStatus;

      // approved / rejected
      if (previousStatus == "pending" && currentStatus == "approved") {
        _showItemBanner(
          title: "Item Approved",
          message: "$itemName has been approved. Check My Items.",
          success: true,
        );
      }

      if (previousStatus == "pending" && currentStatus == "rejected") {
        _showItemBanner(
          title: "Item Rejected",
          message: "$itemName has been rejected.",
          success: false,
        );
      }
    }
  });
}

  void _showItemBanner({
    required String title,
    required String message,
    required bool success,
  }) {
    showSimpleNotification(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: success
              ? const Color.fromARGB(255, 24, 151, 79)
              : const Color.fromARGB(229, 211, 47, 47),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(message,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15)),
          ],
        ),
      ),
      background: Colors.transparent,
      elevation: 0,
      duration: const Duration(seconds: 4),
    );
  }

  // ===============================
  // SAVE FCM TOKEN (OPTIONAL)
  // ===============================
  Future<void> saveFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await FirebaseDatabase.instance
        .ref("users/${user.uid}/fcmToken")
        .set(token);
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    final filteredCategories = CATEGORY_LIST.where((cat) {
      return cat.title.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          ClipPath(
            clipper: SideCurveClipper(),
            child: Container(
              height: 140,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                ),
              ),
              child: const Center(
                child: Text(
                  "Categories",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search categories...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => searchQuery = v),
            ),
          ),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filteredCategories.length,
              itemBuilder: (ctx, i) {
                final category = filteredCategories[i];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubCategoryPage(
                          categoryId: category.id,
                          categoryTitle: category.title,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(category.icon,
                            size: 60,
                            color: const Color(0xFF8A005D)),
                        const SizedBox(height: 10),
                        Text(category.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const SharedBottomNav(currentIndex: 2),
    );
  }
}


// ===============================
// CLIPPER
// ===============================
class SideCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double radius = 40;
    Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height);
    path.arcToPoint(
      Offset(radius, size.height - radius),
      radius: Radius.circular(radius),
    );
    path.lineTo(size.width - radius, size.height - radius);
    path.arcToPoint(
      Offset(size.width, size.height),
      radius: Radius.circular(radius),
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
