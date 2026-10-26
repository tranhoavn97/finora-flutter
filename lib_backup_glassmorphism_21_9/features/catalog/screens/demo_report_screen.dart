import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/v8/finora_v8.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../widgets/catalog_glass_card.dart';
import '../widgets/catalog_hero_card.dart';

final NumberFormat _vnd = NumberFormat('#,##0', 'vi_VN');

/// Screen 6: Report (Báo cáo thống kê, biểu đồ phân tích) in Glassmorphism 2.0
class DemoReportScreen extends StatelessWidget {
  final bool isLiveMode;
  final VoidCallback? onBack;

  const DemoReportScreen({
    super.key,
    this.isLiveMode = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const totalIncome = 68500000;
    const totalExpense = 27850000;
    const netSavings = totalIncome - totalExpense;

    final categories = [
      {'name': 'Ăn uống & Cà phê', 'amount': 7850000, 'color': const Color(0xFFFF9500), 'pct': '28.2%'},
      {'name': 'Nhà cửa & Hóa đơn', 'amount': 5400000, 'color': const Color(0xFF5856D6), 'pct': '19.4%'},
      {'name': 'Giáo dục con cái', 'amount': 6500000, 'color': const Color(0xFF34C759), 'pct': '23.3%'},
      {'name': 'Mua sắm gia đình', 'amount': 3250000, 'color': const Color(0xFFAF52DE), 'pct': '11.7%'},
      {'name': 'Đi lại & Xăng xe', 'amount': 2100000, 'color': const Color(0xFF5AC8FA), 'pct': '7.5%'},
      {'name': 'Khác & Dự phòng', 'amount': 2750000, 'color': Colors.grey, 'pct': '9.9%'},
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
                  title: 'Báo cáo tài chính',
                  onBack: onBack ?? () => Navigator.maybePop(context),
                  actions: [
                    FinoraHeaderIconButton(
                      icon: LucideIcons.calendar,
                      onTap: () {
                        HapticFeedback.lightImpact();
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: CatalogHeroCard(
                title: 'Tích lũy ròng trong kỳ',
                amount: netSavings,
                subtitle: 'Tỷ lệ tiết kiệm đạt 59.3%',
                gradientColors: const [
                  Color(0xFF1A365D),
                  Color(0xFF2B6CB0),
                ],
                metrics: [
                  HeroMetricItem(
                    label: 'Tổng thu nhập',
                    value: '+${_vnd.format(totalIncome)} đ',
                    color: GlassmorphismTokens.income,
                  ),
                  HeroMetricItem(
                    label: 'Tổng chi tiêu',
                    value: '-${_vnd.format(totalExpense)} đ',
                    color: GlassmorphismTokens.expense,
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: CatalogGlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tỷ lệ chi tiêu theo thành viên',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 62,
                            child: Container(
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFF007AFF),
                                borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '👨 Chồng: 62%',
                                style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 38,
                            child: Container(
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF2D55),
                                borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '👩 Vợ: 38%',
                                style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
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
                      'Cơ cấu chi tiêu nhóm ngành',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                    ),
                    Text(
                      '${categories.length} nhóm',
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
                    final cat = categories[idx];
                    final color = cat['color'] as Color;
                    final amt = cat['amount'] as int;
                    return CatalogGlassCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 38,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat['name'] as String,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  cat['pct'] as String,
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '-${_vnd.format(amt)} đ',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: categories.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
