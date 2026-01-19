import '../models/rental_request.dart';
import '../services/orders_service.dart';

class OrdersController {
  final OrdersService _service;
  final String renterUid;

  OrdersController({
    required this.renterUid,
    OrdersService? service,
  }) : _service = service ?? OrdersService();

  List<String> statusesForTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return ["pending", "accepted"];
      case 1:
        return ["active"];
      case 2:
        return ["ended", "rejected", "cancelled", "outdated"];
      default:
        return [];
    }
  }

  Stream<List<RentalRequest>> getRequestsStream(int tabIndex) {
    final statuses = statusesForTab(tabIndex);
    if (statuses.isEmpty) return Stream.value([]);
    return _service.renterRequestsStream(
      renterUid: renterUid,
      statuses: statuses,
    );
  }

  Stream<int> getRequestsCountStream(int tabIndex) {
    final statuses = statusesForTab(tabIndex);
    if (statuses.isEmpty) return Stream.value(0);

    return _service.renterRequestsStream(
      renterUid: renterUid,
      statuses: statuses,
    ).map((list) => list.length);
  }

  String getTabTitle(int tabIndex, String Function(String) t) {
    switch (tabIndex) {
      case 0:
        return t('pending_orders');
      case 1:
        return t('active_orders');
      case 2:
        return t('previous_orders');
      default:
        return t('error');
    }
  }

  String getEmptyTextForTab(int tabIndex, String Function(String) t) {
    switch (tabIndex) {
      case 0:
        return t('no_pending_orders');
      case 1:
        return t('no_active_orders');
      case 2:
        return t('no_previous_orders');
      default:
        return t('error_loading');
    }
  }

  Map<String, String?> getRequestDetails(RentalRequest req) {
    return {
      'Owner Name': req.ownerName,
      'Rental Type': req.rentalType,
      'Quantity': req.rentalQuantity.toString(),
      'Start Date': _formatDate(req.startDate),
      'End Date': _formatDate(req.endDate),
      'Total Price': '${req.totalPrice.toStringAsFixed(2)}JD',
      if (req.pickupTime != null && req.pickupTime!.isNotEmpty)
        'Pickup Time': req.pickupTime,
    };
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> deleteIfPending(RentalRequest req) async {
    if (req.status != "pending") return;
    await _service.deletePendingRequest(
      requestId: req.id,
    );
  }
}
