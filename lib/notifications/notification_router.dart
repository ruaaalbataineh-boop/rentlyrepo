import 'package:p2/main_user.dart';



class NotificationRouter {
  static void route(Map<String, dynamic> data) {
    final type = data['type'];

    if (type == 'rental_request') {
      navigatorKey.currentState?.pushNamed(
        '/ownerItems',
        arguments: {'tab': 1},
      );
      return;
    }

    if (type == 'rental_status') {
      final requestId = data['requestId'];
      if (requestId != null) {
        navigatorKey.currentState?.pushNamed(
          '/orderDetails',
          arguments: requestId,
        );
      }
      return;
    }
  }
}
