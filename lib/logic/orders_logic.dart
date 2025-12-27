
import 'package:p2/models/rental_request.dart';
import 'package:p2/services/firestore_service.dart';
import 'package:p2/user_manager.dart';

class OrdersLogic {
  final FirestoreService firestoreService;
  
  OrdersLogic({FirestoreService? service})
      : firestoreService = service ?? FirestoreService();

  String get renterUid => UserManager.uid!;

  
  List<String> getStatusesForTab(int tabIndex) {
    switch (tabIndex) {
      case 0: 
        return ["pending", "accepted"];
      case 1: 
        return ["active"];
      case 2: 
        return ["ended", "rejected"];
      default:
        return [];
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
        return '';
    }
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
        return '';
    }
  }

  
  Stream<List<RentalRequest>> getRequestsStream(int tabIndex) {
    final statuses = getStatusesForTab(tabIndex);
    return FirestoreService.getRenterRequestsByStatuses(renterUid, statuses);
  }


  bool shouldShowQRButton(String status) {
    return status == "accepted";
  }

  
  Map<String, String> getRequestDetails(RentalRequest req) {
    final details = <String, String>{
      'Rental Type': req.rentalType,
      'Quantity': req.rentalQuantity.toString(),
      'Start Date': _formatDate(req.startDate),
      'End Date': _formatDate(req.endDate),
      'Total Price': 'JOD ${req.totalPrice.toStringAsFixed(2)}',
    };
    

    if (req.startTime != null && req.startTime!.isNotEmpty) {
      details['Start Time'] = req.startTime!;
    }
    
    if (req.endTime != null && req.endTime!.isNotEmpty) {
      details['End Time'] = req.endTime!;
    }
    
    if (req.pickupTime != null && req.pickupTime!.isNotEmpty) {
      details['Pickup Time'] = req.pickupTime!;
    }
    
    return details;
  }


  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
