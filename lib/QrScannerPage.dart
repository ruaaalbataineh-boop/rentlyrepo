import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:p2/services/firestore_service.dart';

import 'Orders.dart';

class QrScannerPage extends StatelessWidget {
  final String requestId;

  const QrScannerPage({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    bool scanned = false;

    return Scaffold(
      appBar: AppBar(title: const Text("Scan Pickup QR")),
      body: MobileScanner(
        onDetect: (capture) async {
          if (scanned) return; // prevent double scan
          scanned = true;

          final qr = capture.barcodes.first.rawValue;
          if (qr == null) return;

          try {
            await FirestoreService.updateRentalRequestStatus(
              requestId,
              "active",
              qrToken: qr,
            );

            if (!context.mounted) return;

            // ✅ Close scanner + go to OrdersPage Active tab
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const OrdersPage(initialTab: 1),
              ),
                  (route) => false,
            );
          } catch (e) {
            scanned = false;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Invalid QR code")),
            );
          }
        },
      ),
    );
  }
}
