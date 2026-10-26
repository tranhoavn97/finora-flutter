import 'package:flutter/material.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/subject_filter_pill.dart';
import '../../core/widgets/vikram_widgets.dart';
import '../../state/dashboard_provider.dart';

/// Read-only presentation of ledger data. Never substitutes example balances.
class DashboardSummary extends StatelessWidget {
  final DashboardData data;
  final bool obscure;
  final VoidCallback onToggleVisibility;
  final VoidCallback onDateTap;
  final ValueChanged<OwnerFilter> onOwnerSelected;
  final VoidCallback onAssetsTap;
  final VoidCallback onLoansTap;
  const DashboardSummary(
      {super.key,
      required this.data,
      required this.obscure,
      required this.onToggleVisibility,
      required this.onDateTap,
      required this.onOwnerSelected,
      required this.onAssetsTap,
      required this.onLoansTap});

  String money(num value) =>
      obscure ? '••••••' : Formatters.formatCurrency(value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return FrostedCard(
      hasNotch: true,
      radius: 28,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: TOTAL SPENDING & Period dropdown pill
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.32 : 0.20),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFEF4444),
                            blurRadius: 4,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'TỔNG CHI TIÊU',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
              VikramPillDropdown(
                label: data.periodLabel,
                onTap: onDateTap,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Big Hero Currency (Total Spending / Expense)
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  money(data.periodExpense),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: primaryTextColor,
                    letterSpacing: -1.0,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              IconButton(
                tooltip: obscure ? 'Hiện số dư' : 'Ẩn số dư',
                onPressed: onToggleVisibility,
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: secondaryTextColor,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Trend pill & Active count / Member filter
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              CapsuleBadge(
                text: '12% ít hơn tháng trước',
                icon: Icons.trending_down_rounded,
                bgColor: isDark
                    ? const Color(0xFF064E3B).withValues(alpha: 0.5)
                    : const Color(0xFFDCFCE7),
                textColor:
                    isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A),
              ),
              MemberDropdownPill(
                selected: data.selectedOwner,
                onSelected: onOwnerSelected,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: isDark ? const Color(0xFF223157) : const Color(0xFFE8EDF9),
            height: 1,
          ),
          const SizedBox(height: 14),
          // 2x2 Sub-metrics Grid (Income, Net, Total Balance, Assets & Loans)
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onAssetsTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.arrow_downward_rounded,
                                size: 14, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Thu nhập',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: secondaryTextColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          money(data.periodIncome),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color:
                    isDark ? const Color(0xFF223157) : const Color(0xFFE8EDF9),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: onLoansTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.show_chart_rounded,
                                size: 14, color: Color(0xFF6366F1)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Thuần',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: secondaryTextColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          money(data.periodNet),
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onAssetsTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_outlined,
                                size: 14, color: Color(0xFF0284C7)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Tổng số dư',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: secondaryTextColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          money(data.totalWalletBalance),
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color:
                    isDark ? const Color(0xFF223157) : const Color(0xFFE8EDF9),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: onAssetsTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.pie_chart_outline_rounded,
                                size: 14, color: Color(0xFFF97316)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Tổng tài sản',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: secondaryTextColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          money(data.totalAssetsValue),
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color:
                    isDark ? const Color(0xFF223157) : const Color(0xFFE8EDF9),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: onLoansTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.money_off_rounded,
                                size: 14, color: Color(0xFFEF4444)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Khoản vay',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: secondaryTextColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          money(data.totalBorrowed),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Financial Health Card matching Web AiFinancialHealthWidget
class FinancialHealthCard extends StatelessWidget {
  final DashboardData data;
  final VoidCallback? onAnalyzeTap;

  const FinancialHealthCard({super.key, required this.data, this.onAnalyzeTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    // Dynamic metrics estimation from real data
    final income = data.periodIncome;
    final expense = data.periodExpense;
    final net = data.periodNet;
    final balance = data.totalWalletBalance;
    final debt = data.totalBorrowed;

    final savingsRate =
        income > 0 ? ((net / income) * 100).clamp(0, 100).toInt() : 0;
    final runwayMonths = expense > 0
        ? (balance / expense).clamp(0, 24).toStringAsFixed(1)
        : '6+';

    // Heuristic score (0-100)
    int score = 50;
    if (balance > 0) score += 15;
    if (net > 0) score += 15;
    if (debt == 0) score += 10;
    if (savingsRate >= 20) score += 10;
    score = score.clamp(30, 95);

    final isGreat = score >= 80;
    final isGood = score >= 65;
    final tierLabel =
        isGreat ? 'Xuất sắc' : (isGood ? 'Ổn định' : 'Cần cải thiện');
    final tierColor = isGreat
        ? const Color(0xFF10B981)
        : (isGood ? const Color(0xFF2563EB) : const Color(0xFFF59E0B));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161922) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF22283A) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Text(
                          'Sức khỏe Tài chính AI',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: primaryTextColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF3B82F6).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: const Color(0xFF3B82F6)
                                    .withValues(alpha: 0.2)),
                          ),
                          child: const Text(
                            'COPILOT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2563EB),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Chưa đủ dữ liệu 12 tháng · Ước lượng tức thời theo dòng tiền',
                      style: TextStyle(
                        fontSize: 11,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Layout: Score Badge + 3 KPIs
          LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1.0);
              final isCompact = constraints.maxWidth < 350 || textScale > 1.2;

              final scoreWidget = Container(
                width: isCompact ? double.infinity : 76,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tierColor.withValues(alpha: 0.3)),
                ),
                child: isCompact
                    ? Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 2,
                        children: [
                          Text(
                            '$score',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: tierColor,
                            ),
                          ),
                          Text(
                            tierLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: tierColor,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$score',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: tierColor,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            tierLabel,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: tierColor,
                            ),
                          ),
                        ],
                      ),
              );

              final tilesWidget = Row(
                children: [
                  Expanded(
                    child: _metricTile(
                      context,
                      title: 'DỰ PHÒNG',
                      value: '$runwayMonths th',
                      sub: 'An toàn',
                      icon: Icons.shield_outlined,
                      iconColor: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _metricTile(
                      context,
                      title: 'TÍCH LŨY',
                      value: '$savingsRate%',
                      sub: 'Mục tiêu 20%',
                      icon: Icons.trending_up_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _metricTile(
                      context,
                      title: 'DƯ NỢ',
                      value: debt > 0
                          ? '${(debt / 1000000).toStringAsFixed(1)}Tr'
                          : '0 đ',
                      sub: debt > 0 ? 'Cần chú ý' : 'An toàn',
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: debt > 0
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                  ),
                ],
              );

              if (isCompact) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    scoreWidget,
                    const SizedBox(height: 8),
                    tilesWidget,
                  ],
                );
              }

              return Row(
                children: [
                  scoreWidget,
                  const SizedBox(width: 8),
                  Expanded(child: tilesWidget),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          // AI Narrative & CTA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF10131A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF1E2433) : const Color(0xFFEDF2F7),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates_rounded,
                    size: 15, color: Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    net >= 0
                        ? 'Dòng tiền kỳ này đang dương, tiếp tục duy trì tích lũy.'
                        : 'Chi tiêu đang vượt thu nhập, hãy xem lại các khoản chi.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: onAnalyzeTap,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Xem 360°',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            size: 15, color: Color(0xFF2563EB)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(
    BuildContext context, {
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C202C) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF272D3E) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              Icon(icon, size: 10, color: iconColor),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
