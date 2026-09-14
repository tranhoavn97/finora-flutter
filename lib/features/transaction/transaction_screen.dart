import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/utils/date_filter.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/widgets/morph_icon.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../../data/models/transaction.dart';
import '../../state/transaction_provider.dart';
import '../../data/services/wallet_repository.dart';
import 'add_transaction_page.dart';
import 'transaction_detail_screen.dart';

/// Redesigned Transaction History Screen:
/// - Luxury Obsidian & Royal Indigo compact Spending Card (clean, elegant, non-green)
/// - Streamlined dual-badge income/expense ribbon saving vertical height
/// - Quick calendar selector right inside the card header
/// - Sleek pill search bar and high-end filter pills
/// - Date-grouped transaction list with clear tags (Husband = sky blue, Wife = pink, Wallet = purple)
class TransactionScreen extends StatefulWidget {
  final String userId;
  final String? familyId;
  final VoidCallback? onBack;

  const TransactionScreen({
    super.key,
    required this.userId,
    this.familyId,
    this.onBack,
  });

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  bool _showBalances = true;
  late final TextEditingController _searchController;
  StreamSubscription<String>? _eventsSub;

  @override
  void initState() {
    super.initState();
    final initialQuery = context.read<TransactionProvider>().searchQuery;
    _searchController = TextEditingController(text: initialQuery);
    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<TransactionProvider>();
      provider.load(widget.userId, familyId: widget.familyId);
      _eventsSub = provider.events.listen((msg) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(msg)));
      });
    });
  }

  void _onSearchChanged() {
    context.read<TransactionProvider>().setSearchQuery(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _eventsSub?.cancel();
    super.dispose();
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _openAdd({TransactionModel? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            AddTransactionPage(userId: widget.userId, existing: existing),
      ),
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FilterSheet(),
    );
  }

  void _openOwnerFilterModal() {
    final provider = context.read<TransactionProvider>();
    final currentTag = provider.selectedMemberTag ?? 'all';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 30,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
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
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
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
                      color: const Color(0xFF005FEA).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.people_alt_rounded,
                      color: Color(0xFF005FEA),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Phân loại chi tiêu',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildOwnerOption(
                ctx,
                key: 'all',
                title: 'Tất cả thành viên',
                subtitle: 'Xem toàn bộ giao dịch cả Vợ & Chồng',
                icon: Icons.groups_rounded,
                color: const Color(0xFF0284C7),
                isSelected: currentTag == 'all' || currentTag.isEmpty,
                onTap: () {
                  provider.setSelectedMemberTag(null);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 10),
              _buildOwnerOption(
                ctx,
                key: 'husband',
                title: 'Chồng chi tiêu',
                subtitle: 'Chỉ hiển thị các khoản của Chồng',
                icon: Icons.male_rounded,
                color: const Color(0xFF0284C7),
                isSelected: currentTag == 'husband',
                onTap: () {
                  provider.setSelectedMemberTag('husband');
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 10),
              _buildOwnerOption(
                ctx,
                key: 'wife',
                title: 'Vợ chi tiêu',
                subtitle: 'Chỉ hiển thị các khoản của Vợ',
                icon: Icons.female_rounded,
                color: const Color(0xFFDB2777),
                isSelected: currentTag == 'wife',
                onTap: () {
                  provider.setSelectedMemberTag('wife');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOwnerOption(
    BuildContext context, {
    required String key,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.18 : 0.08)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }

  void _openWalletFilterModal() {
    final provider = context.read<TransactionProvider>();
    final wallets = provider.wallets;
    final currentWalletId = provider.selectedWalletId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 30,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
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
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
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
                      color: const Color(0xFF005FEA).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFF005FEA),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Chọn Ví & Tài khoản',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Option All Wallets
              InkWell(
                onTap: () {
                  provider.setSelectedWalletId(null);
                  Navigator.pop(ctx);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: currentWalletId == null
                        ? const Color(0xFF005FEA).withValues(alpha: 0.12)
                        : (isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: currentWalletId == null
                          ? const Color(0xFF005FEA)
                          : (isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0)),
                      width: currentWalletId == null ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF005FEA).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.all_inclusive_rounded,
                          color: Color(0xFF005FEA),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tất cả ví',
                          style: TextStyle(
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (currentWalletId == null)
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF005FEA), size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.4,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: wallets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (c, idx) {
                    final w = wallets[idx];
                    final isSelected = currentWalletId == w.id;
                    return InkWell(
                      onTap: () {
                        provider.setSelectedWalletId(w.id);
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF005FEA).withValues(alpha: 0.12)
                              : (isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF005FEA)
                                : (isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0)),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0EA5E9)
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Color(0xFF0284C7),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    w.name,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    formatVND(w.balance),
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF005FEA), size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openDateFilterModal() {
    final provider = context.read<TransactionProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 30,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
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
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
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
                      color: const Color(0xFF005FEA).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Color(0xFF005FEA),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Chọn kỳ thời gian',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  DateFilterOption.today,
                  DateFilterOption.yesterday,
                  DateFilterOption.thisWeek,
                  DateFilterOption.lastWeek,
                  DateFilterOption.thisMonth,
                  DateFilterOption.lastMonth,
                  DateFilterOption.thisYear,
                  DateFilterOption.allTime,
                ].map((opt) {
                  final isSelected = provider.selectedDateFilter == opt;
                  return ChoiceChip(
                    label: Text(opt.label),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0F172A),
                    backgroundColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : const Color(0xFF334155)),
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100)),
                    onSelected: (_) {
                      provider.setSelectedDateFilter(opt);
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  DateTime _parseDate(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(
      timestamp > 100000000000 ? timestamp : timestamp * 1000,
    );
  }

  /// Groups transactions by date string (e.g. "Hôm nay • 01/09/2026")
  Map<String, List<TransactionModel>> _groupTransactions(
      List<TransactionModel> txs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final map = <String, List<TransactionModel>>{};
    for (final tx in txs) {
      final d = _parseDate(tx.date);
      final dayStart = DateTime(d.year, d.month, d.day);

      final dateStr =
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      String header;
      if (dayStart == today) {
        header = 'Hôm nay • $dateStr';
      } else if (dayStart == yesterday) {
        header = 'Hôm qua • $dateStr';
      } else {
        header = dateStr;
      }

      map.putIfAbsent(header, () => []).add(tx);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    final provider = context.watch<TransactionProvider>();
    if (_searchController.text != provider.searchQuery) {
      _searchController.value = TextEditingValue(
        text: provider.searchQuery,
        selection: TextSelection.collapsed(offset: provider.searchQuery.length),
      );
    }
    final transactions = provider.filteredTransactions;

    // Period totals
    final periodIncome = transactions
        .where(
            (t) => {'income', 'borrowing', 'loan_repayment_received'}.contains(
                  WalletRepository.normalizeTransactionType(t.type),
                ))
        .fold<int>(0, (sum, t) => sum + t.amount);

    final periodExpense = transactions
        .where((t) => {'expense', 'loan', 'debt_repayment_paid'}.contains(
              WalletRepository.normalizeTransactionType(t.type),
            ))
        .fold<int>(0, (sum, t) => sum + t.amount);

    final selectedType = provider.selectedType;
    final selectedWalletId = provider.selectedWalletId;
    final selectedMemberTag = provider.selectedMemberTag;

    // Resolve wallet label
    String walletLabel = 'Tất cả ví';
    if (selectedWalletId != null) {
      final matched = provider.wallets.where((w) => w.id == selectedWalletId);
      if (matched.isNotEmpty) {
        walletLabel = matched.first.name;
      }
    }

    // Resolve member tag label
    String memberLabel = 'Vợ chồng';
    if (selectedMemberTag == 'husband') {
      memberLabel = 'Chồng';
    } else if (selectedMemberTag == 'wife') {
      memberLabel = 'Vợ';
    }

    final groupedMap = _groupTransactions(transactions);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: AmbientFloatingBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Page title stays clear; quick add action on the right.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lịch sử giao dịch',
                            style: TextStyle(
                              color: primaryTextColor,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${transactions.length} giao dịch được ghi nhận',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _openAdd(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 13, vertical: 7.5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF005FEA), Color(0xFF0284C7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF005FEA)
                                  .withValues(alpha: 0.28),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded,
                                color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Thêm mới',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 120),
                  children: [
                    // 1. Compact Sleek Spending Card (Obsidian & Amethyst Glass)
                    _buildCompactSpendingCard(
                      periodExpense: periodExpense,
                      periodIncome: periodIncome,
                      dateLabel: provider.selectedDateFilter.label,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    // 2. Pill Search Bar
                    _buildPillSearchBar(isDark: isDark),
                    const SizedBox(height: 10),

                    // 3. Horizontal Filter Tabs Row
                    _buildFilterTabsRow(
                      isDark: isDark,
                      selectedType: selectedType,
                      memberLabel: memberLabel,
                      selectedMemberTag: selectedMemberTag,
                      walletLabel: walletLabel,
                      selectedWalletId: selectedWalletId,
                      provider: provider,
                    ),
                    const SizedBox(height: 14),

                    // 4. Grouped Transactions List
                    if (transactions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: EmptyState(
                          icon: Icons.receipt_long_rounded,
                          title: 'Chưa có giao dịch nào',
                          subtitle:
                              'Hãy thêm giao dịch đầu tiên để quản lý chi tiêu.',
                          actionText: '+ Thêm giao dịch',
                          onAction: () => _openAdd(),
                        ),
                      )
                    else
                      ...groupedMap.entries.map((entry) {
                        final headerText = entry.key;
                        final dayTxs = entry.value;

                        // Calculate day totals
                        final dayIncome = dayTxs
                            .where((t) => {
                                  'income',
                                  'borrowing',
                                  'loan_repayment_received'
                                }.contains(
                                  WalletRepository.normalizeTransactionType(
                                      t.type),
                                ))
                            .fold<int>(0, (sum, t) => sum + t.amount);

                        final dayExpense = dayTxs
                            .where((t) => {
                                  'expense',
                                  'loan',
                                  'debt_repayment_paid'
                                }.contains(
                                  WalletRepository.normalizeTransactionType(
                                      t.type),
                                ))
                            .fold<int>(0, (sum, t) => sum + t.amount);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDayHeader(
                              headerText: headerText,
                              dayIncome: dayIncome,
                              dayExpense: dayExpense,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 8),
                            ...dayTxs.map((tx) => _buildTransactionCard(
                                  tx: tx,
                                  isDark: isDark,
                                  onEdit: () => _openAdd(existing: tx),
                                  onDelete: () async {
                                    final confirm =
                                        await showConfirmDeleteDialog(
                                      context: context,
                                      title: 'Xóa giao dịch?',
                                      content:
                                          'Bạn có chắc chắn muốn xóa giao dịch này không?',
                                    );
                                    if (confirm && mounted) {
                                      if (!context.mounted) return;
                                      context
                                          .read<TransactionProvider>()
                                          .deleteTransaction(widget.userId, tx);
                                    }
                                  },
                                )),
                            const SizedBox(height: 14),
                          ],
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
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 19,
          color: isDark ? Colors.white : const Color(0xFF1E293B),
        ),
      ),
    );
  }

  /// Compact, refined Spending Card — Liquid Glass Deep Obsidian
  Widget _buildCompactSpendingCard({
    required int periodExpense,
    required int periodIncome,
    required String dateLabel,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0A192F), // Deep Royal Obsidian
            Color(0xFF0F172A), // Slate Navy
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Corner ambient light
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF005FEA).withValues(alpha: 0.22),
              ),
            ),
          ),
          // Subtle watermark
          const Positioned(
            right: 12,
            top: 12,
            child: Opacity(
              opacity: 0.07,
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: 78,
                color: Colors.white,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Tag + Eye on left, Date Filter Pill on right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4.5),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF005FEA).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Color(0xFF93C5FD),
                            size: 13,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'TỔNG CHI TIÊU',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _showBalances = !_showBalances);
                          },
                          child: MorphIcon(
                            icon: _showBalances
                                ? LucideIcons.eye
                                : LucideIcons.eye_off,
                            color: Colors.white.withValues(alpha: 0.85),
                            size: 15,
                          ),
                        ),
                      ],
                    ),
                    // Quick period badge on right
                    GestureDetector(
                      onTap: _openDateFilterModal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 0.9,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_month_outlined,
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateLabel,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Main Amount (Total Expenses)
                Text(
                  _showBalances ? formatVND(periodExpense) : '*** đ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 12),

                // Bottom Dual-Badge Ribbon (Compact)
                Row(
                  children: [
                    // Thu vào
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF10B981).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.28),
                            width: 0.9,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.22),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_downward_rounded,
                                size: 11,
                                color: Color(0xFF34D399),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Thu vào',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.68),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    _showBalances
                                        ? '+${formatVND(periodIncome)}'
                                        : '*** đ',
                                    style: const TextStyle(
                                      color: Color(0xFF6EE7B7),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Chi ra
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFEF4444).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                const Color(0xFFEF4444).withValues(alpha: 0.28),
                            width: 0.9,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444)
                                    .withValues(alpha: 0.22),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_upward_rounded,
                                size: 11,
                                color: Color(0xFFF87171),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Chi ra',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.68),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    _showBalances
                                        ? '-${formatVND(periodExpense)}'
                                        : '*** đ',
                                    style: const TextStyle(
                                      color: Color(0xFFFCA5A5),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillSearchBar({required bool isDark}) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: 'Tìm theo ghi chú, danh mục, ví...',
                hintStyle: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13.5,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () => _searchController.clear(),
              child: const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.close_rounded,
                    size: 17, color: Color(0xFF94A3B8)),
              ),
            ),
          GestureDetector(
            onTap: _openFilterSheet,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF005FEA).withValues(alpha: 0.15)
                    : const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.tune_rounded,
                  color: Color(0xFF005FEA), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabsRow({
    required bool isDark,
    required String? selectedType,
    required String memberLabel,
    required String? selectedMemberTag,
    required String walletLabel,
    required String? selectedWalletId,
    required TransactionProvider provider,
  }) {
    final typeIndex = selectedType == 'income'
        ? 1
        : selectedType == 'expense'
            ? 2
            : 0;
    return Column(
      children: [
        BouncyPillTabs(
          height: 38,
          labels: const ['Tất cả', 'Thu', 'Chi'],
          selectedIndex: typeIndex,
          colors: const [
            Color(0xFF475569),
            Color(0xFF059669),
            Color(0xFFE11D48)
          ],
          onChanged: (index) => provider.setSelectedType(
            index == 1
                ? 'income'
                : index == 2
                    ? 'expense'
                    : null,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(children: [
            _buildFilterChipPill(
              label: provider.activeDateFilterLabel,
              icon: Icons.calendar_month_rounded,
              isActive:
                  provider.selectedDateFilter != DateFilterOption.thisMonth,
              isDark: isDark,
              onTap: _openDateFilterModal,
            ),
            const SizedBox(width: 8),
            _buildFilterChipPill(
              label: memberLabel,
              icon: Icons.people_alt_rounded,
              isActive: selectedMemberTag != null && selectedMemberTag != 'all',
              isDark: isDark,
              onTap: _openOwnerFilterModal,
            ),
            const SizedBox(width: 8),
            _buildFilterChipPill(
              label: walletLabel,
              icon: Icons.credit_card_rounded,
              isActive: selectedWalletId != null,
              isDark: isDark,
              onTap: _openWalletFilterModal,
            ),
            const SizedBox(width: 8),
            _buildFilterChipPill(
              label: 'Bộ lọc',
              icon: Icons.tune_rounded,
              isActive: false,
              isDark: isDark,
              onTap: _openFilterSheet,
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildFilterChipPill({
    required String label,
    IconData? icon,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    // Luxury dark obsidian pill for active state
    final activeColor =
        isDark ? const Color(0xFF005FEA) : const Color(0xFF0F172A);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6.5),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isActive
                ? activeColor
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? activeColor.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13.5,
                color: isActive
                    ? Colors.white
                    : (isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 4.5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? Colors.white
                    : (isDark ? Colors.white : const Color(0xFF1E293B)),
                fontSize: 12.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayHeader({
    required String headerText,
    required int dayIncome,
    required int dayExpense,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF005FEA).withValues(alpha: 0.18)
                      : const Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  size: 11,
                  color: Color(0xFF005FEA),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                headerText,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          if (_showBalances && (dayIncome > 0 || dayExpense > 0))
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dayIncome > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6.5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+${formatVND(dayIncome)}',
                      style: const TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (dayExpense > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6.5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '-${formatVND(dayExpense)}',
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard({
    required TransactionModel tx,
    required bool isDark,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final normType = WalletRepository.normalizeTransactionType(tx.type);
    final isInflow =
        {'income', 'borrowing', 'loan_repayment_received'}.contains(normType);
    final isTransfer = normType == 'transfer';

    final sign = isInflow ? '+' : (isTransfer ? '' : '-');
    final amountColor = isTransfer
        ? const Color(0xFF64748B)
        : (isInflow ? const Color(0xFF059669) : const Color(0xFFDC2626));

    final amountStr = _showBalances ? '$sign${formatVND(tx.amount)}' : '*** đ';

    final title = (tx.note != null && tx.note!.trim().isNotEmpty)
        ? tx.note!
        : (tx.categoryName ?? 'Giao dịch');

    final d = _parseDate(tx.date);
    final timeStr =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    // Subtitle note
    final subtitleNote = (tx.note != null &&
            tx.note!.trim().isNotEmpty &&
            tx.categoryName != null)
        ? tx.categoryName!
        : (tx.categoryName ?? 'Giao dịch');

    // Wallet tag name
    final walletName = tx.walletName ?? tx.fromWalletName ?? 'Ví';

    // Member tag (Chồng or Vợ according to web)
    final isWife = tx.creatorTag == 'Vợ' ||
        tx.creatorTag?.toLowerCase() == 'wife' ||
        tx.ownerName?.toLowerCase() == 'vợ' ||
        tx.ownerName?.toLowerCase() == 'wife' ||
        tx.owner?.toLowerCase() == 'wife' ||
        tx.fromOwner?.toLowerCase() == 'wife' ||
        tx.paidByOwner?.toLowerCase() == 'wife' ||
        tx.tags.any(
            (tag) => tag.toLowerCase() == 'vợ' || tag.toLowerCase() == 'wife');
    final isHusband = !isWife;

    final liveCategory = context
        .read<TransactionProvider>()
        .categories
        .cast<dynamic>()
        .firstWhere(
          (category) =>
              (tx.categoryId?.isNotEmpty == true &&
                  category?.id == tx.categoryId) ||
              (tx.categoryName?.isNotEmpty == true &&
                  category?.name.toString().trim().toLowerCase() ==
                      tx.categoryName!.trim().toLowerCase()),
          orElse: () => null,
        );
    final resolvedCategoryIcon = liveCategory?.icon ?? tx.categoryIcon;
    final resolvedCategoryColor = liveCategory?.color ?? tx.categoryColor;
    final isAi = tx.tags.contains('Finora AI') || tx.creatorTag == 'AI';

    return Dismissible(
      key: ValueKey('tx_${tx.id}'),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.amber.shade700,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit();
          return false;
        } else if (direction == DismissDirection.endToStart) {
          onDelete();
          return false;
        }
        return false;
      },
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TransactionDetailScreen(
                userId: widget.userId,
                transaction: tx,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.025),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Category Icon in circular badge
              TransactionIconWidget(
                type: tx.type,
                categoryIcon: resolvedCategoryIcon,
                categoryName: liveCategory?.name ?? tx.categoryName ?? tx.note,
                categoryColor: resolvedCategoryColor,
                merchantId: tx.merchantId,
                size: 42,
              ),
              const SizedBox(width: 12),

              // Title and Tags
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitleNote.isNotEmpty &&
                        subtitleNote.toLowerCase() != title.toLowerCase()) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitleNote,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 5,
                      runSpacing: 3,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Wallet Tag Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6.5, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0C4A6E).withValues(alpha: 0.5)
                                : const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF005FEA)
                                  .withValues(alpha: 0.2),
                              width: 0.6,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.credit_card_rounded,
                                size: 10,
                                color: Color(0xFF005FEA),
                              ),
                              const SizedBox(width: 3.5),
                              Text(
                                walletName,
                                style: const TextStyle(
                                  color: Color(0xFF005FEA),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Husband / Wife Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6.5, vertical: 2),
                          decoration: BoxDecoration(
                            color: isHusband
                                ? (isDark
                                    ? const Color(0xFF0C4A6E)
                                        .withValues(alpha: 0.5)
                                    : const Color(0xFFE0F2FE))
                                : (isDark
                                    ? const Color(0xFF4C0519)
                                        .withValues(alpha: 0.5)
                                    : const Color(0xFFFCE7F3)),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isHusband
                                  ? const Color(0xFF0284C7)
                                      .withValues(alpha: 0.2)
                                  : const Color(0xFFDB2777)
                                      .withValues(alpha: 0.2),
                              width: 0.6,
                            ),
                          ),
                          child: Text(
                            isHusband ? 'Chồng' : 'Vợ',
                            style: TextStyle(
                              color: isHusband
                                  ? const Color(0xFF0284C7)
                                  : const Color(0xFFDB2777),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        if (isAi)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF005FEA)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF005FEA)
                                    .withValues(alpha: 0.28),
                                width: 0.6,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome_rounded,
                                    size: 8.5, color: Color(0xFF0284C7)),
                                SizedBox(width: 2),
                                Text(
                                  'AI',
                                  style: TextStyle(
                                    color: Color(0xFF0284C7),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Text(
                          timeStr,
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Amount Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amountStr,
                    style: TextStyle(
                      color: amountColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isInflow
                          ? const Color(0xFF059669)
                              .withValues(alpha: isDark ? 0.20 : 0.08)
                          : (isTransfer
                              ? const Color(0xFF64748B)
                                  .withValues(alpha: isDark ? 0.20 : 0.08)
                              : const Color(0xFFDC2626)
                                  .withValues(alpha: isDark ? 0.20 : 0.08)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      isInflow
                          ? 'thu về'
                          : (isTransfer ? 'chuyển ví' : 'đã chi'),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: amountColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPastelColor(TransactionModel tx) {
    final norm = WalletRepository.normalizeTransactionType(tx.type);
    if (norm == 'income') {
      return const Color(0xFFFEF3C7); // Warm amber
    }
    if (norm == 'transfer') {
      return const Color(0xFFE0F2FE); // Indigo pastel
    }
    final name = (tx.categoryName ?? '').toLowerCase();
    if (name.contains('ăn') || name.contains('uống') || name.contains('food')) {
      return const Color(0xFFFFEDD5); // Orange pastel
    }
    if (name.contains('mua') || name.contains('sắm')) {
      return const Color(0xFFFCE7F3); // Pink pastel
    }
    return const Color(0xFFF1F5F9); // Slate pastel
  }
}

/// Filter Sheet Bottom Sheet
class _FilterSheet extends StatefulWidget {
  const _FilterSheet();

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<TransactionProvider>();
    _searchController = TextEditingController(text: provider.searchQuery);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    context.read<TransactionProvider>().setSearchQuery(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final provider = context.watch<TransactionProvider>();

    return GlassBottomSheet(
      radius: 32,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.md,
            bottom: AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Bộ lọc nâng cao',
                style: AppTypography.title2.copyWith(
                  color: primaryTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Search
              Text(
                'Tìm kiếm',
                style: AppTypography.caption2.copyWith(
                  color: secondaryTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              GlassTextField(
                controller: _searchController,
                hint: 'Tìm kiếm ghi chú, danh mục...',
                suffix: const Icon(Icons.search, size: 20),
              ),
              const SizedBox(height: AppSpacing.md),

              // Date range
              Text(
                'Khoảng thời gian',
                style: AppTypography.caption2.copyWith(
                  color: secondaryTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: DateFilterOption.values.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.xs),
                  itemBuilder: (_, i) {
                    final option = DateFilterOption.values[i];
                    return FilterChipX(
                      label: option.label,
                      selected: provider.selectedDateFilter == option,
                      onTap: () => context
                          .read<TransactionProvider>()
                          .setSelectedDateFilter(option),
                    );
                  },
                ),
              ),

              // Wallets
              if (provider.wallets.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Tài khoản / Ví',
                  style: AppTypography.caption2.copyWith(
                    color: secondaryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: provider.wallets.length + 1,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.xs),
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return FilterChipX(
                          label: 'Tất cả ví',
                          selected: provider.selectedWalletId == null,
                          onTap: () => context
                              .read<TransactionProvider>()
                              .setSelectedWalletId(null),
                        );
                      }
                      final wallet = provider.wallets[i - 1];
                      return FilterChipX(
                        label: wallet.name,
                        selected: provider.selectedWalletId == wallet.id,
                        onTap: () => context
                            .read<TransactionProvider>()
                            .setSelectedWalletId(wallet.id),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                expand: true,
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Áp dụng',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
