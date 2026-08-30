import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/glass_widgets.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
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
    context.read<MoreProvider>().load(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<MoreProvider>().notifications;

    return GlassScaffold(
      appBar: GlassTopBar(
        title: 'Thông báo',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        child: notifications.isEmpty
            ? Center(
                child: EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'Chưa có thông báo nào',
                  subtitle: 'Các cập nhật và nhắc nhở chi tiêu sẽ xuất hiện ở đây.',
                ),
              )
            : ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                        content: 'Bạn có chắc chắn muốn xóa thông báo này không?',
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
        return AppColors.warning;
      case 'danger':
        return AppColors.error;
      case 'success':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  IconData get _icon {
    switch (notif.type) {
      case 'warning':
      case 'danger':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatDate(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final unread = !notif.isRead;
    final typeColor = _typeColor;

    return GlassCard(
      radius: 20,
      highlighted: unread,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: _icon, tint: typeColor, size: 40, radius: 14),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (unread) ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(color: typeColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        notif.title ?? 'Thông báo hệ thống',
                        style: TextStyle(
                          fontWeight: unread ? FontWeight.bold : FontWeight.w600,
                          color: unread ? c.textPrimary : c.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  notif.message ?? '',
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDate(notif.createdAt),
                  style: TextStyle(
                    color: c.textTertiary,
                    fontSize: 11,
                  ),
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
                  icon: const Icon(Icons.check_rounded, color: AppColors.success, size: 18),
                  tooltip: 'Đánh dấu đã đọc',
                ),
              IconButton(
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                icon: Icon(Icons.delete_outline_rounded,
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
