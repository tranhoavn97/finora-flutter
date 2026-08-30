import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/custom_date_picker_dialog.dart';
import '../../core/widgets/subject_filter_pill.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../../data/models/transaction.dart';
import '../../state/transaction_provider.dart';
import '../../state/wallet_provider.dart';
import '../../data/services/wallet_repository.dart';
import 'transaction_detail_screen.dart';
import '../../data/models/wallet.dart';

class TransactionHistorySheet extends StatefulWidget {
  final String userId;
  final String? walletId;
  final String? walletName;
  final String? categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String? categoryGroup;

  const TransactionHistorySheet({
    super.key,
    required this.userId,
    this.walletId,
    this.walletName,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.categoryGroup,
  });

  @override
  State<TransactionHistorySheet> createState() =>
      _TransactionHistorySheetState();
}

class _TransactionHistorySheetState extends State<TransactionHistorySheet> {
  String _type = 'all';
  String _owner = 'all';
  late DateTime? _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TransactionProvider>().load(widget.userId);
    });
  }

  String get userId => widget.userId;
  String? get walletId => widget.walletId;
  String? get walletName => widget.walletName;
  String? get categoryId => widget.categoryId;
  String? get categoryName => widget.categoryName;
  String? get categoryIcon => widget.categoryIcon;
  String? get categoryColor => widget.categoryColor;
  String? get categoryGroup => widget.categoryGroup;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final txProvider = context.watch<TransactionProvider>();

    // Contextual histories intentionally ignore the transaction page's global
    // filters, so older records never disappear when a card/category is opened.
    final allTxs = List<TransactionModel>.from(txProvider.transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final List<TransactionModel> contextual;
    if (walletId != null) {
      contextual = allTxs.where((t) {
        return t.walletId == walletId ||
            t.fromWalletId == walletId ||
            t.toWalletId == walletId ||
            t.creditCardId == walletId;
      }).toList();
    } else if (categoryName != null) {
      contextual = allTxs.where((t) {
        return t.categoryName == categoryName ||
            (categoryId != null && t.categoryId == categoryId);
      }).toList();
    } else {
      contextual = allTxs;
    }
    final txs = contextual.where((t) {
      if (_type != 'all' && t.type != _type) return false;
      if (_owner != 'all' && t.owner != _owner) return false;
      if (_month != null) {
        final date = t.date > 100000000000
            ? DateTime.fromMillisecondsSinceEpoch(t.date)
            : DateTime.fromMillisecondsSinceEpoch(t.date * 1000);
        if (date.year != _month!.year || date.month != _month!.month)
          return false;
      }
      return true;
    }).toList();

    final isWallet = walletId != null;
    final isCategory = categoryName != null;
    final title = isWallet
        ? (walletName ?? 'Ví')
        : (isCategory ? categoryName! : 'Dòng tiền thu chi');

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: Material(
        color: isDark ? const Color(0xFF10172B) : Colors.white,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isWallet
                              ? 'LỊCH SỬ GIAO DỊCH VÍ'
                              : 'LỊCH SỬ DANH MỤC',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: c.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: c.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color:
                            isDark ? Colors.white10 : const Color(0xFFEDF2FA),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded,
                          color: c.textPrimary, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Header summary card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: isWallet
                  ? _buildWalletHeaderCard(context)
                  : (isCategory
                      ? _buildCategoryHeaderCard(context, txs)
                      : _buildGlobalCashFlowHeaderCard(context, txs)),
            ),
            const SizedBox(height: 14),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                if (!isCategory) ...[
                  SegmentedControl(
                    options: const [
                      ('all', 'Tất cả'),
                      ('income', 'Thu'),
                      ('expense', 'Chi')
                    ],
                    selected: _type,
                    onChanged: (value) => setState(() => _type = value),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(children: [
                  Expanded(
                    child: SubjectFilterPill(
                      compact: true,
                      selected: OwnerFilter.fromString(_owner),
                      onSelected: (value) =>
                          setState(() => _owner = value.value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: _month == null
                        ? 'Lọc theo tháng'
                        : 'Tháng ${_month!.month}/${_month!.year}',
                    onPressed: () async {
                      final picked = await CustomDatePickerSheet.show(context,
                          initialDate: _month ?? DateTime.now());
                      if (picked != null && mounted)
                        setState(
                            () => _month = DateTime(picked.year, picked.month));
                    },
                    icon: const Icon(Icons.calendar_month_rounded),
                  ),
                  if (_month != null)
                    IconButton(
                      tooltip: 'Bỏ lọc tháng',
                      onPressed: () => setState(() => _month = null),
                      icon: const Icon(Icons.close_rounded),
                    ),
                ]),
              ]),
            ),
            const SizedBox(height: 12),

            // Subheader
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isCategory
                        ? 'Giao dịch trong danh mục'
                        : 'Giao dịch gần đây',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  Text(
                    '${txs.length} giao dịch',
                    style: TextStyle(
                      fontSize: 12,
                      color: c.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Transactions list
            Expanded(
              child: txs.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 40, horizontal: 20),
                      child: Center(
                        child: EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'Chưa có giao dịch nào',
                          subtitle:
                              'Không tìm thấy giao dịch nào trong sổ này.',
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      physics: const BouncingScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: txs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final tx = txs[idx];
                        return _HistoryTransactionRow(
                          tx: tx,
                          userId: userId,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => TransactionDetailScreen(
                                userId: userId,
                                transaction: tx,
                              ),
                            ));
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

  Widget _buildWalletHeaderCard(BuildContext context) {
    final walletProvider = context.read<WalletProvider>();
    final wallet = walletProvider.wallets.firstWhere(
      (w) => w.id == walletId,
      orElse: () => const Wallet(),
    );

    final isCredit = wallet.isCreditCard;
    final gradient = wallet.owner == 'wife'
        ? const [Color(0xFFBE185D), Color(0xFFF472B6)]
        : wallet.owner == 'husband'
            ? const [Color(0xFF1D4ED8), Color(0xFF38BDF8)]
            : const [Color(0xFF0F766E), Color(0xFF2DD4BF)];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isCredit ? 'Hạn mức & Dư nợ' : 'Số dư khả dụng',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  wallet.ownerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isCredit
                ? formatVND(wallet.currentDebt)
                : formatVND(wallet.balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          if (isCredit) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: wallet.creditLimit > 0
                    ? (wallet.currentDebt / wallet.creditLimit)
                    : 0,
                minHeight: 6,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Hạn mức: ${formatVND(wallet.creditLimit)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryHeaderCard(
      BuildContext context, List<TransactionModel> txs) {
    final hexColor = categoryColor ?? '#0891B2';
    final tint = _parseHexColor(hexColor) ?? AppColors.primary;
    final total = txs.fold<int>(0, (sum, tx) => sum + tx.amount);
    final isExpense = categoryGroup == 'expense';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(tint, const Color(0xFF0F172A), .42)!,
            tint,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: .25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Text(
              CategoryIconHelper.resolveIcon(categoryIcon ?? categoryName),
              style: const TextStyle(fontSize: 27),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(categoryName ?? 'Danh mục',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  '${txs.length} giao dịch • ${isExpense ? 'Đã chi' : 'Đã ghi nhận'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatVND(total),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalCashFlowHeaderCard(
      BuildContext context, List<TransactionModel> txs) {
    final c = context.fc;

    int totalIncome = 0;
    int totalExpense = 0;

    for (final tx in txs) {
      if (tx.type == 'income' ||
          tx.type == 'borrowing' ||
          tx.type == 'loan_repayment_received') {
        totalIncome += tx.amount;
      } else if (tx.type == 'expense' ||
          tx.type == 'loan' ||
          tx.type == 'debt_repayment_paid') {
        totalExpense += tx.amount;
      }
    }

    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TỔNG THU',
                  style: TextStyle(
                    color: c.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatVND(totalIncome),
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: const Color(0xFFE8EEF8),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TỔNG CHI',
                  style: TextStyle(
                    color: c.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatVND(totalExpense),
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color? _parseHexColor(String? hex) {
    if (hex == null) return null;
    var clean = hex.trim().replaceFirst('#', '');
    if (clean.length == 6) clean = 'FF$clean';
    if (clean.length != 8) return null;
    final value = int.tryParse(clean, radix: 16);
    if (value == null) return null;
    return Color(value);
  }
}

class _HistoryTransactionRow extends StatelessWidget {
  final TransactionModel tx;
  final String userId;
  final VoidCallback onTap;

  const _HistoryTransactionRow({
    required this.tx,
    required this.userId,
    required this.onTap,
  });

  String _formatDateTime(int timestampMs) {
    if (timestampMs == 0) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final hour = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final mo = d.month.toString().padLeft(2, '0');
    return '$hour:$min • $dd/$mo';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;

    final isInflow =
        {'income', 'borrowing', 'loan_repayment_received'}.contains(tx.type);
    final isTransfer = tx.type == 'transfer';
    final isInvestment = tx.type == 'investment';

    final sign = isInflow ? '+' : ((isTransfer || isInvestment) ? '' : '-');
    final amountColor = isTransfer
        ? c.textSecondary
        : (isInvestment
            ? AppColors.primary
            : (isInflow ? AppColors.success : AppColors.error));

    final String title = (tx.note != null && tx.note!.isNotEmpty)
        ? tx.note!
        : (tx.categoryName ?? 'Giao dịch');

    final walletLabel = tx.walletName ?? tx.fromWalletName ?? 'Ví';

    final ownerColor = tx.owner == 'wife'
        ? AppColors.wife
        : tx.owner == 'husband'
            ? AppColors.husband
            : const Color(0xFF0F766E);
    return Material(
      color: ownerColor.withValues(alpha: .075),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: ownerColor.withValues(alpha: .18)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconBadge(
                emoji: CategoryIconHelper.resolveTransactionIcon(
                  transactionType: tx.type,
                  categoryIcon: tx.categoryIcon,
                  categoryName: tx.categoryName,
                  note: tx.note,
                ),
                tint: amountColor,
                size: 42,
                radius: 14,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          walletLabel,
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDateTime(tx.date),
                          style: TextStyle(
                            color: c.textTertiary,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isTransfer
                    ? formatVND(tx.amount)
                    : '$sign${formatVND(tx.amount)}',
                style: TextStyle(
                  color: amountColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
