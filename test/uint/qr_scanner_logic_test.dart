
import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/qr_scanner_logic.dart';


void main() {
  group('QrScannerLogic', () {
    test('validateQrCode returns false for null', () {
      expect(QrScannerLogic.validateQrCode(null), false);
    });

    test('validateQrCode returns false for empty string', () {
      expect(QrScannerLogic.validateQrCode(''), false);
    });

    test('validateQrCode returns true for valid qr', () {
      expect(QrScannerLogic.validateQrCode('valid_qr_123'), true);
      expect(QrScannerLogic.validateQrCode('ABC123'), true);
    });

    test('shouldProcessQr returns false for null', () {
      expect(QrScannerLogic.shouldProcessQr(null), false);
    });

    test('shouldProcessQr returns true for non-null', () {
      expect(QrScannerLogic.shouldProcessQr('qr_code'), true);
      expect(QrScannerLogic.shouldProcessQr(''), true);
    });

    test('getSuccessMessage returns correct message', () {
      expect(QrScannerLogic.getSuccessMessage(), "Pickup confirmed");
    });

    test('getErrorMessage returns correct message', () {
      expect(QrScannerLogic.getErrorMessage(), "Invalid QR code");
    });

    test('getNullErrorMessage returns correct message', () {
      expect(QrScannerLogic.getNullErrorMessage(), "No QR code detected");
    });
  });
}
