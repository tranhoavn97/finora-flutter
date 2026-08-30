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
  String _filter = 'all';

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
      builder: (_) => AddGoalPage(userId: widget.userId, goal: goal),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final provider = context.watch<MoreProvider>();
    final allGoals = [...provider.goals]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final goals = _filter == 'all'
        ? allGoals
        : allGoals.where((g) => g.status == _filter).toList();

    final totalSaved = allGoals.fold<int>(0, (s, g) => s + g.savedAmount);
    final totalTarget = allGoals.fold<int>(0, (s, g) => s + g.targetAmount);

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
      body: Column(
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
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: totalTarget <= 0
                        ? 0
                        : (totalSaved / totalTarget).clamp(0, 1),
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(99),
                    backgroundColor: Colors.white.withOpacity(.18),
                    color: AppColors.success,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final entry in const [
                  ('all', 'Tất cả'),
                  ('active', 'Đang làm'),
                  ('paused', 'Tạm dừng'),
                  ('completed', 'Hoàn thành')
                ]) ...[
                  FilterChipX(
                      label: entry.$2,
                      selected: _filter == entry.$1,
                      onTap: () => setState(() => _filter = entry.$1)),
                  const SizedBox(width: 8),
                ],
              ]),
            ),
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
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                    itemCount: goals.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) {
                      final goal = goals[i];
                      return _GoalRow(
                        key: ValueKey(goal.id),
                        goal: goal,
                        onDeposit: () => _openDeposit(goal),
                        onEdit: () => _openEdit(goal),
                        onToggleStatus: () => provider.setGoalStatus(
                          widget.userId,
                          goal.id,
                          goal.status == 'paused' ? 'active' : 'paused',
                        ),
                        onComplete: () => provider.setGoalStatus(
                            widget.userId, goal.id, 'completed'),
                        onDelete: () async {
                          final mode = await showDialog<String>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Xóa mục tiêu'),
                              content: Text(
                                  'Bạn muốn xử lý các giao dịch đã góp vào “${goal.name}” thế nào?'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    child: const Text('Hủy')),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, 'goal'),
                                    child: const Text('Chỉ xóa mục tiêu')),
                                FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, 'both'),
                                    child: const Text('Xóa và hoàn tiền ví')),
                              ],
                            ),
                          );
                          if (mode != null && context.mounted) {
                            final p = context.read<MoreProvider>();
                            if (mode == 'both') {
                              p.deleteGoalWithTransactions(
                                  widget.userId, goal.id);
                            } else {
                              p.deleteGoal(widget.userId, goal.id);
                            }
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
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onComplete;
  final VoidCallback onDelete;
  const _GoalRow({
    super.key,
    required this.goal,
    required this.onDeposit,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onComplete,
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
    const goalPalette = [
      Color(0xFF2563EB),
      Color(0xFFEC4899),
      Color(0xFFF97316),
      Color(0xFF06B6D4),
      Color(0xFF10B981),
    ];
    final goalColor =
        goalPalette[goal.name.hashCode.abs() % goalPalette.length];

    return GlassCard(
      color: goalColor.withValues(alpha: isDark ? .13 : .075),
      customBorder: Border.all(color: goalColor.withValues(alpha: .18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(icon: Icons.savings, tint: goalColor),
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
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'deposit') onDeposit();
                      if (v == 'edit') onEdit();
                      if (v == 'toggle') onToggleStatus();
                      if (v == 'complete') onComplete();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      if (goal.status == 'active')
                        const PopupMenuItem(
                            value: 'deposit', child: Text('Góp thêm tiền')),
                      const PopupMenuItem(
                          value: 'edit', child: Text('Sửa mục tiêu')),
                      if (goal.status != 'completed')
                        PopupMenuItem(
                            value: 'toggle',
                            child: Text(goal.status == 'paused'
                                ? 'Tiếp tục'
                                : 'Tạm dừng')),
                      if (goal.status != 'completed')
                        const PopupMenuItem(
                            value: 'complete',
                            child: Text('Đánh dấu hoàn thành')),
                      const PopupMenuItem(
                          value: 'delete', child: Text('Xóa mục tiêu')),
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
                  style: AppTypography.caption2
                      .copyWith(color: goalColor, fontWeight: FontWeight.bold)),
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
              valueColor: AlwaysStoppedAnimation<Color>(goalColor),
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
  final _noteController = TextEditingController();
  Wallet? _selectedWallet;
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final amount = int.tryParse(
            _amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;
    if (amount <= 0 || _selectedWallet == null) return;
    if (_selectedWallet!.balance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số dư ví không đủ')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await context.read<MoreProvider>().depositToGoal(
          widget.userId, widget.goal, _selectedWallet!, amount,
          note: _noteController.text);
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

    final wallets = context
        .watch<MoreProvider>()
        .wallets
        .where((w) => !w.isCreditCard)
        .toList();
    _selectedWallet ??= wallets.isNotEmpty ? wallets.first : null;
    final diff = widget.goal.targetAmount - widget.goal.savedAmount;
    final remaining = diff < 0 ? 0 : diff;

    return GlassDialog(
      radius: 28,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gửi tiền tiết kiệm',
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
          const SizedBox(height: AppSpacing.md),
          GlassTextField(
            controller: _noteController,
            hint: 'Ghi chú (không bắt buộc)',
          ),
          if (wallets.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Trích tiền từ ví',
                style: AppTypography.caption1.copyWith(
                    color: secondaryTextColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final w in wallets)
                  FilterChipX(
                    label: w.name,
                    selected: _selectedWallet?.id == w.id,
                    onTap: () => setState(() => _selectedWallet = w),
                  ),
              ],
            ),
          ],
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
  final Goal? goal;
  const AddGoalPage({super.key, required this.userId, this.goal});

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
    final goal = widget.goal;
    if (goal != null) {
      _nameController.text = goal.name;
      _targetController.text = goal.targetAmount.toString();
      if (goal.targetDate != null) {
        final days = DateTime.fromMillisecondsSinceEpoch(goal.targetDate!)
            .difference(DateTime.now())
            .inDays;
        _daysController.text = (days < 0 ? 0 : days).toString();
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
      final goal = Goal(
        id: widget.goal?.id ?? '',
        userId: widget.userId,
        name: name,
        targetAmount: target,
        savedAmount: widget.goal?.savedAmount ?? 0,
        targetDate: targetDate,
        status: widget.goal?.status ?? 'active',
        createdAt: widget.goal?.createdAt ?? now,
        updatedAt: now,
      );
      if (widget.goal == null) {
        await context.read<MoreProvider>().addGoal(widget.userId, goal);
      } else {
        await context
            .read<MoreProvider>()
            .updateGoal(widget.userId, widget.goal!.id, goal);
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
        title: widget.goal == null ? 'Tạo mục tiêu tiết kiệm' : 'Sửa mục tiêu',
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
                        widget.goal == null ? 'Tạo mục tiêu' : 'Lưu thay đổi',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
