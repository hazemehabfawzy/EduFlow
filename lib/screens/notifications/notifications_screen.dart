import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final provider =
        context.watch<NotificationProvider>();
    final notifications = provider.notifications;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.surfaceDark
          : const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        surfaceTintColor: AppColors.primary,
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (provider.hasUnread)
            TextButton(
              onPressed: () => provider.markAllRead(),
              child: Text(
                'Mark all read',
                style: GoogleFonts.poppins(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState(isDark)
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                // Stream auto-refreshes; this is a UX hint
                await Future.delayed(
                    const Duration(milliseconds: 500));
              },
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                    16, 16, 16, 40),
                itemCount: notifications.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  return _NotificationTile(
                    notification: notif,
                    isDark: isDark,
                    onTap: () => _handleTap(
                        context, notif, provider),
                    onDismiss: () =>
                        provider.deleteNotification(
                            notif.id),
                  )
                      .animate()
                      .fadeIn(
                          duration: 300.ms,
                          delay: Duration(
                              milliseconds:
                                  30 * index))
                      .slideX(begin: 0.05);
                },
              ),
            ),
    );
  }

  void _handleTap(
    BuildContext context,
    NotificationModel notif,
    NotificationProvider provider,
  ) {
    // Mark as read
    if (!notif.isRead) {
      provider.markRead(notif.id);
    }

    // Navigate based on type
    if (notif.courseId != null) {
      // For course-related notifications,
      // go back and let HomeScreen handle navigation
      Navigator.of(context).pop();
    }
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color:
                  AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          )
              .animate()
              .scale(
                  duration: 600.ms,
                  curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text(
            'No notifications yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.white
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When students enroll or new courses\nare published, you\'ll see them here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.isDark,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            // Unread = slightly tinted background
            color: isUnread
                ? (isDark
                    ? AppColors.primary
                        .withOpacity(0.15)
                    : AppColors.primary
                        .withOpacity(0.05))
                : (isDark
                    ? AppColors.cardDark
                    : AppColors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread
                  ? AppColors.primary
                      .withOpacity(0.3)
                  : (isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight),
              width: isUnread ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ── Notification icon ────────────────
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _typeColor(notification.type)
                      .withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    notification.emoji,
                    style: const TextStyle(
                        fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // ── Content ─────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isDark
                                  ? AppColors.white
                                  : AppColors
                                      .textPrimary,
                            ),
                          ),
                        ),
                        // Unread dot
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration:
                                const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.body,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color:
                            AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.timeAgo,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w500,
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

  Color _typeColor(String type) {
    switch (type) {
      case 'new_course': return AppColors.primary;
      case 'new_enrollment': return AppColors.success;
      case 'course_complete': return AppColors.warning;
      case 'new_rating': return AppColors.accent;
      case 'new_lesson': return AppColors.info;
      default: return AppColors.primary;
    }
  }
}
