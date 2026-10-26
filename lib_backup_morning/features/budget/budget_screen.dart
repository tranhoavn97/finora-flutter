import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../data/models/category.dart';
import '../../data/models/finance_models.dart';
import '../../state/budget_provider.dart';
import '../../state/more_provider.dart';

class BudgetScreen extends StatefulWidget {
  final String userId;
  const BudgetScreen({super.key, required this.userId});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  String _selectedMember = 'all'; // 'all', 'husband', 'wife'
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BudgetProvider>().load(widget.userId);
        context.read<MoreProvider>().load(widget.userId);
      }
    });
  }

  void _openAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassBottomSheet(
          radius: 30, child: _AddBudgetDialog(userId: widget.userId)),
    );
  }

  Future<void> _confirmDeleteBudget(BudgetSpentData item) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => GlassBottomSheet(
        radius: 30,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircleAvatar(
                radius: 25,
                backgroundColor: Color(0xFFFFE4E6),
                child: Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444))),
            const SizedBox(height: 12),
            const Text('Xóa ngân sách?',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(
                'Hạn mức “${item.budget.categoryName}” sẽ bị xóa. Giao dịch đã ghi không bị ảnh hưởng.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF74809A))),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: const StadiumBorder()),
                      onPressed: () => Navigator.pop(sheetContext, false),
                      child: const Text('Giữ lại'))),
              const SizedBox(width: 10),
              Expanded(
                  child: FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          minimumSize: const Size.fromHeight(48),
                          shape: const StadiumBorder()),
                      onPressed: () => Navigator.pop(sheetContext, true),
                      child: const Text('Xóa'))),
            ]),
          ]),
        ),
      ),
    );
    if (confirmed == true && mounted) {
      await context
          .read<BudgetProvider>()
          .deleteBudget(widget.userId, item.budget.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final source = provider.budgetsWithSpent;
    final items = source;
    final totalLimit =
        items.fold<int>(0, (sum, e) => sum + e.budget.limitAmount);
    final totalSpent = items.fold<int>(0, (sum, e) => sum + e.spentAmount);
    final remaining = totalLimit - totalSpent;
    final progress =
        totalLimit == 0 ? 0.0 : (totalSpent / totalLimit).clamp(0.0, 1.0);
    final filtered = items.where((e) {
      if (_statusFilter == 'active') return e.progress < 1;
      if (_statusFilter == 'done') return e.progress >= 1;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF7F9FD),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
          children: [
            _newHeader(isDark),
            const SizedBox(height: 17),
            _summaryCard(totalLimit, totalSpent, remaining, progress, isDark),
            const SizedBox(height: 20),
            _sectionTitle('Tổng quan theo danh mục', 'Xem báo cáo', null),
            const SizedBox(height: 10),
            if (items.isEmpty)
              _budgetEmptyOverview(isDark)
            else
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 9),
                  itemBuilder: (_, index) =>
                      _categoryOverview(items[index], index, isDark),
                ),
              ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _statusTabs(isDark)),
              const SizedBox(width: 10),
              const Text('Sắp xếp',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF74809A))),
              const SizedBox(width: 4),
              const Icon(Icons.tune_rounded,
                  size: 19, color: Color(0xFF74809A)),
            ]),
            const SizedBox(height: 17),
            const Text('Danh sách ngân sách',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF172033) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE7ECF4)),
                boxShadow: [
                  BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? .16 : .045),
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ],
              ),
              child: Column(children: [
                for (var i = 0; i < filtered.length; i++) ...[
                  _budgetRow(filtered[i], i, isDark, source.isNotEmpty),
                  if (i < filtered.length - 1)
                    Divider(
                        height: 1,
                        indent: 72,
                        color:
                            isDark ? Colors.white10 : const Color(0xFFEDF1F7)),
                ],
                if (filtered.isEmpty)
                  const Padding(
                      padding: EdgeInsets.all(28),
                      child: Text('Chưa có ngân sách phù hợp')),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _budgetEmptyOverview(bool dark) => Container(
        height: 126,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF172033) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: dark ? Colors.white10 : const Color(0xFFE7ECF4)),
        ),
        child: Row(children: [
          const CircleAvatar(
              radius: 25,
              backgroundColor: Color(0xFFE4F8FB),
              child: Icon(Icons.account_balance_wallet_outlined,
                  color: Color(0xFF0EA5B7))),
          const SizedBox(width: 13),
          const Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Chưa có ngân sách tháng này',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                SizedBox(height: 4),
                Text('Tạo hạn mức đầu tiên để theo dõi chi tiêu.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF74809A)))
              ])),
          IconButton(onPressed: _openAdd, icon: const Icon(Icons.add_rounded))
        ]),
      );

  Widget _newHeader(bool isDark) => Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ngân sách',
              style: TextStyle(
                  fontSize: 29,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF10172C))),
          const SizedBox(height: 8),
          const Text('Quản lý ngân sách, kiểm soát chi tiêu hiệu quả',
              style: TextStyle(fontSize: 12, color: Color(0xFF74809A))),
        ])),
        _roundAction(
            Icons.add_rounded, const Color(0xFF0EA5C6), Colors.white, _openAdd),
      ]);

  Widget _roundAction(IconData icon, Color bg, Color fg, VoidCallback tap) =>
      InkWell(
        onTap: tap,
        customBorder: const CircleBorder(),
        child: Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE8EDF5)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: .07),
                      blurRadius: 12,
                      offset: const Offset(0, 5))
                ]),
            child: Icon(icon, color: fg, size: 23)),
      );

  void _showBudgetHelp() => showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
            title: const Text('Ngân sách hoạt động thế nào?'),
            content: const Text(
                'Tạo hạn mức cho từng nhóm chi tiêu. Finora tự động cộng các giao dịch trong tháng và cảnh báo khi bạn sắp vượt hạn mức.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đã hiểu'))
            ],
          ));

  Widget _summaryCard(
      int limit, int spent, int remaining, double progress, bool isDark) {
    final percent = (progress * 100).round();
    final money = NumberFormat('#,##0', 'vi_VN');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF093947), Color(0xFF0B6472)])
            : const LinearGradient(
                colors: [Color(0xFFF8FCFF), Color(0xFFCFF4FB)]),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFB9EAF2)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF0EA5B7).withValues(alpha: .18),
              blurRadius: 24,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .9),
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF06B6D4).withValues(alpha: .14),
                        blurRadius: 14)
                  ]),
              child: const Icon(Icons.track_changes_rounded,
                  color: Color(0xFF0EA5B7), size: 31)),
          const SizedBox(width: 13),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Tổng ngân sách tháng ${DateTime.now().month}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark ? Colors.white70 : const Color(0xFF25304C))),
                const SizedBox(height: 5),
                Text('${money.format(limit)} đ',
                    style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color:
                            isDark ? Colors.white : const Color(0xFF0898B4))),
              ])),
          SizedBox(
              width: 76,
              height: 76,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: Colors.white.withValues(alpha: .68),
                    color: const Color(0xFF0EA5B7)),
                Text('$percent%',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, color: Color(0xFF0B96AF))),
              ])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _summaryMetric('Đã sử dụng', spent, percent, isDark)),
          Container(width: 1, height: 44, color: const Color(0xFF8FD8E4)),
          Expanded(
              child:
                  _summaryMetric('Còn lại', remaining, 100 - percent, isDark)),
        ]),
        const SizedBox(height: 13),
        ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: Colors.white.withValues(alpha: .65),
                color: const Color(0xFF18B8C4))),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.calendar_month_outlined,
              size: 16, color: Color(0xFF17AFC2)),
          const SizedBox(width: 6),
          const Expanded(
              child: Text('Kết thúc vào cuối tháng',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF74809A)))),
          Text(
              '01/${DateTime.now().month.toString().padLeft(2, '0')} - ${DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day}/${DateTime.now().month.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF74809A))),
          const Icon(Icons.chevron_right_rounded,
              size: 16, color: Color(0xFF74809A)),
        ]),
      ]),
    );
  }

  Widget _summaryMetric(String label, int value, int percent, bool isDark) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF74809A))),
          const SizedBox(height: 3),
          Text('${NumberFormat('#,##0', 'vi_VN').format(value)} đ',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF099CB5))),
          Text('$percent%',
              style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4F5D78))),
        ]),
      );

  Widget _sectionTitle(String title, String action, IconData? icon) =>
      Row(children: [
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900))),
        Text(action,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF74809A))),
        Icon(icon ?? Icons.chevron_right_rounded,
            size: 18, color: const Color(0xFF74809A)),
      ]);

  static const _accents = [
    Color(0xFFF6B900),
    Color(0xFF2D98F0),
    Color(0xFF18B16C),
    Color(0xFF7657F6),
    Color(0xFFEC6090),
    Color(0xFF8E98AE)
  ];

  Widget _categoryOverview(BudgetSpentData item, int index, bool isDark) {
    final color = _accents[index % _accents.length];
    final p = item.progress.clamp(0.0, 1.0);
    return Container(
      width: 112,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF172033) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE9EDF5)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: .04),
                blurRadius: 13,
                offset: const Offset(0, 6))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 39,
            height: 39,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: color.withValues(alpha: .13), shape: BoxShape.circle),
            child: Text(
                CategoryIconHelper.resolveIcon(item.budget.categoryIcon),
                style: const TextStyle(fontSize: 20))),
        const SizedBox(height: 8),
        Text(item.budget.categoryName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text('${NumberFormat.compact(locale: 'vi').format(item.spentAmount)} đ',
            style:
                const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
        const Spacer(),
        ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: LinearProgressIndicator(
                value: p,
                minHeight: 5,
                backgroundColor: color.withValues(alpha: .12),
                color: color)),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
              'Còn ${NumberFormat.compact(locale: 'vi').format(item.budget.limitAmount - item.spentAmount)} đ',
              style: const TextStyle(fontSize: 8.5, color: Color(0xFF74809A))),
          Text('${(p * 100).round()}%',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: p >= .9 ? Colors.red : color))
        ]),
      ]),
    );
  }

  Widget _statusTabs(bool isDark) => Container(
        height: 36,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
            color: isDark ? Colors.white10 : const Color(0xFFF0F3F9),
            borderRadius: BorderRadius.circular(99)),
        child: Row(children: [
          _statusTab('all', 'Tất cả'),
          _statusTab('active', 'Đang hoạt động'),
          _statusTab('done', 'Đã hoàn thành'),
        ]),
      );

  Widget _statusTab(String key, String label) => Expanded(
      child: InkWell(
          onTap: () => setState(() => _statusFilter = key),
          borderRadius: BorderRadius.circular(99),
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color:
                      _statusFilter == key ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                  border: _statusFilter == key
                      ? Border.all(color: const Color(0xFF20B9CC))
                      : null),
              child: Text(label,
                  maxLines: 1,
                  style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: _statusFilter == key
                          ? const Color(0xFF079BB4)
                          : const Color(0xFF4F5D78))))));

  Widget _budgetRow(
      BudgetSpentData item, int index, bool isDark, bool canDelete) {
    final color = _accents[index % _accents.length];
    final progress = item.progress.clamp(0.0, 1.0);
    final remain = item.budget.limitAmount - item.spentAmount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 11),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 45,
            height: 45,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: color.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(15)),
            child: Text(
                CategoryIconHelper.resolveIcon(item.budget.categoryIcon),
                style: const TextStyle(fontSize: 21))),
        const SizedBox(width: 11),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(item.budget.categoryName,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w900))),
            Text('${NumberFormat('#,##0', 'vi_VN').format(item.spentAmount)} đ',
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
            Text(
                ' / ${NumberFormat('#,##0', 'vi_VN').format(item.budget.limitAmount)} đ',
                style: const TextStyle(fontSize: 10, color: Color(0xFF74809A))),
            PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_horiz_rounded,
                    size: 18, color: Color(0xFF74809A)),
                onSelected: (v) async {
                  if (v == 'delete' && canDelete) {
                    await _confirmDeleteBudget(item);
                  }
                },
                itemBuilder: (_) => [
                      if (canDelete)
                        const PopupMenuItem(
                            value: 'delete', child: Text('Xóa ngân sách'))
                    ]),
          ]),
          const SizedBox(height: 3),
          Text(_budgetDescription(item.budget.categoryName),
              style: const TextStyle(fontSize: 9.5, color: Color(0xFF74809A))),
          const SizedBox(height: 7),
          Row(children: [
            Expanded(
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: color.withValues(alpha: .12),
                        color: color))),
            const SizedBox(width: 10),
            Text('Còn ${NumberFormat('#,##0', 'vi_VN').format(remain)} đ',
                style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: remain < 0 ? Colors.red : color)),
            const Icon(Icons.chevron_right_rounded,
                size: 17, color: Color(0xFF74809A)),
          ]),
          const SizedBox(height: 4),
          Text('${(progress * 100).round()}% đã sử dụng',
              style: const TextStyle(fontSize: 9, color: Color(0xFF74809A))),
        ])),
      ]),
    );
  }

  String _budgetDescription(String name) => switch (name.toLowerCase()) {
        'ăn uống' => 'Chi tiêu cho ăn uống hằng ngày',
        'đi lại' => 'Chi phí xăng xe, di chuyển',
        'mua sắm' => 'Mua sắm cá nhân, quần áo, đồ dùng',
        'giải trí' => 'Xem phim, du lịch, trò chơi',
        'sức khỏe' => 'Chi phí chăm sóc sức khỏe',
        _ => 'Các chi phí khác',
      };

  Widget _buildLegacy(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final data = provider.budgetsWithSpent;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);

    final totalLimit = data.fold<int>(0, (s, d) => s + d.budget.limitAmount);
    final totalSpent = data.fold<int>(0, (s, d) => s + d.spentAmount);
    final displayLimit = totalLimit;
    final displaySpent = totalSpent;
    final remaining = displayLimit - displaySpent;
    final totalProgress = displayLimit > 0 ? (displaySpent / displayLimit).clamp(0.0, 1.0) : 0.0;
    final totalPercent = (totalProgress * 100).round();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Header: Back, "Quản lý ngân sách" + "+" Add Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Icon(Icons.chevron_left_rounded,
                        color: primaryTextColor, size: 22),
                  ),
                ),
                Text(
                  'Quản lý ngân sách',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: primaryTextColor,
                  ),
                ),
                GestureDetector(
                  onTap: _openAdd,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Member Segmented Tab: Tất cả / Chồng / Vợ (Dark Navy Active Pill)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  _buildMemberTab('all', 'Tất cả', isDark),
                  _buildMemberTab('husband', 'Chồng', isDark),
                  _buildMemberTab('wife', 'Vợ', isDark),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Amber/Orange Hero Card: "HẠN MỨC THÁNG 08/2026"
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFEA580C),
                    Color(0xFFF97316),
                    Color(0xFFFBBF24)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.35),
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
                        'HẠN MỨC THÁNG 08/2026',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 0.8,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$totalPercent% đã dùng',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${NumberFormat('#,##0', 'vi_VN').format(displayLimit)} đ',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Sub-row: Đã chi tiêu / Còn lại khả dụng
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đã chi tiêu',
                            style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${NumberFormat('#,##0', 'vi_VN').format(displaySpent)} đ',
                            style: const TextStyle(
                                fontSize: 13.5,
                                color: Colors.white,
                                fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Còn lại khả dụng',
                            style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${NumberFormat('#,##0', 'vi_VN').format(remaining)} đ',
                            style: const TextStyle(
                                fontSize: 13.5,
                                color: Colors.white,
                                fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Yellow Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: totalProgress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFEF08A)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // 3. Section: DANH SÁCH NGÂN SÁCH
            Text(
              'DANH SÁCH NGÂN SÁCH (${data.isEmpty ? 4 : data.length})',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: secondaryTextColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            // Budget List Cards
            if (data.isEmpty) ...[
              _buildDemoBudgetItem(
                icon: '🍜',
                title: 'Ăn uống',
                limit: '2.000.000 đ',
                spent: '2.000.000 đ',
                progress: 1.0,
                percent: '100%',
                isDark: isDark,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
              ),
              const SizedBox(height: 10),
              _buildDemoBudgetItem(
                icon: '📦',
                title: 'Khác',
                limit: '1.000.000 đ',
                spent: '1.000.000 đ',
                progress: 1.0,
                percent: '100%',
                isDark: isDark,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
              ),
              const SizedBox(height: 10),
              _buildDemoBudgetItem(
                icon: '🛍️',
                title: 'Shopee',
                limit: '1.000.000 đ',
                spent: '1.000.000 đ',
                progress: 1.0,
                percent: '100%',
                isDark: isDark,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
              ),
              const SizedBox(height: 10),
              _buildDemoBudgetItem(
                icon: '🏠',
                title: 'Nhà ở',
                limit: '1.000.000 đ',
                spent: '1.000.000 đ',
                progress: 1.0,
                percent: '100%',
                isDark: isDark,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
              ),
            ] else ...[
              for (final item in data)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFEDD5),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  CategoryIconHelper.resolveIcon(
                                      item.budget.categoryIcon),
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                item.budget.categoryName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: primaryTextColor,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                '${NumberFormat('#,##0', 'vi_VN').format(item.budget.limitAmount)} đ',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: primaryTextColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Color(0xFFEF4444), size: 20),
                                onPressed: () async {
                                  await context
                                      .read<BudgetProvider>()
                                      .deleteBudget(
                                          widget.userId, item.budget.id);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (item.spentAmount /
                                  (item.budget.limitAmount > 0
                                      ? item.budget.limitAmount
                                      : 1))
                              .clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor:
                              isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFF97316)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Đã dùng: ${NumberFormat('#,##0', 'vi_VN').format(item.spentAmount)} / ${NumberFormat('#,##0', 'vi_VN').format(item.budget.limitAmount)} đ',
                            style: TextStyle(
                                fontSize: 12,
                                color: secondaryTextColor,
                                fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${((item.spentAmount / (item.budget.limitAmount > 0 ? item.budget.limitAmount : 1)) * 100).round()}%',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF97316)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDemoBudgetItem({
    required String icon,
    required String title,
    required String limit,
    required String spent,
    required double progress,
    required String percent,
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFEDD5),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(icon, style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: primaryTextColor,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    limit,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444), size: 20),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor:
                  isDark ? Colors.white10 : const Color(0xFFF1F5F9),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFF97316)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đã dùng: $spent / $limit',
                style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w500),
              ),
              Text(
                percent,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF97316)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTab(String key, String label, bool isDark) {
    final selected = _selectedMember == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMember = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? const Color(0xFF334155) : const Color(0xFF1E1B4B))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected
                  ? Colors.white
                  : (isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }
}

// Modal Dialog to Add Budget
class _AddBudgetDialog extends StatefulWidget {
  final String userId;
  const _AddBudgetDialog({required this.userId});

  @override
  State<_AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<_AddBudgetDialog> {
  final _amountController = TextEditingController();
  Category? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final moreProvider = context.watch<MoreProvider>();
    final categories = moreProvider.categories
        .where((c) => c.categoryGroup == 'expense')
        .toList();

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Thêm ngân sách danh mục',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: primaryTextColor),
          ),
          const SizedBox(height: 16),

          // Dropdown for Category
          DropdownButtonFormField<Category>(
            decoration: InputDecoration(
              labelText: 'Chọn danh mục',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            items: categories.map((c) {
              return DropdownMenuItem<Category>(
                value: c,
                child:
                    Text('${CategoryIconHelper.resolveIcon(c.icon)} ${c.name}'),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedCategory = val),
          ),
          const SizedBox(height: 14),

          // Amount field
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [DotSeparatorTextInputFormatter()],
            decoration: InputDecoration(
              labelText: 'Hạn mức ngân sách (VNĐ)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                final digits =
                    _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
                final amount = int.tryParse(digits) ?? 0;
                if (amount > 0 && _selectedCategory != null) {
                  final now = DateTime.now();
                  final monthStr =
                      '${now.year}-${now.month.toString().padLeft(2, '0')}';
                  final budget = Budget(
                    userId: widget.userId,
                    monthKey: monthStr,
                    categoryId: _selectedCategory!.id,
                    categoryName: _selectedCategory!.name,
                    categoryIcon: _selectedCategory!.icon,
                    limitAmount: amount,
                  );
                  await context
                      .read<BudgetProvider>()
                      .addBudget(widget.userId, budget);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: const StadiumBorder(),
              ),
              child: const Text('Lưu ngân sách',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
