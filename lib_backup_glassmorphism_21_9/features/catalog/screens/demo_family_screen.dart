import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../core/design_system/v8/finora_v8.dart';
import '../widgets/catalog_glass_card.dart';
import '../widgets/catalog_hero_card.dart';

/// Screen 11: Family (Tài chính gia đình & chia sẻ ví) in Glassmorphism 2.0
class DemoFamilyScreen extends StatefulWidget {
  final bool isLiveMode;
  final VoidCallback? onBack;

  const DemoFamilyScreen({
    super.key,
    this.isLiveMode = false,
    this.onBack,
  });

  @override
  State<DemoFamilyScreen> createState() => _DemoFamilyScreenState();
}

class _DemoFamilyScreenState extends State<DemoFamilyScreen> {
  final String _inviteCode = 'FN-8899';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final members = [
      {
        'name': 'Louis Trần',
        'role': 'Trưởng nhóm gia đình',
        'tag': '👨 Chồng',
        'email': 'louis.tran@finora.io',
        'isOwner': true,
        'color': const Color(0xFF007AFF),
      },
      {
        'name': 'Mai Anh',
        'role': 'Đồng quản trị',
        'tag': '👩 Vợ',
        'email': 'maianh.nguyen@finora.io',
        'isOwner': false,
        'color': const Color(0xFFFF2D55),
      },
    ];

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
                  title: 'Tài chính gia đình',
                  onBack: widget.onBack ?? () => Navigator.maybePop(context),
                  actions: [
                    FinoraAddIconButton(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showInviteDialog(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: CatalogHeroCard(
                title: 'Tổ ấm FINORA',
                amount: 142500000,
                subtitle: 'Tổng tài sản ròng gia đình',
                gradientColors: [
                  Color(0xFF701A75),
                  Color(0xFFA21CAF),
                ],
                metrics: [
                  HeroMetricItem(
                    label: 'Số thành viên',
                    value: '2 người',
                    color: Colors.white,
                  ),
                  HeroMetricItem(
                    label: 'Ví dùng chung',
                    value: '3 ví',
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: CatalogGlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA21CAF).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.qr_code, color: Color(0xFFA21CAF), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mã mời gia đình bí mật',
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _inviteCode,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.copy, size: 18),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Clipboard.setData(ClipboardData(text: _inviteCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã sao chép mã mời gia đình!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Thành viên kết nối',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                    ),
                    Text(
                      '${members.length} người',
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black45),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, idx) {
                    final m = members[idx];
                    final color = m['color'] as Color;
                    return CatalogGlassCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: color.withValues(alpha: 0.2),
                            child: Text(
                              (m['name'] as String).substring(0, 1),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      m['name'] as String,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        m['tag'] as String,
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  m['role'] as String,
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45),
                                ),
                              ],
                            ),
                          ),
                          const Icon(LucideIcons.chevron_right, size: 18, color: Colors.grey),
                        ],
                      ),
                    );
                  },
                  childCount: members.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mời thành viên vào gia đình'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gửi mã mời bên dưới cho vợ hoặc chồng để liên kết sổ chi tiêu gia đình:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _inviteCode,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2.0),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }
}
