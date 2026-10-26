import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/design_system/v8/finora_v8.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/subject_filter_pill.dart';
import '../../data/models/transaction.dart';
import '../../state/transaction_provider.dart';
import '../../core/widgets/finora_motion.dart';

enum ReportQuickPeriod {
  thisMonth,
  lastMonth,
  thisYear,
}

class ReportScreen extends StatefulWidget {
  final String userId;
  final bool isRoot;
  const ReportScreen({super.key, required this.userId, this.isRoot = false});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportQuickPeriod _quickPeriod = ReportQuickPeriod.thisYear;
  OwnerFilter _ownerFilter = OwnerFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<TransactionProvider>().load(widget.userId),
    );
  }

  bool _isIncome(TransactionModel t) =>
      const {'income', 'borrowing', 'loan_repayment_received'}.contains(t.type);

  bool _isExpense(TransactionModel t) => const {
        'expense',
        'saving',
        'lending',
        'debt_repayment',
        'credit_card_payment',
      }.contains(t.type);

  bool _matchesPeriod(DateTime date, ReportQuickPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case ReportQuickPeriod.thisMonth:
        return date.year == now.year && date.month == now.month;
      case ReportQuickPeriod.lastMonth:
        final lastMonthDate = DateTime(now.year, now.month - 1, 1);
        return date.year == lastMonthDate.year &&
            date.month == lastMonthDate.month;
      case ReportQuickPeriod.thisYear:
        return date.year == now.year;
    }
  }

  DateTime _parseTxDate(int raw) {
    if (raw < 10000000000) {
      return DateTime.fromMillisecondsSinceEpoch(raw * 1000);
    }
    return DateTime.fromMillisecondsSinceEpoch(raw);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final sub = dark ? AppColors.darkTextSecondary : const Color(0xFF64748B);
    final provider = context.watch<TransactionProvider>();
    final all = provider.transactions;
    final walletMap = {for (final w in provider.wallets) w.id: w};

    // Filter transactions by selected member & period
    final txs = all.where((t) {
      final memberOk = _ownerFilter.matchTransaction(t, walletMap: walletMap);
      final dateOk = _matchesPeriod(_parseTxDate(t.date), _quickPeriod);
      return memberOk && dateOk;
    }).toList();

    // 1. Total Income & Expense
    final income = txs.where(_isIncome).fold<int>(0, (s, t) => s + t.amount);
    final expense = txs.where(_isExpense).fold<int>(0, (s, t) => s + t.amount);
    final netAmount = income - expense;

    // 2. Category structure for Donut chart
    final categoryTotals = <String, int>{};
    for (final t in txs.where(_isExpense)) {
      final cat = (t.categoryName != null && t.categoryName!.trim().isNotEmpty)
          ? t.categoryName!.trim()
          : 'Khác';
      categoryTotals[cat] = (categoryTotals[cat] ?? 0) + t.amount;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Consolidate beyond top 5 into 'Khác'
    final List<MapEntry<String, int>> displayCategories = [];
    if (sortedCategories.length <= 5) {
      displayCategories.addAll(sortedCategories);
    } else {
      displayCategories.addAll(sortedCategories.take(4));
      final otherSum = sortedCategories
          .skip(4)
          .fold<int>(0, (prev, element) => prev + element.value);
      displayCategories.add(MapEntry('Khác', otherSum));
    }

    const categoryColors = [
      Color(0xFF10B981), // Emerald green
      Color(0xFF06B6D4), // Cyan
      Color(0xFFF59E0B), // Amber
      Color(0xFFEF4444), // Red
      Color(0xFF3B82F6), // Blue
      Color(0xFF0284C7), // Sky Blue (Replaced Purple)
      Color(0xFFEC4899), // Pink
    ];

    // 3. Husband vs Wife spending ratio
    int husbandExpense = 0;
    int wifeExpense = 0;
    for (final t in txs.where(_isExpense)) {
      if (OwnerFilter.husband.matchTransaction(t, walletMap: walletMap)) {
        husbandExpense += t.amount;
      } else if (OwnerFilter.wife.matchTransaction(t, walletMap: walletMap)) {
        wifeExpense += t.amount;
      }
    }
    final totalCouples = husbandExpense + wifeExpense;
    final double husbandRatio =
        totalCouples > 0 ? (husbandExpense / totalCouples) : 0.5;
    final int husbandPercent = (husbandRatio * 100).round();
    final int wifePercent = 100 - husbandPercent;

    // 4. Last 6 months trend
    final now = DateTime.now();
    final List<DateTime> months = List.generate(6, (i) {
      return DateTime(now.year, now.month - 5 + i, 1);
    });

    final monthlyStats = months.map((m) {
      final monthTxs = all.where((t) {
        final memberOk = _ownerFilter.matchTransaction(t, walletMap: walletMap);
        final d = _parseTxDate(t.date);
        final isMonth = d.year == m.year && d.month == m.month;
        return memberOk && isMonth;
      }).toList();

      final mIncome =
          monthTxs.where(_isIncome).fold<int>(0, (s, t) => s + t.amount);
      final mExpense =
          monthTxs.where(_isExpense).fold<int>(0, (s, t) => s + t.amount);

      return {
        'label':
            '${m.month.toString().padLeft(2, '0')}/${m.year.toString().substring(2)}',
        'income': mIncome,
        'expense': mExpense,
      };
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientFloatingBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
            children: [
              FinoraPageHeader(
                title: 'Báo cáo tài chính',
                onBack: !widget.isRoot && Navigator.of(context).canPop()
                    ? () => Navigator.of(context).pop()
                    : null,
              ),
              const SizedBox(height: 12),

              // Unified Harmonious Filter Bar: [ Tháng này | Tháng trước | Năm nay ] + [ 👥 Tất cả ▾ ]
              Row(
                children: [
                  Expanded(
                    child: _buildPeriodSelector(dark),
                  ),
                  const SizedBox(width: 8),
                  _buildMemberFilterButton(dark),
                ],
              ),
              const SizedBox(height: 14),

              // Card 1: TÍCH LŨY RÒNG TRONG KỲ
              FinoraStaggeredItem(
                index: 0,
                child: _buildNetWorthCard(
                  dark: dark,
                  netAmount: netAmount,
                  income: income,
                  expense: expense,
                ),
              ),
              const SizedBox(height: 14),

              // Card 2: Cơ cấu danh mục chi tiêu
              FinoraStaggeredItem(
                index: 1,
                child: _buildExpenseCategoryCard(
                  dark: dark,
                  categories: displayCategories,
                  totalExpense: expense,
                  colors: categoryColors,
                  text: text,
                  sub: sub,
                ),
              ),
              const SizedBox(height: 14),

              // Card 3: Tỷ trọng chi tiêu Vợ & Chồng
              FinoraStaggeredItem(
                index: 2,
                child: _buildCoupleRatioCard(
                  dark: dark,
                  husbandExpense: husbandExpense,
                  wifeExpense: wifeExpense,
                  husbandPercent: husbandPercent,
                  wifePercent: wifePercent,
                  text: text,
                  sub: sub,
                ),
              ),
              const SizedBox(height: 14),

              // Card 4: Biến động Thu - Chi 6 tháng gần nhất
              FinoraStaggeredItem(
                index: 3,
                child: _buildSixMonthsTrendCard(
                  dark: dark,
                  monthlyStats: monthlyStats,
                  text: text,
                  sub: sub,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildPeriodSelector(bool dark) {
    const periods = [
      ReportQuickPeriod.thisMonth,
      ReportQuickPeriod.lastMonth,
      ReportQuickPeriod.thisYear,
    ];
    const labels = ['Tháng này', 'Tháng trước', 'Năm nay'];
    final selectedIndex = periods.indexOf(_quickPeriod);
    final x = (selectedIndex / (periods.length - 1)) * 2 - 1;

    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xFF2C2C2E)
            : const Color(0xFFE5E5EA).withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark ? const Color(0xFF38383A) : const Color(0xFFD1D1D6),
          width: 0.5,
        ),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment(x, 0),
            child: FractionallySizedBox(
              widthFactor: 1 / periods.length,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF007AFF).withValues(alpha: 0.28),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: List.generate(periods.length, (i) {
              final isSelected = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (!isSelected) {
                      HapticFeedback.selectionClick();
                      setState(() => _quickPeriod = periods[i]);
                    }
                  },
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (dark
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFF636366)),
                        letterSpacing: -0.2,
                      ),
                      child: Text(
                        labels[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  IconData _getMemberIcon(OwnerFilter filter) {
    switch (filter) {
      case OwnerFilter.husband:
        return Icons.person_rounded;
      case OwnerFilter.wife:
        return Icons.person_2_rounded;
      case OwnerFilter.joint:
        return Icons.people_outline_rounded;
      case OwnerFilter.all:
      default:
        return Icons.people_alt_rounded;
    }
  }

  Widget _buildMemberFilterButton(bool dark) {
    return PopupMenuButton<OwnerFilter>(
      initialValue: _ownerFilter,
      tooltip: 'Lọc theo thành viên',
      onSelected: (val) {
        HapticFeedback.selectionClick();
        setState(() => _ownerFilter = val);
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: dark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
          width: 0.5,
        ),
      ),
      color: dark ? const Color(0xFF1C1C1E) : Colors.white,
      elevation: 10,
      offset: const Offset(0, 46),
      itemBuilder: (ctx) => [
        _buildPopupMenuItem(OwnerFilter.all, 'Tất cả', Icons.people_alt_rounded, dark),
        _buildPopupMenuItem(OwnerFilter.husband, 'Chồng', Icons.person_rounded, dark),
        _buildPopupMenuItem(OwnerFilter.wife, 'Vợ', Icons.person_2_rounded, dark),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: dark
              ? const Color(0xFF2C2C2E)
              : const Color(0xFFE5E5EA).withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: dark ? const Color(0xFF38383A) : const Color(0xFFD1D1D6),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getMemberIcon(_ownerFilter),
              size: 15,
              color: const Color(0xFF007AFF),
            ),
            const SizedBox(width: 5),
            Text(
              _ownerFilter.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: dark ? Colors.white : const Color(0xFF1C1C1E),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: dark ? const Color(0xFF8E8E93) : const Color(0xFF636366),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<OwnerFilter> _buildPopupMenuItem(
    OwnerFilter filter,
    String label,
    IconData icon,
    bool dark,
  ) {
    final isSelected = _ownerFilter == filter;
    return PopupMenuItem<OwnerFilter>(
      value: filter,
      height: 40,
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: isSelected
                ? const Color(0xFF007AFF)
                : (dark ? const Color(0xFF8E8E93) : const Color(0xFF636366)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF007AFF)
                    : (dark ? Colors.white : const Color(0xFF1C1C1E)),
              ),
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check_rounded,
              size: 16,
              color: Color(0xFF007AFF),
            ),
        ],
      ),
    );
  }

  Widget _buildNetWorthCard({
    required bool dark,
    required int netAmount,
    required int income,
    required int expense,
  }) {
    final isNegative = netAmount < 0;
    final netColor =
        isNegative ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: dark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TÍCH LŨY RÒNG TRONG KỲ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: dark ? Colors.white60 : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          FinoraAnimatedAmount(
            amount: netAmount.toDouble(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: netColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng thu nhập',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: dark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FinoraAnimatedAmount(
                      amount: income.toDouble(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Tổng chi tiêu',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: dark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FinoraAnimatedAmount(
                      amount: expense.toDouble(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCategoryCard({
    required bool dark,
    required List<MapEntry<String, int>> categories,
    required int totalExpense,
    required List<Color> colors,
    required Color text,
    required Color sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: dark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cơ cấu danh mục chi tiêu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: text,
            ),
          ),
          const SizedBox(height: 18),
          if (categories.isEmpty || totalExpense == 0)
            Container(
              height: 120,
              alignment: Alignment.center,
              child: Text(
                'Không có dữ liệu chi tiêu trong kỳ này',
                style: TextStyle(color: sub, fontSize: 13),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Donut Chart
                SizedBox(
                  width: 130,
                  height: 130,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 36,
                      startDegreeOffset: -90,
                      sections: [
                        for (int i = 0; i < categories.length; i++)
                          PieChartSectionData(
                            color: colors[i % colors.length],
                            value: categories[i].value.toDouble(),
                            title: '',
                            radius: 20,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Legend list
                Expanded(
                  child: Column(
                    children: [
                      for (int i = 0; i < categories.length; i++) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: colors[i % colors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  categories[i].key,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: text,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${totalExpense > 0 ? (categories[i].value * 100 / totalExpense).round() : 0}%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCoupleRatioCard({
    required bool dark,
    required int husbandExpense,
    required int wifeExpense,
    required int husbandPercent,
    required int wifePercent,
    required Color text,
    required Color sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: dark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tỷ trọng chi tiêu Vợ & Chồng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: text,
                ),
              ),
              const Icon(
                Icons.donut_small_rounded,
                size: 20,
                color: Color(0xFF3B82F6),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Dual Segmented Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: husbandPercent > 0 ? husbandPercent : 1,
                    child: Container(
                      color: const Color(0xFF173B70),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: wifePercent > 0 ? wifePercent : 1,
                    child: Container(
                      color: const Color(0xFFDB2777),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Chồng Row
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF173B70),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Chồng',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: text,
                ),
              ),
              const Spacer(),
              FinoraAnimatedAmount(
                amount: husbandExpense.toDouble(),
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: text,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF173B70).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$husbandPercent%',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF173B70),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Vợ Row
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFDB2777),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Vợ',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: text,
                ),
              ),
              const Spacer(),
              FinoraAnimatedAmount(
                amount: wifeExpense.toDouble(),
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: text,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDB2777).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$wifePercent%',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFDB2777),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSixMonthsTrendCard({
    required bool dark,
    required List<Map<String, dynamic>> monthlyStats,
    required Color text,
    required Color sub,
  }) {
    // Find highest value among income and expense for chart normalization
    double maxVal = 1000000;
    for (final s in monthlyStats) {
      final inc = (s['income'] as int).toDouble();
      final exp = (s['expense'] as int).toDouble();
      if (inc > maxVal) maxVal = inc;
      if (exp > maxVal) maxVal = exp;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: dark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Biến động Thu - Chi 6 tháng gần nhất',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: text,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxVal * 1.15,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < monthlyStats.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              monthlyStats[idx]['label'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: sub,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (int i = 0; i < monthlyStats.length; i++)
                    BarChartGroupData(
                      x: i,
                      barsSpace: 4,
                      barRods: [
                        // Income bar (green)
                        BarChartRodData(
                          toY: (monthlyStats[i]['income'] as int).toDouble(),
                          color: const Color(0xFF10B981),
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        // Expense bar (red)
                        BarChartRodData(
                          toY: (monthlyStats[i]['expense'] as int).toDouble(),
                          color: const Color(0xFFEF4444),
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
