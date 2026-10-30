import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/bank_sync_service.dart';
import '../../state/more_provider.dart';
import '../../features/notification/notification_screen.dart';

class FinoraNotificationBell extends StatelessWidget {
  final String userId;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  const FinoraNotificationBell({
    super.key,
    required this.userId,
    this.size = 38.0,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final more = context.watch<MoreProvider?>();
    final bank = BankSyncService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: bank,
      builder: (context, _) {
        final count = bank.pending.length +
            bank.unrecognizedCount +
            (more?.notifications.where((n) => !n.isRead).length ?? 0);

        final bg = backgroundColor ??
            (isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.95));
        final fg = iconColor ??
            (count > 0
                ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A)));

        return Semantics(
          label: 'Thông báo, $count mục cần xem',
          button: true,
          child: Tooltip(
            message: 'Thông báo',
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NotificationScreen(userId: userId),
                    ),
                  );
                },
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bg,
                    border: Border.all(
                      color: count > 0
                          ? const Color(0xFF10B981)
                              .withValues(alpha: isDark ? 0.45 : 0.30)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : const Color(0xFFE2E8F0)),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: isDark ? 0.25 : 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        count > 0
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_none_rounded,
                        size: size * 0.50,
                        color: fg,
                      ),
                      if (count > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.5,
                              vertical: 1.5,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF0F172A)
                                    : Colors.white,
                                width: 1.6,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE11D48)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              count > 99 ? '99+' : '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
