import 'dart:async';
import 'package:flutter/material.dart';
import '../main_user.dart';
import '../chat_bar_notification.dart';

class InAppNotification {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static final ValueNotifier<_NotifData?> _dataNotifier =
      ValueNotifier(null);

  static void show({
    required String name,
    required String message,
    String? imageUrl,
    required VoidCallback onTap,
    required VoidCallback onDismiss, // 👈 جديد

  }) {
    _dataNotifier.value = _NotifData(
      name: name,
      message: message,
      imageUrl: imageUrl,
      onTap: onTap,
    );

    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    if (_entry == null) {
      _entry = OverlayEntry(
        builder: (context) => SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ValueListenableBuilder<_NotifData?>(
                valueListenable: _dataNotifier,
                builder: (_, data, __) {
                  if (data == null) return const SizedBox();

                  return Material(
                    color: Colors.transparent,
                   child: ChatBarNotification(
                      name: data.name,
                      message: data.message,
                      imageUrl: data.imageUrl,
                      onTap: () {
                        hide();
                        data.onTap();
                        onDismiss();
                      },
                    ),
    
                  );
                },
              ),
            ),
          ),
        ),
      );

      overlay.insert(_entry!);
    }

    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 4), () {
  hide();
  onDismiss(); // 👈 مهم
    });
  }


static void showBusiness({
  required Widget child,
  required VoidCallback onDismiss,
}) {
  final overlay = navigatorKey.currentState?.overlay;
  if (overlay == null) return;

  // نشيل أي إشعار حالي
  hide();

  _entry = OverlayEntry(
    builder: (_) => SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Material(
            color: Colors.transparent,
            child: child,
          ),
        ),
      ),
    ),
  );

  overlay.insert(_entry!);

  _timer?.cancel();
  _timer = Timer(const Duration(seconds: 4), () {
    hide();
    onDismiss();
  });
}


  static void hide() {
    _timer?.cancel();
    _dataNotifier.value = null;
    _entry?.remove();
    _entry = null;
  }
}

class _NotifData {
  final String name;
  final String message;
  final String? imageUrl;
  final VoidCallback onTap;

  _NotifData({
    required this.name,
    required this.message,
    this.imageUrl,
    required this.onTap,
  });
}
