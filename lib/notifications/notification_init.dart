import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_router.dart';

class NotificationInit {
  static bool _started = false;

  static Future<void> start() async {
    if (_started) return;
    _started = true;

    await FirebaseMessaging.instance.requestPermission();

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      NotificationRouter.route(message.data);
    });

    final initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      NotificationRouter.route(initialMessage.data);
    }
  }
}
