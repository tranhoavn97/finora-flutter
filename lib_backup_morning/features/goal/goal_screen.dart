import '../../core/widgets/finora/financial_components.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../../data/models/finance_models.dart';
import '../../data/models/wallet.dart';
import '../../state/more_provider.dart';

/// Savings goals page — accumulated savings vs. target per goal.
class GoalScreen extends StatefulWidget {
  final String userId;
  const GoalScreen({super.key, required this.userId});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  StreamSubscription<String>? _eventsSub;
  String _goalFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<MoreProvider>();
      provider.load(widget.userId);
      _eventsSub = provider.events.listen((msg) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(msg)));
      });
    });
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    super.dispose();
  }

  void _openAdd() {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AddGoalPage(userId: widget.userId),
    ));
  }

  void _openEdit(Goal goal) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AddGoalPage(userId: widget.userId, existing: goal),
    ));
  }

  void _openDeposit(Goal goal) {
    showDialog(
      context: context,
      builder: (_) => _DepositDialog(userId: widget.userId, goal: goal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MoreProvider>();
    final active = provider.goals.where((g) => g.status == 'active').toList();
    final completed =
        provider.goals.where((g) => g.status != 'active').toList();
    final totalTarget = active.fold<int>(0, (s, g) => s + g.targetAmount);
    return Scaffold(
      backgroundColor: dark ? AppColors.darkBg : const Color(0xFFF7F9FD),
      body: SafeArea(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
              children: [
            Row(children: [
              const BackButton(),
              const Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Mục tiêu',
                        style: TextStyle(
                            fontSize: 29, fontWeight: FontWeight.w900)),
                    SizedBox(height: 5),
                    Text('Theo dõi và chinh phục mục tiêu tài chính',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF74809A)))
                  ])),

              _goalAction(Icons.add_rounded, const Color(0xFF16B364),
                  Colors.white, _openAdd),
            ]),
            const SizedBox(height: 20),
            _goalOverview(active.length, totalTarget, dark),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 3, 8, 3),
              decoration: BoxDecoration(
                  color: dark ? Colors.white10 : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: dark ? Colors.white12 : const Color(0xFFE2E8F0))),
              child: Row(children: [
                const Icon(Icons.filter_list_rounded,
                    size: 18, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                const Expanded(
                    child: Text('Hiển thị',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700))),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _goalFilter,
                    borderRadius: BorderRadius.circular(18),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: dark ? Colors.white : const Color(0xFF0F172A)),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                      DropdownMenuItem(
                          value: 'active', child: Text('Đang thực hiện')),
                      DropdownMenuItem(value: 'near', child: Text('Sắp đạt')),
                      DropdownMenuItem(
                          value: 'completed', child: Text('Đã hoàn thành')),
                    ],
                    onChanged: (value) =>
                        setState(() => _goalFilter = value ?? 'all'),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 21),
            _goalSection(_goalFilter == 'completed' ? 'Tiến độ mục tiêu' : 'Đang thực hiện', '${active.length} mục tiêu'),
            const SizedBox(height: 9),
            if (_goalFilter == 'completed')
              const SizedBox.shrink()
            else if (active
                .where((g) =>
                    _goalFilter != 'near' ||
                    (g.targetAmount > 0 &&
                        g.savedAmount / g.targetAmount >= .8))
                .isEmpty)
              _goalEmpty()
            else
              for (var i = 0; i < active.length; i++)
                if (_goalFilter != 'near' ||
                    (active[i].targetAmount > 0 &&
                        active[i].savedAmount / active[i].targetAmount >= .8))
                  Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: _modernGoal(active[i], i, dark)),
            if (completed.isNotEmpty &&
                (_goalFilter == 'all' || _goalFilter == 'completed')) ...[
              const SizedBox(height: 12),
              _goalSection(
                  'Đã hoàn thành', '${completed.length} mục tiêu'),
              const SizedBox(height: 9),
              Container(
                  decoration: BoxDecoration(
                      color: dark ? const Color(0xFF172033) : Colors.white,
                      borderRadius: BorderRadius.circular(20)),
                  child: Column(children: [
                    for (var i = 0; i < completed.length; i++)
                      _completedGoal(completed[i], dark)
                  ]))
            ],
            const SizedBox(height: 20),
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFEAFBF2),
                    borderRadius: BorderRadius.circular(18)),
                child: const Row(children: [
                  CircleAvatar(
                      backgroundColor: Color(0xFFCFF5DD),
                      child: Icon(Icons.lightbulb_outline_rounded,
                          color: Color(0xFF16A05D))),
                  SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Mẹo nhỏ',
                            style: TextStyle(
                                color: Color(0xFF108E50),
                                fontWeight: FontWeight.w800)),
                        Text(
                            'Kiên trì mỗi ngày, bạn sẽ sớm chạm đến mục tiêu của mình!',
                            style: TextStyle(fontSize: 10.5))
                      ]))
                ]))
          ])),
    );
  }

  Widget _goalAction(IconData icon, Color bg, Color fg, VoidCallback tap) =>
      InkWell(
          onTap: tap,
          customBorder: const CircleBorder(),
          child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: .08),
                        blurRadius: 12)
                  ]),
              child: Icon(icon, color: fg)));
  Widget _goalOverview(int count, int total, bool dark) => Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            const Color(0xFF16B364).withValues(alpha: dark ? .18 : .10),
            const Color(0xFF2563EB).withValues(alpha: dark ? .14 : .07),
          ]),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: dark ? Colors.white12 : Colors.white),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: .07),
                blurRadius: 18,
                offset: const Offset(0, 7))
          ]),
      child: Row(children: [
        Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
                color: const Color(0xFF16B364).withValues(alpha: .14),
                shape: BoxShape.circle),
            child: const Icon(Icons.track_changes_rounded,
                color: Color(0xFF16B364))),
        const SizedBox(width: 11),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mục tiêu',
              style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
          Text('$count',
              style: const TextStyle(
                  fontSize: 22,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF16A05D))),
        ]),
        Container(
            width: 1,
            height: 38,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: const Color(0xFFD8E4EA)),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Tổng số tiền cần đạt',
              style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
          const SizedBox(height: 3),
          Text(formatVND(total),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2563EB))),
        ])),
      ]));
  Widget _goalSummary(IconData icon, String label, String value, String suffix,
          Color color, bool dark) =>
      Container(
          height: 105,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                color.withValues(alpha: .10),
                color.withValues(alpha: .035)
              ]),
              borderRadius: BorderRadius.circular(21)),
          child: Row(children: [
            Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: color)),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 10.5, color: Color(0xFF56637D))),
                  const SizedBox(height: 5),
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: suffix.isEmpty ? 16 : 27,
                          fontWeight: FontWeight.w900,
                          color: suffix.isEmpty ? null : color)),
                  if (suffix.isNotEmpty)
                    Text(suffix,
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF74809A)))
                ]))
          ]));
  Widget _goalSection(String title, String action) => Row(children: [
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w900))),
        Text(action,
            style: const TextStyle(fontSize: 11, color: Color(0xFF66738B)))
      ]);
  Widget _goalEmpty() => Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: const Center(child: Text('Chưa có mục tiêu đang thực hiện')));
  Widget _modernGoal(Goal goal, int index, bool dark) {
    final colors = [
      const Color(0xFF16A65C),
      const Color(0xFF176CF3),
      const Color(0xFFF28B00)
    ];
    final color = colors[index % colors.length];
    final p = goal.targetAmount == 0
        ? 0.0
        : (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0);
    final days = goal.targetDate == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(goal.targetDate!)
            .difference(DateTime.now())
            .inDays;
    return InkWell(
        onTap: () => _openDeposit(goal),
        borderRadius: BorderRadius.circular(20),
        child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: dark ? const Color(0xFF172033) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: dark ? Colors.white10 : const Color(0xFFE8EDF5)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: .05),
                      blurRadius: 16,
                      offset: const Offset(0, 7))
                ]),
            child: Row(children: [
              Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      shape: BoxShape.circle),
                  child: Icon(
                      index == 0
                          ? Icons.beach_access_rounded
                          : index == 1
                              ? Icons.phone_iphone_rounded
                              : Icons.school_rounded,
                      size: 34,
                      color: color)),
              const SizedBox(width: 13),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(goal.name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 7),
                    Text(
                        '${formatVND(goal.savedAmount)} / ${formatVND(goal.targetAmount)}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: LinearProgressIndicator(
                            value: p,
                            minHeight: 6,
                            backgroundColor: color.withValues(alpha: .12),
                            color: color)),
                    const SizedBox(height: 8),
                    Text(
                        days == null
                            ? 'Không giới hạn thời gian'
                            : '▣  Còn ${days < 0 ? 0 : days} ngày',
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF66738B)))
                  ])),
              const SizedBox(width: 10),
              Column(children: [
                Icon(Icons.bookmark_rounded, color: color),
                const SizedBox(height: 10),
                Text('${(p * 100).round()}%',
                    style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: color)),
                const Text('Đã đạt',
                    style: TextStyle(fontSize: 10, color: Color(0xFF74809A))),
                PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') _openEdit(goal);
                      if (v == 'delete') onDeleteGoal(goal);
                    },
                    itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'edit', child: Text('Chỉnh sửa')),
                          PopupMenuItem(
                              value: 'delete', child: Text('Xóa mục tiêu'))
                        ],
                    icon: const Icon(Icons.more_horiz_rounded, size: 18))
              ])
            ])));
  }

  Future<void> onDeleteGoal(Goal goal) async {
    final ok = await showConfirmDeleteDialog(
        context: context,
        title: 'Xóa mục tiêu?',
        content: 'Bạn có chắc chắn muốn xóa mục tiêu "${goal.name}" không?');
    if (ok && mounted)
      context.read<MoreProvider>().deleteGoal(widget.userId, goal.id);
  }

  Widget _completedGoal(Goal goal, bool dark) => ListTile(
      leading: const CircleAvatar(
          backgroundColor: Color(0xFFDDF8E7),
          child: Icon(Icons.check_rounded, color: Color(0xFF16A65C))),
      title:
          Text(goal.name, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(
          '${formatVND(goal.savedAmount)} / ${formatVND(goal.targetAmount)}'),
      trailing: const Text('100% ›',
          style: TextStyle(
              color: Color(0xFF16A65C),
              fontSize: 18,
              fontWeight: FontWeight.w900)));

  Widget _buildLegacy(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final provider = context.watch<MoreProvider>();
    final goals = provider.goals.where((g) => g.status == 'active').toList();

    final totalSaved = goals.fold<int>(0, (s, g) => s + g.savedAmount);
    final totalTarget = goals.fold<int>(0, (s, g) => s + g.targetAmount);

    return GlassScaffold(
      appBar: GlassTopBar(
        title: 'Mục tiêu tiết kiệm',
        onBack: () => Navigator.of(context).pop(),
        actions: [
          IconButton(
            onPressed: _openAdd,
            icon: const Icon(Icons.add, color: AppColors.accent),
          ),
        ],
      ),
      body: provider.isRefreshing
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? FinoraDataMessage(
                  title: 'Dữ liệu chưa sẵn sàng',
                  message: provider.error!,
                  onRetry: () => provider.load(widget.userId, force: true))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
                      child: GlassCard(
                        highlighted: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TỔNG TÍCH LŨY TIẾT KIỆM',
                                style: AppTypography.caption1.copyWith(
                                    color: secondaryTextColor,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8)),
                            const SizedBox(height: 8),
                            Text(formatVND(totalSaved),
                                style: AppTypography.largeTitle.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Mục tiêu tổng: ${formatVND(totalTarget)}',
                                style: AppTypography.caption2
                                    .copyWith(color: secondaryTextColor)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text('MỤC TIÊU HOẠT ĐỘNG',
                          style: AppTypography.caption1.copyWith(
                              color: secondaryTextColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8)),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Expanded(
                      child: goals.isEmpty
                          ? Center(
                              child: EmptyState(
                                icon: Icons.flag,
                                title: 'Chưa thiết lập mục tiêu nào',
                                subtitle:
                                    'Các mục tiêu tiết kiệm hoạt động sẽ hiển thị ở đây.',
                                actionText: '+ Thêm mục tiêu',
                                onAction: _openAdd,
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                                  0, AppSpacing.md, AppSpacing.md),
                              itemCount: goals.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (_, i) {
                                final goal = goals[i];
                                return _GoalRow(
                                  key: ValueKey(goal.id),
                                  goal: goal,
                                  onDeposit: () => _openDeposit(goal),
                                  onDelete: () async {
                                    final confirm =
                                        await showConfirmDeleteDialog(
                                      context: context,
                                      title: 'Xóa mục tiêu?',
                                      content:
                                          'Bạn có chắc chắn muốn xóa mục tiêu "${goal.name}" không?',
                                    );
                                    if (confirm && context.mounted) {
                                      context
                                          .read<MoreProvider>()
                                          .deleteGoal(widget.userId, goal.id);
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final Goal goal;
  final VoidCallback onDeposit;
  final VoidCallback onDelete;
  const _GoalRow({
    super.key,
    required this.goal,
    required this.onDeposit,
    required this.onDelete,
  });

  String _targetDateStr() {
    final t = goal.targetDate;
    if (t == null) return 'Không giới hạn';
    final d = DateTime.fromMillisecondsSinceEpoch(t);
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final progress = goal.targetAmount > 0
        ? (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconBadge(icon: Icons.savings, tint: Color(0xFFF5B942)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name,
                        style: AppTypography.body.copyWith(
                            color: primaryTextColor,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('Hạn đạt: ${_targetDateStr()}',
                        style: AppTypography.caption2
                            .copyWith(color: secondaryTextColor)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatVND(goal.targetAmount),
                      style: AppTypography.body.copyWith(
                          color: primaryTextColor,
                          fontWeight: FontWeight.bold)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: onDeposit,
                        tooltip: 'Nạp tiền',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 28, minHeight: 28),
                        icon: const Icon(Icons.add,
                            color: AppColors.success, size: 20),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: onDelete,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 28, minHeight: 28),
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Đã góp: ${formatVND(goal.savedAmount)}',
                  style: AppTypography.caption2
                      .copyWith(color: secondaryTextColor)),
              Text('${(progress * 100).toInt()}%',
                  style: AppTypography.caption2.copyWith(
                      color: const Color(0xFFF5B942),
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: AppRadius.input,
            child: LinearProgressIndicator(
              value: progress.toDouble(),
              minHeight: 6,
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.08),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFF5B942)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Deposit dialog — adds [amount] to the goal's saved total via updateGoal.
class _DepositDialog extends StatefulWidget {
  final String userId;
  final Goal goal;
  const _DepositDialog({required this.userId, required this.goal});

  @override
  State<_DepositDialog> createState() => _DepositDialogState();
}

class _DepositDialogState extends State<_DepositDialog> {
  final _amountController = TextEditingController();
  Wallet? _selectedWallet;
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final amount = int.tryParse(
            _amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;
    if (amount <= 0) return;

    setState(() => _isSaving = true);
    try {
      final updated = widget.goal.copyWith(
        savedAmount: widget.goal.savedAmount + amount,
      );
      await context.read<MoreProvider>().updateGoal(
            widget.userId,
            widget.goal.id,
            updated,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final wallets = context.watch<MoreProvider>().wallets;
    _selectedWallet ??= wallets.isNotEmpty ? wallets.first : null;
    final diff = widget.goal.targetAmount - widget.goal.savedAmount;
    final remaining = diff < 0 ? 0 : diff;

    return GlassDialog(
      radius: 28,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ghi nhận tích lũy',
              style: AppTypography.subhead.copyWith(
                  color: primaryTextColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
              'Mục tiêu: ${widget.goal.name}\nCòn thiếu: ${formatVND(remaining)}',
              style: AppTypography.body.copyWith(
                  color: primaryTextColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          Text('Số tiền tích lũy',
              style: AppTypography.caption1.copyWith(
                  color: secondaryTextColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.xs),
          GlassTextField(
            controller: _amountController,
            hint: '0 ₫',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          const Text(
              'Chỉ cập nhật tiến độ mục tiêu; tiền vẫn ở ví và không phát sinh chuyển tiền. Không cộng khoản này lần nữa vào tài sản ròng.'),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Hủy',
                      style: AppTypography.buttonLabel
                          .copyWith(color: secondaryTextColor)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryButton(
                  expand: true,
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Xác nhận góp',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Full-screen form to create a savings goal.
class AddGoalPage extends StatefulWidget {
  final String userId;
  final Goal? existing;
  const AddGoalPage({super.key, required this.userId, this.existing});

  @override
  State<AddGoalPage> createState() => _AddGoalPageState();
}

class _AddGoalPageState extends State<AddGoalPage> {
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _daysController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final goal = widget.existing;
    if (goal != null) {
      _nameController.text = goal.name;
      _targetController.text = '${goal.targetAmount}';
      if (goal.targetDate != null) {
        final days = DateTime.fromMillisecondsSinceEpoch(goal.targetDate!)
            .difference(DateTime.now())
            .inDays;
        if (days > 0) _daysController.text = '$days';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final name = _nameController.text.trim();
    final target = int.tryParse(
            _targetController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;
    if (name.isEmpty || target <= 0) return;

    setState(() => _isSaving = true);

    try {
      final daysStr = _daysController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final days = daysStr.isEmpty ? null : int.tryParse(daysStr);
      final now = DateTime.now().millisecondsSinceEpoch;
      final targetDate = days != null ? now + days * 24 * 60 * 60 * 1000 : null;
      final existing = widget.existing;
      final goal = Goal(
        id: existing?.id ?? '',
        userId: widget.userId,
        name: name,
        targetAmount: target,
        savedAmount: existing?.savedAmount ?? 0,
        targetDate: targetDate,
        status: existing?.status ?? 'active',
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );
      if (existing == null) {
        await context.read<MoreProvider>().addGoal(widget.userId, goal);
      } else {
        await context
            .read<MoreProvider>()
            .updateGoal(widget.userId, existing.id, goal);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return GlassScaffold(
      appBar: GlassTopBar(
        title: widget.existing == null
            ? 'Tạo mục tiêu tiết kiệm'
            : 'Chỉnh sửa mục tiêu',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.lg),
              children: [
                Text('Tên mục tiêu',
                    style: AppTypography.caption1.copyWith(
                        color: secondaryTextColor,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                GlassTextField(
                  controller: _nameController,
                  hint: 'Ví dụ: Quỹ dự phòng, Mua xe máy...',
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Số tiền mục tiêu (VND)',
                    style: AppTypography.caption1.copyWith(
                        color: secondaryTextColor,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                GlassTextField(
                  controller: _targetController,
                  hint: '0 ₫',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Thời gian thực hiện (số ngày, tùy chọn)',
                    style: AppTypography.caption1.copyWith(
                        color: secondaryTextColor,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                GlassTextField(
                  controller: _daysController,
                  hint: 'Số ngày...',
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
              child: PrimaryButton(
                expand: true,
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        widget.existing == null
                            ? 'Tạo mục tiêu'
                            : 'Lưu thay đổi',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
