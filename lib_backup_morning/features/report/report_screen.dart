import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction.dart';
import '../../domain/finance/finance_summary.dart';
import '../../state/transaction_provider.dart';

class ReportScreen extends StatefulWidget {
  final String userId;
  final bool isRoot;
  const ReportScreen({super.key, required this.userId, this.isRoot = false});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _month = DateTime.now();
  String _member = 'all';
  String _period = 'month';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TransactionProvider>().load(widget.userId);
    });
  }

  bool _income(TransactionModel t) => FinanceSummary.isIncome(t);
  bool _expense(TransactionModel t) => FinanceSummary.isExpense(t);

  bool _inSelectedPeriod(DateTime date) {
    switch (_period) {
      case 'week':
        final anchor = DateTime(_month.year, _month.month, _month.day);
        final start = anchor.subtract(Duration(days: anchor.weekday - 1));
        final end = start.add(const Duration(days: 7));
        return !date.isBefore(start) && date.isBefore(end);
      case 'quarter':
        final quarterStart = ((_month.month - 1) ~/ 3) * 3 + 1;
        final start = DateTime(_month.year, quarterStart);
        final end = DateTime(_month.year, quarterStart + 3);
        return !date.isBefore(start) && date.isBefore(end);
      case 'year':
        return date.year == _month.year;
      default:
        return date.year == _month.year && date.month == _month.month;
    }
  }

  void _shiftPeriod(int direction) {
    setState(() {
      _month = switch (_period) {
        'week' => _month.add(Duration(days: 7 * direction)),
        'quarter' => DateTime(_month.year, _month.month + 3 * direction),
        'year' => DateTime(_month.year + direction, _month.month),
        _ => DateTime(_month.year, _month.month + direction),
      };
    });
  }

  String _periodLabel() {
    if (_period == 'year') return '${_month.year}';
    if (_period == 'quarter') {
      return 'Quý ${((_month.month - 1) ~/ 3) + 1}/${_month.year}';
    }
    if (_period == 'week') {
      final start = _month.subtract(Duration(days: _month.weekday - 1));
      final end = start.add(const Duration(days: 6));
      return '${DateFormat('dd/MM').format(start)} – ${DateFormat('dd/MM/yyyy').format(end)}';
    }
    return DateFormat('MM/yyyy').format(_month);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final sub = dark ? AppColors.darkTextSecondary : const Color(0xFF64748B);
    final txs = context.watch<TransactionProvider>().transactions.where((t) {
      final d = DateTime.fromMillisecondsSinceEpoch(t.date);
      final member = _member == 'all' ||
          t.owner == _member ||
          t.ownerName == (_member == 'husband' ? 'Chồng' : 'Vợ');
      return _inSelectedPeriod(d) && member;
    }).toList();
    final income = txs.where(_income).fold<int>(0, (s, t) => s + t.amount);
    final expense = txs.where(_expense).fold<int>(0, (s, t) => s + t.amount);
    final groups = <String, int>{};
    for (final t in txs.where(_expense)) {
      final k =
          t.categoryName?.trim().isNotEmpty == true ? t.categoryName! : 'Khác';
      groups[k] = (groups[k] ?? 0) + t.amount;
    }
    final sorted = groups.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    const colors = [
      Color(0xFF2563EB),
      Color(0xFF06B6D4),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF64748B)
    ];
    return Scaffold(
        backgroundColor: dark ? AppColors.darkBg : const Color(0xFFF7F9FC),
        body: SafeArea(
            child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
              Row(children: [
                if (!widget.isRoot)
                  _button(Icons.chevron_left_rounded,
                      () => Navigator.pop(context), dark),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Báo cáo & Phân tích',
                          style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              color: text)),
                      const SizedBox(height: 3),
                      Text('Hiểu rõ thói quen chi tiêu của bạn',
                          style: TextStyle(fontSize: 11.5, color: sub)),
                    ])),
                _button(Icons.calendar_month_rounded, () async {
                  final d = await showDatePicker(
                      context: context,
                      initialDate: _month,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (d != null)
                    setState(() => _month = DateTime(d.year, d.month));
                }, dark)
              ]),
              const SizedBox(height: 16),
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: dark ? const Color(0xFF172033) : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color:
                              dark ? Colors.white10 : const Color(0xFFE8EDF5))),
                  child: GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      crossAxisSpacing: 7,
                      mainAxisSpacing: 7,
                      childAspectRatio: 2.15,
                      children: [
                        _reportMetricCard('Tổng chi', expense,
                            const Color(0xFFE11D48), Icons.wallet_rounded),
                        _reportMetricCard('Tổng thu', income,
                            const Color(0xFF16A34A), Icons.savings_rounded),
                        _reportMetricCard('Số dư', income - expense,
                            const Color(0xFF2563EB), Icons.layers_rounded),
                        _reportMetricCard('Giao dịch', txs.length,
                            const Color(0xFFF97316), Icons.credit_card_rounded,
                            money: false),
                      ])),
              const SizedBox(height: 16),
              Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: dark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: .05),
                            blurRadius: 14)
                      ]),
                  child: Row(children: [
                    _periodTab('week', 'Tuần'),
                    _periodTab('month', 'Tháng'),
                    _periodTab('quarter', 'Quý'),
                    _periodTab('year', 'Năm'),
                    _periodTab('custom', 'Tùy chọn')
                  ])),
              const SizedBox(height: 12),
              Container(
                  height: 45,
                  decoration: BoxDecoration(
                      color: dark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(23)),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                            onPressed: () => _shiftPeriod(-1),
                            icon: const Icon(Icons.chevron_left_rounded)),
                        const SizedBox(width: 18),
                        const Icon(Icons.calendar_month_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(_periodLabel(),
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(width: 18),
                        IconButton(
                            onPressed: () => _shiftPeriod(1),
                            icon: const Icon(Icons.chevron_right_rounded))
                      ])),
              const SizedBox(height: 12),
              Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: dark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(18)),
                  child: Row(children: [
                    _tab('all', 'Tất cả'),
                    _tab('husband', 'Chồng'),
                    _tab('wife', 'Vợ')
                  ])),
              const SizedBox(height: 16),
              Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFF0F3D74),
                        Color(0xFF087EA4),
                        Color(0xFF06B6D4)
                      ]),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                            color:
                                const Color(0xFF0891B2).withValues(alpha: .25),
                            blurRadius: 24,
                            offset: const Offset(0, 10))
                      ]),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  'DÒNG TIỀN • ${DateFormat('MM/yyyy').format(_month)}',
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12)),
                              Text('${txs.length} giao dịch',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700))
                            ]),
                        const SizedBox(height: 12),
                        Text(formatVND(income - expense),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 31,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 18),
                        Row(children: [
                          Expanded(
                              child: _metric(
                                  'Thu vào', income, const Color(0xFF6EE7B7))),
                          Container(
                              width: 1, height: 42, color: Colors.white24),
                          Expanded(
                              child: _metric(
                                  'Chi ra', expense, const Color(0xFFFCA5A5)))
                        ])
                      ])),
              const SizedBox(height: 18),
              Text('Cơ cấu chi tiêu',
                  style: TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w900, color: text)),
              const SizedBox(height: 10),
              Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      color: dark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: dark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE5EAF1))),
                  child: sorted.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 34),
                          child: Center(
                              child: Text('Chưa có chi tiêu trong tháng này',
                                  style: TextStyle(
                                      color: sub,
                                      fontWeight: FontWeight.w600))))
                      : Column(children: [
                          SizedBox(
                              height: 190,
                              child: PieChart(PieChartData(
                                  centerSpaceRadius: 55,
                                  sectionsSpace: 3,
                                  sections: [
                                    for (var i = 0; i < sorted.length; i++)
                                      PieChartSectionData(
                                          color: colors[i % colors.length],
                                          value: sorted[i].value.toDouble(),
                                          radius: 22,
                                          title: '')
                                  ]))),
                          for (var i = 0; i < sorted.length; i++)
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Row(children: [
                                  Container(
                                      width: 11,
                                      height: 11,
                                      decoration: BoxDecoration(
                                          color: colors[i % colors.length],
                                          shape: BoxShape.circle)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: Text(sorted[i].key,
                                          style: TextStyle(
                                              color: text,
                                              fontWeight: FontWeight.w700))),
                                  Text(
                                      '${expense == 0 ? 0 : (sorted[i].value * 100 / expense).round()}%',
                                      style: TextStyle(
                                          color: sub,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(width: 12),
                                  Text(formatVND(sorted[i].value),
                                      style: TextStyle(
                                          color: text,
                                          fontWeight: FontWeight.w800))
                                ]))
                        ])),
              const SizedBox(height: 18),
              _trendCard(txs, dark, text, sub),
              const SizedBox(height: 18),
              _insightCard(sorted, income, expense, dark),
            ])));
  }

  Widget _trendCard(
      List<TransactionModel> txs, bool dark, Color text, Color sub) {
    final byDayIncome = <DateTime, int>{};
    final byDayExpense = <DateTime, int>{};
    for (final tx in txs) {
      final raw = DateTime.fromMillisecondsSinceEpoch(tx.date);
      final day = DateTime(raw.year, raw.month, raw.day);
      if (_income(tx)) {
        byDayIncome[day] = (byDayIncome[day] ?? 0) + tx.amount;
      } else if (_expense(tx)) {
        byDayExpense[day] = (byDayExpense[day] ?? 0) + tx.amount;
      }
    }
    final days = {...byDayIncome.keys, ...byDayExpense.keys}.toList()..sort();
    final maxValue = [...byDayIncome.values, ...byDayExpense.values, 1]
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    for (var i = 0; i < days.length; i++) {
      incomeSpots
          .add(FlSpot(i.toDouble(), (byDayIncome[days[i]] ?? 0).toDouble()));
      expenseSpots
          .add(FlSpot(i.toDouble(), (byDayExpense[days[i]] ?? 0).toDouble()));
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
          color: dark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: dark ? Colors.white10 : const Color(0xFFE5EAF1))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text('Xu hướng thu chi',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w900, color: text))),
          _legendDot(const Color(0xFF22C55E), 'Thu'),
          const SizedBox(width: 10),
          _legendDot(const Color(0xFFF43F5E), 'Chi'),
        ]),
        const SizedBox(height: 14),
        if (days.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(
                child: Text('Chưa đủ dữ liệu để vẽ xu hướng',
                    style: TextStyle(color: sub))),
          )
        else
          SizedBox(
            height: 175,
            child: LineChart(LineChartData(
              minY: 0,
              maxY: maxValue * 1.15,
              gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue / 3),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                  showTitles: true,
                  interval:
                      days.length > 8 ? (days.length / 4).ceilToDouble() : 1,
                  getTitlesWidget: (value, meta) {
                    final i = value.round();
                    if (i < 0 || i >= days.length)
                      return const SizedBox.shrink();
                    return Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Text(DateFormat('dd/MM').format(days[i]),
                            style: const TextStyle(
                                fontSize: 8, color: Color(0xFF94A3B8))));
                  },
                )),
              ),
              lineBarsData: [
                _line(incomeSpots, const Color(0xFF22C55E)),
                _line(expenseSpots, const Color(0xFFF43F5E)),
              ],
            )),
          ),
      ]),
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) => LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: const FlDotData(show: false),
      belowBarData:
          BarAreaData(show: true, color: color.withValues(alpha: .10)));

  Widget _legendDot(Color color, String label) => Row(children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
      ]);

  Widget _insightCard(
      List<MapEntry<String, int>> groups, int income, int expense, bool dark) {
    final balance = income - expense;
    final top = groups.isEmpty ? null : groups.first;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: dark
                ? const [Color(0xFF18233A), Color(0xFF22304A)]
                : const [Color(0xFFF0FDF4), Color(0xFFFFFBEB)]),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: dark ? Colors.white10 : Colors.white),
      ),
      child: Row(children: [
        const CircleAvatar(
            backgroundColor: Color(0xFFFFF1C7),
            child: Icon(Icons.lightbulb_rounded, color: Color(0xFFF59E0B))),
        const SizedBox(width: 11),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Phân tích nhanh',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(
              top == null
                  ? 'Hãy ghi thêm giao dịch để Finora phân tích thói quen chi tiêu.'
                  : '${top.key} là nhóm chi lớn nhất (${formatVND(top.value)}). ${balance >= 0 ? 'Bạn đang dư ${formatVND(balance)} trong kỳ.' : 'Chi đang vượt thu ${formatVND(-balance)} trong kỳ.'}',
              style: const TextStyle(
                  fontSize: 10.5, height: 1.35, color: Color(0xFF64748B))),
        ])),
      ]),
    );
  }

  Widget _tab(String k, String label) => Expanded(
      child: GestureDetector(
          onTap: () => setState(() => _member = k),
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                  color: _member == k
                      ? const Color(0xFF0F3D74)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(15)),
              alignment: Alignment.center,
              child: Text(label,
                  style: TextStyle(
                      color:
                          _member == k ? Colors.white : const Color(0xFF64748B),
                      fontWeight: FontWeight.w800)))));
  Widget _periodTab(String key, String label) => Expanded(
      child: InkWell(
          onTap: () async {
            if (key == 'custom') {
              final selected = await showDatePicker(
                  context: context,
                  initialDate: _month,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)));
              if (selected == null || !mounted) return;
              setState(() {
                _period = 'custom';
                _month = selected;
              });
            } else {
              setState(() => _period = key);
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 9),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  gradient: _period == key
                      ? const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF60A5FA)])
                      : null,
                  borderRadius: BorderRadius.circular(20)),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _period == key
                          ? Colors.white
                          : const Color(0xFF334155))))));
  Widget _metric(String label, int value, Color color) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(formatVND(value),
            style: TextStyle(
                color: color, fontWeight: FontWeight.w900, fontSize: 16))
      ]));
  Widget _reportMetricCard(String label, int value, Color color, IconData icon,
          {bool money = true}) =>
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                color.withValues(alpha: .08),
                color.withValues(alpha: .015)
              ]),
              borderRadius: BorderRadius.circular(15)),
          child: Row(children: [
            Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    shape: BoxShape.circle),
                child: Icon(icon, size: 18, color: color)),
            const SizedBox(width: 9),
            Expanded(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 1,
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(money ? formatVND(value) : '$value',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: color))
              ],
            ))
          ]));
  Widget _button(IconData icon, VoidCallback tap, bool dark) => InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              color: dark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14)),
          child: Icon(icon)));
}
