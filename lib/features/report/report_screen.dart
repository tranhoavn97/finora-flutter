import '../../core/widgets/finora/financial_components.dart'
    show TransactionRow;
import '../transaction/transaction_detail_sheet.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/utils/date_filter.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/date_filter_modal.dart';
import '../../core/widgets/finora_date_picker_sheet.dart';
import '../../core/widgets/finora_member_filter.dart';
import '../../core/widgets/finora_motion.dart';
import '../../core/widgets/finora_privacy_mask.dart';
import '../../core/widgets/subject_filter_pill.dart';
import '../../data/models/transaction.dart';
import '../../state/theme_studio_controller.dart';
import '../../state/transaction_provider.dart';

enum ReportQuickPeriod {
  thisMonth,
  lastMonth,
  thisQuarter,
  sixMonths,
  thisYear,
  allTime,
  customRange,
}

class _CategoryStatItem {
  final String name;
  final int amount;
  final int count;

  const _CategoryStatItem({
    required this.name,
    required this.amount,
    required this.count,
  });
}

class ReportScreen extends StatefulWidget {
  final String userId;
  final bool isRoot;
  final bool isTab;
  const ReportScreen({
    super.key,
    required this.userId,
    this.isRoot = false,
    this.isTab = false,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportQuickPeriod _quickPeriod = ReportQuickPeriod.thisMonth;
  OwnerFilter _ownerFilter = OwnerFilter.all;
  DateTimeRange? _customRange;
  bool _showIncomeCategories = false; // false: Chi tiêu, true: Thu nhập

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

  bool _isLendingOrLoanRepayment(TransactionModel t) =>
      const {'lending', 'loan_repayment_received'}.contains(t.type);

  bool _isBorrowingOrDebtRepayment(TransactionModel t) => const {
        'borrowing',
        'debt_repayment',
        'credit_card_payment'
      }.contains(t.type);

  DateTime _parseTxDate(int raw) {
    if (raw < 10000000000) {
      return DateTime.fromMillisecondsSinceEpoch(raw * 1000);
    }
    return DateTime.fromMillisecondsSinceEpoch(raw);
  }

  bool _matchesPeriod(DateTime date, ReportQuickPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case ReportQuickPeriod.thisMonth:
        return date.year == now.year && date.month == now.month;
      case ReportQuickPeriod.lastMonth:
        final lastMonthDate = DateTime(now.year, now.month - 1, 1);
        return date.year == lastMonthDate.year &&
            date.month == lastMonthDate.month;
      case ReportQuickPeriod.thisQuarter:
        final startQuarterMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        final quarterStart = DateTime(now.year, startQuarterMonth, 1);
        final quarterEnd = DateTime(now.year, startQuarterMonth + 3, 1);
        return !date.isBefore(quarterStart) && date.isBefore(quarterEnd);
      case ReportQuickPeriod.sixMonths:
        final sixMonthsStart = DateTime(now.year, now.month - 5, 1);
        return !date.isBefore(sixMonthsStart);
      case ReportQuickPeriod.thisYear:
        return date.year == now.year;
      case ReportQuickPeriod.allTime:
        return true;
      case ReportQuickPeriod.customRange:
        if (_customRange == null) return true;
        final start = DateTime(
          _customRange!.start.year,
          _customRange!.start.month,
          _customRange!.start.day,
        );
        final end = DateTime(
          _customRange!.end.year,
          _customRange!.end.month,
          _customRange!.end.day,
          23,
          59,
          59,
          999,
        );
        return !date.isBefore(start) && !date.isAfter(end);
    }
  }

  int _activePeriodDaysCount() {
    final now = DateTime.now();
    switch (_quickPeriod) {
      case ReportQuickPeriod.thisMonth:
        return now.day.clamp(1, 31);
      case ReportQuickPeriod.lastMonth:
        return DateTime(now.year, now.month, 0).day.clamp(1, 31);
      case ReportQuickPeriod.thisQuarter:
        final startQuarterMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        final quarterStart = DateTime(now.year, startQuarterMonth, 1);
        return (now.difference(quarterStart).inDays + 1).clamp(1, 92);
      case ReportQuickPeriod.sixMonths:
        final sixMonthsStart = DateTime(now.year, now.month - 5, 1);
        return (now.difference(sixMonthsStart).inDays + 1).clamp(1, 185);
      case ReportQuickPeriod.thisYear:
        final yearStart = DateTime(now.year, 1, 1);
        return (now.difference(yearStart).inDays + 1).clamp(1, 366);
      case ReportQuickPeriod.allTime:
        return 30;
      case ReportQuickPeriod.customRange:
        if (_customRange == null) return 30;
        return (_customRange!.end.difference(_customRange!.start).inDays + 1)
            .clamp(1, 3650);
    }
  }

  Future<void> _pickCustomRange() async {
    HapticFeedback.selectionClick();
    final picked = await FinoraDatePickerSheet.showDateRange(
      context,
      initialStartDate: _customRange?.start ??
          DateTime.now().subtract(const Duration(days: 30)),
      initialEndDate: _customRange?.end ?? DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _customRange = picked;
        _quickPeriod = ReportQuickPeriod.customRange;
      });
    }
  }

  // ignore: unused_element
  Future<void> _openUnifiedDateFilterModal() async {
    final res = await showDateFilterModal(
      context,
      currentOption: DateFilterOption.thisMonth,
      currentCustomRange: _customRange,
    );
    if (res == null || !mounted) return;
    setState(() {
      if (res.option == DateFilterOption.thisMonth) {
        _quickPeriod = ReportQuickPeriod.thisMonth;
      } else if (res.option == DateFilterOption.lastMonth) {
        _quickPeriod = ReportQuickPeriod.lastMonth;
      } else if (res.option == DateFilterOption.thisYear) {
        _quickPeriod = ReportQuickPeriod.thisYear;
      } else if (res.option == DateFilterOption.allTime) {
        _quickPeriod = ReportQuickPeriod.allTime;
      } else if (res.option == DateFilterOption.customRange &&
          res.customRange != null) {
        _customRange = res.customRange;
        _quickPeriod = ReportQuickPeriod.customRange;
      }
    });
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

    // 1. Cashflow Breakdown Totals
    final income = txs.where(_isIncome).fold<int>(0, (s, t) => s + t.amount);
    final expense = txs.where(_isExpense).fold<int>(0, (s, t) => s + t.amount);
    final netCashflow = income - expense;
    final lendingFlow = txs
        .where(_isLendingOrLoanRepayment)
        .fold<int>(0, (s, t) => s + t.amount);
    final debtFlow = txs
        .where(_isBorrowingOrDebtRepayment)
        .fold<int>(0, (s, t) => s + t.amount);
    final double savingsRate = income > 0
        ? (((income - expense) / income) * 100).clamp(-999.0, 100.0)
        : 0.0;
    final int avgDailyExpense = (expense / _activePeriodDaysCount()).round();

    // 2. Category structure for Donut chart & detailed list (toggleable between Chi tiêu & Thu nhập)
    final targetTxs = _showIncomeCategories
        ? txs.where(_isIncome).toList()
        : txs.where(_isExpense).toList();
    final targetCategoryTotal = targetTxs.fold<int>(0, (s, t) => s + t.amount);

    final categoryAmountMap = <String, int>{};
    final categoryCountMap = <String, int>{};
    for (final t in targetTxs) {
      final cat = (t.categoryName != null && t.categoryName!.trim().isNotEmpty)
          ? t.categoryName!.trim()
          : 'Khác';
      categoryAmountMap[cat] = (categoryAmountMap[cat] ?? 0) + t.amount;
      categoryCountMap[cat] = (categoryCountMap[cat] ?? 0) + 1;
    }

    final sortedCategoryStats = categoryAmountMap.entries
        .map(
          (e) => _CategoryStatItem(
            name: e.key,
            amount: e.value,
            count: categoryCountMap[e.key] ?? 1,
          ),
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    const categoryColors = [
      Color(0xFF10B981), // Emerald green
      Color(0xFF2563EB), // Cobalt Blue
      Color(0xFFF59E0B), // Amber
      Color(0xFFE11D48), // Rose Red
      Color(0xFF06B6D4), // Cyan
      Color(0xFF0D9488), // Teal
      Color(0xFFDB2777), // Pink
    ];

    // 3. Husband vs Wife cashflow analysis (both Income & Expense)
    int husbandIncome = 0;
    int wifeIncome = 0;
    int husbandExpense = 0;
    int wifeExpense = 0;
    int otherMemberExpense = 0;

    for (final t in txs) {
      final isHusband =
          OwnerFilter.husband.matchTransaction(t, walletMap: walletMap);
      final isWife = OwnerFilter.wife.matchTransaction(t, walletMap: walletMap);
      if (_isIncome(t)) {
        if (isHusband) {
          husbandIncome += t.amount;
        } else if (isWife) {
          wifeIncome += t.amount;
        }
      }
      if (_isExpense(t)) {
        if (isHusband) {
          husbandExpense += t.amount;
        } else if (isWife) {
          wifeExpense += t.amount;
        } else {
          otherMemberExpense += t.amount;
        }
      }
    }

    final totalCouples = husbandExpense + wifeExpense;
    final double husbandRatio =
        totalCouples > 0 ? (husbandExpense / totalCouples) : 0.0;
    final int husbandPercent = (husbandRatio * 100).round();
    final int wifePercent = totalCouples > 0 ? 100 - husbandPercent : 0;

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
        'monthShort': 'T${m.month}',
        'income': mIncome,
        'expense': mExpense,
        'net': mIncome - mExpense,
      };
    }).toList();

    final studio = Provider.of<ThemeStudioController?>(context, listen: true);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card 1 — Chi Tiết Dòng Tiền Ròng (Cashflow Waterfall & Breakdown Card)
          FinoraStaggeredItem(
            index: 0,
            child: _buildCashflowWaterfallCard(
              dark: dark,
              income: income,
              expense: expense,
              netCashflow: netCashflow,
              lendingFlow: lendingFlow,
              debtFlow: debtFlow,
              savingsRate: savingsRate,
              avgDailyExpense: avgDailyExpense,
              text: text,
              sub: sub,
            ),
          ),
          const SizedBox(height: 12),

          // Bộ lọc thời gian & thành viên (Tất cả / Chồng / Vợ) được đẩy xuống dưới widget tổng quan
          _buildFilterBar(dark, studio),
          const SizedBox(height: 14),

          // Card 2 — Biểu Đồ Xu Hướng Dòng Tiền 6 Tháng (6-Month Cashflow Bar Chart)
          FinoraStaggeredItem(
            index: 1,
            child: _buildSixMonthsTrendCard(
              dark: dark,
              monthlyStats: monthlyStats,
              text: text,
              sub: sub,
            ),
          ),
          const SizedBox(height: 12),

          // Card 3 — Cơ Cấu Danh Mục Chi Tiết (Toggleable between Chi tiêu & Thu nhập)
          FinoraStaggeredItem(
            index: 2,
            child: _buildCategoryStructureCard(
              dark: dark,
              categories: sortedCategoryStats,
              transactions: targetTxs,
              totalAmount: targetCategoryTotal,
              colors: categoryColors,
              text: text,
              sub: sub,
            ),
          ),
          const SizedBox(height: 12),

          // Card 4 — Phân Tích Dòng Tiền Vợ & Chồng
          FinoraStaggeredItem(
            index: 3,
            child: _buildCoupleRatioCard(
              dark: dark,
              husbandIncome: husbandIncome,
              wifeIncome: wifeIncome,
              husbandExpense: husbandExpense,
              wifeExpense: wifeExpense,
              otherMemberExpense: otherMemberExpense,
              husbandPercent: husbandPercent,
              wifePercent: wifePercent,
              text: text,
              sub: sub,
            ),
          ),
        ],
      ),
    );
  }

  /// Bộ lọc ngày & thành viên đặt dưới widget tổng quan (`height: 40`)
  Widget _buildFilterBar(bool dark, ThemeStudioController? studio) {
    final periodItems = <(ReportQuickPeriod, String)>[
      (ReportQuickPeriod.thisMonth, 'Tháng này'),
      (ReportQuickPeriod.lastMonth, 'Tháng trước'),
      (ReportQuickPeriod.thisQuarter, 'Quý này (3T)'),
      (ReportQuickPeriod.sixMonths, '6 tháng'),
      (ReportQuickPeriod.thisYear, 'Năm nay'),
      (ReportQuickPeriod.allTime, 'Tất cả'),
    ];

    String currentLabel = 'Tháng này';
    for (final (period, label) in periodItems) {
      if (_quickPeriod == period) currentLabel = label;
    }
    if (_quickPeriod == ReportQuickPeriod.customRange && _customRange != null) {
      currentLabel =
          '${DateFormat('dd/MM').format(_customRange!.start)} - ${DateFormat('dd/MM').format(_customRange!.end)}';
    }

    return Row(
      children: [
        // 1. Period Selector Dropdown Pill (Equal height 40px, premium style)
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: () => _showPeriodSheet(dark, periodItems),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: const Color(0xFF0F6E56)
                      .withValues(alpha: dark ? 0.35 : 0.22),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.16 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F6E56)
                          .withValues(alpha: dark ? 0.22 : 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      size: 14,
                      color: Color(0xFF0F6E56),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      currentLabel,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: dark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // 2. Member Filter Pill (👥 Tất cả / Chồng / Vợ - Equal height 40px & equal width)
        Expanded(
          child: _buildMemberButton(dark, studio),
        ),
      ],
    );
  }

  Future<void> _showPeriodSheet(
    bool dark,
    List<(ReportQuickPeriod, String)> periodItems,
  ) async {
    HapticFeedback.selectionClick();
    final itemsWithMeta = <({
      ReportQuickPeriod period,
      String title,
      String subtitle,
      IconData icon,
      Color iconColor,
      Color iconBgLight,
      Color iconBgDark,
    })>[
      (
        period: ReportQuickPeriod.thisMonth,
        title: 'Tháng này',
        subtitle: 'Từ ngày 1 đến hết tháng hiện tại',
        icon: Icons.calendar_today_rounded,
        iconColor: const Color(0xFF00875A),
        iconBgLight: const Color(0xFFE6F7F0),
        iconBgDark: const Color(0xFF13382C),
      ),
      (
        period: ReportQuickPeriod.lastMonth,
        title: 'Tháng trước',
        subtitle: 'Số liệu tháng liền kề trước đó',
        icon: Icons.history_rounded,
        iconColor: const Color(0xFF0284C7),
        iconBgLight: const Color(0xFFE0F2FE),
        iconBgDark: const Color(0xFF0C2D48),
      ),
      (
        period: ReportQuickPeriod.thisQuarter,
        title: 'Quý này',
        subtitle: 'Thống kê trọn 3 tháng của quý hiện tại',
        icon: Icons.pie_chart_rounded,
        iconColor: const Color(0xFFD97706),
        iconBgLight: const Color(0xFFFEF3C7),
        iconBgDark: const Color(0xFF382305),
      ),
      (
        period: ReportQuickPeriod.sixMonths,
        title: '6 tháng gần nhất',
        subtitle: 'Nửa năm để nhìn rõ xu hướng dòng tiền dài hạn',
        icon: Icons.auto_awesome_rounded,
        iconColor: const Color(0xFFE11D48),
        iconBgLight: const Color(0xFFFFECEF),
        iconBgDark: const Color(0xFF3B1019),
      ),
      (
        period: ReportQuickPeriod.thisYear,
        title: 'Năm nay',
        subtitle: 'Toàn bộ 12 tháng năm ',
        icon: Icons.calendar_month_rounded,
        iconColor: const Color(0xFF0F6E56),
        iconBgLight: const Color(0xFFE6F4EA),
        iconBgDark: const Color(0xFF083329),
      ),
      (
        period: ReportQuickPeriod.allTime,
        title: 'Toàn bộ thời gian',
        subtitle: 'Lịch sử từ ngày đầu tiên sử dụng app',
        icon: Icons.all_inclusive_rounded,
        iconColor: const Color(0xFF64748B),
        iconBgLight: const Color(0xFFF1F5F9),
        iconBgDark: const Color(0xFF1E293B),
      ),
      (
        period: ReportQuickPeriod.customRange,
        title: 'Tùy chọn khoảng ngày...',
        subtitle: 'Chọn ngày bắt đầu và kết thúc linh hoạt',
        icon: Icons.tune_rounded,
        iconColor: const Color(0xFF4F46E5),
        iconBgLight: const Color(0xFFEEF2FF),
        iconBgDark: const Color(0xFF1E1B4B),
      ),
    ];

    final selected = await showModalBottomSheet<ReportQuickPeriod>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.78,
          ),
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: (dark ? Colors.white : Colors.black)
                  .withValues(alpha: dark ? 0.12 : 0.08),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.40 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: dark
                            ? const Color(0xFF0F6E56).withValues(alpha: 0.35)
                            : const Color(0xFFE6F4EA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.calendar_today_rounded,
                        color: Color(0xFF0F6E56),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kỳ phân tích báo cáo',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: dark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Chọn khoảng thời gian để thống kê dữ liệu',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: dark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    for (final item in itemsWithMeta) ...[
                      Builder(builder: (ctx) {
                        final isSelected = _quickPeriod == item.period;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.pop(sheetContext, item.period);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (dark
                                        ? const Color(0xFF064E3B)
                                            .withValues(alpha: 0.35)
                                        : const Color(0xFFF0FDF4))
                                    : (dark
                                        ? Colors.white.withValues(alpha: 0.04)
                                        : const Color(0xFFF8FAFC)),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF0F6E56)
                                      : (dark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFE2E8F0)),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 20,
                                    color: isSelected
                                        ? const Color(0xFF0F6E56)
                                        : (dark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? const Color(0xFF0F6E56)
                                            : (dark
                                                ? Colors.white
                                                : const Color(0xFF0F172A)),
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF0F6E56),
                                      size: 22,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || selected == null) return;
    if (selected == ReportQuickPeriod.customRange) {
      _pickCustomRange();
    } else {
      setState(() => _quickPeriod = selected);
    }
  }

  Widget _buildMemberButton(bool dark, ThemeStudioController? studio) {
    final memberStr = _ownerFilter == OwnerFilter.husband
        ? 'husband'
        : (_ownerFilter == OwnerFilter.wife ? 'wife' : null);

    return FinoraUnifiedMemberPill(
      currentMember: memberStr,
      height: 40,
      onSelected: (val) {
        setState(() {
          if (val == 'husband') {
            _ownerFilter = OwnerFilter.husband;
          } else if (val == 'wife') {
            _ownerFilter = OwnerFilter.wife;
          } else {
            _ownerFilter = OwnerFilter.all;
          }
        });
      },
      isDark: dark,
    );
  }

  Widget _buildReportGlassCard({
    required Widget child,
    required bool dark,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.22 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: dark
              ? const Color(0xFF142033).withValues(alpha: 0.90)
              : Colors.white.withValues(alpha: 0.96),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (dark ? Colors.white : Colors.black)
                    .withValues(alpha: dark ? 0.09 : 0.05),
                width: 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Card 1 — Chi Tiết Dòng Tiền Ròng (Cashflow Waterfall & Breakdown Card)
  Widget _buildCashflowWaterfallCard({
    required bool dark,
    required int income,
    required int expense,
    required int netCashflow,
    required int lendingFlow,
    required int debtFlow,
    required double savingsRate,
    required int avgDailyExpense,
    required Color text,
    required Color sub,
  }) {
    final isPositive = netCashflow >= 0;
    final badgeColor =
        isPositive ? const Color(0xFF10B981) : const Color(0xFFE11D48);
    final maxBreakdown = [
      income,
      expense,
      lendingFlow,
      debtFlow,
      1,
    ].reduce((a, b) => a > b ? a : b);

    return _buildReportGlassCard(
      dark: dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Dòng tiền ròng (Thu - Chi) + Net Badge (+Thặng dư / -Thâm hụt)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dòng tiền',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: FinoraPrivacyMask(
                        child: Text(
                          '${isPositive ? '+' : '-'}${formatVND(netCashflow.abs())}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: dark ? 0.20 : 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: badgeColor.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Image.asset(
                        isPositive
                            ? 'assets/mascot/expression-04-excited.png'
                            : 'assets/mascot/sticker-01-encourage.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: dark ? 0.20 : 0.12),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: badgeColor.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      isPositive ? '+Thặng dư' : '-Thâm hụt',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Summary Pills: Tỷ lệ tích luỹ (%) & Trung bình chi/ngày
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: (dark ? Colors.white : Colors.black)
                        .withValues(alpha: dark ? 0.05 : 0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tỷ lệ tích luỹ',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: sub,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${savingsRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: savingsRate >= 0
                                ? const Color(0xFF10B981)
                                : const Color(0xFFE11D48),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: (dark ? Colors.white : Colors.black)
                        .withValues(alpha: dark ? 0.05 : 0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trung bình chi/ngày',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: sub,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: FinoraPrivacyMask(
                          child: Text(
                            formatVND(avgDailyExpense),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: text,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 4 Clear Horizontal Breakdown Rows with progress bars & right-pinned amounts
          _buildCashflowBreakdownRow(
            label: 'Tổng thu nhập',
            formattedAmount: '+${formatVND(income)}',
            color: const Color(0xFF10B981),
            progress: (income / maxBreakdown).clamp(0.0, 1.0),
            dark: dark,
            text: text,
          ),
          const SizedBox(height: 10),
          _buildCashflowBreakdownRow(
            label: 'Tổng chi tiêu',
            formattedAmount: '-${formatVND(expense)}',
            color: const Color(0xFFE11D48),
            progress: (expense / maxBreakdown).clamp(0.0, 1.0),
            dark: dark,
            text: text,
          ),
          const SizedBox(height: 10),
          _buildCashflowBreakdownRow(
            label: 'Cho vay / Thu nợ',
            formattedAmount: formatVND(lendingFlow),
            color: const Color(0xFFD97706),
            progress: (lendingFlow / maxBreakdown).clamp(0.0, 1.0),
            dark: dark,
            text: text,
          ),
          const SizedBox(height: 10),
          _buildCashflowBreakdownRow(
            label: 'Đi vay / Trả nợ',
            formattedAmount: formatVND(debtFlow),
            color: const Color(0xFF0284C7),
            progress: (debtFlow / maxBreakdown).clamp(0.0, 1.0),
            dark: dark,
            text: text,
          ),
        ],
      ),
    );
  }

  Widget _buildCashflowBreakdownRow({
    required String label,
    required String formattedAmount,
    required Color color,
    required double progress,
    required bool dark,
    required Color text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 118),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: FinoraPrivacyMask(
                  child: Text(
                    formattedAmount,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: (dark ? Colors.white : Colors.black)
                .withValues(alpha: dark ? 0.08 : 0.05),
            borderRadius: BorderRadius.circular(100),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: constraints.maxWidth * progress,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Card 2 — Biểu Đồ Xu Hướng Dòng Tiền 6 Tháng (`6-Month Cashflow Bar Chart`)
  Widget _buildSixMonthsTrendCard({
    required bool dark,
    required List<Map<String, dynamic>> monthlyStats,
    required Color text,
    required Color sub,
  }) {
    double maxVal = 1000000;
    for (final s in monthlyStats) {
      final inc = (s['income'] as int).toDouble();
      final exp = (s['expense'] as int).toDouble();
      if (inc > maxVal) maxVal = inc;
      if (exp > maxVal) maxVal = exp;
    }

    return _buildReportGlassCard(
      dark: dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Biến động',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Biến động Thu - Chi 6 tháng gần nhất',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: sub,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Thu',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: sub,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D48),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Chi',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: sub,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 172,
            child: BarChart(
              BarChartData(
                maxY: maxVal * 1.15,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => dark ? const Color(0xFF1E293B) : Colors.white,
                    tooltipRoundedRadius: 8,
                    tooltipPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final isIncome = rodIndex == 0;
                      final type = isIncome ? 'Thu' : 'Chi';
                      final val = rod.toY.toInt();
                      return BarTooltipItem(
                        '$type: ${formatVND(val)}',
                        TextStyle(
                          color: isIncome
                              ? const Color(0xFF10B981)
                              : const Color(0xFFE11D48),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
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
                      reservedSize: 26,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < monthlyStats.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              monthlyStats[idx]['label'] as String,
                              style: TextStyle(
                                fontSize: 10.5,
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
                      barsSpace: 5,
                      barRods: [
                        BarChartRodData(
                          toY: (monthlyStats[i]['income'] as int).toDouble(),
                          gradient: const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0xFF00866A), Color(0xFF34D399)],
                          ),
                          width: 10,
                          borderRadius: BorderRadius.circular(6),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxVal * 1.05,
                            color: (dark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.04),
                          ),
                        ),
                        BarChartRodData(
                          toY: (monthlyStats[i]['expense'] as int).toDouble(),
                          gradient: const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0xFFBE123C), Color(0xFFFB7185)],
                          ),
                          width: 10,
                          borderRadius: BorderRadius.circular(6),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxVal * 1.05,
                            color: (dark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.04),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Monthly net cashflow summary row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (int i = 0; i < monthlyStats.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Builder(builder: (context) {
                    final net = monthlyStats[i]['net'] as int;
                    final mLabel = monthlyStats[i]['monthShort'] as String;
                    final isPos = net >= 0;
                    final netColor = isPos
                        ? const Color(0xFF10B981)
                        : const Color(0xFFE11D48);
                    final compactNet = net.abs() >= 1000000
                        ? '${(net.abs() / 1000000).toStringAsFixed(1)}Tr'
                        : '${(net.abs() / 1000).round()}k';
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: netColor.withValues(alpha: dark ? 0.16 : 0.08),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '$mLabel: ${isPos ? '+' : '-'}$compactNet',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: netColor,
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card 3 — Cơ Cấu Danh Mục Chi Tiết (Toggleable between Chi tiêu & Thu nhập)
  Widget _buildCategoryStructureCard({
    required bool dark,
    required List<_CategoryStatItem> categories,
    required List<TransactionModel> transactions,
    required int totalAmount,
    required List<Color> colors,
    required Color text,
    required Color sub,
  }) {
    final chartCategories = categories.take(6).toList();

    return _buildReportGlassCard(
      dark: dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with title & 2-pill toggle (Chi tiêu vs Thu nhập)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _showIncomeCategories ? 'Cơ cấu thu nhập' : 'Cơ cấu chi tiêu',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cơ cấu danh mục chi tiêu',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: sub,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 2-pill stadium toggle: Chi tiêu vs Thu nhập
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  color: (dark ? Colors.white : Colors.black)
                      .withValues(alpha: dark ? 0.08 : 0.05),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_showIncomeCategories) {
                          HapticFeedback.selectionClick();
                          setState(() => _showIncomeCategories = false);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: !_showIncomeCategories
                              ? const Color(0xFFE11D48)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'Chi tiêu',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: !_showIncomeCategories ? Colors.white : sub,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (!_showIncomeCategories) {
                          HapticFeedback.selectionClick();
                          setState(() => _showIncomeCategories = true);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _showIncomeCategories
                              ? const Color(0xFF10B981)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'Thu nhập',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _showIncomeCategories ? Colors.white : sub,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (categories.isEmpty || totalAmount == 0)
            Container(
              height: 110,
              alignment: Alignment.center,
              child: Text(
                _showIncomeCategories
                    ? 'Không có dữ liệu thu nhập trong kỳ này'
                    : 'Không có dữ liệu chi tiêu trong kỳ này',
                style: TextStyle(color: sub, fontSize: 13),
              ),
            )
          else ...[
            // Donut Chart with Center Total
            Center(
              child: SizedBox(
                width: 136,
                height: 136,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2.5,
                        centerSpaceRadius: 42,
                        startDegreeOffset: -90,
                        sections: [
                          for (int i = 0; i < chartCategories.length; i++)
                            PieChartSectionData(
                              color: colors[i % colors.length],
                              value: chartCategories[i].amount.toDouble(),
                              title: '',
                              radius: 18,
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _showIncomeCategories ? 'Tổng thu' : 'Tổng chi',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: sub,
                            ),
                          ),
                          const SizedBox(height: 1),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              totalAmount >= 1000000
                                  ? '${(totalAmount / 1000000).toStringAsFixed(1)}Tr'
                                  : '${(totalAmount / 1000).round()}k',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: text,
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
            const SizedBox(height: 14),

            // Full list of categories below with visual percentage progress bars & cards
            for (int i = 0; i < categories.length; i++) ...[
              Builder(builder: (ctx) {
                final cat = categories[i];
                final catColor = colors[i % colors.length];
                final pct = totalAmount > 0
                    ? (cat.amount / totalAmount).clamp(0.0, 1.0)
                    : 0.0;
                final pctStr = (pct * 100).toStringAsFixed(1);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () =>
                        _showCategoryTransactions(cat.name, transactions),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: (dark ? Colors.white : Colors.black)
                            .withValues(alpha: dark ? 0.04 : 0.025),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (dark ? Colors.white : Colors.black)
                              .withValues(alpha: dark ? 0.06 : 0.04),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: catColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  cat.name,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: text,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: catColor.withValues(
                                      alpha: dark ? 0.18 : 0.10),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$pctStr%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: catColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              FinoraPrivacyMask(
                                child: Text(
                                  formatVND(cat.amount),
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: text,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 4,
                              backgroundColor: (dark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.06),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(catColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        ],
      ),
    );
  }

  void _showCategoryTransactions(
      String name, List<TransactionModel> transactions) {
    final items = transactions
        .where((tx) =>
            (tx.categoryName?.trim().isNotEmpty == true
                ? tx.categoryName!.trim()
                : 'Khác') ==
            name)
        .toList();
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
            top: false,
            child: SizedBox(
              height: MediaQuery.sizeOf(sheetContext).height * 0.75,
              child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text(
                        'Các giao dịch thuộc kỳ và thành viên đang chọn.',
                        style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 16),
                    for (final tx in items)
                      TransactionRow(
                          transaction: tx,
                          onTap: () => showTransactionDetailSheet(sheetContext,
                              userId: widget.userId, transaction: tx)),
                  ]),
            )));
  }

  /// Card 4 — Phân Tích Dòng Tiền Vợ & Chồng
  Widget _buildCoupleRatioCard({
    required bool dark,
    required int husbandIncome,
    required int wifeIncome,
    required int husbandExpense,
    required int wifeExpense,
    required int otherMemberExpense,
    required int husbandPercent,
    required int wifePercent,
    required Color text,
    required Color sub,
  }) {
    return _buildReportGlassCard(
      dark: dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tỷ trọng chi tiêu Vợ & Chồng',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Phân tích Thu nhập & Chi tiêu theo thành viên',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: sub,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.pie_chart_outline_rounded,
                size: 19,
                color: dark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (husbandExpense + wifeExpense > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: SizedBox(
                height: 9,
                child: Row(
                  children: [
                    Expanded(
                      flex: husbandPercent > 0 ? husbandPercent : 1,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      flex: wifePercent > 0 ? wifePercent : 1,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFF472B6), Color(0xFFDB2777)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              // Chồng Pod (Blue #0284C7)
              Expanded(
                child: _buildMemberComparisonPod(
                  title: 'Chồng',
                  accentColor: const Color(0xFF0284C7),
                  percent: husbandPercent,
                  income: husbandIncome,
                  expense: husbandExpense,
                  dark: dark,
                  text: text,
                  sub: sub,
                ),
              ),
              const SizedBox(width: 10),
              // Vợ Pod (Pink #DB2777)
              Expanded(
                child: _buildMemberComparisonPod(
                  title: 'Vợ',
                  accentColor: const Color(0xFFDB2777),
                  percent: wifePercent,
                  income: wifeIncome,
                  expense: wifeExpense,
                  dark: dark,
                  text: text,
                  sub: sub,
                ),
              ),
            ],
          ),
          if (otherMemberExpense > 0) ...[
            const SizedBox(height: 10),
            Text(
              'Chung / chưa phân loại: ${formatVND(otherMemberExpense)}',
              style: TextStyle(fontSize: 11.5, color: sub),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberComparisonPod({
    required String title,
    required Color accentColor,
    required int percent,
    required int income,
    required int expense,
    required bool dark,
    required Color text,
    required Color sub,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: dark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentColor.withValues(alpha: dark ? 0.25 : 0.15),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: dark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Chi tiêu',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: sub,
            ),
          ),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: FinoraPrivacyMask(
              child: Text(
                '-${formatVND(expense)}',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: text,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Thu nhập',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: sub,
            ),
          ),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: FinoraPrivacyMask(
              child: Text(
                '+${formatVND(income)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
