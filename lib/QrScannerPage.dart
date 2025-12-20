
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:p2/logic/qr_scanner_logic.dart';
import 'package:p2/services/firestore_service.dart';


class QrScannerPage extends StatelessWidget {
  final String requestId;

  const QrScannerPage({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Pickup QR")),
      body: MobileScanner(
        onDetect: (capture) async {
          final qr = capture.barcodes.first.rawValue;
          
          if (!QrScannerLogic.shouldProcessQr(qr)) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(QrScannerLogic.getNullErrorMessage())),
              );
            }
            return;
          }

          if (!QrScannerLogic.validateQrCode(qr)) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(QrScannerLogic.getErrorMessage())),
              );
            }
            return;
          }

          try {
            await FirestoreService.updateRentalRequestStatus(
              requestId,
              "active",
              qrToken: qr!,
            );

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(QrScannerLogic.getSuccessMessage())),
              );
              Navigator.pop(context);
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(QrScannerLogic.getErrorMessage())),
              );
            }
          }
        },
      ),
    );
  }
}
