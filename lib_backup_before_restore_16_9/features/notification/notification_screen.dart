import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/premium_widgets.dart';
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
    final unreadCount = notifications.where((n) => !n.isRead).length;

    // Split into Today vs Earlier
    final now = DateTime.now();
    final todayNotifs = <AppNotification>[];
    final earlierNotifs = <AppNotification>[];

    for (final n in notifications) {
      final date = DateTime.fromMillisecondsSinceEpoch(n.createdAt);
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        todayNotifs.add(n);
      } else {
        earlierNotifs.add(n);
      }
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF14273A) : const Color(0xFFF1F6FA),
      body: AmbientFloatingBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 1. Soft Header: head('Hộp thư', 'Bạn có 2 cập nhật mới', btn('check-check', 'notice'))
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.maybePop(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E3146) : Colors.white,
                              borderRadius: BorderRadius.circular(19),
                              border: Border.all(
                                color: isDark ? const Color(0xFF2E455C) : const Color(0xFFDCE7F0),
                              ),
                            ),
                            child: Icon(
                              LucideIcons.chevron_left,
                              size: 20,
                              color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hộp thư',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              unreadCount > 0
                                  ? 'Bạn có $unreadCount cập nhật mới'
                                  : 'Hộp thư đã cập nhật đầy đủ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFFABC0D3) : const Color(0xFF7A90A5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        for (final n in notifications.where((x) => !x.isRead)) {
                          provider.markNotificationAsRead(widget.userId, n.id);
                        }
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E3146) : const Color(0xFFE8F1FC),
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2E455C) : const Color(0xFFDCE7F0),
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.check_check,
                          size: 18,
                          color: Color(0xFF005FEA),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Notification List
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  children: [
                    // Attention Card matching app.js
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2B2215) : const Color(0xFFFFF6E8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? const Color(0xFF4D3B22) : const Color(0xFFF0DFC2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CẦN BẠN CHÚ Ý',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: Color(0xFFAA7B36),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ngân sách mua sắm\nđã dùng 90%',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              letterSpacing: -0.4,
                              color: isDark ? const Color(0xFFF7E6D0) : const Color(0xFF233D58),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Còn 400.000 ₫ cho tháng này.\nMột chút điều chỉnh để giữ đúng kế hoạch.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: isDark ? const Color(0xFFD4C2AA) : const Color(0xFF7A90A5),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => Navigator.maybePop(context),
                            child: const Text(
                              'Xem ngân sách →',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF005FEA),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section: HÔM NAY
                    _buildSectionHeader('HÔM NAY', isDark),
                    const SizedBox(height: 10),
                    if (todayNotifs.isEmpty)
                      _buildNotificationTile(
                        icon: LucideIcons.flag,
                        tileColor: const Color(0xFFE4EFEA),
                        iconColor: const Color(0xFF138875),
                        title: 'Đã qua nửa chặng đường',
                        subtitle: 'Mục tiêu Đà Lạt đã đạt 60% · 10:20',
                        unread: true,
                        isDark: isDark,
                      )
                    else
                      ...todayNotifs.map((n) => _buildRealNotificationRow(n, isDark, provider)),

                    const SizedBox(height: 20),

                    // Section: TRƯỚC ĐÓ
                    _buildSectionHeader('TRƯỚC ĐÓ', isDark),
                    const SizedBox(height: 10),
                    if (earlierNotifs.isEmpty) ...[
                      _buildNotificationTile(
                        icon: LucideIcons.credit_card,
                        tileColor: const Color(0xFFEAF1FF),
                        iconColor: const Color(0xFF005FEA),
                        title: 'Nhắc lịch thanh toán',
                        subtitle: 'Thẻ Visa đến hạn 25/09 · Hôm qua',
                        unread: false,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _buildNotificationTile(
                        icon: LucideIcons.chart_pie,
                        tileColor: const Color(0xFFF3E8FF),
                        iconColor: const Color(0xFF9333EA),
                        title: 'Báo cáo tháng đã sẵn sàng',
                        subtitle: 'Cùng nhìn lại tháng 8 · 01/09',
                        unread: false,
                        isDark: isDark,
                      ),
                    ] else
                      ...earlierNotifs.map((n) => _buildRealNotificationRow(n, isDark, provider)),

                    const SizedBox(height: 24),

                    // Primary Button: Đánh dấu tất cả đã đọc
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          for (final n in notifications.where((x) => !x.isRead)) {
                            provider.markNotificationAsRead(widget.userId, n.id);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã đánh dấu tất cả thông báo là đã đọc'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF005FEA),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Đánh dấu tất cả đã đọc',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

  Widget _buildSectionHeader(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: isDark ? const Color(0xFFABC0D3) : const Color(0xFF7A90A5),
      ),
    );
  }

  Widget _buildNotificationTile({
    required IconData icon,
    required Color tileColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool unread,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2C3E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2B3F55) : const Color(0xFFE4EDF4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Icon(icon, size: 20, color: iconColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                    color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? const Color(0xFFABC0D3) : const Color(0xFF7A90A5),
                  ),
                ),
              ],
            ),
          ),
          if (unread)
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF005FEA),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRealNotificationRow(AppNotification n, bool isDark, MoreProvider provider) {
    final unread = !n.isRead;
    final date = DateTime.fromMillisecondsSinceEpoch(n.createdAt);
    String two(int v) => v.toString().padLeft(2, '0');
    final timeStr = '${two(date.hour)}:${two(date.minute)} · ${two(date.day)}/${two(date.month)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(n.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => provider.deleteNotification(widget.userId, n.id),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFC86359),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(LucideIcons.trash, color: Colors.white, size: 20),
        ),
        child: GestureDetector(
          onTap: () {
            if (unread) provider.markNotificationAsRead(widget.userId, n.id);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2C3E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF2B3F55) : const Color(0xFFE4EDF4),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: n.type == 'warning'
                        ? const Color(0xFFFFF4E5)
                        : (n.type == 'danger'
                            ? const Color(0xFFFDE8E8)
                            : const Color(0xFFEAF1FF)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      n.type == 'warning'
                          ? LucideIcons.triangle_alert
                          : (n.type == 'danger'
                              ? LucideIcons.circle_alert
                              : LucideIcons.bell),
                      size: 20,
                      color: n.type == 'warning'
                          ? const Color(0xFFE67E22)
                          : (n.type == 'danger'
                              ? const Color(0xFFC86359)
                              : const Color(0xFF005FEA)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title ?? 'Thông báo',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                          color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${n.message ?? ""} · $timeStr',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? const Color(0xFFABC0D3) : const Color(0xFF7A90A5),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (unread)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF005FEA),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
