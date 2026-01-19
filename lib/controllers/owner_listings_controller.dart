import '../models/rental_request.dart';
import '../services/owner_listings_service.dart';

class OwnerListingsController {
  final String ownerUid;
  final OwnerListingsService _service;

  OwnerListingsController({
    required this.ownerUid,
    OwnerListingsService? service,
  }) : _service = service ?? OwnerListingsService();

  Stream<List<Map<String, dynamic>>> getMyItems() {
    return _service.ownerItemsStream(ownerUid);
  }

  Stream<List<RentalRequest>> getRequests() {
    return _service.ownerRequestsStream(ownerUid);
  }

  Future<void> acceptRequest(String id) async {
    await _service.updateRequestStatus(id, "accepted");
  }

  Future<void> rejectRequest(String id) async {
    await _service.updateRequestStatus(id, "rejected");
  }

  Stream<int> myItemsCount() {
    return _service.myItemsCount(ownerUid);
  }

  Stream<int> pendingRequestsCount() {
    return _service.pendingRequestsCount(ownerUid);
  }

  Future<void> forceActivate(String id) async {
    await _service.forceActivate(id);
  }

  Future<void> forceEnd(String id) async {
    await _service.forceEnd(id);
  }

  bool canReview(RentalRequest r) {
    return (r.status == "ended" || r.status == "cancelled") &&
        r.reviewedByOwnerAt == null;
  }
}
