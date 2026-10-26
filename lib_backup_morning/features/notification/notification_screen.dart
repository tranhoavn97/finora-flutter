import '../../core/widgets/finora/financial_components.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/glass_widgets.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../../data/models/finance_models.dart';
import '../../state/more_provider.dart';

class NotificationScreen extends StatefulWidget {
  final String userId;
  const NotificationScreen({super.key, required this.userId});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MoreProvider>().load(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MoreProvider>();
    final notifications = provider.notifications;

    return GlassScaffold(
      appBar: GlassTopBar(
        title: 'Thông báo',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: provider.isRefreshing
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? FinoraDataMessage(
                  title: 'Chưa tải được thông báo',
                  message: provider.error!,
                  onRetry: () => provider.load(widget.userId, force: true))
              : notifications.isEmpty
                  ? const Center(
                      child: EmptyState(
                        icon: Icons.notifications_none,
                        title: 'Bạn không có thông báo nào',
                        subtitle: 'Các thông báo mới sẽ xuất hiện ở đây.',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                          AppSpacing.xs, AppSpacing.md, AppSpacing.lg),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) {
                        final n = notifications[i];
                        return _NotificationRow(
                          notif: n,
                          onRead: () => context
                              .read<MoreProvider>()
                              .markNotificationAsRead(widget.userId, n.id),
                          onDelete: () async {
                            final confirm = await showConfirmDeleteDialog(
                              context: context,
                              title: 'Xóa thông báo?',
                              content:
                                  'Bạn có chắc chắn muốn xóa thông báo này không?',
                            );
                            if (confirm && context.mounted) {
                              context
                                  .read<MoreProvider>()
                                  .deleteNotification(widget.userId, n.id);
                            }
                          },
                        );
                      },
                    ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final AppNotification notif;
  final VoidCallback onRead;
  final VoidCallback onDelete;
  const _NotificationRow({
    required this.notif,
    required this.onRead,
    required this.onDelete,
  });

  Color get _typeColor {
    switch (notif.type) {
      case 'warning':
        return const Color(0xFFF5B942);
      case 'danger':
        return AppColors.error;
      case 'success':
        return AppColors.success;
      default:
        return AppColors.accent;
    }
  }

  IconData get _icon {
    switch (notif.type) {
      case 'warning':
      case 'danger':
        return Icons.warning_amber;
      default:
        return Icons.info;
    }
  }

  String _formatDate(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final unread = !notif.isRead;
    final typeColor = _typeColor;

    return GlassCard(
      highlighted: unread,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: _icon, tint: typeColor, size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (unread) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: typeColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        notif.title ?? 'Thông báo hệ thống',
                        style: AppTypography.body.copyWith(
                          fontWeight:
                              unread ? FontWeight.bold : FontWeight.normal,
                          color: unread ? primaryTextColor : secondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notif.message ?? '',
                  style: AppTypography.caption2
                      .copyWith(color: secondaryTextColor),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDate(notif.createdAt),
                  style: AppTypography.caption2.copyWith(
                      color: isDark ? Colors.white38 : Colors.black38),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              if (unread)
                IconButton(
                  onPressed: onRead,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  icon: const Icon(Icons.check,
                      color: AppColors.success, size: 18),
                  tooltip: 'Đánh dấu đã đọc',
                ),
              IconButton(
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                icon: Icon(Icons.delete_outline,
                    color: AppColors.error.withValues(alpha: 0.7), size: 18),
                tooltip: 'Xóa',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
