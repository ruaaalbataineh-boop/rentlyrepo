import 'package:flutter/material.dart';

class BusinessNotificationBar extends StatelessWidget {
  final String message;
  final Color backgroundColor; // ✅ نفس الاسم
  final IconData icon;
  final VoidCallback onTap;

  const BusinessNotificationBar({
    super.key,
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: backgroundColor, // ✅
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
