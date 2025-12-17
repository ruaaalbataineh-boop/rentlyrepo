import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class AdminLayout extends StatefulWidget {
  final Widget child;
  const AdminLayout({super.key, required this.child});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  final String ADMIN_UID = "m3B5iwPzb3N8EffKu0PsLnpb93k2";

  DateTime? _lastSeenTime;
  bool _snackVisible = false;

  @override
  void initState() {
    super.initState();

    
    _lastSeenTime = DateTime.now();

    FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: ADMIN_UID)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) return;

      final doc = snapshot.docs.first;
      final data = doc.data();

      final Timestamp? ts = data['createdAt'];
      if (ts == null) return;

      final createdAt = ts.toDate();

      
      if (createdAt.isBefore(_lastSeenTime!)) return;

      if (_snackVisible) return;

      _snackVisible = true;

      final snackBar = SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                data['title'] ?? 'New item pending approval',
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1F0F46),
        behavior: SnackBarBehavior.floating,

        // SnackBar   
        margin: const EdgeInsets.only(
          top: 20,
          left: 16,
          right: 16,
          bottom: 600,
        ),

        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            context.go('/items'); 
          },
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      Future.delayed(const Duration(seconds: 4), () {
        _snackVisible = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
    );
  }
}
