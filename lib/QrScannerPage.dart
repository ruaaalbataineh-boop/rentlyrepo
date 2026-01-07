import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:p2/services/firestore_service.dart';

import 'Orders.dart';

class QrScannerPage extends StatefulWidget {
  final String requestId;
  final bool isReturnPhase;

  const QrScannerPage({
    super.key,
    required this.requestId,
    this.isReturnPhase = false,
  });

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  StreamSubscription<DocumentSnapshot>? _sub;

  bool loading = true;
  bool allowScan = false;
  String? message;

  bool scanned = false;

  final List<File> pickedImages = [];
  String? severity;

  @override
  void initState() {
    super.initState();
    _listenStatus();
    _checkAvailability();
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

  Future<void> _checkAvailability() async {
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

    final startDate = DateTime.parse(data["startDate"]);
    final endDate = DateTime.parse(data["endDate"]);

    //PICKUP PHASE
    if (!widget.isReturnPhase) {
      final isTodayStart =
          today.year == startDate.year &&
              today.month == startDate.month &&
              today.day == startDate.day;

      if (!isTodayStart) {
        setState(() {
          message =
          "QR Scanner will be available on ${startDate.toString().split(' ')[0]}.";
          loading = false;
        });
        return;
      }

      setState(() {
        allowScan = true;
        loading = false;
      });
      return;
    }

    //RETURN PHASE
    final expiredLimit = endDate.add(const Duration(days: 3));

    if (today.isBefore(endDate)) {
      setState(() {
        message =
        "Return scanner will be available on ${endDate.toString().split(' ')[0]}.";
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

    setState(() {
      allowScan = true;
      loading = false;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  //  REPORT ISSUE UI
  Future<void> pickImages() async {
    final images = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (images == null) return;

    setState(() {
      pickedImages.addAll(images.map((e) => File(e.path)));
    });
  }

  void removeImage(int index) {
    setState(() => pickedImages.removeAt(index));
  }

  void showReportDialog() {
    severity = null;
    pickedImages.clear();
    XFile? pickedVideo;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.92,
          padding: const EdgeInsets.all(16),
          child: StatefulBuilder(
            builder: (context, setState) =>
                SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Center(
                        child: Text(
                          widget.isReturnPhase
                              ? "Report Return Issue"
                              : "Report Pickup Issue",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [

                          //CAMERA
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8A005D),
                            ),
                            onPressed: () async {
                              final img = await ImagePicker().pickImage(
                                source: ImageSource.camera,
                                imageQuality: 85,
                              );
                              if (img != null) {
                                setState(() =>
                                    pickedImages.add(File(img.path)));
                              }
                            },
                            icon: const Icon(Icons.camera_alt),
                            label: const Text("Camera"),
                          ),

                          //VIDEO
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            onPressed: () async {
                              final vid = await ImagePicker().pickVideo(
                                source: ImageSource.camera,
                                maxDuration:
                                const Duration(seconds: 30),
                              );
                              if (vid != null) {
                                setState(() => pickedVideo = vid);
                              }
                            },
                            icon: const Icon(Icons.videocam),
                            label: const Text("Video"),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // PREVIEW IMAGES
                      if (pickedImages.isNotEmpty)
                        Wrap(
                          children: List.generate(
                            pickedImages.length,
                                (i) => Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Image.file(
                                    pickedImages[i],
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() =>
                                          pickedImages.removeAt(i));
                                    },
                                    child: const CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.red,
                                      child: Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // PREVIEW VIDEO
                      if (pickedVideo != null)
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Row(
                            children: [
                              const Icon(Icons.videocam,
                                  color: Colors.orange),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  pickedVideo!.name,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    setState(() => pickedVideo = null),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                              )
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      // RETURN ONLY DAMAGE LEVEL
                      if (widget.isReturnPhase)
                        DropdownButtonFormField<String>(
                          value: severity,
                          dropdownColor: Colors.white,
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Color(0xFFEDE7F6),
                            labelText: "Damage Severity",
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: "low",
                                child: Text("Low Damage")),
                            DropdownMenuItem(
                                value: "medium",
                                child: Text("Medium Damage")),
                            DropdownMenuItem(
                                value: "high",
                                child: Text("Severe Damage")),
                          ],
                          onChanged: (v) =>
                              setState(() => severity = v),
                        ),

                      const SizedBox(height: 14),

                      //  DESCRIPTION
                      TextField(
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: "Describe the issue (optional)",
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.isReturnPhase
                                  ? Colors.orange
                                  : Colors.red,
                            ),
                            onPressed: () async {
                              Navigator.pop(context);

                              await FirestoreService
                                  .updateRentalRequestStatus(
                                widget.requestId,
                                widget.isReturnPhase
                                    ? "ended"
                                    : "cancelled",
                              );
                            },
                            child: Text(
                              widget.isReturnPhase
                                  ? "Submit & End Rental"
                                  : "Submit & Cancel Rental",
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
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
                : !allowScan
                ? Text(
              message ?? "Scanner unavailable",
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 18),
            )
                : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 350,
                  width: 300,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: MobileScanner(
                    onDetect: (capture) async {
                      if (scanned) return;
                      scanned = true;

                      final qr =
                          capture.barcodes.first.rawValue;
                      if (qr == null) return;

                      try {
                        if (widget.isReturnPhase) {
                          await FirestoreService.confirmReturn(
                            requestId: widget.requestId,
                            qrToken: qr,
                          );
                        } else {
                          await FirestoreService.confirmPickup(
                            requestId: widget.requestId,
                            qrToken: qr,
                          );
                        }

                        if (!context.mounted) return;

                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const OrdersPage(initialTab: 1)),
                              (route) => false,
                        );
                      } catch (e) {
                        scanned = false;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Scan failed: $e")),
                        );
                      }

                    },
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  widget.isReturnPhase
                      ? "Scan renter's QR to complete return"
                      : "Scan owner's QR to activate rental",
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16),
                ),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  onPressed: showReportDialog,
                  icon: const Icon(Icons.report),
                  label: const Text("Report Issue"),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
