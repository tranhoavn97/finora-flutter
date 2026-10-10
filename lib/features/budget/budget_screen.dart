import '../../core/widgets/finora_summary_card.dart';
import '../../core/widgets/ai_context_button.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/utils/date_filter.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/premium_widgets.dart';
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
import '../../core/widgets/studio_progress.dart';

/// Trang Quản lý Ngân sách chuẩn theo Hình 2:
/// - Top Bar: Nút back tròn, Tiêu đề "Quản lý ngân sách", Nút thêm (+) tròn
/// - Bộ chọn thành viên dạng segmented pill: Tất cả | Chồng | Vợ
/// - Hero Card cam hoàng hôn (Hạn mức tháng, Gauge tròn % đã dùng, Tổng ngân sách, Đã chi tiêu, Còn lại khả dụng, Thanh tiến trình phát sáng)
/// - Danh sách thẻ ngân sách danh mục: Icon pastel, tên danh mục, icon bút chì sửa, icon thùng rác xóa, số tiền đã chi / hạn mức, % hoàn thành và vạch tiến độ
class BudgetScreen extends StatefulWidget {
  final String userId;
  const BudgetScreen({super.key, required this.userId});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
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
      ScaffoldMessenger.of(context).showSnackBar(
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
        ScaffoldMessenger.of(context).showSnackBar(
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
    final provider = context.watch<BudgetProvider>();
    final txProv = context.watch<TransactionProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);

    final allTxs = txProv.transactions;
    final now = DateTime.now();
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

    final totalLimit =
        effectiveItems.fold<int>(0, (sum, e) => sum + e.budget.limitAmount);
    final totalSpent =
        effectiveItems.fold<int>(0, (sum, e) => sum + e.spentAmount);
    final remaining = totalLimit - totalSpent;
    final progress =
        totalLimit == 0 ? 0.0 : (totalSpent / totalLimit).clamp(0.0, 1.0);

    return GlassScaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassTopBar(
        title: 'Quản lý ngân sách',
        showBottomDivider: false,
        onBack: () => Navigator.of(context).maybePop(),
        actions: [AiContextButton(userId: widget.userId, screen: 'Ngân sách')],
      ),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // 1. Thẻ tổng quan ngân sách Hero Card (Cuộn tự nhiên theo danh sách chuẩn Apple/Revolut)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                GlassScaffold.topInset(context, 8),
                16,
                8,
              ),
              child: _buildOrangeHeroCard(
                totalLimit: totalLimit,
                totalSpent: totalSpent,
                remaining: remaining,
                progress: progress,
                month: now.month,
                year: now.year,
                isDark: isDark,
              ),
            ),
          ),

          // 2. Thanh công cụ (Bộ lọc thành viên + Nút AI + Nút Thêm)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMemberSegmentedControl(isDark: isDark),
                  ),
                  const SizedBox(width: 8),
                  _buildAiAnalyzeButton(isDark: isDark),
                  const SizedBox(width: 8),
                  _buildAddBudgetButton(isDark: isDark),
                ],
              ),
            ),
          ),
          if (effectiveItems.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding:
                      const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  alignment: Alignment.center,
                  decoration: studio?.getCardDecoration(
                        isDark: isDark,
                        radius: studio.getCardRadius(),
                      ) ??
                      BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                      Icon(
                        Icons.pie_chart_outline_rounded,
                        size: 40,
                        color: isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chưa có ngân sách nào trong tháng',
                        style: TextStyle(
                          color:
                              isDark ? Colors.white70 : const Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _openAdd,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEA580C),
                            borderRadius: BorderRadius.circular(100),
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
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.30),
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
              const SizedBox(width: 4),
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

  /// Hero Card Cam Hoàng Hôn chuẩn Hình 2
  Widget _buildOrangeHeroCard({
    required int totalLimit,
    required int totalSpent,
    required int remaining,
    required double progress,
    required int month,
    required int year,
    required bool isDark,
  }) {
    final pct = (progress * 100).round();
    final badgeLabel = pct <= 75
        ? 'An toàn ($pct%)'
        : (pct <= 95 ? 'Cảnh báo ($pct%)' : 'Bội chi ($pct%)');
    final badgeCol = pct <= 75
        ? const Color(0xFF34C759)
        : (pct <= 95 ? const Color(0xFFFF9500) : const Color(0xFFFF3B30));
    return FinoraSummaryCard(
        title: 'NGÂN SÁCH THÁNG ${month.toString().padLeft(2, '0')}/$year',
        amount: totalLimit,
        icon: Icons.pie_chart_outline_rounded,
        accent: badgeCol,
        subtitle: 'Hạn mức chi tiêu kế hoạch trong kỳ',
        badgeText: badgeLabel,
        badgeColor: badgeCol,
        progress: progress,
        metricColors: const [Color(0xFFFF3B30), Color(0xFF34C759)],
        metrics: [('Đã chi tiêu', totalSpent), ('Còn lại', remaining)]);
  }

  /// Thẻ ngân sách từng danh mục chuẩn Theme Studio
  Widget _buildCategoryBudgetCard({
    required BudgetSpentData item,
    required int index,
    required bool isDark,
  }) {
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final cardRadius = studio?.getCardRadius() ?? 20.0;
    final cardPadding =
        studio != null ? studio.getCardPadding(studio.globalDensity) : 15.0;

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
    final progress = item.progress.clamp(0.0, 1.0);
    final percent = (item.progress * 100).round();
    final remain = item.budget.limitAmount - item.spentAmount;
    final isExceeded = remain < 0;

    // Màu theo tỷ lệ chi tiêu:
    // >= 100%: đỏ
    // >= 80%: cam/vàng
    // < 80%: xanh lục / màu chủ đạo theme
    final Color statusColor;
    if (item.progress >= 1.0) {
      statusColor = const Color(0xFFEF4444);
    } else if (item.progress >= 0.8) {
      statusColor = const Color(0xFFF59E0B);
    } else {
      statusColor = studio?.primaryColor ?? const Color(0xFF10B981);
    }

    final cardDecoration = studio?.getCardDecoration(
          isDark: isDark,
          radius: cardRadius,
        ) ??
        BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(
            color: isDark
                ? const Color(0xFF334155).withValues(alpha: 0.8)
                : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        );

    final effectiveBlur = studio?.glassBlur ?? 18.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          if (cardDecoration.boxShadow != null) ...cardDecoration.boxShadow!,
          if (studio != null) ...studio.getGlowShadows(isDark),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius),
        child: BackdropFilter(
          filter:
              ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
          child: InkWell(
            onTap: () => _showCategoryHistory(item),
            borderRadius: BorderRadius.circular(cardRadius),
            child: Container(
              padding: EdgeInsets.all(cardPadding),
              decoration: BoxDecoration(
                color: studio?.getCardFillColor(isDark) ?? cardDecoration.color,
                borderRadius: BorderRadius.circular(cardRadius),
                border: studio?.getCardBorder(isDark) ?? cardDecoration.border,
              ),
              child: Column(
                children: [
                  // Dòng 1: Icon + Tên danh mục + Badge phần trăm + Menu 3 chấm
                  Row(
                    children: [
                      // Icon danh mục chuẩn Liquid Glass Badge
                      CategoryIconBadge(
                        icon: categoryIcon,
                        categoryName: categoryName,
                        size: 44,
                        color: BankIconRegistry.parseThemeColor(
                          categoryColor,
                          fallback: statusColor,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Tên danh mục & Badge trạng thái
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              categoryName,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                fontSize: 15.5 * (studio?.fontScale ?? 1.0),
                                fontWeight: FontWeight.w800,
                                fontFamily: studio?.fontFamilyName,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(
                                    alpha: isDark ? 0.20 : 0.09),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                '$percent% • ${isExceeded ? "Vượt hạn mức" : (percent >= 80 ? "Gần chạm mức" : "Trong kiểm soát")}',
                                style: TextStyle(
                                  fontSize: 10.5 * (studio?.fontScale ?? 1.0),
                                  fontWeight: FontWeight.w700,
                                  fontFamily: studio?.fontFamilyName,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Nút 3 chấm thay cho nút sửa và xoá
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.more_vert_rounded,
                          size: 20,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
                                    size: 16, color: Color(0xFF005FEA)),
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
                                    size: 16, color: Color(0xFFEF4444)),
                                SizedBox(width: 8),
                                Text('Xóa ngân sách',
                                    style: TextStyle(color: Color(0xFFEF4444))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Đường hairline phân cách
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Divider(
                      height: 1,
                      thickness: 0.8,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),

                  // Dòng 2: Chi tiết số tiền: Đã chi / Hạn mức & Còn lại
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đã chi / Hạn mức',
                            style: TextStyle(
                              fontSize: 11 * (studio?.fontScale ?? 1.0),
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                              fontFamily: studio?.fontFamilyName,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${studio?.formatCurrency(item.spentAmount) ?? formatVND(item.spentAmount)} / ${studio?.formatCurrency(item.budget.limitAmount) ?? formatVND(item.budget.limitAmount)}',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              fontSize: 14 * (studio?.fontScale ?? 1.0),
                              fontWeight: FontWeight.w800,
                              fontFamily: studio?.fontFamilyName,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isExceeded ? 'Vượt hạn mức' : 'Còn lại khả dụng',
                            style: TextStyle(
                              fontSize: 11 * (studio?.fontScale ?? 1.0),
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                              fontFamily: studio?.fontFamilyName,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${isExceeded ? '-' : ''}${studio?.formatCurrency(remain.abs()) ?? formatVND(remain.abs())}',
                            style: TextStyle(
                              color: isExceeded
                                  ? const Color(0xFFEF4444)
                                  : (isDark
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFF059669)),
                              fontSize: 14.5 * (studio?.fontScale ?? 1.0),
                              fontWeight: FontWeight.w900,
                              fontFamily: studio?.fontFamilyName,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 11),

                  // Dòng 3: Vạch tiến độ gradient bo tròn tinh tế
                  StudioBudgetProgress(
                    progress: progress,
                    height: 5.5,
                    color: statusColor,
                    trackColor: isDark
                        ? const Color(0xFF334155).withValues(alpha: 0.45)
                        : const Color(0xFFE2E8F0).withValues(alpha: 0.70),
                    style: studio?.budgetStyle ?? AppBudgetStyle.liquidBar,
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
          DropdownButtonFormField<Category>(
            initialValue: _selectedCategory,
            decoration: InputDecoration(
              filled: true,
              fillColor:
                  isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            hint: const Text('Chọn một danh mục...'),
            items: categories.map((c) {
              return DropdownMenuItem<Category>(
                value: c,
                child: Row(
                  children: [
                    CategoryIconWidget(
                      icon: c.icon,
                      categoryName: c.name,
                      size: 28,
                      color: BankIconRegistry.parseThemeColor(c.color),
                    ),
                    const SizedBox(width: 9),
                    Expanded(child: Text(c.name)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedCategory = val),
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
            inputFormatters: [DotSeparatorTextInputFormatter()],
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
