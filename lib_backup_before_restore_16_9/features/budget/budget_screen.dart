import 'dart:math' as math;
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
import '../goal/goal_screen.dart';

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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                          borderRadius: BorderRadius.circular(14)),
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
                          borderRadius: BorderRadius.circular(14)),
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
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F7FA),
      body: AmbientFloatingBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
            children: [
              // 1. Warm Hero Card: "Chi tiêu có kế hoạch", Gauge bán nguyệt, Đã dùng / Hạn mức
              _buildPlannedSpendingHeroCard(
                totalLimit: totalLimit,
                totalSpent: totalSpent,
                remaining: remaining,
                progress: progress,
                month: now.month,
                year: now.year,
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              // 2. Member filter pill (Tất cả | Chồng | Vợ)
              _buildMemberSegmentedControl(isDark: isDark, height: 38),
              const SizedBox(height: 20),

              // 3. Phong bì tháng này (Envelope List)
              _buildEnvelopeSection(
                items: effectiveItems,
                isDark: isDark,
              ),
              const SizedBox(height: 6),

              // 4. Highlight Card "BẠN CÓ THỂ CHI TRUNG BÌNH"
              _buildDailyAverageCard(
                remaining: remaining,
                now: now,
                isDark: isDark,
              ),

              // 5. Motivational Goal Banner
              _buildGoalBanner(isDark),
            ],
          ),
        ),
      ),
    );
  }

  /// Bộ lọc thành viên (Hình 2): Tất cả | Chồng | Vợ
  Widget _buildMemberSegmentedControl(
      {required bool isDark, double height = 44}) {
    const members = ['all', 'husband', 'wife'];
    return BouncyPillTabs(
      labels: const ['Tất cả', 'Chồng', 'Vợ'],
      selectedIndex: members.indexOf(_memberFilter),
      colors: const [Color(0xFF005FEA), Color(0xFF173B70), Color(0xFFDB2777)],
      height: height,
      onChanged: (i) => setState(() => _memberFilter = members[i]),
    );
  }

  Widget _buildGoalBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.32),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => GoalScreen(userId: widget.userId)),
          ),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.stars_rounded, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tiết kiệm nhiều hơn, Mơ lớn hơn',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Thiết lập mục tiêu và xem tiến độ tích lũy',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Hero Card "Chi tiêu có kế hoạch" chuẩn giao diện tham chiếu
  Widget _buildPlannedSpendingHeroCard({
    required int totalLimit,
    required int totalSpent,
    required int remaining,
    required double progress,
    required int month,
    required int year,
    required bool isDark,
  }) {
    final monthStr = '${month.toString().padLeft(2, '0')} / $year';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF231A12),
                  const Color(0xFF1E160F),
                  const Color(0xFF18120B),
                ]
              : [
                  const Color(0xFFFFFBF2),
                  const Color(0xFFFDF3DF),
                  const Color(0xFFF8E7CD),
                ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? const Color(0xFF3F301F) : const Color(0xFFF0DFCB),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFFD4B48A))
                .withValues(alpha: isDark ? 0.35 : 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tiêu đề + Nút thêm (+)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (Navigator.canPop(context)) ...[
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 42,
                    height: 42,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2218) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF4A3A28)
                            : const Color(0xFFEADBCA),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: isDark ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                ),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chi tiêu có kế hoạch',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'THÁNG $monthStr',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark
                            ? const Color(0xFFB8A490)
                            : const Color(0xFF8C7D6A),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _openAdd,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2218) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF4A3A28)
                          : const Color(0xFFEADBCA),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 22,
                    color: isDark ? Colors.white : const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 2. Đồng hồ bán nguyệt (Semi-circular Gauge)
          Center(
            child: SizedBox(
              width: 230,
              height: 130,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  CustomPaint(
                    size: const Size(230, 130),
                    painter: _SemiCircleGaugePainter(
                      progress: progress,
                      trackColor: isDark
                          ? const Color(0xFF3A2D1F)
                          : const Color(0xFFF1E2C8),
                      progressColor: const Color(0xFFD97706),
                      strokeWidth: 15,
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              NumberFormat('#,##0', 'vi_VN').format(remaining),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'đ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationThickness: 1.5,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Còn lại trong ngân sách',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFFB8A490)
                                : const Color(0xFF786B5A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 3. Tóm tắt Đã dùng & Hạn mức
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark
                          ? const Color(0xFFB8A490)
                          : const Color(0xFF786B5A),
                    ),
                    children: [
                      const TextSpan(text: 'Đã dùng '),
                      TextSpan(
                        text: _formatCompactMillion(totalSpent),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark
                          ? const Color(0xFFB8A490)
                          : const Color(0xFF786B5A),
                    ),
                    children: [
                      const TextSpan(text: 'Hạn mức '),
                      TextSpan(
                        text: _formatCompactMillion(totalLimit),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Định dạng tiền triệu gọn gàng (ví dụ: 12,4 triệu, 20 triệu)
  String _formatCompactMillion(num amount) {
    if (amount == 0) return '0 triệu';
    final inMillions = amount / 1000000.0;
    if (inMillions >= 1) {
      if (inMillions == inMillions.roundToDouble()) {
        return '${inMillions.toInt()} triệu';
      }
      final str = inMillions.toStringAsFixed(1).replaceAll('.', ',');
      return '$str triệu';
    } else if (amount >= 1000) {
      return '${NumberFormat('#,##0', 'vi_VN').format(amount)} đ';
    } else {
      return '${amount.toInt()} đ';
    }
  }

  /// Danh sách "Phong bì tháng này" chuẩn thiết kế tham chiếu
  Widget _buildEnvelopeSection({
    required List<BudgetSpentData> items,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề & Gợi ý AI
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Phong bì tháng này',
              style: TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: _isAnalyzingAi ? null : _analyzeBudgetsWithAi,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: _isAnalyzingAi
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Gợi ý AI',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        if (items.isEmpty)
          _buildEmptyEnvelopeState(isDark)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildEnvelopeRow(items[index], isDark);
            },
          ),
      ],
    );
  }

  /// Hàng phong bì đơn lẻ với outline icon và thanh tiến trình bo tròn
  Widget _buildEnvelopeRow(BudgetSpentData item, bool isDark) {
    final outlineIcon = _getOutlineCategoryIcon(
      item.budget.categoryName,
      item.budget.categoryIcon,
    );
    final barColor = _getEnvelopeColor(item.budget.categoryName, item.progress);
    final remain = item.budget.limitAmount - item.spentAmount;
    final isExceeded = remain < 0;
    final isNearLimit = !isExceeded && item.progress >= 0.8;

    return InkWell(
      onTap: () => _showCategoryHistory(item),
      onLongPress: () => _openEnvelopeActions(item),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dòng trên: Icon outline + Tên danh mục & Số tiền chi/hạn mức
            Row(
              children: [
                Icon(
                  outlineIcon,
                  size: 20,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF475569),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.budget.categoryName,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${NumberFormat('#,##0', 'vi_VN').format(item.spentAmount)} / ${NumberFormat('#,##0', 'vi_VN').format(item.budget.limitAmount)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Thanh tiến trình mỏng bo tròn
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: item.progress.clamp(0.0, 1.0),
                minHeight: 5.5,
                backgroundColor:
                    isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),

            // Cảnh báo gần chạm hạn mức / vượt hạn mức chuẩn giao diện tham chiếu
            if (isNearLimit || isExceeded) ...[
              const SizedBox(height: 6),
              Text(
                isExceeded
                    ? 'Vượt hạn mức ${NumberFormat('#,##0', 'vi_VN').format(remain.abs())} đ'
                    : 'Còn ${NumberFormat('#,##0', 'vi_VN').format(remain)} đ • Gần chạm hạn mức',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isExceeded
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFC2410C),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Popup tùy chọn Sửa / Xóa khi người dùng nhấn giữ phong bì
  void _openEnvelopeActions(BudgetSpentData item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined,
                    color: Color(0xFF005FEA)),
                title: Text('Chỉnh sửa hạn mức "${item.budget.categoryName}"'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openEdit(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444)),
                title: Text('Xóa ngân sách "${item.budget.categoryName}"'),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteBudget(item);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Biểu tượng outline tương ứng từng nhóm danh mục theo mẫu ảnh
  IconData _getOutlineCategoryIcon(String categoryName, String? iconName) {
    final name = categoryName.toLowerCase();
    if (name.contains('ăn') ||
        name.contains('uống') ||
        name.contains('food') ||
        name.contains('nhà hàng') ||
        name.contains('cà phê') ||
        name.contains('cafe')) {
      return Icons.restaurant_outlined;
    }
    if (name.contains('sắm') ||
        name.contains('shop') ||
        name.contains('chợ') ||
        name.contains('siêu thị')) {
      return Icons.shopping_bag_outlined;
    }
    if (name.contains('chuyển') ||
        name.contains('xe') ||
        name.contains('xăng') ||
        name.contains('travel') ||
        name.contains('car') ||
        name.contains('đi lại')) {
      return Icons.directions_car_outlined;
    }
    if (name.contains('nhà') ||
        name.contains('điện') ||
        name.contains('nước') ||
        name.contains('bill')) {
      return Icons.home_outlined;
    }
    if (name.contains('học') || name.contains('sách') || name.contains('edu')) {
      return Icons.school_outlined;
    }
    if (name.contains('sức khỏe') ||
        name.contains('y tế') ||
        name.contains('thuốc') ||
        name.contains('health')) {
      return Icons.favorite_border_rounded;
    }
    if (name.contains('giải trí') ||
        name.contains('game') ||
        name.contains('phim')) {
      return Icons.sports_esports_outlined;
    }
    return Icons.folder_open_outlined;
  }

  /// Màu thanh tiến trình phong bì: Ăn uống (vàng hổ phách), Mua sắm (đỏ đất nung), Di chuyển (xanh ngọc)
  Color _getEnvelopeColor(String categoryName, double progress) {
    if (progress >= 1.0) return const Color(0xFFEF4444);
    final name = categoryName.toLowerCase();
    if (name.contains('ăn') || name.contains('uống')) {
      return const Color(0xFFD97706); // Warm Ochre
    }
    if (name.contains('sắm') || name.contains('shop')) {
      return const Color(0xFFC2410C); // Terracotta
    }
    if (name.contains('chuyển') ||
        name.contains('xe') ||
        name.contains('đi lại')) {
      return const Color(0xFF0D9488); // Teal
    }
    if (progress >= 0.8) return const Color(0xFFF59E0B);
    return const Color(0xFF005FEA);
  }

  /// Trạng thái trống khi chưa tạo ngân sách
  Widget _buildEmptyEnvelopeState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 40,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 10),
          Text(
            'Chưa có phong bì chi tiêu nào',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tạo các phong bì như Ăn uống, Mua sắm, Di chuyển để quản lý kế hoạch chi tiêu dễ dàng.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color:
                  isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _openAdd,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Thêm phong bì'),
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _initDemoEnvelopes,
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: const Text('Tạo mẫu chuẩn'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  shape: const StadiumBorder(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Khởi tạo mẫu phong bì chi tiêu chuẩn (Ăn uống 5M, Mua sắm 4M, Di chuyển 2M)
  Future<void> _initDemoEnvelopes() async {
    final now = DateTime.now();
    final monthKey = currentMonthKey();
    final categories = context.read<MoreProvider>().categories;

    final demoItems = [
      {'name': 'Ăn uống', 'amount': 5000000, 'icon': 'restaurant'},
      {'name': 'Mua sắm', 'amount': 4000000, 'icon': 'shopping_bag'},
      {'name': 'Di chuyển', 'amount': 2000000, 'icon': 'directions_car'},
    ];

    for (final demo in demoItems) {
      final name = demo['name'] as String;
      final amount = demo['amount'] as int;
      final matchCat = categories.where(
        (c) => c.name.toLowerCase().contains(name.toLowerCase()),
      );
      final catId = matchCat.isNotEmpty ? matchCat.first.id : '';

      final budget = Budget(
        id: 'budget_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(9999)}',
        userId: widget.userId,
        categoryId: catId,
        categoryName: name,
        categoryIcon: demo['icon'] as String,
        categoryColor: '#D97706',
        limitAmount: amount,
        monthKey: monthKey,
        isRecurring: true,
        isArchived: false,
        alertThreshold: 80,
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      );
      await context
          .read<BudgetProvider>()
          .addBudget(widget.userId, budget);
    }
  }

  /// Thẻ "BẠN CÓ THỂ CHI TRUNG BÌNH" chuẩn thiết kế tham chiếu
  Widget _buildDailyAverageCard({
    required int remaining,
    required DateTime now,
    required bool isDark,
  }) {
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = math.max(1, lastDayOfMonth - now.day + 1);
    final dailyAverage =
        remaining > 0 ? (remaining / remainingDays).round() : 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF64748B))
                .withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BẠN CÓ THỂ CHI TRUNG BÌNH',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isDark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                NumberFormat('#,##0', 'vi_VN').format(dailyAverage),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'đ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationThickness: 1.5,
                  color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/ ngày còn lại',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// CustomPainter vẽ thước đo bán nguyệt 180 độ (từ góc 180° theo chiều kim đồng hồ)
class _SemiCircleGaugePainter extends CustomPainter {
  final double progress; // 0.0 đến 1.0
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _SemiCircleGaugePainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    this.strokeWidth = 15.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, radius + strokeWidth / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Vòng cung nền (nửa trên: từ pi đến 2*pi, tức 180 độ)
    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      trackPaint,
    );

    // Vòng cung tiến trình đã chi tiêu
    final clampedProgress = progress.clamp(0.0, 1.0);
    final sweepAngle = math.pi * clampedProgress;
    if (sweepAngle > 0.005) {
      canvas.drawArc(
        rect,
        math.pi,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SemiCircleGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
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

