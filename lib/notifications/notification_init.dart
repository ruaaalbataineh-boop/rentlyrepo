import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:p2/notifications/business_notification_bar.dart';
import 'notification_router.dart';
import 'in_app_notification.dart';
import 'chat_notification_manager.dart';

class NotificationInit {
  static bool _started = false;

  static Future<void> start() async {
    if (_started) return;
    _started = true;

    await FirebaseMessaging.instance.requestPermission();

    // 🔔 1) التطبيق مفتوح → In-App Notification
  FirebaseMessaging.onMessage.listen((message) {
  final data = message.data;
  final type = data['type'];

  // 💬 CHAT
  if (type == 'chat') {
    ChatNotificationManager.onMessage(data);
    return;
  }

  // 📦 BUSINESS
  final messageText = (data['message'] ?? '').toString().trim();
  if (messageText.isEmpty) return;

  Color bgColor = Colors.blue;
  IconData icon = Icons.notifications;

  if (type == 'rental_decision') {
    final status = data['status'];

    if (status == 'accepted') {
      bgColor = Colors.green;
      icon = Icons.check_circle;
    } else if (status == 'rejected') {
      bgColor = Colors.red;
      icon = Icons.cancel;
    }
  } else if (type == 'rental_request') {
    bgColor = Colors.orange;
    icon = Icons.hourglass_top;
  } else if (type == 'admin_item_approved') {
    bgColor = Colors.green.shade700;
    icon = Icons.verified;
  }

  InAppNotification.showBusiness(
    child: BusinessNotificationBar(
      message: messageText,
      backgroundColor: bgColor,
      icon: icon,
      onTap: () {
        NotificationRouter.route(data);
      },
    ),
    onDismiss: () {},
  );
});

    // 🔔 2) التطبيق بالخلفية → ضغط على إشعار النظام
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      NotificationRouter.route(message.data);
    });

    // 🔔 3) التطبيق مغلق تمامًا
    final initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      NotificationRouter.route(initialMessage.data);
    }
  }
}
