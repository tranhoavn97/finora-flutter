import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  if (progress > 0.7) return AppColors.warning;
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
    HapticFeedback.selectionClick();
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AddBudgetPage(userId: widget.userId),
    ));
  }

  void _openEdit(Budget budget) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AddBudgetPage(userId: widget.userId, budget: budget),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final provider = context.watch<BudgetProvider>();
    final data = provider.budgetsWithSpent;

    final totalLimit = data.fold<int>(0, (s, d) => s + d.budget.limitAmount);
    final totalSpent = data.fold<int>(0, (s, d) => s + d.spentAmount);
    final totalProgress =
        totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0.0;
    final summaryColor = _meterColor(totalProgress);

    final now = DateTime.now();
    final monthLabel = '${now.month.toString().padLeft(2, '0')}/${now.year}';

    return GlassScaffold(
      appBar: GlassTopBar(
        title: 'Quản lý ngân sách',
        onBack: () => Navigator.of(context).pop(),
        actions: [
          IconButton(
            onPressed: _openAdd,
            icon: const Icon(Icons.add_rounded,
                color: AppColors.primary, size: 24),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SubjectFilterPill(
                selected: provider.selectedOwner,
                onSelected: (filter) => provider.setOwnerFilter(filter),
                compact: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF9A3412),
                      Color(0xFFEA580C),
                      Color(0xFFF59E0B),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEA580C).withOpacity(0.40),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'HẠN MỨC THÁNG $monthLabel',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.white70,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.25)),
                          ),
                          child: Text(
                            '${(totalProgress * 100).toInt()}% đã dùng',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox.expand(
                                child: CircularProgressIndicator(
                                  value: totalProgress.toDouble(),
                                  strokeWidth: 7,
                                  strokeCap: StrokeCap.round,
                                  backgroundColor: Colors.white24,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    totalProgress > .9
                                        ? const Color(0xFFFDA4AF)
                                        : const Color(0xFFFDE047),
                                  ),
                                ),
                              ),
                              Text(
                                '${(totalProgress * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tổng ngân sách',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 11)),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  formatVND(totalLimit),
                                  style: const TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Đã chi tiêu',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatVND(totalSpent),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Còn lại khả dụng',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatVND(totalLimit - totalSpent),
                              style: const TextStyle(
                                color: Color(0xFFFEF08A),
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: LinearProgressIndicator(
                        value: totalProgress.toDouble().clamp(0.0, 1.0),
                        minHeight: 7,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          totalProgress > 1.0
                              ? const Color(0xFFFB7185)
                              : const Color(0xFFFDE047),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: data.isEmpty
                  ? Center(
                      child: EmptyState(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Chưa thiết lập ngân sách nào',
                        subtitle:
                            'Thiết lập hạn mức chi tiêu để kiểm soát dòng tiền tốt hơn.',
                        actionText: 'Thêm ngân sách',
                        onAction: _openAdd,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 2, 14, 20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: data.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) {
                        final item = data[i];
                        return _BudgetRow(
                          key: ValueKey(item.budget.id),
                          data: item,
                          userId: widget.userId,
                          onEdit: () => _openEdit(item.budget),
                          onDelete: () async {
                            final confirm = await showConfirmDeleteDialog(
                              context: context,
                              title: 'Xóa ngân sách?',
                              content:
                                  'Bạn có chắc chắn muốn xóa hạn mức ngân sách "${item.budget.categoryName}" không?',
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
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final BudgetSpentData data;
  final String userId;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  const _BudgetRow(
      {super.key,
      required this.data,
      required this.userId,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final budget = data.budget;
    final progress = data.progress.clamp(0.0, 1.0);
    final meterColor = _meterColor(data.progress);
    final tint = _parseHexColor(budget.categoryColor) ?? AppColors.primary;

    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () {
        HapticFeedback.selectionClick();
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
            size: 42,
            radius: 14,
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
                      child: Text(
                        budget.categoryName,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Tùy chọn ngân sách',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints.tightFor(width: 32, height: 32),
                      icon: const Icon(Icons.more_horiz_rounded, size: 21),
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                            value: 'edit', child: Text('Sửa ngân sách')),
                        PopupMenuItem(
                            value: 'delete', child: Text('Xóa ngân sách')),
                      ],
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
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        color: meterColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: LinearProgressIndicator(
                    value: progress.toDouble(),
                    minHeight: 5,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE8EEF8),
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
  final Budget? budget;
  const AddBudgetPage({super.key, required this.userId, this.budget});

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
  void initState() {
    super.initState();
    final budget = widget.budget;
    if (budget != null) {
      _limitController.text = budget.limitAmount.toString();
      _isRecurring = budget.isRecurring;
      _alertThreshold = budget.alertThreshold;
    }
  }

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
    final limit =
        int.tryParse(_limitController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
            0;
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
      if (widget.budget == null) {
        await context.read<BudgetProvider>().addBudget(widget.userId, budget);
      } else {
        await context
            .read<BudgetProvider>()
            .updateBudget(widget.userId, widget.budget!.id, budget);
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
    final c = context.fc;
    final provider = context.watch<BudgetProvider>();
    final categories = _expenseCategories(provider);
    if (_selectedCategory == null) {
      if (widget.budget == null) {
        _selectedCategory = categories.isNotEmpty ? categories.first : null;
      } else {
        for (final category in categories) {
          if (category.id == widget.budget!.categoryId) {
            _selectedCategory = category;
            break;
          }
        }
      }
    }

    return GlassScaffold(
      appBar: GlassTopBar(
        title: widget.budget == null ? 'Thiết lập ngân sách' : 'Sửa ngân sách',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  GlassCard(
                    radius: 22,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Overline('DANH MỤC CHI TIÊU'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final cat in categories)
                              FilterChipX(
                                label:
                                    '${CategoryIconHelper.resolveIcon(cat.icon)} ${cat.name}',
                                selected: _selectedCategory?.id == cat.id,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedCategory = cat);
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  GlassCard(
                    radius: 22,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Overline('HẠN MỨC CHI TỐI ĐA'),
                        const SizedBox(height: 6),
                        FinoraTextField(
                          controller: _limitController,
                          hint: '0 ₫',
                          keyboardType: TextInputType.number,
                          inputFormatters: [DotSeparatorTextInputFormatter()],
                          radius: 18,
                        ),
                        const SizedBox(height: 14),
                        Overline('CẢNH BÁO KHI VƯỢT QUÁ: $_alertThreshold%'),
                        const SizedBox(height: 6),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  GlassCard(
                    radius: 22,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lặp lại hàng tháng',
                                style: TextStyle(
                                  color: c.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tự động áp dụng cho các tháng tiếp theo',
                                style: TextStyle(
                                  color: c.textSecondary,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isRecurring,
                          activeTrackColor: AppColors.primary,
                          activeColor: Colors.white,
                          onChanged: (v) => setState(() => _isRecurring = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: PrimaryButton(
                expand: true,
                onPressed: _isSaving ? null : _submit,
                isLoading: _isSaving,
                child: const Text('Lưu ngân sách',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
