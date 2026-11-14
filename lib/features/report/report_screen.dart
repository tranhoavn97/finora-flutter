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
      currentCustomYear: _customDate?.year,
      currentCustomMonth: _customDate?.month,
      showAllTime: true,
    );
    if (res == null || !mounted) return;
    setState(() {
      _dateOption = res.option;
      if (res.option == DateFilterOption.customMonth &&
          res.customYear != null &&
          res.customMonth != null) {
        _customDate = DateTime(res.customYear!, res.customMonth!, 1);
        _customRange = null;
      } else {
        _customDate = res.customDate;
        _customRange = res.customRange;
      }
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
    final sidePad = studio?.pageHorizontalMargin ?? 12.0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
          sidePad,
          widget.isTab ? GlassScaffold.topInset(context, 4, 44) : 8,
          sidePad,
          120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bộ lọc 35/65: Thành viên (Tất cả / Chồng / Vợ) & Thời gian đặt ngay đầu trang Báo cáo
          _buildFilterBar(dark, studio),
          const SizedBox(height: 10),

          // Card 1 — Chi Tiết Dòng Tiền Ròng (Executive Cashflow Summary Card)
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
          const SizedBox(height: 10),

          // Card 2 — Cơ Cấu Danh Mục Chi Tiết (Toggleable between Chi tiêu & Thu nhập)
          FinoraStaggeredItem(
            index: 1,
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
          const SizedBox(height: 10),

          // Card 3 — Phân Tích Dòng Tiền Vợ & Chồng
          FinoraStaggeredItem(
            index: 2,
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
          const SizedBox(height: 10),

          // Card 4 — Biểu Đồ Xu Hướng Dòng Tiền 6 Tháng (6-Month Cashflow Bar Chart)
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
    );
  }

  /// Bộ lọc 35/65: Thành viên (35%) & Thời gian (65%)
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
        Expanded(
          flex: 35,
          child: _buildMemberButton(dark, studio),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 65,
          child: Builder(
            builder: (context) {
              final studio =
                  Provider.of<ThemeStudioController?>(context, listen: true);
              final primary =
                  studio?.resolvedPrimary ?? const Color(0xFF059669);
              final secondary =
                  Color.lerp(primary, Colors.black, 0.18) ?? const Color(0xFF047857);
              final op = (studio?.glassOpacity ?? 0.92).clamp(0.18, 1.0);
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: _openUnifiedDateFilterModal,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primary.withValues(alpha: op),
                          secondary.withValues(alpha: op),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(
                              alpha: (dark ? 0.32 : 0.22) * op),
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
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              currentLabel,
                              maxLines: 1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
      expand: true,
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
            ? const Color(0xFF131A22).withValues(alpha: 0.96)
            : Colors.white.withValues(alpha: 0.98));

    return Container(
      decoration: BoxDecoration(
        color: cardFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: dark ? const Color(0xFF263344) : const Color(0xFFE2E8F0),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.28 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
  }

  /// Card 1 — Chi Tiết Dòng Tiền Ròng (Redesigned Executive Bento Cashflow Card)
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
    final statusColor =
        isPositive ? const Color(0xFF10B981) : const Color(0xFFE11D48);
    final debtLoanTotal = lendingFlow + debtFlow;

    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final op = studio?.glassOpacity ?? 0.90;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [
                  const Color(0xFF162231).withValues(alpha: op),
                  const Color(0xFF111924).withValues(alpha: op),
                ]
              : [
                  Colors.white.withValues(alpha: op),
                  (isPositive
                          ? const Color(0xFFF4FBF8)
                          : const Color(0xFFFFF8F9))
                      .withValues(alpha: op),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: statusColor.withValues(alpha: dark ? 0.32 : 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: dark ? 0.14 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Executive Header: Icon Badge + DÒNG TIỀN RÒNG + Status Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isPositive
                        ? [const Color(0xFF10B981), const Color(0xFF059669)]
                        : [const Color(0xFFF43F5E), const Color(0xFFE11D48)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  isPositive
                      ? Icons.account_balance_wallet_rounded
                      : Icons.warning_amber_rounded,
                  size: 19,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DÒNG TIỀN RÒNG',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                        color: sub,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: FinoraPrivacyMask(
                        child: Text(
                          '${isPositive ? "+" : "−"}${formatVND(netCashflow.abs())}',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                            color: isPositive
                                ? (dark
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFF047857))
                                : (dark
                                    ? const Color(0xFFFB7185)
                                    : const Color(0xFFBE123C)),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: dark ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.32),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 13.5,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPositive ? 'Thặng dư' : 'Thâm hụt',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2. Unified Dual-Flow Ledger Box (Thu vào vs Chi ra + Integrated Bar)
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: dark
                  ? const Color(0xFF0E1621).withValues(alpha: 0.78)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: 0.07)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IntrinsicHeight(
                  child: Row(
                    children: [
                      // Tổng thu vào
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.south_west_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Tổng thu vào',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: sub,
                                    ),
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
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        color: dark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE2E8F0),
                      ),
                      // Tổng chi ra
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF43F5E),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.north_east_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Tổng chi ra',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: sub,
                                    ),
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
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Thu ${(incomeRatio * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    Text(
                      'Tỷ trọng thu chi',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: sub,
                      ),
                    ),
                    Text(
                      'Chi ${(expenseRatio * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF43F5E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 7,
                    child: Row(
                      children: [
                        Expanded(
                          flex: (incomeRatio * 1000).toInt().clamp(1, 999),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF34D399)],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2.5),
                        Expanded(
                          flex: (expenseRatio * 1000).toInt().clamp(1, 999),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFFB7185), Color(0xFFE11D48)],
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
          ),

          const SizedBox(height: 10),

          // 3. 3-Column Sub-Metrics Strip: Tỷ lệ tích luỹ | Chi TB/ngày | Vay & Cho vay
          Row(
            children: [
              Expanded(
                child: _buildCashflowMiniMetric(
                  dark: dark,
                  icon: Icons.savings_outlined,
                  iconColor: savingsRate >= 0
                      ? const Color(0xFF10B981)
                      : const Color(0xFFE11D48),
                  label: 'Tỷ lệ tích luỹ',
                  valueWidget: Text(
                    '${savingsRate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: savingsRate >= 0
                          ? const Color(0xFF10B981)
                          : const Color(0xFFE11D48),
                    ),
                  ),
                  sub: sub,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCashflowMiniMetric(
                  dark: dark,
                  icon: Icons.today_rounded,
                  iconColor: const Color(0xFF0284C7),
                  label: 'Chi tiêu TB/ngày',
                  valueWidget: FinoraPrivacyMask(
                    child: Text(
                      formatVND(avgDailyExpense),
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: text,
                      ),
                    ),
                  ),
                  sub: sub,
                ),
              ),
              if (debtLoanTotal > 0) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCashflowMiniMetric(
                    dark: dark,
                    icon: Icons.swap_horiz_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    label: 'Vay & Cho vay',
                    valueWidget: FinoraPrivacyMask(
                      child: Text(
                        formatVND(debtLoanTotal),
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: text,
                        ),
                      ),
                    ),
                    sub: sub,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashflowMiniMetric({
    required bool dark,
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget valueWidget,
    required Color sub,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: (dark ? Colors.white : Colors.black)
            .withValues(alpha: dark ? 0.045 : 0.025),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (dark ? Colors.white : Colors.black)
              .withValues(alpha: dark ? 0.06 : 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12.5, color: iconColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: sub,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: valueWidget,
          ),
        ],
      ),
    );
  }

  /// Card 2 — Biểu Đồ Xu Hướng Dòng Tiền 6 Tháng (`6-Month Cashflow Trend Card`)
  Widget _buildSixMonthsTrendCard({
    required bool dark,
    required List<Map<String, dynamic>> monthlyStats,
    required Color text,
    required Color sub,
  }) {
    double maxVal = 1000000;
    int total6mIncome = 0;
    int total6mExpense = 0;
    for (final s in monthlyStats) {
      final inc = (s['income'] as int);
      final exp = (s['expense'] as int);
      total6mIncome += inc;
      total6mExpense += exp;
      if (inc.toDouble() > maxVal) maxVal = inc.toDouble();
      if (exp.toDouble() > maxVal) maxVal = exp.toDouble();
    }
    final avg6mIncome =
        monthlyStats.isNotEmpty ? (total6mIncome / monthlyStats.length).round() : 0;
    final avg6mExpense =
        monthlyStats.isNotEmpty ? (total6mExpense / monthlyStats.length).round() : 0;

    return _buildReportGlassCard(
      dark: dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with circular icon badge + legend
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0284C7)
                      .withValues(alpha: dark ? 0.20 : 0.10),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  size: 18,
                  color: Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 10),
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
                    const SizedBox(height: 1),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (dark ? Colors.white : Colors.black)
                      .withValues(alpha: dark ? 0.06 : 0.04),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
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
                      decoration: const BoxDecoration(
                        color: Color(0xFFE11D48),
                        shape: BoxShape.circle,
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
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 6-Month Average KPI Summary Strip
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981)
                        .withValues(alpha: dark ? 0.12 : 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.south_west_rounded,
                        size: 13,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'TB Thu:',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: sub,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: FinoraPrivacyMask(
                            child: Text(
                              formatVND(avg6mIncome),
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF10B981),
                              ),
                            ),
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
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D48)
                        .withValues(alpha: dark ? 0.12 : 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.north_east_rounded,
                        size: 13,
                        color: Color(0xFFE11D48),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'TB Chi:',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: sub,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: FinoraPrivacyMask(
                            child: Text(
                              formatVND(avg6mExpense),
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFE11D48),
                              ),
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
          SizedBox(
            height: 176,
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
                    barWidth: 3.0,
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
                    barWidth: 3.0,
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
          // Monthly net cashflow summary strip
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
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: netColor.withValues(alpha: dark ? 0.14 : 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: netColor.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Text(
                        '$mLabel: ${isPos ? '+' : '-'}$compactNet',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
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
    final topHighlights = categories.take(3).toList();
    final accentColor = _showIncomeCategories
        ? const Color(0xFF10B981)
        : const Color(0xFFE11D48);

    return _buildReportGlassCard(
      dark: dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with circular icon badge, title & 2-pill toggle (Chi tiêu vs Thu nhập)
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: dark ? 0.20 : 0.10),
                ),
                child: Icon(
                  Icons.donut_large_rounded,
                  size: 18,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _showIncomeCategories
                          ? 'Cơ cấu thu nhập'
                          : 'Cơ cấu chi tiêu',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
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
              decoration: BoxDecoration(
                color: (dark ? Colors.white : Colors.black)
                    .withValues(alpha: dark ? 0.03 : 0.02),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _showIncomeCategories
                    ? 'Không có dữ liệu thu nhập trong kỳ này'
                    : 'Không có dữ liệu chi tiêu trong kỳ này',
                style: TextStyle(color: sub, fontSize: 13),
              ),
            )
          else ...[
            // Side-by-side Donut Chart + Top 3 Highlights Pod
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (dark ? Colors.white : Colors.black)
                    .withValues(alpha: dark ? 0.035 : 0.02),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: (dark ? Colors.white : Colors.black)
                      .withValues(alpha: dark ? 0.06 : 0.04),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 126,
                    height: 126,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 2.2,
                            centerSpaceRadius: 39,
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
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _showIncomeCategories ? 'Tổng thu' : 'Tổng chi',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: sub,
                                ),
                              ),
                              const SizedBox(height: 1),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: FinoraPrivacyMask(
                                  child: Text(
                                    totalAmount >= 1000000
                                        ? '${(totalAmount / 1000000).toStringAsFixed(1)}Tr'
                                        : '${(totalAmount / 1000).round()}k',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w900,
                                      color: text,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              'NHÓM DẪN ĐẦU',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.7,
                                color: sub,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: sub.withValues(alpha: dark ? 0.16 : 0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${categories.length}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: sub,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        for (int i = 0; i < topHighlights.length; i++) ...[
                          if (i > 0) const SizedBox(height: 6),
                          Builder(builder: (context) {
                            final item = topHighlights[i];
                            final c = colors[i % colors.length];
                            final pct = totalAmount > 0
                                ? ((item.amount / totalAmount) * 100)
                                    .toStringAsFixed(0)
                                : '0';
                            return Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: text,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$pct%',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: c,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Full list of categories below with rank badges, transaction count & progress bars
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
                                width: 22,
                                height: 22,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: catColor.withValues(
                                      alpha: dark ? 0.22 : 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                    color: catColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
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
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: sub.withValues(
                                            alpha: dark ? 0.16 : 0.09),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '${cat.count}',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: sub,
                                        ),
                                      ),
                                    ),
                                  ],
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
                              const SizedBox(width: 8),
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
                              minHeight: 4.5,
                              backgroundColor:
                                  (dark ? Colors.white : Colors.black)
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
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => GlassBottomSheet(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                height: MediaQuery.sizeOf(sheetContext).height * 0.72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FinoraSheetDragHandle(),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${items.length} giao dịch',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Các giao dịch thuộc kỳ và thành viên đang chọn.',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (ctx, idx) {
                          final tx = items[idx];
                          return TransactionRow(
                            transaction: tx,
                            onTap: () => showTransactionDetailSheet(
                              sheetContext,
                              userId: widget.userId,
                              transaction: tx,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ));
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
    final studio = Provider.of<ThemeStudioController?>(context);
    final husbandTitle = studio?.husbandDisplayLabel ?? 'Chồng';
    final wifeTitle = studio?.wifeDisplayLabel ?? 'Vợ';

    return _buildReportGlassCard(
      dark: dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFDB2777)
                      .withValues(alpha: dark ? 0.20 : 0.10),
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  size: 18,
                  color: Color(0xFFDB2777),
                ),
              ),
              const SizedBox(width: 10),
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
                    const SizedBox(height: 1),
                    Text(
                      'Phân tích Thu nhập & Chi tiêu theo thành viên',
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
            ],
          ),
          const SizedBox(height: 14),
          if (husbandExpense + wifeExpense > 0) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color:
                    (dark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: (dark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.06),
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
                            color:
                                const Color(0xFF0284C7).withValues(alpha: 0.28),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
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
                            color:
                                const Color(0xFFDB2777).withValues(alpha: 0.28),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
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
                  memberKey: 'husband',
                  title: husbandTitle,
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
                  memberKey: 'wife',
                  title: wifeTitle,
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
    required String memberKey,
    required String title,
    required Color accentColor,
    required int percent,
    required int income,
    required int expense,
    required bool dark,
    required Color text,
    required Color sub,
  }) {
    final net = income - expense;
    final isNetPos = net >= 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: dark ? 0.12 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: dark ? 0.26 : 0.16),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FinoraMemberAvatar(
                member: memberKey,
                size: 24,
                isDark: dark,
                showRing: true,
              ),
              const SizedBox(width: 6),
              Expanded(
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
          const SizedBox(height: 10),
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
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: (dark ? Colors.white : Colors.black)
                  .withValues(alpha: dark ? 0.06 : 0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ròng:',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: sub,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: FinoraPrivacyMask(
                      child: Text(
                        '${isNetPos ? "+" : "−"}${formatVND(net.abs())}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: isNetPos
                              ? const Color(0xFF10B981)
                              : const Color(0xFFE11D48),
                        ),
                      ),
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
}
