import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentSharingLogic {
  String userId = '';
  String paymentCode = '';
  String invoiceId = '';
  DateTime invoiceDate = DateTime.now();

  List<Map<String, dynamic>> invoices = [];
  bool newestFirst = true;
  bool showCode = false;
  bool isLoading = true;

  final SharedPreferences prefs;

  PaymentSharingLogic(this.prefs);

  Future<void> initialize() async {
    await _loadOrCreateUserId();
    await _loadInvoices();
    _generateInvoiceId();
    isLoading = false;
  }

  Future<void> _loadOrCreateUserId() async {
    if (prefs.containsKey('permanentUserId')) {
      userId = prefs.getString('permanentUserId')!;
    } else {
      final storedNumber = prefs.getInt('userCounter') ?? 0;
      final newNumber = storedNumber + 1;
      userId = 'PAY${newNumber.toString().padLeft(6, '0')}';
      await prefs.setInt('userCounter', newNumber);
      await prefs.setString('permanentUserId', userId);
    }
  }

  Future<void> _loadInvoices() async {
    final stored = prefs.getStringList('invoices') ?? [];
    invoices = stored
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
    _sortInvoices();
  }

  void _generateInvoiceId() {
    invoiceDate = DateTime.now();
    final t = invoiceDate.millisecondsSinceEpoch.toString();
    invoiceId = 'INV-${t.substring(t.length - 8)}';
  }

  void _sortInvoices() {
    invoices.sort((a, b) {
      final da = DateTime.parse(a['date']);
      final db = DateTime.parse(b['date']);
      return newestFirst ? db.compareTo(da) : da.compareTo(db);
    });
  }

  Future<void> toggleSortOrder() async {
    newestFirst = !newestFirst;
    _sortInvoices();
    await _saveInvoices();
  }

  Future<void> _saveInvoices() async {
    await prefs.setStringList(
      'invoices',
      invoices.map((e) => jsonEncode(e)).toList(),
    );
  }

  Future<String?> generatePaymentCode(String amountStr, String description) async {
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      return 'Please enter a valid amount';
    }

    _generateInvoiceId(); 

    paymentCode =
        '${userId}_${amount.toStringAsFixed(2)}_${invoiceDate.millisecondsSinceEpoch}';

    final invoice = {
      'id': invoiceId,
      'amount': amount.toStringAsFixed(2),
      'description': description.isEmpty ? 'Payment Request' : description,
      'date': invoiceDate.toIso8601String(),
      'status': 'Pending',
      'payment_code': paymentCode,
      'user_id': userId,
      'timestamp': invoiceDate.millisecondsSinceEpoch,  
    };

    invoices.add(invoice);
    _sortInvoices();
    showCode = true;

    await _saveInvoices();

    return null;
  }

  Future<bool> deleteInvoice(String invoiceId) async {
    final initialLength = invoices.length;
    invoices.removeWhere((invoice) => invoice['id'] == invoiceId);

    if (invoices.length < initialLength) {
      await _saveInvoices();
      return true;
    }
    return false;
  }

  Future<void> toggleInvoiceStatus(String invoiceId) async {
    final invoiceIndex = invoices.indexWhere((inv) => inv['id'] == invoiceId);
    
    if (invoiceIndex != -1) {
      final invoice = invoices[invoiceIndex];
      invoice['status'] = invoice['status'] == 'Pending' ? 'Paid' : 'Pending';
      await _saveInvoices();
    }
  }

  Map<String, dynamic>? getInvoice(String invoiceId) {
    final index = invoices.indexWhere((inv) => inv['id'] == invoiceId);
    return index != -1 ? invoices[index] : null;
  }

  int get totalInvoices => invoices.length;
}
