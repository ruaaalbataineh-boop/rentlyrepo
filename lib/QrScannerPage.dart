import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:p2/services/firestore_service.dart';
import 'package:p2/services/storage_service.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/input_validator.dart';
import 'package:p2/security/secure_storage.dart';
import 'views/Orders.dart';
import 'config/dev_config.dart';
import 'package:p2/logic/qr_scanner_logic.dart';
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
  String? _userId;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _initializeSecurity();
    _listenStatus();
    _checkAvailability();
    _scannerController = MobileScannerController();
  }

  Future<void> _initializeSecurity() async {
    try {
      
      final token = await SecureStorage.getToken();
      if (token != null) {
    
        _userId = 'current_user_id'; 
      }
    } catch (error) {
      ErrorHandler.logError('Initialize Scanner Security', error);
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

  Future<void> _checkAvailability() async {
    try {
      final datesValid = await QrLogic.verifyRequestDates(
        widget.requestId, 
        widget.isReturnPhase
      );

      if (!datesValid && !DEV_MODE) {
        setState(() {
          message = widget.isReturnPhase
              ? "Return scanner will be available on the end date."
              : "Pickup scanner will be available on the start date.";
          loading = false;
        });
        return;
      }

      
      if (_userId != null) {
        final hasPermission = await QrLogic.validateUserPermission(
          widget.requestId, 
          _userId!
        );
        
        if (!hasPermission) {
          setState(() {
            message = "You don't have permission to scan this QR.";
            loading = false;
          });
          return;
        }
      }

      setState(() {
        allowScan = true;
        loading = false;
      });
    } catch (error) {
      ErrorHandler.logError('Check Availability', error);
      setState(() {
        message = QrLogic.getSafeMessage(error.toString());
        loading = false;
      });
    }
  }

  Future<void> _handleQrScan(String qrCode) async {
    if (scanned) return;
    scanned = true;

    try {
  
      final isValid = await QrLogic.validateQrToken(qrCode, widget.requestId);
      if (!isValid) {
        scanned = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(QrLogic.getInvalidQrMessage()),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      
      if (_userId != null) {
        final scanValid = await QrLogic.validateScanRequest(
          widget.requestId, 
          qrCode, 
          widget.isReturnPhase, 
          _userId!
        );

        if (!scanValid) {
          scanned = false;
          return;
        }
      }

      
      if (widget.isReturnPhase) {
        await FirestoreService.confirmReturn(
          requestId: widget.requestId,
          qrToken: qrCode,
        );
      } else {
        await FirestoreService.confirmPickup(
          requestId: widget.requestId,
          qrToken: qrCode,
        );
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(QrLogic.getSuccessMessage(widget.isReturnPhase)),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const OrdersPage(initialTab: 1)),
          (route) => false,
      );
    } catch (error) {
      scanned = false;
      ErrorHandler.logError('Handle QR Scan', error);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(QrLogic.getErrorMessage(widget.isReturnPhase)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final img = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (img != null) {
        final file = File(img.path);
        
      
        final fileSize = await file.length();
        const maxSize = 10 * 1024 * 1024; // 10MB
        
        if (fileSize > maxSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Image is too large. Maximum size is 10MB.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() => pickedImages.add(file));
      }
    } catch (error) {
      ErrorHandler.logError('Pick Image from Camera', error);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getSafeError(error)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickVideoFromCamera() async {
    try {
      final vid = await ImagePicker().pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 30),
      );
      
      if (vid != null) {
        final file = File(vid.path);
        final fileSize = await file.length();
        const maxSize = 50 * 1024 * 1024; // 50MB
        
        if (fileSize > maxSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Video is too large. Maximum size is 50MB.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        setState(() {});
      }
    } catch (error) {
      ErrorHandler.logError('Pick Video from Camera', error);
    }
  }

  void showReportDialog() {
    severity = null;
    pickedImages.clear();
    _descriptionController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: _buildReportDialogContent(context),
      ),
    );
  }

  Widget _buildReportDialogContent(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.95,
      padding: const EdgeInsets.all(18),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
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

            _buildMediaButtons(context),

            const SizedBox(height: 20),

            if (pickedImages.isNotEmpty) _buildImagesPreview(),

            if (widget.isReturnPhase) _buildDamageDropdown(),

            const SizedBox(height: 16),

            _buildDescriptionField(),

            const SizedBox(height: 22),

            _buildDialogButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8A005D),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _pickImageFromCamera,
          icon: const Icon(Icons.camera_alt, color: Colors.white),
          label: const Text(
            "Live Photo",
            style: TextStyle(color: Colors.white),
          ),
        ),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _pickVideoFromCamera,
          icon: const Icon(Icons.videocam, color: Colors.white),
          label: const Text(
            "Live Video",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildImagesPreview() {
    return Wrap(
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
                  child: Icon(Icons.close, size: 15, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDamageDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          validator: (value) {
            if (value == null) {
              return 'Please select damage severity';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Description (optional)",
          style: TextStyle(fontWeight: FontWeight.bold),
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
      ],
    );
  }

  Widget _buildDialogButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "Cancel",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isReturnPhase ? Colors.orange : Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () async {
            try {
              final safeDescription = InputValidator.sanitizeInput(
                _descriptionController.text
              );

              final List<String> uploadedUrls = [];

    
              for (var image in pickedImages) {
                final url = await StorageService.uploadReportMedia(
                  requestId: widget.requestId,
                  file: image,
                  fileName: "img_${DateTime.now().millisecondsSinceEpoch}.jpg",
                );
                uploadedUrls.add(url);
              }

              await FirestoreService.submitIssueReport(
                requestId: widget.requestId,
                type: widget.isReturnPhase ? "return_issue" : "pickup_issue",
                severity: severity,
                description: safeDescription,
                mediaUrls: uploadedUrls,
              );

              if (!mounted) return;
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Issue reported successfully"),
                  backgroundColor: Colors.green,
                ),
              );

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const OrdersPage(initialTab: 2),
                ),
                (route) => false,
              );
            } catch (error) {
              ErrorHandler.logError('Submit Report', error);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ErrorHandler.getSafeError(error)),
                    backgroundColor: Colors.red,
                  ),
                );
              }
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
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _sub?.cancel();
    _scannerController?.dispose();
    super.dispose();
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
            ? Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  QrLogic.getSafeMessage(message),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.black87),
                ),
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
                      controller: _scannerController,
                      onDetect: (capture) async {
                        final qr = capture.barcodes.first.rawValue;
                        if (qr != null) {
                          await _handleQrScan(qr);
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    widget.isReturnPhase
                        ? "Scan renter's QR to complete return"
                        : "Scan owner's QR to activate rental",
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
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
