import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';

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
      backgroundColor:
          dark ? const Color(0xFF14273A) : const Color(0xFFF1F6FA),
      body: AmbientFloatingBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              // Header: head('Bức tranh tài chính', 'Hiểu tiền của bạn đang đi đâu')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bức tranh tài chính',
                          style: TextStyle(
                            color: dark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Hiểu tiền của bạn đang đi đâu',
                          style: TextStyle(
                            color: dark ? const Color(0xFFABC0D3) : const Color(0xFF7A90A5),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.isRoot && Navigator.of(context).canPop())
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF1D354B) : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: dark ? const Color(0xFF2C4861) : const Color(0xFFDCE5EF),
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 19,
                          color: dark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Segmented Tabs: ['Tháng này', 'Tháng trước']
              Container(
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF1D354B) : const Color(0xFFE6EEF5),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _quickPeriod = ReportQuickPeriod.thisMonth),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _quickPeriod == ReportQuickPeriod.thisMonth
                                ? (dark ? const Color(0xFF26435C) : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: _quickPeriod == ReportQuickPeriod.thisMonth
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Tháng này',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _quickPeriod == ReportQuickPeriod.thisMonth
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: _quickPeriod == ReportQuickPeriod.thisMonth
                                  ? (dark ? Colors.white : const Color(0xFF173452))
                                  : (dark ? const Color(0xFF8EAEC8) : const Color(0xFF5A7590)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _quickPeriod = ReportQuickPeriod.lastMonth),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _quickPeriod == ReportQuickPeriod.lastMonth
                                ? (dark ? const Color(0xFF26435C) : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: _quickPeriod == ReportQuickPeriod.lastMonth
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Tháng trước',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _quickPeriod == ReportQuickPeriod.lastMonth
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: _quickPeriod == ReportQuickPeriod.lastMonth
                                  ? (dark ? Colors.white : const Color(0xFF173452))
                                  : (dark ? const Color(0xFF8EAEC8) : const Color(0xFF5A7590)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // 1. Donut Chart (Demo: .donut 190x190)
              Center(
                child: Container(
                  width: 190,
                  height: 190,
                  margin: const EdgeInsets.symmetric(vertical: 18),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        Color(0xFF005FEA),
                        Color(0xFF005FEA),
                        Color(0xFF62B9CA),
                        Color(0xFF62B9CA),
                        Color(0xFFEDBF74),
                        Color(0xFFEDBF74),
                        Color(0xFF005FEA),
                      ],
                      stops: [0.0, 0.43, 0.43, 0.68, 0.68, 1.0, 1.0],
                    ),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF172A3D) : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'TỔNG CHI TIÊU',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: dark ? const Color(0xFFABC0D3) : const Color(0xFF7A90A5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          expense > 1000000
                              ? '${(expense / 1000000).toStringAsFixed(1).replaceAll('.', ',')} triệu'
                              : formatVND(expense),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: dark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '↓ 6,3% so với kỳ trước',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF258674),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Legend (Demo: .legend)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDemoLegend('Sinh hoạt', const Color(0xFF005FEA), dark),
                  const SizedBox(width: 16),
                  _buildDemoLegend('Mua sắm', const Color(0xFF62B9CA), dark),
                  const SizedBox(width: 16),
                  _buildDemoLegend('Khác', const Color(0xFFEDBF74), dark),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Section Phân bổ chi tiêu (Demo: section('Phân bổ chi tiêu', 'categories', 'Danh mục'))
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Phân bổ chi tiêu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: dark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                    ),
                  ),
                  const Text(
                    'Danh mục ↗',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF005FEA),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildDemoReportRow(
                icon: LucideIcons.house,
                color: const Color(0xFF005FEA),
                bgColor: const Color(0xFFE5EFFF),
                title: 'Sinh hoạt',
                subtitle: '43% tổng chi',
                amount: '5.332.000 ₫',
                dark: dark,
              ),
              _buildDemoReportRow(
                icon: LucideIcons.shopping_bag,
                color: const Color(0xFF258674),
                bgColor: const Color(0xFFE2F2EA),
                title: 'Mua sắm',
                subtitle: '25% tổng chi',
                amount: '3.100.000 ₫',
                dark: dark,
              ),
              _buildDemoReportRow(
                icon: LucideIcons.ellipsis,
                color: const Color(0xFFB77626),
                bgColor: const Color(0xFFFFF0D7),
                title: 'Khác',
                subtitle: '32% tổng chi',
                amount: '3.968.000 ₫',
                dark: dark,
              ),
              const SizedBox(height: 24),

              // 4. Section Nhịp chi 6 tháng (Demo: section('Nhịp chi 6 tháng', 'transactions', 'Chi tiết'))
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nhịp chi 6 tháng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: dark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                    ),
                  ),
                  const Text(
                    'Chi tiết ↗',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF005FEA),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 6 Bars (Demo: .bars)
              Container(
                height: 130,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDemoBar(42, false, dark),
                    _buildDemoBar(65, false, dark),
                    _buildDemoBar(55, false, dark),
                    _buildDemoBar(87, true, dark), // Max
                    _buildDemoBar(74, false, dark),
                    _buildDemoBar(68, false, dark),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['T4', 'T5', 'T6', 'T7', 'T8', 'T9'].map((m) => Text(
                    m,
                    style: TextStyle(
                      fontSize: 11,
                      color: dark ? const Color(0xFFABC0D3) : const Color(0xFF7A90A5),
                      fontWeight: FontWeight.w600,
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoLegend(String label, Color color, bool dark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: dark ? const Color(0xFFABC0D3) : const Color(0xFF5A7590),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDemoBar(double heightPercent, bool isActive, bool dark) {
    return Container(
      width: 28,
      height: 130 * (heightPercent / 100),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF005FEA)
            : (dark ? const Color(0xFF26435C) : const Color(0xFFDCE7F1)),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildDemoReportRow({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String title,
    required String subtitle,
    required String amount,
    required bool dark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1D354B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dark ? const Color(0xFF2C4861) : const Color(0xFFE1E9F1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: color),
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
                    fontWeight: FontWeight.w700,
                    color: dark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: dark ? const Color(0xFFABC0D3) : const Color(0xFF7A90A5),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: dark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPeriodSelector(bool dark) {
    const periods = [
      ReportQuickPeriod.thisMonth,
      ReportQuickPeriod.lastMonth,
      ReportQuickPeriod.thisYear,
    ];
    return BouncyPillTabs(
      labels: const ['Tháng này', 'Tháng trước', 'Năm nay'],
      selectedIndex: periods.indexOf(_quickPeriod),
      colors: const [
        Color(0xFF2563EB),
        Color(0xFF0D9488),
        Color(0xFFEA580C),
      ],
      onChanged: (i) => setState(() => _quickPeriod = periods[i]),
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
        color: dark
            ? const Color(0xFF161B26).withValues(alpha: 0.75)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF1E293B).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
        color: dark
            ? const Color(0xFF161B26).withValues(alpha: 0.75)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF1E293B).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
        color: dark
            ? const Color(0xFF161B26).withValues(alpha: 0.75)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF1E293B).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
        color: dark
            ? const Color(0xFF161B26).withValues(alpha: 0.75)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF1E293B).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
