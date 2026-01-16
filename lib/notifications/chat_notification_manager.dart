import 'dart:collection';

import 'package:p2/notifications/chat_id_utils.dart';
import 'package:p2/notifications/active_chat_tracker.dart';

import 'in_app_notification.dart';
import 'notification_router.dart';

class ChatNotificationManager {
  static final Queue<Map<String, dynamic>> _queue = Queue();
  static bool _isShowing = false;

  static void onMessage(Map<String, dynamic> data) {
    _queue.addLast(data);
    _tryShowNext();
  }

  static void _tryShowNext() {
    if (_isShowing || _queue.isEmpty) return;

    _isShowing = true;
    final data = _queue.removeFirst();

    // ---------- message text ----------
    final messageText =
        (data['messageText'] ?? '').toString().trim();

    if (messageText.isEmpty) {
      _isShowing = false;
      _tryShowNext();
      return;
    }

    // ---------- sender name ----------
    final senderName =
        (data['senderName'] ?? '').toString().trim();

    if (senderName.isEmpty) {
      _isShowing = false;
      _tryShowNext();
      return;
    }

    // ---------- chatId normalize ----------
    final chatIdRaw =
        (data['chatId'] ?? '').toString().trim();

    if (chatIdRaw.isEmpty) {
      _isShowing = false;
      _tryShowNext();
      return;
    }

    final parts = chatIdRaw.split('-');
    String normalizedChatId = chatIdRaw;

    if (parts.length >= 2) {
      normalizedChatId =
          normalizeChatId(parts[0], parts[1]);
    }

    // ---------- BLOCK if same chat open ----------
    if (ActiveChatTracker.activeChatId ==
        normalizedChatId) {
      _isShowing = false;
      _tryShowNext();
      return;
    }

    // ---------- BLOCK if on chat list ----------
    if (ActiveChatTracker.isOnChatPage) {
      _isShowing = false;
      _tryShowNext();
      return;
    }

    // ---------- show notification ----------
    InAppNotification.show(
      name: senderName,
      message: messageText,
      imageUrl: data['senderImage'],
      onTap: () {
        NotificationRouter.route(data);
        _onDismiss();
      },
      onDismiss: _onDismiss,
    );
  }

  static void _onDismiss() {
    _isShowing = false;
    _tryShowNext();
  }
}
