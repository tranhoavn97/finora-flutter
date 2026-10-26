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

/// Screen 4: Budget (Ngân sách & hạn mức chi tiêu) in Glassmorphism 2.0
class DemoBudgetScreen extends StatefulWidget {
  final bool isLiveMode;
  final VoidCallback? onBack;

  const DemoBudgetScreen({
    super.key,
    this.isLiveMode = false,
    this.onBack,
  });

  @override
  State<DemoBudgetScreen> createState() => _DemoBudgetScreenState();
}

class _DemoBudgetScreenState extends State<DemoBudgetScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final budgets = CatalogMockData.budgets;
    final totalLimit = budgets.fold<int>(0, (s, b) => s + b.limit);
    final totalSpent = budgets.fold<int>(0, (s, b) => s + b.spent);
    final percent = totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0.0;

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
                  title: 'Ngân sách chi tiêu',
                  onBack: widget.onBack ?? () => Navigator.maybePop(context),
                  actions: [
                    FinoraAddIconButton(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Thêm hạn mức ngân sách mới')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: CatalogHeroCard(
                title: 'Hạn mức tháng 09/2026',
                amount: totalLimit - totalSpent,
                subtitle: 'Còn lại khả dụng',
                gradientColors: const [
                  Color(0xFFE65100),
                  Color(0xFFFF9800),
                ],
                metrics: [
                  HeroMetricItem(
                    label: 'Đã chi tiêu',
                    value: _vnd.format(totalSpent),
                    color: Colors.white,
                  ),
                  HeroMetricItem(
                    label: 'Tổng định mức',
                    value: _vnd.format(totalLimit),
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
                  onTap: () {
                    CatalogBottomSheets.showAiBudgetAnalysisSheet(context);
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: GlassmorphismTokens.primary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(LucideIcons.sparkles, color: GlassmorphismTokens.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Finora AI Phân Tích Ngân Sách',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Gợi ý tối ưu chi tiêu 9 ngày cuối tháng',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.chevron_right, size: 18, color: Colors.grey),
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
                      'Hạng mục ngân sách',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                    ),
                    Text(
                      '${(percent * 100).toStringAsFixed(1)}% đã dùng',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: percent > 0.85 ? GlassmorphismTokens.expense : GlassmorphismTokens.primary,
                      ),
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
                    final b = budgets[idx];
                    return _buildBudgetCard(b, isDark);
                  },
                  childCount: budgets.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(CatalogBudgetItem item, bool isDark) {
    final progress = item.limit > 0 ? (item.spent / item.limit).clamp(0.0, 1.0) : 0.0;
    final isWarning = progress >= 0.80;

    return CatalogGlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: () {
        CatalogBottomSheets.showAiBudgetAnalysisSheet(context);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.category,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Còn lại: ${_vnd.format(item.limit - item.spent)} đ',
                      style: TextStyle(
                        fontSize: 12,
                        color: isWarning ? GlassmorphismTokens.warning : (isDark ? Colors.white60 : Colors.black54),
                        fontWeight: isWarning ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_vnd.format(item.spent)} đ',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '/ ${_vnd.format(item.limit)} đ',
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.90
                    ? GlassmorphismTokens.expense
                    : (progress > 0.75 ? GlassmorphismTokens.warning : item.color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
