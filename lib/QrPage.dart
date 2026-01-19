import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
 import 'package:p2/logic/qr_scanner_logic.dart';
import 'package:p2/security/error_handler.dart';
import 'config/dev_config.dart';
import 'package:p2/security/secure_storage.dart';

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
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initializeSecurity();
    _listenStatus();
    _loadQR();
  }

  Future<void> _initializeSecurity() async {
    try {
      
      final token = await SecureStorage.getToken();
      if (token != null) {
      
        _userId = 'current_user_id';
      }
    } catch (error) {
      ErrorHandler.logError('Initialize QR Security', error);
    }
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
    try {
      setState(() => loading = true);

      
      final datesValid = await QrLogic.verifyRequestDates(
        widget.requestId, 
        widget.isReturnPhase
      );

      if (!datesValid && !DEV_MODE) {
        setState(() {
          message = widget.isReturnPhase
              ? "Return QR will be available on the end date."
              : "Pickup QR will be available on the start date.";
          loading = false;
        });
        return;
      }

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
      
      
      final qrField = widget.isReturnPhase ? "returnQrToken" : "pickupQrToken";
      final existingToken = data[qrField]?.toString();

      if (existingToken != null && existingToken.isNotEmpty) {
    
        final isValid = await QrLogic.validateQrToken(existingToken, widget.requestId);
        if (isValid) {
          setState(() {
            qrToken = existingToken;
            loading = false;
          });
          return;
        }
      }

      final newToken = "${widget.requestId}_${DateTime.now().millisecondsSinceEpoch}";
       
      final isValidNew = await QrLogic.validateQrToken(newToken, widget.requestId);
      if (!isValidNew) {
        setState(() {
          message = "Failed to generate valid QR code.";
          loading = false;
        });
        return;
      }

      await ref.update({
        qrField: newToken,
        "${qrField.replaceFirst('Token', 'GeneratedAt')}": FieldValue.serverTimestamp(),
      });

      setState(() {
        qrToken = newToken;
        loading = false;
      });

    } catch (error) {
      ErrorHandler.logError('Load QR', error);
      setState(() {
        message = QrLogic.getSafeMessage(error.toString());
        loading = false;
      });
    }
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: qrToken!,
                    version: QrVersions.auto,
                    size: 250,
                    backgroundColor: Colors.white,
                  ),
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
                const SizedBox(height: 10),
                Text(
                  "Request ID: ${widget.requestId.substring(0, 8)}...",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            )
                : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                QrLogic.getSafeMessage(message),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
