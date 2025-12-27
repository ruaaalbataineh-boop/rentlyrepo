import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
void main() {

  testWidgets('Page UI loads correctly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockQrScannerPage(requestId: "REQ1"),
        ),
      );

      expect(find.text("Scan Pickup QR"), findsOneWidget);
      expect(find.byKey(const Key('scan_btn')), findsOneWidget);
    },
  );

  testWidgets('Successful scan updates request and navigates',
        (tester) async {
      MockFirestoreService.shouldFail = false;

      await tester.pumpWidget(
        const MaterialApp(
          home: MockQrScannerPage(requestId: "REQ123"),
        ),
      );

      await tester.tap(find.byKey(const Key('scan_btn')));
      await tester.pumpAndSettle();

      expect(MockFirestoreService.lastRequestId, "REQ123");
      expect(MockFirestoreService.lastStatus, "active");
      expect(MockFirestoreService.lastQr, "QR123");

      expect(find.byKey(const Key('orders_page')), findsOneWidget);
      expect(find.text("Orders Page - Tab 1"), findsOneWidget);
    },
  );

  testWidgets('Invalid QR shows error message',
        (tester) async {
      MockFirestoreService.shouldFail = true;

      await tester.pumpWidget(
        const MaterialApp(
          home: MockQrScannerPage(requestId: "REQ999"),
        ),
      );

      await tester.tap(find.byKey(const Key('scan_btn')));
      await tester.pump();

      expect(find.text("Invalid QR code"), findsOneWidget);
    },
  );

  testWidgets('Prevent double scan',
        (tester) async {
      MockFirestoreService.shouldFail = false;

      await tester.pumpWidget(
        const MaterialApp(
          home: MockQrScannerPage(requestId: "REQ777"),
        ),
      );

      await tester.tap(find.byKey(const Key('scan_btn')));
      await tester.tap(find.byKey(const Key('scan_btn')));
      await tester.pumpAndSettle();

      expect(MockFirestoreService.lastRequestId, "REQ777");
      expect(find.byKey(const Key('orders_page')), findsOneWidget);
    },
  );
}




class MockFirestoreService {
  static bool shouldFail = false;
  static String? lastRequestId;
  static String? lastStatus;
  static String? lastQr;

  static Future<void> updateRentalRequestStatus(
      String requestId,
      String status, {
        String? qrToken,
      }) async {
    if (shouldFail) {
      throw Exception("Invalid QR");
    }

    lastRequestId = requestId;
    lastStatus = status;
    lastQr = qrToken;
  }
}

/// =======================
/// MOCK ORDERS PAGE
/// =======================
class MockOrdersPage extends StatelessWidget {
  final int initialTab;
  const MockOrdersPage({super.key, required this.initialTab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "Orders Page - Tab $initialTab",
          key: const Key('orders_page'),
        ),
      ),
    );
  }
}

/// =======================
/// MOCK QR SCANNER PAGE
/// =======================
class MockQrScannerPage extends StatelessWidget {
  final String requestId;
  const MockQrScannerPage({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    bool scanned = false;

    return Scaffold(
      appBar: AppBar(title: const Text("Scan Pickup QR")),
      body: Center(
        child: ElevatedButton(
          key: const Key('scan_btn'),
          onPressed: () async {
            if (scanned) return;
            scanned = true;

            final fakeQr = "QR123";

            try {
              await MockFirestoreService.updateRentalRequestStatus(
                requestId,
                "active",
                qrToken: fakeQr,
              );

              if (!context.mounted) return;

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const MockOrdersPage(initialTab: 1),
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
          child: const Text("Simulate Scan"),
        ),
      ),
    );
  }
}


