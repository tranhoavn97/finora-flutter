import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/v8/finora_v8.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../catalog_mock_data.dart';
import '../widgets/catalog_bottom_sheets.dart';
import '../widgets/catalog_glass_card.dart';
import '../widgets/catalog_hero_card.dart';

final NumberFormat _vnd = NumberFormat('#,##0', 'vi_VN');

/// Screen 5: Goal (Mục tiêu tiết kiệm & tích lũy) in Glassmorphism 2.0
class DemoGoalScreen extends StatefulWidget {
  final bool isLiveMode;
  final VoidCallback? onBack;

  const DemoGoalScreen({
    super.key,
    this.isLiveMode = false,
    this.onBack,
  });

  @override
  State<DemoGoalScreen> createState() => _DemoGoalScreenState();
}

class _DemoGoalScreenState extends State<DemoGoalScreen> {
  String _activeTab = 'Đang tích lũy';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goals = CatalogMockData.goals;
    final totalTarget = goals.fold<int>(0, (s, g) => s + g.targetAmount);
    final totalCurrent = goals.fold<int>(0, (s, g) => s + g.currentAmount);

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
                  title: 'Mục tiêu tài chính',
                  onBack: widget.onBack ?? () => Navigator.maybePop(context),
                  actions: [
                    FinoraAddIconButton(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tạo mục tiêu tiết kiệm mới')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: CatalogHeroCard(
                title: 'Tổng tích lũy hiện tại',
                amount: totalCurrent,
                subtitle: 'Mục tiêu tổng: ${_vnd.format(totalTarget)} đ',
                gradientColors: const [
                  Color(0xFF0F5132),
                  Color(0xFF198754),
                ],
                metrics: [
                  HeroMetricItem(
                    label: 'Tiến độ chung',
                    value: '${(totalCurrent * 100 / totalTarget).toStringAsFixed(1)}%',
                    color: Colors.white,
                  ),
                  HeroMetricItem(
                    label: 'Số mục tiêu',
                    value: '${goals.length} kế hoạch',
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: ['Đang tích lũy', 'Đã hoàn thành', 'Đã lưu trữ'].map((t) {
                    final isSel = _activeTab == t;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _activeTab = t);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel
                              ? GlassmorphismTokens.primary.withValues(alpha: isDark ? 0.35 : 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSel
                                ? GlassmorphismTokens.primary.withValues(alpha: 0.6)
                                : (isDark ? Colors.white12 : Colors.black12),
                          ),
                        ),
                        child: Text(
                          t,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                            color: isSel ? GlassmorphismTokens.primary : (isDark ? Colors.white60 : Colors.black54),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, idx) {
                    final g = goals[idx];
                    return _buildGoalCard(g, isDark);
                  },
                  childCount: goals.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(CatalogGoalItem goal, bool isDark) {
    final progress = goal.progress;

    return CatalogGlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      onTap: () {
        CatalogBottomSheets.showGoalDepositSheet(context, goal);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: goal.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: goal.color.withValues(alpha: 0.3)),
                ),
                child: Icon(goal.icon, color: goal.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hạn chót: ${goal.targetDate}',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  CatalogBottomSheets.showGoalDepositSheet(context, goal);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: GlassmorphismTokens.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: GlassmorphismTokens.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.plus, size: 14, color: GlassmorphismTokens.primary),
                      SizedBox(width: 4),
                      Text(
                        'Nạp quỹ',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GlassmorphismTokens.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đã có: ${_vnd.format(goal.currentAmount)} đ',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: progress >= 1.0 ? GlassmorphismTokens.income : GlassmorphismTokens.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(goal.color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mục tiêu: ${_vnd.format(goal.targetAmount)} đ (còn thiếu ${_vnd.format(goal.remaining)} đ)',
            style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
          ),
        ],
      ),
    );
  }
}
