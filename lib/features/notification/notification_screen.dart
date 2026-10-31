import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/services/bank_sync_service.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../data/models/finance_models.dart';
import '../../state/family_provider.dart';
import '../../state/more_provider.dart';
import '../../state/theme_studio_controller.dart';
import 'bank_inbox_view.dart';

class NotificationScreen extends StatefulWidget {
  final String userId;
  final int initialTab;
  const NotificationScreen({
    super.key,
    required this.userId,
    this.initialTab = 0,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _bank = BankSyncService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bank.initialize();
      context.read<MoreProvider?>()?.load(
            widget.userId,
            familyId: context.read<FamilyProvider?>()?.familyId,
          );
    });
  }

  Future<void> _markAllAsRead(
    MoreProvider more,
    List<AppNotification> items,
  ) async {
    for (final n in items) {
      if (!n.isRead && n.id.isNotEmpty) {
        await more.markNotificationAsRead(widget.userId, n.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final more = context.watch<MoreProvider?>();
    final items = more?.notifications ?? const <AppNotification>[];
    final unread = items.where((n) => !n.isRead).length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPad = MediaQuery.of(context).padding.top;

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab.clamp(0, 1),
      child: AnimatedBuilder(
        animation: _bank,
        builder: (context, _) {
          final pending = _bank.pending.length + _bank.unrecognizedCount;
          return GlassScaffold(
            extendBodyBehindAppBar: true,
            appBar: GlassTopBar(
              title: '',
              titleWidget: _buildNotificationTopBarContent(
                isDark: isDark,
                pending: pending,
                unread: unread,
                more: more,
                items: items,
              ),
              showBack: true,
              onBack: () => Navigator.of(context).maybePop(),
              height: 104,
            ),
            body: TabBarView(
              physics: const BouncingScrollPhysics(),
              children: [
                BankInboxView(
                  userId: widget.userId,
                  topPadding: GlassScaffold.topInset(context, 6, 104),
                ),
                _ActivityTab(
                  userId: widget.userId,
                  topPadding: GlassScaffold.topInset(context, 6, 104),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationTopBarContent({
    required bool isDark,
    required int pending,
    required int unread,
    required MoreProvider? more,
    required List<AppNotification> items,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông báo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    pending + unread > 0
                        ? '${pending + unread} mục cần bạn kiểm tra'
                        : 'Tất cả thông báo đã được cập nhật',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (unread > 0 && more != null)
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _markAllAsRead(more, items);
                },
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669)
                        .withValues(alpha: isDark ? 0.22 : 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFF059669).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.done_all_rounded,
                        size: 15,
                        color: isDark
                            ? const Color(0xFF34D399)
                            : const Color(0xFF059669),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Đọc hết',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFF34D399)
                              : const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 38,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
          child: TabBar(
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            splashBorderRadius: BorderRadius.circular(999),
            indicator: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF059669).withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            labelColor: Colors.white,
            unselectedLabelColor:
                isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(text: 'Giao dịch chờ ($pending)'),
              Tab(text: 'Hoạt động ($unread)'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityTab extends StatelessWidget {
  final String userId;
  final double? topPadding;
  const _ActivityTab({required this.userId, this.topPadding});

  ({IconData icon, Color color}) _styleForType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('budget') || lower.contains('warning')) {
      return (icon: Icons.warning_amber_rounded, color: const Color(0xFFD97706));
    }
    if (lower.contains('income') || lower.contains('receive')) {
      return (icon: Icons.south_west_rounded, color: const Color(0xFF059669));
    }
    if (lower.contains('expense') || lower.contains('spend')) {
      return (icon: Icons.north_east_rounded, color: const Color(0xFFE11D48));
    }
    if (lower.contains('family') || lower.contains('member')) {
      return (icon: Icons.people_alt_rounded, color: const Color(0xFF7C3AED));
    }
    if (lower.contains('goal') || lower.contains('saving')) {
      return (icon: Icons.savings_rounded, color: const Color(0xFF0284C7));
    }
    return (
      icon: Icons.notifications_active_rounded,
      color: const Color(0xFF059669),
    );
  }

  String _formatDate(int createdAtMs) {
    if (createdAtMs <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(
      createdAtMs < 100000000000 ? createdAtMs * 1000 : createdAtMs,
    ).toLocal();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24 && dt.day == now.day) {
      return 'Hôm nay • ${DateFormat('HH:mm').format(dt)}';
    }
    return DateFormat('HH:mm • dd/MM/yyyy').format(dt);
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF059669)
                    .withValues(alpha: isDark ? 0.18 : 0.10),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 32,
                color: Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Chưa có thông báo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Cảnh báo ngân sách, nhắc lịch và hoạt động gia đình sẽ hiện ở đây.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final more = context.watch<MoreProvider?>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (more == null) {
      return _buildEmptyState(isDark);
    }
    if (more.isRefreshing && more.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (more.notifications.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, topPadding ?? 16, 16, 32),
      physics: const BouncingScrollPhysics(),
      itemCount: more.notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = more.notifications[index];
        final meta = _styleForType(item.type ?? 'info');
        final isUnread = !item.isRead;
        final title = (item.title?.trim().isNotEmpty == true)
            ? item.title!.trim()
            : 'Thông báo';
        final message = item.message?.trim() ?? '';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              HapticFeedback.selectionClick();
              if (isUnread && item.id.isNotEmpty) {
                more.markNotificationAsRead(userId, item.id);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? (isUnread
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF0F172A).withValues(alpha: 0.75))
                    : (isUnread ? Colors.white : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isUnread
                      ? meta.color.withValues(alpha: isDark ? 0.45 : 0.30)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : const Color(0xFFE2E8F0)),
                  width: isUnread ? 1.2 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isDark ? 0.20 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: meta.color.withValues(alpha: isDark ? 0.20 : 0.12),
                      border: Border.all(
                        color:
                            meta.color.withValues(alpha: isDark ? 0.35 : 0.22),
                      ),
                    ),
                    child: Icon(
                      meta.icon,
                      size: 20,
                      color: meta.color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isUnread
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            if (isUnread)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: meta.color,
                                  boxShadow: [
                                    BoxShadow(
                                      color: meta.color.withValues(alpha: 0.45),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (message.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.38,
                              color: isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ],
                        if (item.createdAt > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 12,
                                color: isDark
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(item.createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
