import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../views/Categories_Page.dart';
import '../views/Chats_Page.dart';
import '../views/Orders.dart';
import '../views/Setting.dart';
import '../views/owner_listings.dart';

import '../services/auth_service.dart';
import 'package:p2/notifications/active_chat_tracker.dart';
import '../security/error_handler.dart';

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
  StreamSubscription<DatabaseEvent>? _chatsSub;
  StreamSubscription<QuerySnapshot>? _pendingRequestsSub;

  int _pendingRequestsCount = 0;
  int _unreadChatsCount = 0;

  final int _maxUnreadCount = 99;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final auth = context.read<AuthService>();
      final uid = auth.currentUid;

      if (uid == null) return;

      _listenToPendingRequests(uid);
      _listenToChats(uid);

      setState(() => _isInitialized = true);
    } catch (e) {
      ErrorHandler.logError('BottomNav Init', e);
    }
  }

  @override
  void dispose() {
    _chatsSub?.cancel();
    _pendingRequestsSub?.cancel();
    super.dispose();
  }

  void _listenToPendingRequests(String uid) {
    _pendingRequestsSub = FirebaseFirestore.instance
        .collection("rentalRequests")
        .where("itemOwnerUid", isEqualTo: uid)
        .where("status", isEqualTo: "pending")
        .snapshots()
        .listen((snap) {
      if (!mounted) return;

      setState(() {
        _pendingRequestsCount =
        snap.docs.length > _maxUnreadCount
            ? _maxUnreadCount
            : snap.docs.length;
      });
    });
  }

  void _listenToChats(String uid) {
    _chatsSub = FirebaseDatabase.instance.ref("chats").onValue.listen((event) {
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
        final lastSender = chatData['lastSender'];

        if (unreadMap is! Map) return;

        if (unreadMap[uid] == true && lastSender != uid) {
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
          (_) => false,
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
          _buildIcon(Icons.settings, 0),
          _buildIcon(Icons.shopping_bag_outlined, 1),
          _buildIcon(Icons.home_outlined, 2),

          Stack(
            clipBehavior: Clip.none,
            children: [
              _buildIcon(Icons.chat_bubble_outline, 3),
              if (_unreadChatsCount > 0)
                _badge(_unreadChatsCount),
            ],
          ),

          Stack(
            clipBehavior: Clip.none,
            children: [
              _buildIcon(Icons.storage_rounded, 4),
              if (_pendingRequestsCount > 0 && widget.currentIndex != 4)
                _badge(_pendingRequestsCount),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalNavBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(5, (i) {
        return GestureDetector(
          onTap: () => _navigate(context, i),
          child: Icon(_getIcon(i), color: Colors.white),
        );
      }),
    );
  }

  IconData _getIcon(int index) {
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

  Widget _buildIcon(IconData icon, int index) {
    final active = index == widget.currentIndex;

    return GestureDetector(
      onTap: () => _navigate(context, index),
      child: Icon(
        icon,
        size: active ? 32 : 26,
        color: active ? Colors.white : Colors.white70,
      ),
    );
  }

  Widget _badge(int count) {
    return Positioned(
      top: -6,
      right: -10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
