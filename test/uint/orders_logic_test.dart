import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:p2/logic/orders_logic.dart';
import 'package:p2/models/rental_request.dart';
import 'package:p2/services/firestore_service.dart';
import 'package:p2/user_manager.dart';
import 'package:p2/security/route_guard.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

void main() {
  late OrdersLogic logic;
  late MockFirestoreService mockService;

 setUp(() {
  mockService = MockFirestoreService();

  RouteGuard.testAuthenticated = true;
  UserManager.setTestUid('testUser123');

  logic = OrdersLogic(service: mockService);
});

tearDown(() {
  RouteGuard.testAuthenticated = false;
  UserManager.setTestUid(null);
});

  tearDown(() {
    RouteGuard.testAuthenticated = false;
   UserManager.setTestUid(null);

  });

  group('OrdersLogic Unit Tests', () {

    test('getStatusesForTab returns correct statuses', () {
      expect(logic.getStatusesForTab(0), ['pending', 'accepted']);
      expect(logic.getStatusesForTab(1), ['active']);
      expect(logic.getStatusesForTab(2),
          ['ended', 'rejected', 'cancelled', 'outdated']);
    });

    test('getStatusesForTab with invalid index returns empty list', () {
      expect(logic.getStatusesForTab(-1), []);
      expect(logic.getStatusesForTab(5), []);
    });

    test('getTabTitle returns correct titles when initialized', () {
      String t(String key) => key;

      expect(logic.getTabTitle(0, t), 'pending_orders');
      expect(logic.getTabTitle(1, t), 'active_orders');
      expect(logic.getTabTitle(2, t), 'previous_orders');
    });

    test('getEmptyTextForTab returns correct messages', () {
      String t(String key) => key;

      expect(logic.getEmptyTextForTab(0, t), 'no_pending_orders');
      expect(logic.getEmptyTextForTab(1, t), 'no_active_orders');
      expect(logic.getEmptyTextForTab(2, t), 'no_previous_orders');
    });

    test('getRequestsStream returns empty stream for invalid tab', () async {
      final stream = logic.getRequestsStream(99);
      final result = await stream.first;
      expect(result, isEmpty);
    });

    test('getRequestDetails returns access denied for wrong user', () {
      final req = RentalRequest(
        id: '1',
        itemId: 'item1',
        itemTitle: 'Camera',
        renterUid: 'anotherUser',
        status: 'active',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 1)),
        totalPrice: 20,
        rentalType: 'daily',
        rentalQuantity: 1, itemOwnerUid: '', renterName: '', rentalPrice: 0, paymentStatus: '',
      );

      final details = logic.getRequestDetails(req);
      expect(details.containsKey('Error'), true);
    });

    test('getRequestDetails returns valid details for correct user', () {
      final req = RentalRequest(
        id: '1',
        itemId: 'item1',
        itemTitle: 'Camera',
        renterUid: 'testUser123',
        ownerName: 'Ali',
        status: 'active',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 3),
        totalPrice: 50,
        rentalType: 'daily',
        rentalQuantity: 1, itemOwnerUid: '', renterName: '', rentalPrice: 0, paymentStatus: '',
      );

      final details = logic.getRequestDetails(req);

      expect(details['Owner Name'], 'Ali');
      expect(details['Total Price'], '50.00JD');
    });

    test('clearCache does not throw', () async {
      await logic.clearCache();
      expect(true, true);
    });

    test('cleanupResources does not throw', () {
      logic.cleanupResources();
      expect(true, true);
    });
  });
}
