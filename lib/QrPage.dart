import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QrPage extends StatefulWidget {
  final String qrToken;
  final String requestId;
  final bool isReturnPhase;

  const QrPage({
    super.key,
    required this.qrToken,
    required this.requestId,
    this.isReturnPhase = false,
  });

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  StreamSubscription<DocumentSnapshot>? _sub;

  @override
  void initState() {
    super.initState();

    // LISTEN FOR STATUS CHANGE
    _sub = FirebaseFirestore.instance
        .collection("rentalRequests")
        .doc(widget.requestId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;

      final status = snap["status"];
      if (!widget.isReturnPhase && status == "active") {
        if (mounted) Navigator.pop(context);
      }
      if (widget.isReturnPhase && status == "ended") {
        if (mounted) Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QrImageView(
                    data: widget.qrToken,
                    version: QrVersions.auto,
                    size: 250,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Waiting for user to scan…",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[200],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
