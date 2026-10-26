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

  void _openDeposit(Goal goal) {
    showDialog(
      context: context,
      builder: (_) => _DepositDialog(userId: widget.userId, goal: goal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final provider = context.watch<MoreProvider>();
    final goals =
        provider.goals.where((g) => g.status == 'active').toList();

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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
            child: GlassCard(
              highlighted: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TỔNG TÍCH LŨY TIẾT KIỆM',
                      style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Text(formatVND(totalSaved),
                      style: AppTypography.largeTitle.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Mục tiêu tổng: ${formatVND(totalTarget)}',
                      style: AppTypography.caption2.copyWith(color: secondaryTextColor)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text('MỤC TIÊU HOẠT ĐỘNG',
                style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
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
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                    itemCount: goals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) {
                      final goal = goals[i];
                      return _GoalRow(
                        key: ValueKey(goal.id),
                        goal: goal,
                        onDeposit: () => _openDeposit(goal),
                        onDelete: () async {
                          final confirm = await showConfirmDeleteDialog(
                            context: context,
                            title: 'Xóa mục tiêu?',
                            content: 'Bạn có chắc chắn muốn xóa mục tiêu "${goal.name}" không?',
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
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

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
                        constraints: const BoxConstraints(
                            minWidth: 28, minHeight: 28),
                        icon: const Icon(Icons.add,
                            color: AppColors.success, size: 20),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: onDelete,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 28, minHeight: 28),
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
                  style: AppTypography.caption2.copyWith(color: secondaryTextColor)),
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
              backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFF5B942)),
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
    final amount = int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

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
          Text('Gửi tiền tiết kiệm',
              style: AppTypography.subhead.copyWith(color: primaryTextColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
              'Mục tiêu: ${widget.goal.name}\nCòn thiếu: ${formatVND(remaining)}',
              style: AppTypography.body.copyWith(
                  color: primaryTextColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          Text('Số tiền tích lũy',
              style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.xs),
          GlassTextField(
            controller: _amountController,
            hint: '0 ₫',
            keyboardType: TextInputType.number,
          ),
          if (wallets.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Trích tiền từ ví',
                style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
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
                      style: AppTypography.buttonLabel.copyWith(color: secondaryTextColor)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryButton(
                  expand: true,
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
  const AddGoalPage({super.key, required this.userId});

  @override
  State<AddGoalPage> createState() => _AddGoalPageState();
}

class _AddGoalPageState extends State<AddGoalPage> {
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _daysController = TextEditingController();
  bool _isSaving = false;

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
    final target = int.tryParse(_targetController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (name.isEmpty || target <= 0) return;

    setState(() => _isSaving = true);
    
    try {
      final daysStr = _daysController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final days = daysStr.isEmpty ? null : int.tryParse(daysStr);
      final now = DateTime.now().millisecondsSinceEpoch;
      final targetDate =
          days != null ? now + days * 24 * 60 * 60 * 1000 : null;
      final goal = Goal(
        userId: widget.userId,
        name: name,
        targetAmount: target,
        savedAmount: 0,
        targetDate: targetDate,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );
      await context.read<MoreProvider>().addGoal(widget.userId, goal);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return GlassScaffold(
      appBar: GlassTopBar(
        title: 'Tạo mục tiêu tiết kiệm',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.lg),
              children: [
                Text('Tên mục tiêu',
                    style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                GlassTextField(
                  controller: _nameController,
                  hint: 'Ví dụ: Quỹ dự phòng, Mua xe máy...',
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Số tiền mục tiêu (VND)',
                    style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                GlassTextField(
                  controller: _targetController,
                  hint: '0 ₫',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Thời gian thực hiện (số ngày, tùy chọn)',
                    style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
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
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
              child: PrimaryButton(
                expand: true,
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Tạo mục tiêu',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
