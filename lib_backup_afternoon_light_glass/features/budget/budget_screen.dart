import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/date_filter.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../../data/models/category.dart';
import '../../data/models/finance_models.dart';
import '../../state/budget_provider.dart';
import '../transaction/transaction_history_sheet.dart';

/// Parses a "#RRGGBB" / "#AARRGGBB" hex string into a [Color], or null.
Color? _parseHexColor(String? hex) {
  if (hex == null) return null;
  var clean = hex.trim().replaceFirst('#', '');
  if (clean.length == 6) clean = 'FF$clean';
  if (clean.length != 8) return null;
  final value = int.tryParse(clean, radix: 16);
  if (value == null) return null;
  return Color(value);
}

Color _meterColor(double progress) {
  if (progress > 0.9) return AppColors.error;
  if (progress > 0.7) return const Color(0xFFF5B942);
  return AppColors.success;
}

/// Budget management page — monthly limits vs. spending per category.
class BudgetScreen extends StatefulWidget {
  final String userId;
  const BudgetScreen({super.key, required this.userId});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  StreamSubscription<String>? _eventsSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<BudgetProvider>();
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
      builder: (_) => AddBudgetPage(userId: widget.userId),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final provider = context.watch<BudgetProvider>();
    final data = provider.budgetsWithSpent;

    final totalLimit = data.fold<int>(0, (s, d) => s + d.budget.limitAmount);
    final totalSpent = data.fold<int>(0, (s, d) => s + d.spentAmount);
    final totalProgress =
        totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0.0;
    final summaryColor = _meterColor(totalProgress);

    final now = DateTime.now();
    final monthLabel =
        '${now.month.toString().padLeft(2, '0')}/${now.year}';

    return GlassScaffold(
      appBar: GlassTopBar(
        title: 'Quản lý ngân sách',
        onBack: () => Navigator.of(context).pop(),
        actions: [
          IconButton(
            onPressed: _openAdd,
            icon: Icon(Icons.add, color: AppColors.accent),
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
                  Text('Tháng $monthLabel',
                      style: AppTypography.caption1.copyWith(color: secondaryTextColor)),
                  const SizedBox(height: 4),
                  Text('Tổng ngân sách: ${formatVND(totalLimit)}',
                      style: AppTypography.title2.copyWith(color: primaryTextColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Đã dùng: ${formatVND(totalSpent)}',
                          style: AppTypography.caption2.copyWith(color: secondaryTextColor)),
                      Text('${(totalProgress * 100).toInt()}%',
                          style: AppTypography.caption2.copyWith(
                              color: summaryColor,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: LinearProgressIndicator(
                      value: totalProgress.toDouble(),
                      minHeight: 6,
                      backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(summaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: data.isEmpty
                ? Center(
                    child: EmptyState(
                      icon: Icons.account_balance_wallet,
                      title: 'Chưa thiết lập ngân sách nào',
                      subtitle:
                          'Thiết lập hạn mức chi tiêu để kiểm soát dòng tiền tốt hơn.',
                      actionText: '+ Thêm ngân sách',
                      onAction: _openAdd,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 40),
                    itemCount: data.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) {
                      final item = data[i];
                      return _BudgetRow(
                        key: ValueKey(item.budget.id),
                        data: item,
                        userId: widget.userId,
                        onDelete: () async {
                          final confirm = await showConfirmDeleteDialog(
                            context: context,
                            title: 'Xóa ngân sách?',
                            content: 'Bạn có chắc chắn muốn xóa ngân sách này không?',
                          );
                          if (confirm && context.mounted) {
                            context
                                .read<BudgetProvider>()
                                .deleteBudget(widget.userId, item.budget.id);
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

class _BudgetRow extends StatelessWidget {
  final BudgetSpentData data;
  final String userId;
  final VoidCallback onDelete;
  const _BudgetRow({super.key, required this.data, required this.userId, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final budget = data.budget;
    final progress = data.progress.clamp(0.0, 1.0);
    final meterColor = _meterColor(data.progress);
    final tint =
        _parseHexColor(budget.categoryColor) ?? AppColors.success;

    return GlassCard(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => FractionallySizedBox(
            heightFactor: 0.85,
            child: TransactionHistorySheet(
              userId: userId,
              categoryId: budget.categoryId,
              categoryName: budget.categoryName,
            ),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconBadge(
            emoji: CategoryIconHelper.resolveIcon(
                budget.categoryIcon ?? budget.categoryName),
            tint: tint,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(budget.categoryName,
                          style: AppTypography.body.copyWith(
                              color: primaryTextColor,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
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
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                          '${formatVND(data.spentAmount)} / ${formatVND(budget.limitAmount)}',
                          style: AppTypography.caption2
                              .copyWith(color: secondaryTextColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Text('${(progress * 100).toInt()}%',
                        style: AppTypography.caption2.copyWith(
                            color: meterColor,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: LinearProgressIndicator(
                    value: progress.toDouble(),
                    minHeight: 6,
                    backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(meterColor),
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

/// Full-screen form to set a new budget for an expense category.
class AddBudgetPage extends StatefulWidget {
  final String userId;
  const AddBudgetPage({super.key, required this.userId});

  @override
  State<AddBudgetPage> createState() => _AddBudgetPageState();
}

class _AddBudgetPageState extends State<AddBudgetPage> {
  final _limitController = TextEditingController();
  Category? _selectedCategory;
  bool _isRecurring = true;
  int _alertThreshold = 80;
  bool _isSaving = false;

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  List<Category> _expenseCategories(BudgetProvider provider) {
    return provider.categories
        .where((c) => c.categoryGroup == 'expense' && !c.isArchived)
        .toList();
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final limit = int.tryParse(_limitController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final cat = _selectedCategory;
    if (limit <= 0 || cat == null) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final budget = Budget(
        userId: widget.userId,
        categoryId: cat.id,
        categoryName: cat.name,
        categoryIcon: cat.icon,
        categoryColor: cat.color,
        limitAmount: limit,
        monthKey: currentMonthKey(),
        isRecurring: _isRecurring,
        alertThreshold: _alertThreshold,
        createdAt: now,
        updatedAt: now,
      );
      await context.read<BudgetProvider>().addBudget(widget.userId, budget);
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

    final provider = context.watch<BudgetProvider>();
    final categories = _expenseCategories(provider);
    _selectedCategory ??= categories.isNotEmpty ? categories.first : null;

    return GlassScaffold(
      appBar: GlassTopBar(
        title: 'Thiết lập ngân sách',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.lg),
              children: [
                Text('Chọn danh mục chi tiêu',
                    style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final cat in categories)
                      FilterChipX(
                        label: '${CategoryIconHelper.resolveIcon(cat.icon)} ${cat.name}',
                        selected: _selectedCategory?.id == cat.id,
                        onTap: () => setState(() => _selectedCategory = cat),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Hạn mức chi tối đa',
                    style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                GlassTextField(
                  controller: _limitController,
                  hint: '0 ₫',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Cảnh báo khi dùng vượt quá: $_alertThreshold%',
                    style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                SegmentedControl(
                  options: const [
                    ('50', '50%'),
                    ('80', '80%'),
                    ('90', '90%'),
                    ('100', '100%'),
                  ],
                  selected: _alertThreshold.toString(),
                  onChanged: (v) => setState(
                      () => _alertThreshold = int.tryParse(v) ?? 80),
                ),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Lặp lại hàng tháng',
                                style: AppTypography.body.copyWith(
                                    color: primaryTextColor,
                                    fontWeight: FontWeight.bold)),
                            Text('Tự động áp dụng cho các tháng tiếp theo',
                                style: AppTypography.caption2
                                    .copyWith(color: secondaryTextColor)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isRecurring,
                        activeTrackColor: AppColors.accent,
                        activeColor: Colors.white,
                        onChanged: (v) => setState(() => _isRecurring = v),
                      ),
                    ],
                  ),
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
                    : const Text('Lưu ngân sách',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
