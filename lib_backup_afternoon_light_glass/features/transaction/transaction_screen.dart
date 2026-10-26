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
import '../../data/models/transaction.dart';
import '../../state/transaction_provider.dart';
import '../../data/services/wallet_repository.dart';
import 'add_transaction_page.dart';
import 'transaction_detail_screen.dart';

/// Transactions tab — overview spending card, type/filter controls and a
/// swipe-to-act list of transactions. Designed to live inside MainScreen's
/// IndexedStack, so it returns a transparent [Scaffold] body (no backdrop).
class TransactionScreen extends StatefulWidget {
  final String userId;
  const TransactionScreen({super.key, required this.userId});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  bool _showBalances = true;
  StreamSubscription<String>? _eventsSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<TransactionProvider>();
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

  void _openAdd({TransactionModel? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddTransactionPage(userId: widget.userId, existing: existing),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final provider = context.watch<TransactionProvider>();
    final transactions = provider.filteredTransactions;
    final groupedItems = _groupTransactions(transactions);
    final totalExpenses = transactions
        .where((t) => WalletRepository.normalizeTransactionType(t.type) == 'expense')
        .fold<int>(0, (sum, t) => sum + t.amount);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xs),
              Text('Giao dịch',
                  style: AppTypography.largeTitle.copyWith(color: primaryTextColor, fontWeight: FontWeight.w800)),
              const SizedBox(height: AppSpacing.sm),

              // Overview spending summary card
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tổng chi tiêu tháng này',
                        style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(formatVND(totalExpenses),
                        style: AppTypography.title1.copyWith(color: primaryTextColor, fontWeight: FontWeight.w800)),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: SegmentedControl(
                            options: const [
                              ('all', 'Tất cả'),
                              ('income', 'Thu'),
                              ('expense', 'Chi'),
                            ],
                            selected: provider.selectedType ?? 'all',
                            onChanged: (v) => provider
                                .setSelectedType(v == 'all' ? null : v),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          flex: 1,
                          child: _FilterButton(onTap: _openFilterSheet),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Transaction list / empty state
              Expanded(
                child: transactions.isEmpty
                    ? Center(
                        child: EmptyState(
                          icon: Icons.receipt_long,
                          title: 'Chưa có giao dịch nào',
                          subtitle:
                              'Hãy thêm giao dịch đầu tiên để bắt đầu quản lý.',
                          actionText: '+ Thêm giao dịch',
                          onAction: () => _openAdd(),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 120),
                        itemCount: groupedItems.length,
                        itemBuilder: (context, i) {
                          final item = groupedItems[i];
                          if (item.isHeader) {
                            return _buildMonthHeader(context, item);
                          }
                          final tx = item.transaction!;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _TransactionCell(
                              key: ValueKey(tx.id),
                              tx: tx,
                              showBalances: _showBalances,
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
                              onEdit: () => _openAdd(existing: tx),
                              onDelete: () async {
                                final confirm = await showConfirmDeleteDialog(
                                  context: context,
                                  title: 'Xóa giao dịch?',
                                  content: 'Bạn có chắc chắn muốn xóa giao dịch này không?',
                                );
                                if (confirm && context.mounted) {
                                  context
                                      .read<TransactionProvider>()
                                      .deleteTransaction(widget.userId, tx);
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthHeader(BuildContext context, _GroupedItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final incomeText = _showBalances ? formatVND(item.totalIncome) : '***đ';
    final expenseText = _showBalances ? formatVND(item.totalExpense) : '***đ';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.monthHeader!,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tổng thu: $incomeText  |  Tổng chi: $expenseText',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () {
              setState(() {
                _showBalances = !_showBalances;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showBalances ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 16,
                    color: const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _showBalances ? 'Ẩn số dư' : 'Hiện số dư',
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_GroupedItem> _groupTransactions(List<TransactionModel> txs) {
    final List<_GroupedItem> items = [];
    String? currentMonth;
    List<TransactionModel> monthTxs = [];

    for (final tx in txs) {
      final date = DateTime.fromMillisecondsSinceEpoch(tx.date);
      final monthStr = 'Tháng ${date.month}/${date.year}';

      if (currentMonth == null) {
        currentMonth = monthStr;
        monthTxs = [tx];
      } else if (currentMonth == monthStr) {
        monthTxs.add(tx);
      } else {
        items.addAll(_createMonthSection(currentMonth, monthTxs));
        currentMonth = monthStr;
        monthTxs = [tx];
      }
    }
    if (currentMonth != null && monthTxs.isNotEmpty) {
      items.addAll(_createMonthSection(currentMonth, monthTxs));
    }

    return items;
  }

  List<_GroupedItem> _createMonthSection(String monthName, List<TransactionModel> txs) {
    int totalIncome = 0;
    int totalExpense = 0;

    for (final tx in txs) {
      if (tx.type == 'income' || tx.type == 'borrowing' || tx.type == 'loan_repayment_received') {
        totalIncome += tx.amount;
      } else if (tx.type == 'expense' || tx.type == 'loan' || tx.type == 'debt_repayment_paid') {
        totalExpense += tx.amount;
      }
    }

    final List<_GroupedItem> section = [];
    section.add(_GroupedItem(
      monthHeader: monthName,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
    ));

    for (final tx in txs) {
      section.add(_GroupedItem(transaction: tx));
    }

    return section;
  }
}

/// Small tinted "Lọc" button shown next to the segmented control.
class _FilterButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FilterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.12),
          borderRadius: AppRadius.radiusSM,
        ),
        child: Text('Lọc',
            style: AppTypography.caption1.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
            )),
      ),
    );
  }
}

/// A single transaction row: white surface card + hairline border, wrapped in a
/// [Dismissible] (swipe left = delete, swipe right = edit) and tappable to edit.
class _TransactionCell extends StatelessWidget {
  final TransactionModel tx;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showBalances;

  const _TransactionCell({
    super.key,
    required this.tx,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.showBalances,
  });

  static const _inflowTypes = {'income', 'borrowing', 'loan_repayment_received'};

  Color get _tint {
    final hex = tx.categoryColor;
    final parsed = _parseHexColor(hex);
    return parsed ?? AppColors.accent;
  }

  String _formatDateTime(int timestampMs) {
    if (timestampMs == 0) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final hour = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final mo = d.month.toString().padLeft(2, '0');
    return '$hour:$min - $dd/$mo/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final isInflow = _inflowTypes.contains(tx.type);
    final isTransfer = tx.type == 'transfer';
    final isInvestment = tx.type == 'investment';

    final sign = isInflow ? '+' : ((isTransfer || isInvestment) ? '' : '-');
    final amountColor = isTransfer
        ? Colors.grey
        : (isInvestment
            ? const Color(0xFF6366F1)
            : (isInflow ? const Color(0xFF34D399) : const Color(0xFFF87171)));

    final IconData arrowIcon = isTransfer
        ? Icons.swap_horiz
        : (isInvestment
            ? Icons.trending_up
            : (isInflow ? Icons.arrow_upward : Icons.arrow_downward));

    final title = (tx.note != null && tx.note!.trim().isNotEmpty)
        ? tx.note!
        : (tx.categoryName ?? 'Giao dịch');
    
    final walletLabel = tx.walletName ?? tx.fromWalletName ?? 'Ví';
    
    final amountText = showBalances 
        ? (tx.type == 'transfer' ? formatVND(tx.amount) : '$sign${formatVND(tx.amount)}') 
        : '***đ';

    return Dismissible(
      key: ValueKey('dismiss_${tx.id}'),
      background: _SwipeBackground(
        color: Colors.orange,
        alignment: Alignment.centerLeft,
        icon: Icons.edit,
        label: 'Sửa',
        iconLeading: true,
      ),
      secondaryBackground: _SwipeBackground(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        icon: Icons.delete,
        label: 'Xóa',
        iconLeading: false,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit();
          return false;
        }
        if (direction == DismissDirection.endToStart) {
          onDelete();
          return true;
        }
        return false;
      },
      child: GlassCard(
        radius: AppRadius.sm,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconBadge(
              emoji: CategoryIconHelper.resolveIcon(
                  tx.categoryIcon ?? tx.categoryName),
              tint: _tint,
              size: 44,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatDateTime(tx.date),
                    style: TextStyle(
                      color: secondaryTextColor.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isTransfer ? 'Không tốn phí' : 'Phí dịch vụ: Miễn phí',
                    style: TextStyle(
                      color: secondaryTextColor.withOpacity(0.5),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showBalances)
                      Icon(
                        arrowIcon,
                        size: 14,
                        color: amountColor,
                      ),
                    const SizedBox(width: 2),
                    Text(
                      amountText,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'Thành công',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (tx.categoryIcon != null && tx.categoryIcon != '🔄')
                      Text(tx.categoryIcon!, style: const TextStyle(fontSize: 8.5))
                    else
                      Icon(Icons.payment, size: 10, color: secondaryTextColor.withOpacity(0.6)),
                    const SizedBox(width: 3),
                    Text(
                      tx.type == 'transfer' ? '${tx.fromWalletName} ➔ ${tx.toWalletName}' : walletLabel,
                      style: TextStyle(
                        color: secondaryTextColor.withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  final Color color;
  final Alignment alignment;
  final IconData icon;
  final String label;
  final bool iconLeading;
  const _SwipeBackground({
    required this.color,
    required this.alignment,
    required this.icon,
    required this.label,
    required this.iconLeading,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, color: Colors.white, size: 20);
    final text = Text(label,
        style: AppTypography.caption1.copyWith(
            color: Colors.white, fontWeight: FontWeight.bold));
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.card,
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: iconLeading
            ? [iconWidget, const SizedBox(width: AppSpacing.xs), text]
            : [text, const SizedBox(width: AppSpacing.xs), iconWidget],
      ),
    );
  }
}

/// Advanced filter bottom sheet — search, date range and wallet filters.
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
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
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
                    color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Bộ lọc nâng cao',
                  style: AppTypography.title2.copyWith(color: primaryTextColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.md),

              // Search
              Text('Tìm kiếm',
                  style: AppTypography.caption2.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              GlassTextField(
                controller: _searchController,
                hint: 'Tìm kiếm ghi chú, danh mục...',
                suffix: const Icon(Icons.search, size: 20),
              ),
              const SizedBox(height: AppSpacing.md),

              // Date range
              Text('Khoảng thời gian',
                  style: AppTypography.caption2.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: DateFilterOption.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
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
                Text('Tài khoản / Ví',
                    style: AppTypography.caption2.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: provider.wallets.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
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
                child: const Text('Áp dụng',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

class _GroupedItem {
  final String? monthHeader;
  final int totalIncome;
  final int totalExpense;
  final TransactionModel? transaction;

  bool get isHeader => monthHeader != null;

  _GroupedItem({
    this.monthHeader,
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.transaction,
  });
}
