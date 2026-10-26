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

/// Screen 7: Loan (Sổ theo dõi vay nợ & trả góp) in Glassmorphism 2.0
class DemoLoanScreen extends StatefulWidget {
  final bool isLiveMode;
  final VoidCallback? onBack;

  const DemoLoanScreen({
    super.key,
    this.isLiveMode = false,
    this.onBack,
  });

  @override
  State<DemoLoanScreen> createState() => _DemoLoanScreenState();
}

class _DemoLoanScreenState extends State<DemoLoanScreen> {
  bool _isLendTab = true; // true = cho vay, false = vay nợ

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allLoans = CatalogMockData.loans;
    final loans = allLoans.where((l) => l.isLending == _isLendTab).toList();
    final totalPrincipal = loans.fold<int>(0, (s, l) => s + l.amount);
    final totalRemaining = loans.fold<int>(0, (s, l) => s + l.remainingAmount);

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
                  title: 'Sổ vay nợ & Cho vay',
                  onBack: widget.onBack ?? () => Navigator.maybePop(context),
                  actions: [
                    FinoraAddIconButton(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tạo khoản vay / cho vay mới')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: CatalogHeroCard(
                title: _isLendTab ? 'Người khác nợ bạn' : 'Bạn đang nợ người khác',
                amount: totalRemaining,
                subtitle: 'Gốc ban đầu: ${_vnd.format(totalPrincipal)} đ',
                gradientColors: _isLendTab
                    ? const [Color(0xFF065F46), Color(0xFF059669)]
                    : const [Color(0xFF991B1B), Color(0xFFDC2626)],
                metrics: [
                  HeroMetricItem(
                    label: 'Đã thu hồi / Trả',
                    value: _vnd.format(totalPrincipal - totalRemaining),
                    color: Colors.white,
                  ),
                  HeroMetricItem(
                    label: 'Số khoản nợ',
                    value: '${loans.length} khoản',
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isLendTab = true);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isLendTab
                                ? const Color(0xFF059669).withValues(alpha: isDark ? 0.35 : 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _isLendTab
                                  ? const Color(0xFF059669).withValues(alpha: 0.6)
                                  : (isDark ? Colors.white12 : Colors.black12),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Cho vay (Cần thu)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _isLendTab ? FontWeight.bold : FontWeight.normal,
                              color: _isLendTab ? const Color(0xFF10B981) : (isDark ? Colors.white60 : Colors.black54),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isLendTab = false);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isLendTab
                                ? const Color(0xFFDC2626).withValues(alpha: isDark ? 0.35 : 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: !_isLendTab
                                  ? const Color(0xFFDC2626).withValues(alpha: 0.6)
                                  : (isDark ? Colors.white12 : Colors.black12),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Vay nợ (Cần trả)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: !_isLendTab ? FontWeight.bold : FontWeight.normal,
                              color: !_isLendTab ? const Color(0xFFEF4444) : (isDark ? Colors.white60 : Colors.black54),
                            ),
                          ),
                        ),
                      ),
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
                    final loan = loans[idx];
                    return _buildLoanCard(loan, isDark, _isLendTab);
                  },
                  childCount: loans.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanCard(CatalogLoanItem loan, bool isDark, bool isLend) {
    final paid = loan.amount - loan.remainingAmount;
    final progress = (paid / loan.amount).clamp(0.0, 1.0);

    return CatalogGlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: () {
        CatalogBottomSheets.showLoanRepaymentSheet(context, loan);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (isLend ? GlassmorphismTokens.income : GlassmorphismTokens.expense).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isLend ? LucideIcons.arrow_up_right : LucideIcons.arrow_down_left,
                  color: isLend ? GlassmorphismTokens.income : GlassmorphismTokens.expense,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hạn thanh toán: ${loan.dueDate}',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_vnd.format(loan.remainingAmount)} đ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isLend ? GlassmorphismTokens.income : GlassmorphismTokens.expense,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Gốc: ${_vnd.format(loan.amount)} đ',
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
              minHeight: 6,
              backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(
                isLend ? GlassmorphismTokens.income : GlassmorphismTokens.expense,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
