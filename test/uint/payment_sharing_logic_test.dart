import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:p2/logic/payment_sharing_logic.dart';

void main() {
  group('PaymentSharingLogic Tests', () {
    late SharedPreferences prefs;
    late PaymentSharingLogic logic;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      logic = PaymentSharingLogic(prefs);
    });

    test('initialize loads or creates userId', () async {
      await logic.initialize();
      expect(logic.userId, startsWith('PAY'));
      expect(logic.userId.length, greaterThan(0));
    });

    test('generatePaymentCode creates valid code', () async {
      await logic.initialize();
      final error = await logic.generatePaymentCode('100.50', 'Test Payment');
      
      expect(error, isNull);
      expect(logic.paymentCode, isNotNull);
      expect(logic.paymentCode, contains(logic.userId));
      expect(logic.paymentCode, contains('100.50'));
      expect(logic.showCode, true);
    });

    test('generatePaymentCode returns error for invalid amount', () async {
      await logic.initialize();
      final error1 = await logic.generatePaymentCode('', 'Test');
      expect(error1, 'Please enter a valid amount');
      
      final error2 = await logic.generatePaymentCode('0', 'Test');
      expect(error2, 'Please enter a valid amount');
      
      final error3 = await logic.generatePaymentCode('-10', 'Test');
      expect(error3, 'Please enter a valid amount');
    });

    test('invoices are added and sorted', () async {
      await logic.initialize();
      final initialCount = logic.invoices.length;
      
      await logic.generatePaymentCode('100', 'First');
      await logic.generatePaymentCode('200', 'Second');
      
      expect(logic.invoices.length, initialCount + 2);
      expect(logic.invoices[0]['description'], 'Second');
      
      await logic.toggleSortOrder();
      expect(logic.invoices[0]['description'], 'First');
    });

    test('deleteInvoice removes invoice', () async {
      await logic.initialize();
      await logic.generatePaymentCode('100', 'Test');
      
      final initialLength = logic.invoices.length;
      final invoiceId = logic.invoices.first['id'];
      
      final success = await logic.deleteInvoice(invoiceId);
      expect(success, true);
      expect(logic.invoices.length, initialLength - 1);
    });

    test('deleteInvoice returns false for non-existent invoice', () async {
      await logic.initialize();
      final success = await logic.deleteInvoice('non-existent-id');
      expect(success, false);
    });

    test('toggleInvoiceStatus changes status', () async {
      await logic.initialize();
      await logic.generatePaymentCode('100', 'Test');
      final invoiceId = logic.invoices.first['id'];
      
      expect(logic.getInvoice(invoiceId)?['status'], 'Pending');
      
      await logic.toggleInvoiceStatus(invoiceId);
      expect(logic.getInvoice(invoiceId)?['status'], 'Paid');
      
      await logic.toggleInvoiceStatus(invoiceId);
      expect(logic.getInvoice(invoiceId)?['status'], 'Pending');
    });

    test('getInvoice returns null for non-existent invoice', () async {
      await logic.initialize();
      final invoice = logic.getInvoice('non-existent-id');
      expect(invoice, isNull);
    });

    test('totalInvoices returns correct count', () async {
      await logic.initialize();
      final initialCount = logic.totalInvoices;
      
      await logic.generatePaymentCode('100', 'Test 1');
      expect(logic.totalInvoices, initialCount + 1);
      
      await logic.generatePaymentCode('200', 'Test 2');
      expect(logic.totalInvoices, initialCount + 2);
    });

    test('invoiceId is generated correctly', () async {
      await logic.initialize();
      expect(logic.invoiceId, startsWith('INV-'));
      expect(logic.invoiceId.length, greaterThan(8));
    });

    test('invoiceDate is set to current time', () async {
      await logic.initialize();
      expect(logic.invoiceDate, isNotNull);
      expect(logic.invoiceDate.isBefore(DateTime.now().add(Duration(seconds: 1))), true);
    });

    test('isLoading becomes false after initialize', () async {
      expect(logic.isLoading, true);
      await logic.initialize();
      expect(logic.isLoading, false);
    });
  });
}
