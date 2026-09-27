import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constant/app_colors.dart';
import '../../../core/constant/app_sizes.dart';
import '../../../core/helper/sound_helper.dart';

/// Floating Top Push Notification Banner that slides down from top with audio chime
class TopNotificationBanner {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show({
    required BuildContext? context,
    required String title,
    required String message,
    String? imageUrl,
    VoidCallback? onTap,
    Duration duration = const Duration(milliseconds: 4500),
  }) {
    // 1. Play audible sound chime immediately
    SoundHelper.playNotificationSound();

    // 2. Find overlay context
    final overlayState = context != null
        ? Overlay.maybeOf(context)
        : null;

    if (overlayState == null) return;

    // Remove any previous active banner
    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _NotificationBannerWidget(
        title: title,
        message: message,
        imageUrl: imageUrl,
        onTap: onTap,
        onDismiss: () {
          _dismissTimer?.cancel();
          entry.remove();
          if (_currentEntry == entry) _currentEntry = null;
        },
      ),
    );

    _currentEntry = entry;
    overlayState.insert(entry);

    _dismissTimer = Timer(duration, () {
      if (_currentEntry == entry) {
        entry.remove();
        _currentEntry = null;
      }
    });
  }
}

class _NotificationBannerWidget extends StatefulWidget {
  final String title;
  final String message;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  const _NotificationBannerWidget({
    required this.title,
    required this.message,
    this.imageUrl,
    this.onTap,
    required this.onDismiss,
  });


  @override
  State<_NotificationBannerWidget> createState() => _NotificationBannerWidgetState();
}

class _NotificationBannerWidgetState extends State<_NotificationBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleDismiss() async {
    await _animController.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                if (widget.onTap != null) {
                  _handleDismiss();
                  widget.onTap!();
                }
              },
              child: Container(
                width: 380,
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColor.primary.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.primary.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App Icon with Pulse / Sound Badge
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.notifications_active_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Notification Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'EGO STORE • PUSH',
                                style: TextStyle(
                                  color: Color(0xFFA78BFA),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              InkWell(
                                onTap: _handleDismiss,
                                borderRadius: BorderRadius.circular(12),
                                child: const Padding(
                                  padding: EdgeInsets.all(2.0),
                                  child: Icon(Icons.close_rounded, size: 16, color: Colors.white54),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.message,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Optional Image Thumbnail
                    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.imageUrl!,
                          width: 42,
                          height: 42,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
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
