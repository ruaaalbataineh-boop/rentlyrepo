import 'fcm_service.dart';
import '../notifications/notification_init.dart';

class AppInitService {
  static Future<void> initialize() async {
    await FcmService.init();
    await NotificationInit.start();
  }
}
