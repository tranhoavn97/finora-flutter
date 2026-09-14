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
import '../../state/transaction_provider.dart';
import '../transaction/transaction_history_sheet.dart';

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
              'Chưa nhận được đề xuất. Kiểm tra kết nối Finora AI rồi thử lại.',
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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return FractionallySizedBox(
            heightFactor: .82,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF94A3B8).withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          color: Color(0xFF005FEA)),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Hạn mức Finora AI đề xuất',
                          style: TextStyle(
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI chỉ đề xuất. Bạn quyết định áp dụng từng hạn mức.',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: suggestions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final raw = suggestions[index];
                        if (raw is! Map) return const SizedBox.shrink();
                        final suggestion = Map<String, dynamic>.from(raw);
                        final categoryId =
                            suggestion['categoryId']?.toString() ?? '';
                        final match = budgets.where(
                          (item) => item.budget.categoryId == categoryId,
                        );
                        if (match.isEmpty) return const SizedBox.shrink();
                        final item = match.first;
                        final amount =
                            _suggestedAmount(suggestion['suggestedBudget']);
                        if (amount == null || amount <= 0) {
                          return const SizedBox.shrink();
                        }
                        final isApplied = applied.contains(categoryId);
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF005FEA)
                                  .withValues(alpha: 0.18),
                            ),
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
                                    shape: const StadiumBorder(),
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
                                            alertThreshold:
                                                budget.alertThreshold,
                                            createdAt: budget.createdAt,
                                            updatedAt: DateTime.now()
                                                .millisecondsSinceEpoch,
                                          );
                                          await context
                                              .read<BudgetProvider>()
                                              .updateBudget(widget.userId,
                                                  budget.id, updated);
                                          if (sheetContext.mounted) {
                                            setSheetState(
                                              () => applied.add(categoryId),
                                            );
                                          }
                                        },
                                  icon: Icon(isApplied
                                      ? Icons.check_rounded
                                      : Icons.auto_fix_high_rounded),
                                  label: Text(isApplied
                                      ? 'Đã áp dụng'
                                      : 'Áp dụng hạn mức này'),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteBudget(BudgetSpentData item) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 28,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEF4444),
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Xóa ngân sách?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Hạn mức “${item.budget.categoryName}” sẽ bị xóa. Giao dịch đã ghi không bị ảnh hưởng.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100)),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    onPressed: () => Navigator.pop(sheetContext, false),
                    child: Text(
                      'Hủy',
                      style: TextStyle(
                        color:
                            isDark ? Colors.white70 : const Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100)),
                    ),
                    onPressed: () => Navigator.pop(sheetContext, true),
                    child: const Text(
                      'Xóa',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
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
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

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

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: AmbientFloatingBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 1. Top Bar chuẩn Hình 2 (< Quản lý ngân sách +)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    _buildRoundIconButton(
                      icon: Icons.chevron_left_rounded,
                      iconColor:
                          isDark ? Colors.white : const Color(0xFF0F172A),
                      isDark: isDark,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Quản lý ngân sách',
                            style: TextStyle(
                              color: primaryTextColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              // 2. Nội dung cuộn
              Expanded(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
                  children: [
                    // Gộp: 3 tab thành viên + Nút AI đề xuất + Nút thêm (+) thành 1 hàng gọn gàng
                    Row(
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
                    const SizedBox(height: 14),

                    // Hero Card cam hoàng hôn chuẩn Hình 2
                    _buildOrangeHeroCard(
                      totalLimit: totalLimit,
                      totalSpent: totalSpent,
                      remaining: remaining,
                      progress: progress,
                      month: now.month,
                      year: now.year,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

                    // Danh sách các thẻ ngân sách danh mục chuẩn Hình 2
                    if (effectiveItems.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 36, horizontal: 20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1E293B) : Colors.white,
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
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF64748B),
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
                      )
                    else
                      ...effectiveItems.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildCategoryBudgetCard(
                            item: entry.value,
                            index: entry.key,
                            isDark: isDark,
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoundIconButton({
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: iconColor,
        ),
      ),
    );
  }

  /// Bộ lọc thành viên (Hình 2): Tất cả | Chồng | Vợ
  Widget _buildMemberSegmentedControl({required bool isDark, double height = 44}) {
    const members = ['all', 'husband', 'wife'];
    return BouncyPillTabs(
      labels: const ['Tất cả', 'Chồng', 'Vợ'],
      selectedIndex: members.indexOf(_memberFilter),
      colors: const [Color(0xFF005FEA), Color(0xFF173B70), Color(0xFFDB2777)],
      height: height,
      onChanged: (i) => setState(() => _memberFilter = members[i]),
    );
  }

  Widget _buildAiAnalyzeButton({required bool isDark}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isAnalyzingAi ? null : _analyzeBudgetsWithAi,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              const SizedBox(width: 5),
              const Text(
                'AI gợi ý',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openAdd,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF005FEA),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF005FEA).withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
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
    final percent = (progress * 100).round();
    final monthStr = '${month.toString().padLeft(2, '0')}/$year';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFC2410C), // Burnt Orange
            Color(0xFFEA580C), // Sunset Orange
            Color(0xFFF59E0B), // Warm Amber
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withOpacity(0.38),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: HẠN MỨC THÁNG MM/YYYY & [100% đã dùng] badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HẠN MỨC THÁNG $monthStr',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$percent% đã dùng',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 2: Ring gauge % bên trái & Tổng ngân sách bên phải
          Row(
            children: [
              // Circular Percentage Gauge
              SizedBox(
                width: 62,
                height: 62,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 62,
                      height: 62,
                      child: CircularProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        strokeWidth: 4.5,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Tổng ngân sách
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng ngân sách',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatVND(totalLimit),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 3: Dual Column (Đã chi tiêu & Còn lại khả dụng)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Đã chi tiêu
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đã chi tiêu',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formatVND(totalSpent),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),

              // Còn lại khả dụng
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Còn lại khả dụng',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${remaining < 0 ? '-' : ''}${formatVND(remaining.abs())}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Thanh tiến trình phát sáng màu vàng cam ở dưới cùng
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 4.5,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFFACC15)),
            ),
          ),
        ],
      ),
    );
  }

  /// Thẻ ngân sách từng danh mục chuẩn Hình 2
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
    final progress = item.progress.clamp(0.0, 1.0);
    final percent = (item.progress * 100).round();
    final remain = item.budget.limitAmount - item.spentAmount;
    final isExceeded = remain < 0;

    // Màu theo tỷ lệ chi tiêu:
    // >= 100%: đỏ
    // >= 80%: cam/vàng
    // < 80%: xanh lục
    final Color statusColor;
    if (item.progress >= 1.0) {
      statusColor = const Color(0xFFEF4444);
    } else if (item.progress >= 0.8) {
      statusColor = const Color(0xFFF59E0B);
    } else {
      statusColor = const Color(0xFF10B981);
    }

    return InkWell(
      onTap: () => _showCategoryHistory(item),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
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
                  size: 46,
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
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
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
                              alpha: isDark ? 0.22 : 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$percent% • ${isExceeded ? "Vượt hạn mức" : (percent >= 80 ? "Gần chạm mức" : "Trong kiểm soát")}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
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
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                height: 1,
                thickness: 1,
                color: isDark
                    ? const Color(0xFF334155).withValues(alpha: 0.6)
                    : const Color(0xFFF1F5F9),
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
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatVND(item.spentAmount)} / ${formatVND(item.budget.limitAmount)}',
                      style: TextStyle(
                        color:
                            isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
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
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${isExceeded ? '-' : ''}${formatVND(remain.abs())}',
                      style: TextStyle(
                        color: isExceeded
                            ? const Color(0xFFEF4444)
                            : (isDark
                                ? const Color(0xFF34D399)
                                : const Color(0xFF059669)),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Dòng 3: Vạch tiến độ bo tròn hiện đại
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
          ],
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

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: Color(0xFFEA580C),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isEdit ? 'Chỉnh sửa ngân sách' : 'Thêm ngân sách danh mục',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: primaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
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
            value: _selectedCategory,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100)),
                elevation: 0,
              ),
              child: Text(
                isEdit ? 'Lưu thay đổi' : 'Lưu ngân sách',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
