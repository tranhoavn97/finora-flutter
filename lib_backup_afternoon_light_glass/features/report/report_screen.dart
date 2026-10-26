import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../../data/models/transaction.dart';
import '../../state/dashboard_provider.dart';

const _incomeTypes = {'income', 'borrowing', 'loan_repayment_received'};
const _expenseTypes = {'expense', 'lending', 'loan_repayment_sent'};

class ReportScreen extends StatefulWidget {
  final String userId;
  const ReportScreen({super.key, required this.userId});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  static const _periods = ['Tháng này', 'Tháng trước', 'Năm nay', 'Tất cả'];
  String _selectedPeriod = 'Tháng này';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load(widget.userId);
    });
  }

  bool _inPeriod(TransactionModel tx) {
    final now = DateTime.now();
    final d = DateTime.fromMillisecondsSinceEpoch(tx.date);
    switch (_selectedPeriod) {
      case 'Tháng này':
        return d.year == now.year && d.month == now.month;
      case 'Tháng trước':
        final prev = DateTime(now.year, now.month - 1, 1);
        return d.year == prev.year && d.month == prev.month;
      case 'Năm nay':
        return d.year == now.year;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final allTransactions = provider.data.allTransactions;

    return GlassScaffold(
      appBar: GlassTopBar(
        title: 'Báo cáo phân tích',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: allTransactions.isEmpty
          ? const Center(
              child: EmptyState(
                icon: Icons.assessment,
                title: 'Không có dữ liệu báo cáo',
                subtitle: 'Thêm giao dịch để hiển thị biểu đồ phân tích.',
              ),
            )
          : _buildContent(allTransactions),
    );
  }

  Widget _buildContent(List<TransactionModel> allTransactions) {
    final filtered = allTransactions.where(_inPeriod).toList();

    final totalIncome = filtered
        .where((t) => _incomeTypes.contains(t.type))
        .fold<int>(0, (s, t) => s + t.amount);
    final totalExpenses = filtered
        .where((t) => _expenseTypes.contains(t.type))
        .fold<int>(0, (s, t) => s + t.amount);

    // Expenses grouped by category, sorted descending.
    final byCategory = <String, int>{};
    for (final t in filtered.where((t) => _expenseTypes.contains(t.type))) {
      final name = (t.categoryName?.isNotEmpty == true)
          ? t.categoryName!
          : 'Khác';
      byCategory[name] = (byCategory[name] ?? 0) + t.amount;
    }
    final categoryExpenses = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 120),
      children: [
        // Period filter chips
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _periods.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
            itemBuilder: (_, i) {
              final p = _periods[i];
              return Center(
                child: FilterChipX(
                  label: p,
                  selected: _selectedPeriod == p,
                  onTap: () => setState(() => _selectedPeriod = p),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Net income block
        _NetIncomeCard(
          income: totalIncome,
          expenses: totalExpenses,
        ),
        const SizedBox(height: AppSpacing.sm),

        // Expense breakdown donut
        _ExpenseBreakdownCard(
          categoryExpenses: categoryExpenses,
          totalExpenses: totalExpenses,
          transactions: filtered,
        ),
        const SizedBox(height: AppSpacing.sm),

        // Income vs expense trend
        _TrendCard(transactions: allTransactions),
      ],
    );
  }
}

class _NetIncomeCard extends StatelessWidget {
  final int income;
  final int expenses;
  const _NetIncomeCard({required this.income, required this.expenses});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final net = income - expenses;
    return GlassCard(
      highlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tích lũy ròng trong kỳ',
              style: AppTypography.caption1.copyWith(color: secondaryTextColor)),
          const SizedBox(height: 4),
          Text(formatVND(net),
              style: AppTypography.largeTitle.copyWith(
                  color: net >= 0 ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tổng thu nhập',
                      style: AppTypography.caption2.copyWith(color: secondaryTextColor)),
                  Text(formatVND(income),
                      style: AppTypography.body.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Tổng chi tiêu',
                      style: AppTypography.caption2.copyWith(color: secondaryTextColor)),
                  Text(formatVND(expenses),
                      style: AppTypography.body.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Parses a hex category color string (#RRGGBB or #AARRGGBB), falling back to accent.
Color _parseCategoryColor(String? hex) {
  if (hex == null || hex.isEmpty) return AppColors.accent;
  var s = hex.trim().replaceFirst('#', '');
  if (s.length == 6) s = 'FF$s';
  if (s.length != 8) return AppColors.accent;
  final value = int.tryParse(s, radix: 16);
  if (value == null) return AppColors.accent;
  return Color(value);
}

class _ExpenseBreakdownCard extends StatelessWidget {
  final List<MapEntry<String, int>> categoryExpenses;
  final int totalExpenses;
  final List<TransactionModel> transactions;
  const _ExpenseBreakdownCard({
    required this.categoryExpenses,
    required this.totalExpenses,
    required this.transactions,
  });

  Color _colorFor(String categoryName) {
    String? hex;
    for (final t in transactions) {
      if (t.categoryName == categoryName) {
        hex = t.categoryColor;
        break;
      }
    }
    return _parseCategoryColor(hex);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cơ cấu chi tiêu',
              style: AppTypography.subhead.copyWith(color: primaryTextColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          if (totalExpenses == 0)
            SizedBox(
              height: 140,
              child: Center(
                child: Text('Không có dữ liệu chi tiêu',
                    style: AppTypography.caption2.copyWith(color: secondaryTextColor)),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 34,
                      startDegreeOffset: -90,
                      sections: [
                        for (final e in categoryExpenses)
                          PieChartSectionData(
                            value: e.value.toDouble(),
                            color: _colorFor(e.key),
                            radius: 22,
                            showTitle: false,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final e in categoryExpenses.take(5))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _LegendRow(
                            color: _colorFor(e.key),
                            name: e.key,
                            percent:
                                (e.value / totalExpenses * 100).round(),
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
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String name;
  final int percent;
  const _LegendRow(
      {required this.color, required this.name, required this.percent});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(name,
              style: AppTypography.caption1.copyWith(color: primaryTextColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 6),
        Text('$percent%',
            style: AppTypography.caption1.copyWith(
                color: secondaryTextColor, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _MonthBar {
  final String label;
  final int income;
  final int expense;
  const _MonthBar(this.label, this.income, this.expense);
}

class _TrendCard extends StatelessWidget {
  final List<TransactionModel> transactions;
  const _TrendCard({required this.transactions});

  List<_MonthBar> _lastMonths() {
    final now = DateTime.now();
    final bars = <_MonthBar>[];
    for (var i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      var inc = 0, exp = 0;
      for (final t in transactions) {
        final d = DateTime.fromMillisecondsSinceEpoch(t.date);
        if (d.year == m.year && d.month == m.month) {
          if (_incomeTypes.contains(t.type)) inc += t.amount;
          if (_expenseTypes.contains(t.type)) exp += t.amount;
        }
      }
      final label =
          '${m.month.toString().padLeft(2, '0')}/${(m.year % 100).toString().padLeft(2, '0')}';
      bars.add(_MonthBar(label, inc, exp));
    }
    return bars;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final bars = _lastMonths();
    final maxValRaw = bars.fold<int>(
        0, (m, b) => [m, b.income, b.expense].reduce((a, x) => a > x ? a : x));
    final maxY = (maxValRaw == 0 ? 1000000 : maxValRaw).toDouble();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Xu hướng Thu nhập - Chi tiêu',
              style: AppTypography.subhead.copyWith(color: primaryTextColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.15,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(enabled: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= bars.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(bars[i].label,
                              style: AppTypography.caption2.copyWith(
                                  color: secondaryTextColor,
                                  fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < bars.length; i++)
                    BarChartGroupData(
                      x: i,
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(
                          toY: bars[i].income.toDouble(),
                          color: AppColors.success,
                          width: 10,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        BarChartRodData(
                          toY: bars[i].expense.toDouble(),
                          color: AppColors.error,
                          width: 10,
                          borderRadius: BorderRadius.circular(2),
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
