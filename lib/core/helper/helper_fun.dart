import 'package:flutter/material.dart';
import '../../common/widgets/notifications/top_notification_banner.dart';
import '../constant/app_colors.dart';
import '../constant/app_sizes.dart';
import 'sound_helper.dart';

/// Helper functions strictly following CODING_GUIDELINES.md and AI_INSTRUCTIONS.md
class HelperFun {
  HelperFun._();

  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Detects whether active theme is Dark Mode
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Show Top Floating Push Notification banner with Sound Chime
  static void showNotificationAlert({
    required String title,
    required String message,
    String? imageUrl,
    VoidCallback? onTap,
    BuildContext? context,
    int durationSeconds = 4,
  }) {
    // 1. Play audio chime
    SoundHelper.playNotificationSound();

    final targetContext = context ?? navigatorKey.currentContext;

    // 2. Show floating overlay banner at the top of the screen
    if (targetContext != null) {
      TopNotificationBanner.show(
        context: targetContext,
        title: title,
        message: message,
        imageUrl: imageUrl,
        onTap: onTap,
        duration: Duration(seconds: durationSeconds),
      );
      return;
    }


    // 3. Fallback to floating SnackBar if navigator context is not available
    messengerKey.currentState?.hideCurrentSnackBar();
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        duration: Duration(seconds: durationSeconds),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.all(AppSizes.md),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
            border: Border.all(color: AppColor.primary.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColor.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const Text(
                          'Now',
                          style: TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (imageUrl != null && imageUrl.isNotEmpty) ...[
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    imageUrl,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Success Snackbar
  static void successSnackbar(String title, String message, [int durationSeconds = 3]) {
    _showCustomSnackBar(
      title: title,
      message: message,
      backgroundColor: AppColor.success,
      icon: Icons.check_circle_outline_rounded,
      duration: Duration(seconds: durationSeconds),
    );
  }

  /// Backward compatible alias for successnackbar
  static void successnackbar(String title, String message, [int durationSeconds = 3]) {
    successSnackbar(title, message, durationSeconds);
  }

  /// Warning Snackbar
  static void warningSnackbar({required String title, required String message, int durationSeconds = 3}) {
    _showCustomSnackBar(
      title: title,
      message: message,
      backgroundColor: AppColor.warning,
      icon: Icons.warning_amber_rounded,
      duration: Duration(seconds: durationSeconds),
    );
  }

  /// Error Snackbar
  static void errorSnackbar({required String title, required String message, int durationSeconds = 4}) {
    _showCustomSnackBar(
      title: title,
      message: message,
      backgroundColor: AppColor.error,
      icon: Icons.error_outline_rounded,
      duration: Duration(seconds: durationSeconds),
    );
  }

  /// Info Snackbar
  static void infoSnackbar({required String title, required String message, int durationSeconds = 3}) {
    _showCustomSnackBar(
      title: title,
      message: message,
      backgroundColor: AppColor.info,
      icon: Icons.info_outline_rounded,
      duration: Duration(seconds: durationSeconds),
    );
  }

  static void _showCustomSnackBar({
    required String title,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
  }) {
    messengerKey.currentState?.hideCurrentSnackBar();
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.all(AppSizes.md),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm + 4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: AppSizes.sm + 4),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (message.isNotEmpty)
                      Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
