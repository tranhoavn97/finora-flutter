import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/custom_date_picker_dialog.dart';
import '../../core/widgets/transaction_filter_sheet.dart';
import '../../core/widgets/subject_filter_pill.dart';
import '../../data/models/transaction.dart';
import '../../state/transaction_provider.dart';
import 'add_transaction_page.dart';
import 'transaction_detail_screen.dart';

class TransactionScreen extends StatefulWidget {
  final String userId;

  const TransactionScreen({super.key, required this.userId});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  FilterResult _filter = const FilterResult();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filter = FilterResult(
      timeRange: 'month',
      selectedMonth: now.month,
      selectedYear: now.year,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TransactionProvider>().load(widget.userId);
    });
  }

  void _openFilterSheet() async {
    final categories = context
        .read<TransactionProvider>()
        .transactions
        .map((t) => t.categoryName ?? '')
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final res = await TransactionFilterSheet.show(context,
        initialFilter: _filter, categories: categories);
    if (res != null) {
      setState(() {
        _filter = res;
      });
    }
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _setType(String type) => setState(() => _filter = FilterResult(
        owner: _filter.owner,
        type: type,
        query: _filter.query,
        category: _filter.category,
        timeRange: _filter.timeRange,
        selectedMonth: _filter.selectedMonth,
        selectedYear: _filter.selectedYear,
        customDate: _filter.customDate,
      ));

  void _setOwner(String owner) => setState(() => _filter = FilterResult(
        owner: owner,
        type: _filter.type,
        query: _filter.query,
        category: _filter.category,
        timeRange: _filter.timeRange,
        selectedMonth: _filter.selectedMonth,
        selectedYear: _filter.selectedYear,
        customDate: _filter.customDate,
      ));

  void _setMonth(DateTime month) => setState(() => _filter = FilterResult(
        owner: _filter.owner,
        type: _filter.type,
        query: _filter.query,
        category: _filter.category,
        timeRange: 'month',
        selectedMonth: month.month,
        selectedYear: month.year,
      ));

  DateTime get _visibleMonth => DateTime(
        _filter.selectedYear ?? DateTime.now().year,
        _filter.selectedMonth ?? DateTime.now().month,
      );

  Future<void> _pickMonth() async {
    final picked = await CustomDatePickerSheet.show(
      context,
      initialDate: _visibleMonth,
    );
    if (picked != null && mounted) {
      _setMonth(DateTime(picked.year, picked.month));
    }
  }

  DateTime _parseTxDate(int timestamp) {
    if (timestamp <= 0) return DateTime.now();
    if (timestamp > 100000000000) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<TransactionProvider>();
    final allTxs = provider.transactions;

    final filtered = allTxs.where((tx) {
      if (_filter.owner != 'all' && tx.owner != _filter.owner) return false;
      if (_filter.type == 'income' && tx.type != 'income') return false;
      if (_filter.type == 'expense' && tx.type != 'expense') return false;
      if (_filter.type == 'investment' && tx.type != 'investment') return false;
      if (_filter.category != 'all' && tx.categoryName != _filter.category)
        return false;
      if (_filter.query.isNotEmpty) {
        final q = _filter.query.toLowerCase();
        final matchDesc = tx.note?.toLowerCase().contains(q) == true;
        final matchCat = tx.categoryName?.toLowerCase().contains(q) == true;
        if (!matchDesc && !matchCat) return false;
      }
      final txDate = _parseTxDate(tx.date);
      if (_filter.customDate != null) {
        if (txDate.year != _filter.customDate!.year ||
            txDate.month != _filter.customDate!.month ||
            txDate.day != _filter.customDate!.day) {
          return false;
        }
      } else if (_filter.selectedMonth != null &&
          _filter.selectedYear != null) {
        if (txDate.month != _filter.selectedMonth ||
            txDate.year != _filter.selectedYear) {
          return false;
        }
      } else {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final dateOnly = DateTime(txDate.year, txDate.month, txDate.day);
        if (_filter.timeRange == 'today' && dateOnly != today) return false;
        if (_filter.timeRange == 'yesterday' &&
            dateOnly != today.subtract(const Duration(days: 1))) return false;
        if (_filter.timeRange == 'this_week') {
          final weekStart = today.subtract(Duration(days: today.weekday - 1));
          if (dateOnly.isBefore(weekStart) ||
              dateOnly.isAfter(today.add(const Duration(days: 1))))
            return false;
        }
        if (_filter.timeRange == 'this_month' &&
            (txDate.month != now.month || txDate.year != now.year))
          return false;
        if (_filter.timeRange == 'this_year' && txDate.year != now.year)
          return false;
      }
      return true;
    }).toList();

    final totalSpent = filtered.fold<int>(
        0, (sum, tx) => sum + (tx.type == 'expense' ? tx.amount : 0));
    final totalIncome = filtered.fold<int>(
        0, (sum, tx) => sum + (tx.type == 'income' ? tx.amount : 0));
    final cashFlow = totalIncome - totalSpent;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Giao dịch',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, size: 24),
            onPressed: _openFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 26),
            onPressed: () => _push(AddTransactionPage(userId: widget.userId)),
          ),
        ],
      ),
      body: GradientBackground(
          child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0B3357),
                      Color(0xFF155E75),
                      Color(0xFF2563A9)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TỔNG CHI TIÊU TRONG KỲ',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(Formatters.formatCurrency(totalSpent),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                            child: _summaryValue('Thu vào', totalIncome,
                                const Color(0xFF34D399))),
                        Container(width: 1, height: 34, color: Colors.white24),
                        Expanded(
                            child: _summaryValue('Chi ra', -totalSpent,
                                const Color(0xFFFF718B))),
                        Container(width: 1, height: 34, color: Colors.white24),
                        Expanded(
                            child: _summaryValue(
                                'Dòng tiền',
                                cashFlow,
                                cashFlow >= 0
                                    ? const Color(0xFF67E8F9)
                                    : const Color(0xFFFCA5A5))),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildMiniTrend(filtered),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(children: [
                SubjectFilterPill(
                  compact: true,
                  selected: OwnerFilter.fromString(_filter.owner),
                  onSelected: (value) => _setOwner(value.value),
                ),
                const SizedBox(height: 8),
                SegmentedControl(
                  options: const [
                    ('all', 'Tất cả'),
                    ('income', 'Thu'),
                    ('expense', 'Chi')
                  ],
                  selected: _filter.type,
                  onChanged: _setType,
                ),
                const SizedBox(height: 9),
                _buildMonthSelector(isDark),
              ]),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'Không có giao dịch nào khớp với bộ lọc',
                        style: TextStyle(
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF64748B),
                            fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final tx = filtered[index];
                        final isExpense = tx.type == 'expense';
                        final isIncome = tx.type == 'income';
                        final color = isExpense
                            ? const Color(0xFFEF4444)
                            : (isIncome
                                ? const Color(0xFF10B981)
                                : const Color(0xFF3B82F6));
                        final prefix = isExpense ? '-' : (isIncome ? '+' : '');
                        final txDate = _parseTxDate(tx.date);
                        final ownerColor = tx.owner == 'wife'
                            ? const Color(0xFFEC4899)
                            : tx.owner == 'husband'
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF0F766E);

                        return GestureDetector(
                          onTap: () => _push(TransactionDetailScreen(
                              userId: widget.userId, transaction: tx)),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : ownerColor.withValues(alpha: .055),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : ownerColor.withValues(alpha: .12)),
                            ),
                            child: Row(
                              children: [
                                IconBadge(
                                  emoji:
                                      CategoryIconHelper.resolveTransactionIcon(
                                          transactionType: tx.type,
                                          categoryIcon: tx.categoryIcon,
                                          categoryName: tx.categoryName,
                                          note: tx.note),
                                  tint: color,
                                  size: 44,
                                  radius: 15,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.note?.isNotEmpty == true
                                            ? tx.note!
                                            : (tx.categoryName ?? 'Giao dịch'),
                                        style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w800,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 5),
                                      Row(children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: ownerColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            '${tx.walletName ?? 'Ví chính'} • ${tx.ownerName ?? (tx.owner == 'wife' ? 'Vợ' : 'Chồng')}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark
                                                  ? Colors.white54
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                      ]),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      prefix +
                                          Formatters.formatCurrency(tx.amount),
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: color),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('dd/MM • HH:mm')
                                          .format(txDate),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isDark
                                            ? Colors.white38
                                            : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _summaryValue(String label, int amount, Color color) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${amount > 0 ? '+' : ''}${Formatters.formatCurrency(amount)}',
              style: TextStyle(
                  color: color, fontSize: 12.5, fontWeight: FontWeight.w900),
            ),
          ),
        ]),
      );

  Widget _buildMonthSelector(bool isDark) {
    final month = _visibleMonth;
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: .07)
            : Colors.white.withValues(alpha: .76),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE4EAF2),
        ),
      ),
      child: Row(children: [
        IconButton(
          tooltip: 'Tháng trước',
          onPressed: () => _setMonth(DateTime(month.year, month.month - 1)),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: InkWell(
            onTap: _pickMonth,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_month_rounded,
                    size: 18, color: Color(0xFF2563EB)),
                const SizedBox(width: 7),
                Text(
                  'Tháng ${month.month}/${month.year}',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 3),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: 'Tháng sau',
          onPressed: () => _setMonth(DateTime(month.year, month.month + 1)),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ]),
    );
  }

  Widget _buildMiniTrend(List<TransactionModel> transactions) {
    final today = DateTime.now();
    final values = List<double>.generate(7, (index) {
      final target = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: 6 - index));
      return transactions.where((tx) {
        final date = _parseTxDate(tx.date);
        return tx.type == 'expense' &&
            date.year == target.year &&
            date.month == target.month &&
            date.day == target.day;
      }).fold<double>(0, (sum, tx) => sum + tx.amount);
    });
    final maxValue = values.fold<double>(1, (a, b) => a > b ? a : b);
    return Container(
      height: 48,
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (index) {
          final ratio = values[index] / maxValue;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                height: 6 + 27 * ratio,
                decoration: BoxDecoration(
                  color: index == values.length - 1
                      ? const Color(0xFF67E8F9)
                      : Colors.white.withValues(alpha: .42),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
