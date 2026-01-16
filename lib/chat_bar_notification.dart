import 'package:flutter/material.dart';

class ChatBarNotification extends StatefulWidget {
  final String name;
  final String message;
  final String? imageUrl;
  final VoidCallback? onTap;

  const ChatBarNotification({
    super.key,
    required this.name,
    required this.message,
    this.imageUrl,
    this.onTap,
  });

  @override
  State<ChatBarNotification> createState() => _ChatBarNotificationState();
}

class _ChatBarNotificationState extends State<ChatBarNotification>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scale = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    // ▶️ تشغيل الأنيميشن مباشرة
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(100),
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),

                  // ✨ Inner light edge
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),

                  // 🎨 Gradient عنّابي → كحلي
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(255, 150, 20, 70),
                      Color.fromARGB(255, 80, 20, 80),
                      Color.fromARGB(255, 15, 25, 70),
                    ],
                  ),

                  // 🧱 3D Shadow
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.45),
                      offset: const Offset(0, 8),
                      blurRadius: 14,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.18),
                      offset: const Offset(0, -1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // 👤 الصورة
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white.withOpacity(0.18),
                      backgroundImage: widget.imageUrl != null
                          ? NetworkImage(widget.imageUrl!)
                          : null,
                      child: widget.imageUrl == null
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),

                    const SizedBox(width: 12),

                    // 📝 الاسم + الرسالة
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
