import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'Categories_Page.dart';
import 'Chats_Page.dart';
import 'Orders.dart';
import 'Setting.dart';
import 'owner_listings.dart';
import 'fake_uid.dart';

class SharedBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int)? onTabChanged;

  const SharedBottomNav({
    super.key,
    required this.currentIndex,
    this.onTabChanged,
  });

  @override
  State<SharedBottomNav> createState() => _SharedBottomNavState();
}

class _SharedBottomNavState extends State<SharedBottomNav> {
  bool showMyItemsDot = false;
  StreamSubscription<QuerySnapshot>? _myItemsSub;
   
    bool _isFirstMyItemsLoad = true;

  @override
  void initState() {
    super.initState();
    _listenToMyItemsChanges();
  }

  @override
  void dispose() {
    _myItemsSub?.cancel();
    super.dispose();
  }

  void _listenToMyItemsChanges() {
    _myItemsSub = FirebaseFirestore.instance
        .collection("items")
        .where("ownerId", isEqualTo: LoginUID.uid)
        .snapshots()
        .listen((snapshot) {
      // إذا المستخدم داخل صفحة My Items → لا تظهر النقطة
      if (widget.currentIndex == 4) return;

      if (_isFirstMyItemsLoad) {
        _isFirstMyItemsLoad = false;
        return;
        }

        if (snapshot.docChanges.isNotEmpty && widget.currentIndex != 4) {
          setState(() {
          showMyItemsDot = true;
        });
      }
    });
  }

  void _navigate(BuildContext context, int index) {
    if (index == widget.currentIndex) return;

    // لما يدخل My Items نشيل النقطة
    if (index == 4) {
      setState(() {
        showMyItemsDot = false;
      });
    }

    if (widget.onTabChanged != null) {
      widget.onTabChanged!(index);
      return;
    }

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SettingPage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OrdersPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CategoryPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ChatsPage()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OwnerItemsPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFF1B2230),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildIcon(Icons.settings, 0, context),
          _buildIcon(Icons.shopping_bag_outlined, 1, context),
          _buildIcon(Icons.home_outlined, 2, context),
          _buildChatIcon(context),
          _buildMyItemsIcon(context),
        ],
      ),
    );
  }

  Widget _buildIcon(IconData icon, int index, BuildContext context) {
    bool active = index == widget.currentIndex;

    return GestureDetector(
      onTap: () => _navigate(context, index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: EdgeInsets.only(bottom: active ? 8 : 0),
        padding: const EdgeInsets.all(12),
        decoration: active
            ? BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              )
            : null,
        child: Icon(
          icon,
          size: active ? 32 : 26,
          color: active ? Colors.black : Colors.white70,
        ),
      ),
    );
  }

  /// CHAT ICON WITH BADGE
  Widget _buildChatIcon(BuildContext context) {
    bool active = widget.currentIndex == 3;

    return GestureDetector(
      onTap: () => _navigate(context, 3),
      child: StreamBuilder(
        stream: FirebaseDatabase.instance.ref("chats").onValue,
        builder: (context, snapshot) {
          int unreadCount = 0;

          if (snapshot.hasData &&
              snapshot.data!.snapshot.value != null) {
            final raw = snapshot.data!.snapshot.value as Map;
            final chats = Map<String, dynamic>.from(raw);

            for (var chat in chats.values) {
              if (chat["unread"] != null &&
                  chat["unread"][LoginUID.uid] == true) {
                unreadCount++;
              }
            }
          }

          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.only(bottom: active ? 8 : 0),
                padding: const EdgeInsets.all(12),
                decoration: active
                    ? BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      )
                    : null,
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: active ? 32 : 26,
                  color: active ? Colors.black : Colors.white70,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  ///  GREEN DOT
  Widget _buildMyItemsIcon(BuildContext context) {
    bool active = widget.currentIndex == 4;

    return GestureDetector(
      onTap: () => _navigate(context, 4),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: EdgeInsets.only(bottom: active ? 8 : 0),
            padding: const EdgeInsets.all(12),
            decoration: active
                ? BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                   boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    )
                : null,
            child: Icon(
              Icons.storage_rounded,
              size: active ? 32 : 26,
              color: active ? Colors.black : Colors.white70,
            ),
          ),

          if (showMyItemsDot)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
