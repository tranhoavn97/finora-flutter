import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/finora_tokens.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/finora/financial_components.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MoreProvider>();
    final notifications = provider.notifications;

    return Scaffold(
      backgroundColor: FinoraTokens.bg(isDark),
      appBar: AppBar(
        backgroundColor: FinoraTokens.surface(isDark),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Thông báo',
          style: TextStyle(
            color: FinoraTokens.ink(isDark),
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: 'BeVietnamPro',
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: FinoraTokens.ink(isDark), size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: FinoraTokens.line(isDark), height: 1),
        ),
      ),
      body: provider.isRefreshing
          ? Center(child: CircularProgressIndicator(color: FinoraTokens.ink(isDark)))
          : provider.error != null
              ? FinoraDataMessage(
                  title: 'Chưa tải được thông báo',
                  message: provider.error!,
                  onRetry: () => provider.load(widget.userId, force: true))
              : notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_none_rounded, size: 48, color: FinoraTokens.inkTertiary(isDark)),
                          const SizedBox(height: 12),
                          Text(
                            'Bạn không có thông báo nào',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'BeVietnamPro',
                              color: FinoraTokens.ink(isDark),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Các thông báo mới sẽ xuất hiện ở đây.',
                            style: TextStyle(
                              fontSize: 13,
                              color: FinoraTokens.inkSecondary(isDark),
                              fontFamily: 'BeVietnamPro',
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
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

  Color _typeColor(bool isDark) {
    switch (notif.type) {
      case 'warning':
        return isDark ? FinoraTokens.warnAmberDark : FinoraTokens.warnAmber;
      case 'danger':
        return isDark ? FinoraTokens.negRedDark : FinoraTokens.negRed;
      case 'success':
        return isDark ? FinoraTokens.posGreenDark : FinoraTokens.posGreen;
      default:
        return FinoraTokens.inkSecondary(isDark);
    }
  }

  IconData get _icon {
    switch (notif.type) {
      case 'warning':
      case 'danger':
        return Icons.warning_amber_rounded;
      case 'success':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.info_outline_rounded;
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
    final unread = !notif.isRead;
    final typeColor = _typeColor(isDark);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FinoraTokens.surface(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unread
              ? FinoraTokens.ink(isDark).withValues(alpha: 0.25)
              : FinoraTokens.line(isDark),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: FinoraTokens.surface2(isDark),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FinoraTokens.line(isDark)),
            ),
            child: Icon(_icon, color: typeColor, size: 20),
          ),
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
                        decoration: BoxDecoration(
                          color: typeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        notif.title ?? 'Thông báo hệ thống',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 14,
                          fontWeight: unread ? FontWeight.w600 : FontWeight.w500,
                          color: FinoraTokens.ink(isDark),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notif.message ?? '',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 12.5,
                    color: FinoraTokens.inkSecondary(isDark),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDate(notif.createdAt),
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontSize: 11,
                    color: FinoraTokens.inkTertiary(isDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            children: [
              if (unread)
                IconButton(
                  onPressed: onRead,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  icon: Icon(
                    Icons.check_rounded,
                    color: isDark ? FinoraTokens.posGreenDark : FinoraTokens.posGreen,
                    size: 18,
                  ),
                  tooltip: 'Đánh dấu đã đọc',
                ),
              IconButton(
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: isDark ? FinoraTokens.negRedDark : FinoraTokens.negRed,
                  size: 18,
                ),
                tooltip: 'Xóa',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
