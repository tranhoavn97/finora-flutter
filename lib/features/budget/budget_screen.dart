import '../../core/widgets/finora_notice.dart';
import '../../core/widgets/finora_mascot.dart';
import '../../core/theme/finora_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/utils/date_filter.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/bank_icon.dart';
import '../../data/models/category.dart';
import '../../data/models/finance_models.dart';
import '../../data/services/ai_service.dart';
import '../../domain/finance/finance_summary.dart';
import '../../state/budget_provider.dart';
import '../../state/more_provider.dart';
import '../../state/theme_studio_controller.dart';
import '../../state/transaction_provider.dart';
import '../transaction/transaction_history_sheet.dart';
import '../../core/widgets/finora_motion.dart';
import '../../core/widgets/finora_privacy_mask.dart';

/// Trang Quản lý Ngân sách chuẩn theo Hình 2:
/// - Top Bar: Nút back tròn, Tiêu đề "Quản lý ngân sách", Nút thêm (+) tròn
/// - Bộ chọn thành viên dạng segmented pill: Tất cả | Chồng | Vợ
/// - Hero Card cam hoàng hôn (Hạn mức tháng, Gauge tròn % đã dùng, Tổng ngân sách, Đã chi tiêu, Còn lại khả dụng, Thanh tiến trình phát sáng)
/// - Danh sách thẻ ngân sách danh mục: Icon pastel, tên danh mục, icon bút chì sửa, icon thùng rác xóa, số tiền đã chi / hạn mức, % hoàn thành và vạch tiến độ
class BudgetScreen extends StatefulWidget {
  final String userId;
  final bool isTab;
  const BudgetScreen({
    super.key,
    required this.userId,
    this.isTab = true,
  });

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Bộ lọc thành viên (Hình 2): 'all', 'husband', 'wife'
  String _memberFilter = 'all';
  bool _isAnalyzingAi = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BudgetProvider>().load(widget.userId);
        context.read<MoreProvider>().load(widget.userId);
        context.read<TransactionProvider>().load(widget.userId);
      }
    });
  }

  void _openAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddBudgetDialog(userId: widget.userId),
    );
  }

  void _openEdit(BudgetSpentData item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddBudgetDialog(
        userId: widget.userId,
        existingBudget: item.budget,
      ),
    );
  }

  void _showCategoryHistory(BudgetSpentData item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.90,
        child: TransactionHistorySheet(
          userId: widget.userId,
          categoryId: item.budget.categoryId,
          categoryName: item.budget.categoryName,
          categoryIcon: item.budget.categoryIcon,
          categoryColor: item.budget.categoryColor,
        ),
      ),
    );
  }

  Future<void> _analyzeBudgetsWithAi() async {
    if (_isAnalyzingAi) return;
    final budgetProvider = context.read<BudgetProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final budgets = budgetProvider.budgetsWithSpent;
    if (budgets.isEmpty) {
      FinoraNotice.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy tạo ít nhất một ngân sách trước.')),
      );
      return;
    }

    setState(() => _isAnalyzingAi = true);
    try {
      final suggestions = await AiService.getBudgetSuggestions(
        transactions: transactionProvider.transactions
            .map((item) => item.toMap())
            .toList(),
        categories: budgetProvider.categories
            .map((item) => {
                  'id': item.id,
                  'name': item.name,
                  'icon': item.icon,
                  'color': item.color,
                  'categoryGroup': item.categoryGroup,
                })
            .toList(),
        budgets: budgets.map((item) => item.budget.toMap()).toList(),
      );
      if (!mounted) return;
      if (suggestions.isEmpty) {
        FinoraNotice.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chưa đủ dữ liệu chi tiêu để đề xuất hạn mức phù hợp.',
            ),
          ),
        );
        return;
      }
      await _showAiBudgetSuggestions(suggestions, budgets);
    } finally {
      if (mounted) setState(() => _isAnalyzingAi = false);
    }
  }

  int? _suggestedAmount(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value.toString().replaceAll(RegExp(r'[^0-9]'), ''));
  }

  Future<void> _showAiBudgetSuggestions(
    List<dynamic> suggestions,
    List<BudgetSpentData> budgets,
  ) async {
    final applied = <String>{};
    await showFinoraGlassModalBottomSheet<void>(
      context: context,
      isExpanded: true,
      title: 'Hạn mức Finora AI đề xuất',
      subtitle: 'AI chỉ đề xuất. Bạn quyết định áp dụng từng hạn mức.',
      icon: Icons.auto_awesome_rounded,
      iconColor: const Color(0xFF005FEA),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final studio = context.watch<ThemeStudioController>();
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final raw = suggestions[index];
                if (raw is! Map) return const SizedBox.shrink();
                final suggestion = Map<String, dynamic>.from(raw);
                final categoryId = suggestion['categoryId']?.toString() ?? '';
                final match = budgets.where(
                  (item) => item.budget.categoryId == categoryId,
                );
                if (match.isEmpty) return const SizedBox.shrink();
                final item = match.first;
                final amount = _suggestedAmount(suggestion['suggestedBudget']);
                if (amount == null || amount <= 0) {
                  return const SizedBox.shrink();
                }
                final isApplied = applied.contains(categoryId);
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: studio.getCardFill(isDark),
                    borderRadius: BorderRadius.circular(studio.getCardRadius()),
                    border: isApplied
                        ? Border.all(
                            color:
                                const Color(0xFF059669).withValues(alpha: 0.3),
                          )
                        : studio.getCardBorder(isDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.budget.categoryName,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            formatVND(amount),
                            style: const TextStyle(
                              color: Color(0xFF005FEA),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        suggestion['reasoning']?.toString() ??
                            'Đề xuất dựa trên lịch sử chi tiêu gần đây.',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF64748B),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: isApplied
                                ? const Color(0xFF059669)
                                : const Color(0xFF005FEA),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  studio.getButtonRadius()),
                            ),
                          ),
                          onPressed: isApplied
                              ? null
                              : () async {
                                  final budget = item.budget;
                                  final updated = Budget(
                                    id: budget.id,
                                    userId: budget.userId,
                                    categoryId: budget.categoryId,
                                    categoryName: budget.categoryName,
                                    categoryIcon: budget.categoryIcon,
                                    categoryColor: budget.categoryColor,
                                    limitAmount: amount,
                                    monthKey: budget.monthKey,
                                    isRecurring: budget.isRecurring,
                                    isArchived: budget.isArchived,
                                    alertThreshold: budget.alertThreshold,
                                    createdAt: budget.createdAt,
                                    updatedAt:
                                        DateTime.now().millisecondsSinceEpoch,
                                  );
                                  await context
                                      .read<BudgetProvider>()
                                      .updateBudget(
                                          widget.userId, budget.id, updated);
                                  if (sheetContext.mounted) {
                                    setSheetState(
                                      () => applied.add(categoryId),
                                    );
                                  }
                                },
                          icon: Icon(isApplied
                              ? Icons.check_rounded
                              : Icons.auto_fix_high_rounded),
                          label: Text(
                              isApplied ? 'Đã áp dụng' : 'Áp dụng hạn mức này'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteBudget(BudgetSpentData item) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showFinoraGlassModalBottomSheet<bool>(
      context: context,
      title: 'Xóa ngân sách?',
      subtitle: 'Thao tác này không thể hoàn tác',
      icon: Icons.delete_outline_rounded,
      iconColor: const Color(0xFFEF4444),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hạn mức "${item.budget.categoryName}" sẽ bị xóa. Giao dịch đã ghi không bị ảnh hưởng.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FinoraPillButton(
                    label: 'Hủy bỏ',
                    onPressed: () => Navigator.pop(sheetContext, false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FinoraPillButton(
                    label: 'Xóa',
                    primary: true,
                    onPressed: () => Navigator.pop(sheetContext, true),
                  ),
                ),
              ],
            ),
          ],
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
    super.build(context);
    final provider = context.watch<BudgetProvider>();
    final txProv = context.watch<TransactionProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);

    final allTxs = txProv.transactions;
    // Tính toán số tiền đã chi theo bộ lọc thành viên
    final effectiveItems = provider.budgetsWithSpent.map((item) {
      if (_memberFilter == 'all') return item;
      int spent = 0;
      for (final t in allTxs) {
        final matchCategory = t.categoryId == item.budget.categoryId ||
            (t.categoryName != null &&
                item.budget.categoryName.isNotEmpty &&
                t.categoryName!.trim().toLowerCase() ==
                    item.budget.categoryName.trim().toLowerCase());
        final isWife = t.creatorTag == 'Vợ' ||
            t.creatorTag?.toLowerCase() == 'wife' ||
            t.ownerName?.toLowerCase() == 'vợ' ||
            t.ownerName?.toLowerCase() == 'wife' ||
            t.owner?.toLowerCase() == 'wife' ||
            t.fromOwner?.toLowerCase() == 'wife' ||
            t.paidByOwner?.toLowerCase() == 'wife' ||
            t.tags.any((tag) =>
                tag.toLowerCase() == 'vợ' || tag.toLowerCase() == 'wife');
        final matchMember = _memberFilter == 'wife' ? isWife : !isWife;
        if (FinanceSummary.isExpense(t) &&
            matchCategory &&
            matchMember &&
            monthKeyOf(t.date) == currentMonthKey()) {
          spent += t.amount;
        }
      }
      final progress =
          item.budget.limitAmount > 0 ? spent / item.budget.limitAmount : 0.0;
      return BudgetSpentData(item.budget, spent, progress);
    }).toList();

    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vùng cuộn: widget tổng quan → bộ lọc thành viên/công cụ → danh sách
          Expanded(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        16, widget.isTab ? GlassScaffold.topInset(context, 0, 44) : 0, 16, 14),
                    child: Builder(
                      builder: (context) {
                        final totalLimit = effectiveItems.fold<int>(
                            0, (sum, item) => sum + item.budget.limitAmount);
                        final totalSpent = effectiveItems.fold<int>(
                            0, (sum, item) => sum + item.spentAmount);
                        final remaining = totalLimit - totalSpent;
                        final overallProgress = totalLimit > 0
                            ? (totalSpent / totalLimit).clamp(0.0, 1.0)
                            : 0.0;
                        final percentSpent = (overallProgress * 100).round();

                        return Column(
                          children: [
                            // Monthly Budget Hero Card (Emerald Gradient)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: FinoraTokens.emeraldCardDecoration(
                                isDark: isDark,
                                radius: 24,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'NGÂN SÁCH THÁNG ${DateTime.now().month}/${DateTime.now().year}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'BeVietnamPro',
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.8,
                                            color: Color(0xFFE6F7F0),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: _openAdd,
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.18),
                                            borderRadius:
                                                BorderRadius.circular(100),
                                            border: Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: 0.25),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.add_rounded,
                                                size: 13,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 3),
                                              Text(
                                                'Thêm',
                                                style: TextStyle(
                                                  fontFamily: 'BeVietnamPro',
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Chủ động từng khoản chi.',
                                              style: TextStyle(
                                                fontFamily: 'BeVietnamPro',
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: -0.4,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Hạn mức còn lại',
                                              style: TextStyle(
                                                fontFamily: 'BeVietnamPro',
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    Colors.white.withValues(alpha: 0.80),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            FinoraPrivacyMask(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  effectiveItems.isEmpty
                                                      ? '₫ 0'
                                                      : '₫ ${formatVND(remaining).replaceAll(' đ', '').replaceAll(' ₫', '')}',
                                                  style: const TextStyle(
                                                    fontFamily: 'BeVietnamPro',
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: -0.8,
                                                    color: Colors.white,
                                                    fontFeatures: [
                                                      FontFeature.tabularFigures()
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // 3D Saving Dragon Mascot
                                      Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.16),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Image.asset(
                                          'assets/mascot/animation-keypose-02-saving.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (effectiveItems.isNotEmpty) ...[
                                    const SizedBox(height: 14),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(100),
                                      child: LinearProgressIndicator(
                                        value: overallProgress,
                                        minHeight: 8.0,
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.18),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF34D399),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            'Đã chi: ${formatVND(totalSpent)}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'BeVietnamPro',
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white
                                                  .withValues(alpha: 0.85),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Đã dùng $percentSpent%',
                                          style: const TextStyle(
                                            fontFamily: 'BeVietnamPro',
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF6EE7B7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Bộ lọc thành viên + Nút AI + Nút Thêm (đặt dưới widget)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMemberSegmentedControl(
                                      isDark: isDark, height: 40),
                                ),
                                const SizedBox(width: 8),
                                _buildAiAnalyzeButton(isDark: isDark),
                                const SizedBox(width: 8),
                                _buildAddBudgetButton(isDark: isDark),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                if (effectiveItems.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 20),
                        padding: const EdgeInsets.symmetric(
                            vertical: 28, horizontal: 20),
                        alignment: Alignment.center,
                        decoration: studio?.getCardDecoration(
                              isDark: isDark,
                              radius: studio.getCardRadius(),
                            ) ??
                            BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FinoraMascotImage(
                              pose: FinoraMascotPose.focused,
                              size: 76,
                              withGlow: true,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Chưa có ngân sách nào trong tháng',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hãy cùng mèo thần tài Finora thiết lập hạn mức chi tiêu thông minh!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: _openAdd,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 9),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF0F6E56),
                                      Color(0xFF10B981)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981)
                                          .withValues(alpha: 0.30),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  '+ Thêm ngân sách danh mục',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 130),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = effectiveItems[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: FinoraStaggeredItem(
                              index: index,
                              child: _buildCategoryBudgetCard(
                                item: item,
                                index: index,
                                isDark: isDark,
                              ),
                            ),
                          );
                        },
                        childCount: effectiveItems.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bộ lọc thành viên (Hình 2): Tất cả | Chồng | Vợ (Chuẩn hóa FinoraMemberSegmentedFilter 34px)
  Widget _buildMemberSegmentedControl(
      {required bool isDark, double height = 34}) {
    return FinoraMemberSegmentedFilter(
      selectedValue: _memberFilter,
      height: height,
      onChanged: (val) => setState(() => _memberFilter = val),
    );
  }

  Widget _buildAiAnalyzeButton({required bool isDark}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isAnalyzingAi ? null : _analyzeBudgetsWithAi,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? const [Color(0xFF0F766E), Color(0xFF14B8A6)]
                  : const [Color(0xFF0D9488), Color(0xFF2DD4BF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D9488).withValues(alpha: 0.30),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isAnalyzingAi)
                const SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              const SizedBox(width: 5),
              const Text(
                'AI gợi ý',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddBudgetButton({required bool isDark}) {
    return FinoraAddButton(
      onPressed: _openAdd,
      tooltip: 'Thêm ngân sách',
      size: 34.0,
    );
  }

  /// Thẻ ngân sách từng danh mục chuẩn Apple HIG - Hiển thị đầy đủ nội dung & số tiền sát góc phải
  Widget _buildCategoryBudgetCard({
    required BudgetSpentData item,
    required int index,
    required bool isDark,
  }) {
    final liveCategories = context.read<MoreProvider>().categories.where(
          (category) =>
              (item.budget.categoryId.isNotEmpty &&
                  category.id == item.budget.categoryId) ||
              (item.budget.categoryId.isEmpty &&
                  category.name == item.budget.categoryName),
        );
    final liveCategory = liveCategories.isEmpty ? null : liveCategories.first;
    final categoryIcon = liveCategory?.icon ?? item.budget.categoryIcon;
    final categoryName = liveCategory?.name ?? item.budget.categoryName;
    final categoryColor = liveCategory?.color ?? item.budget.categoryColor;
    final budget = item.budget;
    final spent = item.spentAmount;
    final progress = item.progress.clamp(0.0, 1.0);
    final percent = (item.progress * 100).round();
    final remaining = budget.limitAmount - spent;
    final isExceeded = spent > budget.limitAmount || item.progress >= 1.0;

    // Màu theo tỷ lệ chi tiêu chuẩn yêu cầu:
    // < 75%: Emerald #10B981
    // 75–99%: Amber #F59E0B
    // >= 100%: Rose #E11D48
    final Color statusColor;
    final String statusLabel;
    if (isExceeded || percent >= 100) {
      statusColor = const Color(0xFFE11D48);
      statusLabel = 'Vượt hạn mức';
    } else if (percent >= 75) {
      statusColor = const Color(0xFFF59E0B);
      statusLabel = 'Sắp vượt';
    } else {
      statusColor = const Color(0xFF10B981);
      statusLabel = 'An toàn';
    }

    final studio = Provider.of<ThemeStudioController?>(context, listen: false);
    final cardFill = studio?.getCardFillColor(isDark) ??
        (isDark
            ? const Color(0xFF142033).withValues(alpha: 0.88)
            : Colors.white.withValues(alpha: studio?.glassOpacity ?? 0.88));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: cardFill,
          child: InkWell(
            onTap: () => _showCategoryHistory(item),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: isDark ? 0.09 : 0.05),
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Row: Circular CategoryIconBadge (38) + Expanded (Category Name + Status Pill) + Right-pinned Spent Amount + 3-dot menu
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CategoryIconBadge(
                        icon: categoryIcon,
                        categoryName: categoryName,
                        size: 38,
                        color: BankIconRegistry.parseThemeColor(
                          categoryColor,
                          fallback: statusColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              categoryName,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(
                                      alpha: isDark ? 0.20 : 0.12),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: statusColor.withValues(alpha: 0.32),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 112),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FinoraPrivacyMask(
                                child: Text(
                                  formatVND(spent),
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: isExceeded
                                        ? const Color(0xFFE11D48)
                                        : (isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A)),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$percent% đã dùng',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 140),
                        icon: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: isDark ? 0.06 : 0.04),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.more_horiz_rounded,
                            size: 17,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onSelected: (val) {
                          if (val == 'edit') {
                            _openEdit(item);
                          } else if (val == 'delete') {
                            _confirmDeleteBudget(item);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined,
                                    size: 16, color: Color(0xFF0D9488)),
                                SizedBox(width: 8),
                                Text('Sửa ngân sách'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded,
                                    size: 16, color: Color(0xFFE11D48)),
                                SizedBox(width: 8),
                                Text('Xóa ngân sách',
                                    style: TextStyle(color: Color(0xFFE11D48))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Middle: Smooth 6px stadium-rounded progress bar with color-coded fill (<75% #10B981, 75-99% #F59E0B, >=100% #E11D48)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: isDark ? 0.08 : 0.06),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final barWidth = constraints.maxWidth * progress;
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: barWidth,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  BoxShadow(
                                    color: statusColor.withValues(
                                        alpha: isDark ? 0.38 : 0.24),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 7),

                  // Bottom Row: Left = Hạn mức: formatVND(budget.limitAmount), Right = Còn lại: formatVND(remaining) (or Vượt: formatVND(spent - budget.limitAmount) in red)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: FinoraPrivacyMask(
                              child: Text(
                                'Hạn mức: ${formatVND(budget.limitAmount)}',
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 148),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: FinoraPrivacyMask(
                              child: Text(
                                isExceeded
                                    ? 'Vượt: ${formatVND(spent - budget.limitAmount)}'
                                    : 'Còn lại: ${formatVND(remaining)}',
                                maxLines: 1,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: isExceeded
                                      ? const Color(0xFFE11D48)
                                      : (isDark
                                          ? const Color(0xFF34D399)
                                          : const Color(0xFF059669)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Modal Dialog Thêm & Chỉnh sửa Ngân sách
class _AddBudgetDialog extends StatefulWidget {
  final String userId;
  final Budget? existingBudget;
  const _AddBudgetDialog({required this.userId, this.existingBudget});

  @override
  State<_AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<_AddBudgetDialog> {
  final _amountController = TextEditingController();
  Category? _selectedCategory;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingBudget != null) {
      _amountController.text = NumberFormat('#,##0', 'vi_VN')
          .format(widget.existingBudget!.limitAmount);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final moreProvider = context.watch<MoreProvider>();
    final categories = moreProvider.categories
        .where((c) => c.categoryGroup == 'expense')
        .toList();

    if (!_isInit && widget.existingBudget != null && categories.isNotEmpty) {
      _isInit = true;
      for (final c in categories) {
        if (c.id == widget.existingBudget!.categoryId ||
            c.name.trim().toLowerCase() ==
                widget.existingBudget!.categoryName.trim().toLowerCase()) {
          _selectedCategory = c;
          break;
        }
      }
    }

    final isEdit = widget.existingBudget != null;

    return GlassBottomSheet(
      radius: 28,
      showHandle: true,
      title: isEdit ? 'Chỉnh sửa ngân sách' : 'Thêm ngân sách danh mục',
      subtitle: 'Thiết lập hạn mức chi tiêu định kỳ',
      icon: Icons.pie_chart_rounded,
      iconColor: const Color(0xFFEA580C),
      onClose: () => Navigator.pop(context),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn danh mục chi tiêu',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => Container(
                  height: MediaQuery.of(ctx).size.height * 0.65,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 8),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Text(
                              'Chọn danh mục',
                              style: TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: categories.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          ),
                          itemBuilder: (ctx, i) {
                            final c = categories[i];
                            final isSel = _selectedCategory?.id == c.id;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              leading: CategoryIconBadge(
                                icon: c.icon,
                                categoryName: c.name,
                                colorHex: c.color,
                                size: 36,
                                isDark: isDark,
                              ),
                              title: Text(
                                c.name,
                                style: TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  fontSize: 14,
                                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              trailing: isSel
                                  ? const Icon(Icons.check_circle_rounded, color: Color(0xFF00866A), size: 20)
                                  : null,
                              onTap: () {
                                setState(() => _selectedCategory = c);
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  if (_selectedCategory != null) ...[
                    CategoryIconBadge(
                      icon: _selectedCategory!.icon,
                      categoryName: _selectedCategory!.name,
                      colorHex: _selectedCategory!.color,
                      size: 34,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedCategory!.name,
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                      child: Icon(
                        Icons.category_outlined,
                        size: 18,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Chạm để chọn danh mục...',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 14,
                          color: secondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00866A).withValues(alpha: isDark ? 0.20 : 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Đổi ▾',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF34D399) : const Color(0xFF00866A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Hạn mức định mức (VNĐ)',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: const [DotSeparatorTextInputFormatter()],
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor:
                  isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              hintText: 'Ví dụ: 3.000.000 ₫',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          FinoraPillButton(
            label: isEdit ? 'Lưu thay đổi' : 'Lưu ngân sách',
            primary: true,
            icon: Icons.check_rounded,
            onPressed: () async {
              final digits =
                  _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
              final amount = int.tryParse(digits) ?? 0;
              if (amount > 0 && _selectedCategory != null) {
                final now = DateTime.now();
                final monthStr =
                    '${now.year}-${now.month.toString().padLeft(2, '0')}';
                if (isEdit) {
                  final updated = Budget(
                    id: widget.existingBudget!.id,
                    userId: widget.userId,
                    monthKey: widget.existingBudget!.monthKey.isNotEmpty
                        ? widget.existingBudget!.monthKey
                        : monthStr,
                    categoryId: _selectedCategory!.id,
                    categoryName: _selectedCategory!.name,
                    categoryIcon: _selectedCategory!.icon,
                    categoryColor: _selectedCategory!.color,
                    limitAmount: amount,
                    isRecurring: widget.existingBudget!.isRecurring,
                    isArchived: widget.existingBudget!.isArchived,
                    alertThreshold: widget.existingBudget!.alertThreshold,
                    createdAt: widget.existingBudget!.createdAt,
                    updatedAt: DateTime.now().millisecondsSinceEpoch,
                  );
                  await context.read<BudgetProvider>().updateBudget(
                      widget.userId, widget.existingBudget!.id, updated);
                } else {
                  final budget = Budget(
                    userId: widget.userId,
                    monthKey: monthStr,
                    categoryId: _selectedCategory!.id,
                    categoryName: _selectedCategory!.name,
                    categoryIcon: _selectedCategory!.icon,
                    categoryColor: _selectedCategory!.color,
                    limitAmount: amount,
                  );
                  await context
                      .read<BudgetProvider>()
                      .addBudget(widget.userId, budget);
                }
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}
