import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
const _expenseTypes = {
  'expense',
  'lending',
  'loan_repayment_sent',
  'investment'
};

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
        title: 'Báo cáo tài chính',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: allTransactions.isEmpty
            ? Center(
                child: EmptyState(
                  icon: Icons.assessment_outlined,
                  title: 'Chưa có dữ liệu báo cáo',
                  subtitle:
                      'Thêm giao dịch để hệ thống phân tích dòng tiền và biểu đồ.',
                ),
              )
            : _buildContent(allTransactions),
      ),
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

    final byCategory = <String, int>{};
    for (final t in filtered.where((t) => _expenseTypes.contains(t.type))) {
      final name =
          (t.categoryName?.isNotEmpty == true) ? t.categoryName! : 'Khác';
      byCategory[name] = (byCategory[name] ?? 0) + t.amount;
    }
    final categoryExpenses = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final provider = context.watch<DashboardProvider>();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.pageTop,
        AppSpacing.pageHorizontal,
        AppSpacing.md,
      ),
      children: [
        SubjectFilterPill(
          selected: provider.selectedOwner,
          onSelected: (filter) => provider.setOwnerFilter(filter),
          compact: true,
        ),
        const SizedBox(height: 10),

        // Period filter chips
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _periods.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final p = _periods[i];
              return FilterChipX(
                label: p,
                selected: _selectedPeriod == p,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedPeriod = p);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Net income block
        _NetIncomeCard(
          income: totalIncome,
          expenses: totalExpenses,
        ),
        const SizedBox(height: 12),

        // Expense breakdown donut
        _ExpenseBreakdownCard(
          categoryExpenses: categoryExpenses,
          totalExpenses: totalExpenses,
          transactions: filtered,
        ),
        const SizedBox(height: 12),

        // Couple Expense Comparison (Vợ vs Chồng)
        _CoupleComparisonCard(
          transactions: filtered,
          totalExpenses: totalExpenses,
        ),
        const SizedBox(height: 12),

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
    final c = context.fc;
    final net = income - expenses;

    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Overline('TÍCH LŨY RÒNG TRONG KỲ'),
          const SizedBox(height: 4),
          Text(
            formatVND(net),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: net >= 0 ? AppColors.success : AppColors.error,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng thu nhập',
                    style: TextStyle(
                      fontSize: 11,
                      color: c.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatVND(income),
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Tổng chi tiêu',
                    style: TextStyle(
                      fontSize: 11,
                      color: c.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatVND(expenses),
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Color _parseCategoryColor(String? hex) {
  if (hex == null || hex.isEmpty) return AppColors.primary;
  var s = hex.trim().replaceFirst('#', '');
  if (s.length == 6) s = 'FF$s';
  if (s.length != 8) return AppColors.primary;
  final value = int.tryParse(s, radix: 16);
  if (value == null) return AppColors.primary;
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
    final c = context.fc;

    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cơ cấu danh mục chi tiêu',
            style: TextStyle(
              color: c.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          if (totalExpenses == 0)
            SizedBox(
              height: 140,
              child: Center(
                child: Text(
                  'Không có dữ liệu chi tiêu trong kỳ này',
                  style: TextStyle(color: c.textSecondary),
                ),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 32,
                      startDegreeOffset: -90,
                      sections: [
                        for (final e in categoryExpenses)
                          PieChartSectionData(
                            value: e.value.toDouble(),
                            color: _colorFor(e.key),
                            radius: 20,
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
                            percent: (e.value / totalExpenses * 100).round(),
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
    final c = context.fc;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$percent%',
          style: TextStyle(
            color: c.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 12.5,
          ),
        ),
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
    final c = context.fc;
    final bars = _lastMonths();
    final maxValRaw = bars.fold<int>(
        0, (m, b) => [m, b.income, b.expense].reduce((a, x) => a > x ? a : x));
    final maxY = (maxValRaw == 0 ? 1000000 : maxValRaw).toDouble();

    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Biến động Thu - Chi 6 tháng gần nhất',
            style: TextStyle(
              color: c.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
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
                          child: Text(
                            bars[i].label,
                            style: TextStyle(
                              color: c.textTertiary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.5,
                            ),
                          ),
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
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: bars[i].expense.toDouble(),
                          color: AppColors.error,
                          width: 10,
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

class _CoupleComparisonCard extends StatelessWidget {
  final List<TransactionModel> transactions;
  final int totalExpenses;

  const _CoupleComparisonCard({
    required this.transactions,
    required this.totalExpenses,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;

    int husbandExpense = 0;
    int wifeExpense = 0;

    for (final t in transactions.where((t) => _expenseTypes.contains(t.type))) {
      final owner = t.owner?.toLowerCase() ?? '';
      final ownerName = t.ownerName?.toLowerCase() ?? '';

      if (owner == 'wife' || ownerName.contains('vợ')) {
        wifeExpense += t.amount;
      } else {
        husbandExpense += t.amount;
      }
    }

    final total = husbandExpense + wifeExpense;
    final husbandPct = total > 0 ? (husbandExpense / total * 100).round() : 0;
    final wifePct = total > 0 ? (100 - husbandPct) : 0;

    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tỷ trọng chi tiêu Vợ & Chồng',
                style: TextStyle(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const Icon(Icons.people_alt_outlined,
                  size: 18, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 14),

          // Multi-color horizontal progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (husbandPct > 0)
                    Expanded(
                      flex: husbandPct,
                      child: Container(color: AppColors.husband),
                    ),
                  if (wifePct > 0)
                    Expanded(
                      flex: wifePct,
                      child: Container(color: AppColors.wife),
                    ),
                  if (total == 0)
                    Expanded(
                      child:
                          Container(color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Detail rows
          _buildPersonRow(
            context,
            color: AppColors.husband,
            label: '👨 Chồng',
            amount: husbandExpense,
            percent: husbandPct,
          ),
          const SizedBox(height: 8),
          _buildPersonRow(
            context,
            color: AppColors.wife,
            label: '👩 Vợ',
            amount: wifeExpense,
            percent: wifePct,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonRow(
    BuildContext context, {
    required Color color,
    required String label,
    required int amount,
    required int percent,
  }) {
    final c = context.fc;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13.5,
              color: c.textPrimary),
        ),
        const Spacer(),
        Text(
          formatVND(amount),
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13.5,
              color: c.textPrimary),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$percent%',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 11, color: color),
          ),
        ),
      ],
    );
  }
}
