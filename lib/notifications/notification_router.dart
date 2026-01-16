import 'package:flutter/material.dart';
import 'package:p2/main_user.dart';
import 'package:p2/ChatScreen.dart';
import 'package:p2/notifications/active_chat_tracker.dart';
import 'package:p2/notifications/chat_id_utils.dart';

class NotificationRouter {
  static void route(Map<String, dynamic> data) {
    final type = data['type'];

    // 💬 Chat notification
    if (type == 'chat') {
      _openChat(data);
      return;
    }

    // 📥 New rental request → Owner Requests tab
    if (type == 'rental_request') {
      navigatorKey.currentState?.pushNamed(
        '/ownerItems',
        arguments: {'tab': 1},
      );
      return;
    }

    // ✅ / ❌ Accept / Reject → User Orders
    if (type == 'rental_decision') {
      navigatorKey.currentState?.pushNamed(
        '/orders',
        arguments: {'tab': 0},
      );
      return;
    }
  }

  static void _openChat(Map<String, dynamic> data) {
    final senderUid = data['senderUid'];
    final senderName = data['senderName'];
    final chatIdRaw = data['chatId'];

    if (senderUid == null || senderName == null || chatIdRaw == null) {
      return;
    }

    // 🔁 normalize chatId (same logic everywhere)
    final parts = chatIdRaw.toString().split('-');
    String normalizedChatId = chatIdRaw.toString();

    if (parts.length >= 2) {
      normalizedChatId =
          normalizeChatId(parts[0], parts[1]);
    }

    // ❌ إذا نفس الشات مفتوح، لا تفتح واحد جديد
    if (ActiveChatTracker.activeChatId ==
        normalizedChatId) {
      return;
    }

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          personUid: senderUid,
          personName: senderName,
        ),
      ),
    );
  }
}
