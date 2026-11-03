import 'dart:ui' as ui;
import '../../core/widgets/finora/financial_components.dart'
    show TransactionRow;
import '../transaction/transaction_detail_sheet.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/widgets/glass_widgets.dart';
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

class _ReportScreenState extends State<ReportScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  DateFilterOption _dateOption = DateFilterOption.thisMonth;
  DateTime? _customDate;
  DateTimeRange? _customRange;
  OwnerFilter _ownerFilter = OwnerFilter.all;
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

  bool _matchesDate(DateTime date) {
    if (_dateOption == DateFilterOption.customRange && _customRange != null) {
      final start = DateTime(_customRange!.start.year, _customRange!.start.month, _customRange!.start.day);
      final end = DateTime(_customRange!.end.year, _customRange!.end.month, _customRange!.end.day, 23, 59, 59, 999);
      return !date.isBefore(start) && !date.isAfter(end);
    }
    if (_dateOption == DateFilterOption.customDate && _customDate != null) {
      return date.year == _customDate!.year &&
          date.month == _customDate!.month &&
          date.day == _customDate!.day;
    }
    if (_dateOption == DateFilterOption.customMonth && _customDate != null) {
      return date.year == _customDate!.year && date.month == _customDate!.month;
    }
    return isDateInFilterOption(
      date.millisecondsSinceEpoch,
      _dateOption,
      customDate: _customDate,
      customStartDate: _customRange?.start,
      customEndDate: _customRange?.end,
    );
  }

  int _activePeriodDaysCount() {
    final now = DateTime.now();
    switch (_dateOption) {
      case DateFilterOption.today:
      case DateFilterOption.yesterday:
      case DateFilterOption.customDate:
        return 1;
      case DateFilterOption.thisWeek:
      case DateFilterOption.lastWeek:
        return 7;
      case DateFilterOption.thisMonth:
        return now.day.clamp(1, 31);
      case DateFilterOption.lastMonth:
      case DateFilterOption.customMonth:
        final m = _customDate?.month ?? (now.month == 1 ? 12 : now.month - 1);
        final y = _customDate?.year ?? (now.month == 1 ? now.year - 1 : now.year);
        return DateTime(y, m + 1, 0).day.clamp(1, 31);
      case DateFilterOption.thisYear:
        final yearStart = DateTime(now.year, 1, 1);
        return (now.difference(yearStart).inDays + 1).clamp(1, 366);
      case DateFilterOption.allTime:
        return 30;
      case DateFilterOption.customRange:
        if (_customRange == null) return 30;
        return (_customRange!.end.difference(_customRange!.start).inDays + 1)
            .clamp(1, 3650);
    }
  }

  Future<void> _openUnifiedDateFilterModal() async {
    HapticFeedback.selectionClick();
    final res = await showDateFilterModal(
      context,
      currentOption: _dateOption,
      currentCustomDate: _customDate,
      currentCustomRange: _customRange,
      showAllTime: true,
    );
    if (res == null || !mounted) return;
    setState(() {
      _dateOption = res.option;
      _customDate = res.customDate;
      _customRange = res.customRange;
    });
  }



  @override
  Widget build(BuildContext context) {
    super.build(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final sub = dark ? AppColors.darkTextSecondary : const Color(0xFF64748B);
    final provider = context.watch<TransactionProvider>();
    final all = provider.transactions;
    final walletMap = {for (final w in provider.wallets) w.id: w};

    // Filter transactions by selected member & period
    final txs = all.where((t) {
      final memberOk = _ownerFilter.matchTransaction(t, walletMap: walletMap);
      final dateOk = _matchesDate(_parseTxDate(t.date));
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
      padding: EdgeInsets.fromLTRB(
          16, widget.isTab ? GlassScaffold.topInset(context, 4, 44) : 8, 16, 120),
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
    String currentLabel;
    if (_dateOption == DateFilterOption.customRange && _customRange != null) {
      currentLabel =
          '${DateFormat("dd/MM").format(_customRange!.start)} - ${DateFormat("dd/MM/yyyy").format(_customRange!.end)}';
    } else if (_dateOption == DateFilterOption.customMonth && _customDate != null) {
      currentLabel = 'Tháng ${_customDate!.month}/${_customDate!.year}';
    } else if (_dateOption == DateFilterOption.customDate && _customDate != null) {
      currentLabel = DateFormat('dd/MM/yyyy').format(_customDate!);
    } else {
      currentLabel = _dateOption.label;
    }

    return Row(
      children: [
        _buildMemberButton(dark, studio),
        const SizedBox(width: 10),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: _openUnifiedDateFilterModal,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF047857)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669)
                          .withValues(alpha: dark ? 0.32 : 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        currentLabel,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
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
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final cardFill = studio?.getCardFillColor(dark) ??
        (dark
            ? const Color(0xFF142033).withValues(alpha: 0.88)
            : Colors.white.withValues(alpha: studio?.glassOpacity ?? 0.88));
    final blur = studio?.glassBlur ?? 0.0;

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
        child: blur > 0.5
            ? BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: blur.clamp(0.0, 25.0),
                  sigmaY: blur.clamp(0.0, 25.0),
                ),
                child: Material(
                  color: cardFill,
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
              )
            : Material(
                color: cardFill,
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

  /// Card 1 — Chi Tiết Dòng Tiền Ròng (Redesigned Cashflow Card)
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
    final totalFlow = income + expense;
    final double incomeRatio =
        totalFlow > 0 ? (income / totalFlow).clamp(0.0, 1.0) : 0.5;
    final double expenseRatio =
        totalFlow > 0 ? (expense / totalFlow).clamp(0.0, 1.0) : 0.5;

    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.35 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Header: DÒNG TIỀN RÒNG + Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPositive
                                ? const Color(0xFF10B981)
                                : const Color(0xFFE11D48),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'DÒNG TIỀN RÒNG',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: sub,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: FinoraPrivacyMask(
                        child: Text(
                          '${isPositive ? "+" : "−"}${formatVND(netCashflow.abs())}',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                            color: isPositive
                                ? (dark
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFF059669))
                                : (dark
                                    ? const Color(0xFFFB7185)
                                    : const Color(0xFFE11D48)),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isPositive
                      ? const Color(0xFF059669)
                          .withValues(alpha: dark ? 0.22 : 0.12)
                      : const Color(0xFFE11D48)
                          .withValues(alpha: dark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isPositive
                        ? const Color(0xFF059669).withValues(alpha: 0.35)
                        : const Color(0xFFE11D48).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 14,
                      color: isPositive
                          ? const Color(0xFF059669)
                          : const Color(0xFFE11D48),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPositive ? 'Thặng dư' : 'Thâm hụt',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isPositive
                            ? const Color(0xFF059669)
                            : const Color(0xFFE11D48),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 2. Dual Bento Metric Pods: Thu vào vs Chi ra (Bright, solid, high contrast)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xFF0D281E)
                        : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: dark
                          ? const Color(0xFF10B981)
                          : const Color(0xFF86EFAC),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Icon(Icons.arrow_downward_rounded,
                                size: 13, color: Colors.white),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tổng thu vào',
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: dark
                                  ? const Color(0xFF6EE7B7)
                                  : const Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: FinoraPrivacyMask(
                          child: Text(
                            '+${formatVND(income)}',
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: dark
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF047857),
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xFF2D1217)
                        : const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: dark
                          ? const Color(0xFFF43F5E)
                          : const Color(0xFFFDA4AF),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF43F5E),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Icon(Icons.arrow_upward_rounded,
                                size: 13, color: Colors.white),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tổng chi ra',
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: dark
                                  ? const Color(0xFFFDA4AF)
                                  : const Color(0xFFBE123C),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: FinoraPrivacyMask(
                          child: Text(
                            '−${formatVND(expense)}',
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: dark
                                  ? const Color(0xFFFB7185)
                                  : const Color(0xFFBE123C),
                              fontFeatures: const [FontFeature.tabularFigures()],
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

          // 3. Proportion Comparison Track (Thu vs Chi)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Thu ${(incomeRatio * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  Text(
                    'Tỷ trọng thu chi',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: sub,
                    ),
                  ),
                  Text(
                    'Chi ${(expenseRatio * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF43F5E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: [
                      Expanded(
                        flex: (incomeRatio * 1000).toInt().clamp(1, 999),
                        child: Container(color: const Color(0xFF10B981)),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        flex: (expenseRatio * 1000).toInt().clamp(1, 999),
                        child: Container(color: const Color(0xFFF43F5E)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 4. Sub-Metrics: Tỷ lệ tích luỹ & TB chi/ngày
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
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: sub,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${savingsRate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: savingsRate >= 0
                              ? const Color(0xFF10B981)
                              : const Color(0xFFE11D48),
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
                        'Chi tiêu TB/ngày',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: sub,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FinoraPrivacyMask(
                        child: Text(
                          formatVND(avgDailyExpense),
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
            height: 180,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (monthlyStats.length - 1).toDouble().clamp(1.0, 10.0),
                minY: 0,
                maxY: maxVal * 1.18,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        dark ? const Color(0xFF1E293B) : Colors.white,
                    tooltipRoundedRadius: 10,
                    tooltipPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isIncome = spot.barIndex == 0;
                        return LineTooltipItem(
                          '${isIncome ? "Thu: " : "Chi: "}${formatVND(spot.y.toInt())}',
                          TextStyle(
                            color: isIncome
                                ? const Color(0xFF10B981)
                                : const Color(0xFFE11D48),
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                          ),
                        );
                      }).toList();
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
                      reservedSize: 28,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < monthlyStats.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
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
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxVal / 3).clamp(1.0, double.infinity),
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: (dark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Thu nhập (Đường cong xanh ngọc)
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < monthlyStats.length; i++)
                        FlSpot(i.toDouble(),
                            (monthlyStats[i]['income'] as int).toDouble()),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFF10B981),
                    barWidth: 3.2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 3.5,
                        color: const Color(0xFF10B981),
                        strokeWidth: 2,
                        strokeColor:
                            dark ? const Color(0xFF0F172A) : Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF10B981)
                              .withValues(alpha: dark ? 0.22 : 0.12),
                          const Color(0xFF10B981).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  // Chi tiêu (Đường cong đỏ hoa hồng)
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < monthlyStats.length; i++)
                        FlSpot(i.toDouble(),
                            (monthlyStats[i]['expense'] as int).toDouble()),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFFE11D48),
                    barWidth: 3.2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 3.5,
                        color: const Color(0xFFE11D48),
                        strokeWidth: 2,
                        strokeColor:
                            dark ? const Color(0xFF0F172A) : Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFE11D48)
                              .withValues(alpha: dark ? 0.22 : 0.12),
                          const Color(0xFFE11D48).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
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
                width: 154,
                height: 154,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 3.0,
                        centerSpaceRadius: 48,
                        startDegreeOffset: -90,
                        sections: [
                          for (int i = 0; i < chartCategories.length; i++)
                            PieChartSectionData(
                              color: colors[i % colors.length],
                              value: chartCategories[i].amount.toDouble(),
                              title: '',
                              radius: 20,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: husbandPercent > 0 ? husbandPercent : 1,
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
                        ),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.30),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Chồng $husbandPercent%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: wifePercent > 0 ? wifePercent : 1,
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF472B6), Color(0xFFDB2777)],
                        ),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFDB2777).withValues(alpha: 0.30),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Vợ $wifePercent%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
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
