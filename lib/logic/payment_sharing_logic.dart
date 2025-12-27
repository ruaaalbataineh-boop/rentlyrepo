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
    invoices = stored.map((e) => jsonDecode(e)).cast<Map<String, dynamic>>().toList();
    _sortInvoices();
  }

  void _generateInvoiceId() {
    final t = DateTime.now().millisecondsSinceEpoch.toString();
    invoiceId = 'INV-${t.substring(t.length - 8)}';
    invoiceDate = DateTime.now();
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
    prefs.setStringList(
      'invoices',
      invoices.map((e) => jsonEncode(e)).toList(),
    );
  }

  Future<String?> generatePaymentCode(String amountStr, String description) async {
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      return 'Please enter a valid amount';
    }

    paymentCode = '${userId}_${amount.toStringAsFixed(2)}_${DateTime.now().millisecondsSinceEpoch}';

    final invoice = {
      'id': invoiceId,
      'amount': amount.toStringAsFixed(2),
      'description': description.isEmpty ? 'Payment Request' : description,
      'date': invoiceDate.toIso8601String(),
      'status': 'Pending',
      'payment_code': paymentCode,
      'user_id': userId,
    };

    invoices.add(invoice);
    _sortInvoices();
    showCode = true;

    await _saveInvoices();
    _generateInvoiceId();
    
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
    final invoice = invoices.firstWhere(
      (inv) => inv['id'] == invoiceId,
      orElse: () => {},
    );
    
    if (invoice.isNotEmpty) {
      invoice['status'] = invoice['status'] == 'Pending' ? 'Paid' : 'Pending';
      await _saveInvoices();
    }
  }

  Map<String, dynamic>? getInvoice(String invoiceId) {
    try {
      return invoices.firstWhere((inv) => inv['id'] == invoiceId);
    } catch (e) {
      return null;
    }
  }

  int get totalInvoices => invoices.length;
}
