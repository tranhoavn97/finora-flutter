import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/design_system/v8/finora_v8.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../catalog_mock_data.dart';
import '../widgets/catalog_glass_card.dart';

/// Screen 13: Notification (Trung tâm thông báo & cảnh báo tài chính) in Glassmorphism 2.0
class DemoNotificationScreen extends StatefulWidget {
  final bool isLiveMode;
  final VoidCallback? onBack;

  const DemoNotificationScreen({
    super.key,
    this.isLiveMode = false,
    this.onBack,
  });

  @override
  State<DemoNotificationScreen> createState() => _DemoNotificationScreenState();
}

class _DemoNotificationScreenState extends State<DemoNotificationScreen> {
  late List<CatalogNotificationItem> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = List.from(CatalogMockData.notifications);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: FinoraPageHeader(
                  title: 'Trung tâm thông báo',
                  onBack: widget.onBack ?? () => Navigator.maybePop(context),
                  actions: [
                    if (unreadCount > 0)
                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            for (var i = 0; i < _notifications.length; i++) {
                              _notifications[i] = _notifications[i].copyWith(isRead: true);
                            }
                          });
                        },
                        child: const Text('Đã đọc hết', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, idx) {
                    final item = _notifications[idx];
                    return _buildNotificationCard(item, isDark);
                  },
                  childCount: _notifications.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(CatalogNotificationItem item, bool isDark) {
    return CatalogGlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          final idx = _notifications.indexWhere((n) => n.id == item.id);
          if (idx != -1) {
            _notifications[idx] = _notifications[idx].copyWith(isRead: true);
          }
        });
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!item.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: GlassmorphismTokens.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.message,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.time,
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
