// bottom_nav.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'security/route_guard.dart';
import 'security/secure_storage.dart';
import 'security/error_handler.dart';

import 'Categories_Page.dart';
import 'Chats_Page.dart';
import 'Orders.dart';
import 'Setting.dart';
import 'owner_listings.dart';
import 'fake_uid.dart';

// ✅ إضافة فقط
import 'package:p2/notifications/active_chat_tracker.dart';

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
  StreamSubscription<DatabaseEvent>? _chatsSub;
  bool _isFirstMyItemsLoad = true;

  bool _isInitialized = false;
  bool _isListening = false;
  int _maxUnreadCount = 99;
  Timer? _securityTimer;

  // ✅ إضافة فقط
  int _unreadChatsCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeSecurity();
  }

  Future<void> _initializeSecurity() async {
    try {
      if (!RouteGuard.isAuthenticated()) return;
      if (!_isValidUid(LoginUID.uid)) return;

      await Future.delayed(const Duration(milliseconds: 500));

      _listenToMyItemsChanges();
      _listenToChatsChanges();
      _startSecurityTimer();

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      ErrorHandler.logError('BottomNav Initialization', e);
    }
  }

  bool _isValidUid(String uid) {
    if (uid.isEmpty || uid.length > 128) return false;
    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(uid);
  }

  @override
  void dispose() {
    _myItemsSub?.cancel();
    _chatsSub?.cancel();
    _securityTimer?.cancel();
    super.dispose();
  }

  void _startSecurityTimer() {
    _securityTimer = Timer.periodic(const Duration(minutes: 5), (_) {});
  }

  void _listenToMyItemsChanges() {
    if (_isListening) return;

    final uid = LoginUID.uid;
    if (!_isValidUid(uid)) return;

    _myItemsSub = FirebaseFirestore.instance
        .collection("items")
        .where("ownerId", isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      if (widget.currentIndex == 4) return;

      if (_isFirstMyItemsLoad) {
        _isFirstMyItemsLoad = false;
        return;
      }

      setState(() => showMyItemsDot = true);
    });

    _isListening = true;
  }

  
  void _listenToChatsChanges() {
  _chatsSub = FirebaseDatabase.instance.ref("chats").onValue.listen((event) {
    // إذا داخل الشات → لا تعد
    if (ActiveChatTracker.isOnChatPage ||
        ActiveChatTracker.activeChatId != null) {
      if (mounted) setState(() => _unreadChatsCount = 0);
      return;
    }

    int unread = 0;
    final data = event.snapshot.value;
    if (data is! Map) return;

    data.forEach((_, chatData) {
      if (chatData is! Map) return;

      final unreadMap = chatData['unread'];
      if (unreadMap is! Map) return;

      if (unreadMap[LoginUID.uid] == true) {
        unread++;
      }
    });

    if (mounted) {
      setState(() {
        _unreadChatsCount =
            unread > _maxUnreadCount ? _maxUnreadCount : unread;
      });
    }
  });
}

  void _navigate(BuildContext context, int index) {
    if (widget.onTabChanged != null) {
      widget.onTabChanged!(index);
      return;
    }

    final routes = {
      0: const SettingPage(),
      1: const OrdersPage(),
      2: const CategoryPage(),
      3: const ChatsPage(),
      4: const OwnerItemsPage(),
    };

    final destination = routes[index];
    if (destination == null) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) return _buildMinimalNavBar(context);

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
          _buildIcon(Icons.settings, 0, context,
              key: const ValueKey('navSettings')),
          _buildIcon(Icons.shopping_bag_outlined, 1, context,
              key: const ValueKey('navOrders')),
          _buildIcon(Icons.home_outlined, 2, context,
              key: const ValueKey('navHome')),

          // ✅ لفّ أيقونة الشات فقط
          Stack(
            clipBehavior: Clip.none,
            children: [
              _buildChatIcon(context),
              if (_unreadChatsCount > 0 &&
                  !ActiveChatTracker.isOnChatPage &&
                  ActiveChatTracker.activeChatId == null)
                Positioned(
                  top: -6,
                  right: -10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    constraints:
                        const BoxConstraints(minWidth: 20, minHeight: 16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _unreadChatsCount > 99
                          ? '99+'
                          : _unreadChatsCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          _buildMyItemsIcon(context),
        ],
      ),
    );
  }

  Widget _buildMinimalNavBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () => _navigate(context, index),
          child: Icon(_getIconForIndex(index), color: Colors.white),
        );
      }),
    );
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.settings;
      case 1:
        return Icons.shopping_bag_outlined;
      case 2:
        return Icons.home_outlined;
      case 3:
        return Icons.chat_bubble_outline;
      case 4:
        return Icons.storage_rounded;
      default:
        return Icons.error;
    }
  }

  Widget _buildIcon(IconData icon, int index, BuildContext context,
      {Key? key}) {
    final active = index == widget.currentIndex;

    return GestureDetector(
      key: key,
      onTap: () => _navigate(context, index),
      child: Icon(
        icon,
        size: active ? 32 : 26,
        color: active ? Colors.white : Colors.white70,
      ),
    );
  }

  Widget _buildChatIcon(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('navChats'),
      onTap: () => _navigate(context, 3),
      child:
          const Icon(Icons.chat_bubble_outline, color: Colors.white70),
    );
  }

  Widget _buildMyItemsIcon(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('navOwner'),
      onTap: () => _navigate(context, 4),
      child:
          const Icon(Icons.storage_rounded, color: Colors.white70),
    );
  }
}
