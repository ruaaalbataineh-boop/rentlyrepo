import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:p2/services/firestore_service.dart';
import 'package:p2/services/storage_service.dart';
import 'Orders.dart';
import 'config/dev_config.dart';

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
  final TextEditingController _descriptionController = TextEditingController();
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

    DateTime toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.parse(v);
      throw Exception("Invalid date");
    }

    final startDate = toDate(data["startDate"]);
    final endDate = toDate(data["endDate"]);

    if (!widget.isReturnPhase) {
      final isTodayStart =
          today.year == startDate.year &&
              today.month == startDate.month &&
              today.day == startDate.day;

      if (!DEV_MODE && !isTodayStart) {
        setState(() {
          message =
          "QR Scanner will be available on ${startDate.toString().split(' ')[0]}";
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

    final expiredLimit = endDate.add(const Duration(days: 3));

    if (!DEV_MODE && today.isBefore(endDate)) {
      setState(() {
        message =
        "Return scanner will be available on ${endDate.toString().split(' ')[0]}";
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
    _descriptionController.dispose();
    _sub?.cancel();
    super.dispose();
  }

  // REPORT DIALOG
  void showReportDialog() {
    severity = null;
    pickedImages.clear();
    XFile? pickedVideo;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),

        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          padding: const EdgeInsets.all(18),

          child: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,

                children: [
                  //TITLE
                  Center(
                    child: Text(
                      widget.isReturnPhase
                          ? "Report Return Issue"
                          : "Report Pickup Issue",
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F0F46),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  //  BUTTONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [

                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8A005D),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final img = await ImagePicker().pickImage(
                            source: ImageSource.camera,
                            imageQuality: 85,
                          );
                          if (img != null) {
                            setState(() => pickedImages.add(File(img.path)));
                          }
                        },
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        label: const Text(
                          "Live Photo",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),

                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final vid = await ImagePicker().pickVideo(
                            source: ImageSource.camera,
                            maxDuration: const Duration(seconds: 30),
                          );
                          if (vid != null) {
                            setState(() => pickedVideo = vid);
                          }
                        },
                        icon: const Icon(Icons.videocam, color: Colors.white),
                        label: const Text(
                          "Live Video",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  //IMAGES PREVIEW
                  if (pickedImages.isNotEmpty)
                    Wrap(
                      children: List.generate(
                        pickedImages.length,
                            (i) => Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  pickedImages[i],
                                  width: 95,
                                  height: 95,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => pickedImages.removeAt(i));
                                },
                                child: const CircleAvatar(
                                  radius: 13,
                                  backgroundColor: Colors.red,
                                  child: Icon(Icons.close,
                                      size: 15, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // VIDEO PREVIEW
                  if (pickedVideo != null)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.videocam, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              pickedVideo!.name,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => setState(() => pickedVideo = null),
                          )
                        ],
                      ),
                    ),

                  // DAMAGE DROPDOWN
                  if (widget.isReturnPhase) ...[
                    const SizedBox(height: 14),
                    const Text(
                      "Damage Severity",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    DropdownButtonFormField<String>(
                      value: severity,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFEDE7F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "mild",
                          child: Text("Low Damage"),
                        ),
                        DropdownMenuItem(
                          value: "moderate",
                          child: Text("Medium Damage"),
                        ),
                        DropdownMenuItem(
                          value: "severe",
                          child: Text("Severe Damage"),
                        ),
                      ],
                      onChanged: (v) => setState(() => severity = v),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // DESCRIPTION
                  const Text(
                    "Description (optional)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // BUTTONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Cancel",
                          style:
                          TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          widget.isReturnPhase ? Colors.orange : Colors.red,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          try {
                            final List<String> uploadedUrls = [];

                            // upload IMAGES
                            for (var i = 0; i < pickedImages.length; i++) {
                              final url = await StorageService.uploadReportMedia(
                                requestId: widget.requestId,
                                file: pickedImages[i],
                                fileName: "img_${DateTime.now().millisecondsSinceEpoch}_$i.jpg",
                              );
                              uploadedUrls.add(url);
                            }

                            // upload VIDEO
                            if (pickedVideo != null) {
                              final file = File(pickedVideo!.path);
                              final url = await StorageService.uploadReportMedia(
                                requestId: widget.requestId,
                                file: file,
                                fileName: "video_${DateTime.now().millisecondsSinceEpoch}.mp4",
                              );
                              uploadedUrls.add(url);
                            }

                            await FirestoreService.submitIssueReport(
                              requestId: widget.requestId,
                              type: widget.isReturnPhase ? "return_issue" : "pickup_issue",
                              severity: severity,
                              description: _descriptionController.text,
                              mediaUrls: uploadedUrls,
                            );

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Issue reported successfully")),
                            );

                            // go back to orders
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const OrdersPage(initialTab: 2),
                              ),
                                  (route) => false,
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Failed to submit report: $e")),
                            );
                          }
                        },
                        child: Text(
                          widget.isReturnPhase
                              ? "Submit & End Rental"
                              : "Submit & Cancel Rental",
                          style: const TextStyle(color: Colors.white),
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
      backgroundColor: Colors.white,

      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 6),
            Text(
              widget.isReturnPhase
                  ? "Return - QR Scanner"
                  : "Pickup - QR Scanner",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),

      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : !allowScan
            ? Text(
          message ?? "Scanner unavailable",
          textAlign: TextAlign.center,
          style:
          const TextStyle(fontSize: 18, color: Colors.black87),
        )
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 420,
              width: 330,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: MobileScanner(
                onDetect: (capture) async {
                  if (scanned) return;
                  scanned = true;

                  final qr = capture.barcodes.first.rawValue;
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
                      MaterialPageRoute(
                          builder: (_) =>
                          const OrdersPage(initialTab: 1)),
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

            const SizedBox(height: 20),

            Text(
              widget.isReturnPhase
                  ? "Scan renter's QR to complete return"
                  : "Scan owner's QR to activate rental",
              style: const TextStyle(
                  fontSize: 16, color: Colors.black87),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 14),
              ),
              onPressed: showReportDialog,
              icon: const Icon(Icons.report, color: Colors.white),
              label: const Text(
                "Report Issue",
                style: TextStyle(color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}
