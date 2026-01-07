import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'config/dev_config.dart';

class QrPage extends StatefulWidget {
  final String requestId;
  final bool isReturnPhase;

  const QrPage({
    super.key,
    required this.requestId,
    this.isReturnPhase = false,
  });

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  StreamSubscription<DocumentSnapshot>? _sub;

  String? qrToken;
  String? message;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _listenStatus();
    _loadQR();
  }

  void _listenStatus() {
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

  Future<void> _loadQR() async {
    final ref = FirebaseFirestore.instance
        .collection("rentalRequests")
        .doc(widget.requestId);

    final doc = await ref.get();
    if (!doc.exists) {
      setState(() {
        message = "Rental request not found.";
        loading = false;
      });
      return;
    }

    final data = doc.data()!;
    final today = DateTime.now();

    // convert safely
    DateTime toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.parse(v);
      throw Exception("Invalid date format");
    }

    final startDate = toDate(data["startDate"]);
    final endDate = toDate(data["endDate"]);

    //START PHASE
    if (!widget.isReturnPhase) {
      final isTodayStart =
          today.year == startDate.year &&
              today.month == startDate.month &&
              today.day == startDate.day;

      if (!DEV_MODE && !isTodayStart) {
        setState(() {
          message =
          "QR Code will be available on ${startDate.toString().split(' ')[0]}.";
          loading = false;
        });
        return;
      }

      // reuse QR
      final existing = data["pickupQrToken"];
      if (existing != null && existing.toString().isNotEmpty) {
        setState(() {
          qrToken = existing;
          loading = false;
        });
        return;
      }

      // Create new token
      final newToken = "${widget.requestId}_${DateTime.now().millisecondsSinceEpoch}";
      await ref.update({
        "pickupQrToken": newToken,
        "pickupQrGeneratedAt": FieldValue.serverTimestamp(),
      });

      setState(() {
        qrToken = newToken;
        loading = false;
      });

      return;
    }

    // RETURN PHASE
    final expiredLimit = endDate.add(const Duration(days: 3));

    if (!DEV_MODE && today.isBefore(endDate)) {
      setState(() {
        message =
        "Return QR will be available on ${endDate.toString().split(' ')[0]}.";
        loading = false;
      });
      return;
    }

    if (today.isAfter(expiredLimit)) {
      setState(() {
        message =
        "Return period expired.\nThis rental has been automatically closed.";
        loading = false;
      });
      return;
    }

    // Inside allowed window, show QR
    final existing = data["returnQrToken"];
    if (existing != null && existing.toString().isNotEmpty) {
      setState(() {
        qrToken = existing;
        loading = false;
      });
      return;
    }

    final newToken = "${widget.requestId}_${DateTime.now().millisecondsSinceEpoch}";
    await ref.update({
      "returnQrToken": newToken,
      "returnQrGeneratedAt": FieldValue.serverTimestamp(),
    });

    setState(() {
      qrToken = newToken;
      loading = false;
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

          Center(
            child: loading
                ? const CircularProgressIndicator(color: Colors.white)
                : qrToken != null
                ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QrImageView(
                  data: qrToken!,
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 20),
                Text(
                  widget.isReturnPhase
                      ? "Waiting for owner to scan…"
                      : "Waiting for renter to scan…",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[200],
                  ),
                ),
              ],
            )
                : Text(
              message ?? "QR unavailable",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
