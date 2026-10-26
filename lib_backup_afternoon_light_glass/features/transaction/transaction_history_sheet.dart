import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_widgets.dart';
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

class TransactionHistorySheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final txProvider = context.watch<TransactionProvider>();
    
    // Ensure data is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      txProvider.load(userId);
    });

    final allTxs = txProvider.filteredTransactions;

    // Filter logic
    final List<TransactionModel> txs;
    if (walletId != null) {
      txs = allTxs.where((t) {
        return t.walletId == walletId ||
            t.fromWalletId == walletId ||
            t.toWalletId == walletId ||
            t.creditCardId == walletId;
      }).toList();
    } else if (categoryName != null) {
      txs = allTxs.where((t) {
        return t.categoryName == categoryName ||
            (categoryId != null && t.categoryId == categoryId);
      }).toList();
    } else {
      txs = allTxs;
    }

    final isWallet = walletId != null;
    final isCategory = categoryName != null;
    final title = isWallet
        ? (walletName ?? 'Ví')
        : (isCategory ? categoryName! : 'Dòng tiền thu chi');

    return GlassBottomSheet(
      radius: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isWallet ? 'Lịch sử giao dịch ví' : 'Lịch sử giao dịch danh mục',
                        style: AppTypography.caption2.copyWith(color: secondaryTextColor, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: AppTypography.title3.copyWith(color: primaryTextColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: primaryTextColor, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Premium visual header matching the image design
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: isWallet
                ? _buildWalletHeaderCard(context)
                : (isCategory
                    ? _buildCategoryHeaderCard(context)
                    : _buildGlobalCashFlowHeaderCard(context, txs)),
          ),
          const SizedBox(height: AppSpacing.md),

          // Subheader
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Giao dịch gần đây',
                  style: AppTypography.subhead.copyWith(color: primaryTextColor, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${txs.length} giao dịch',
                  style: AppTypography.caption2.copyWith(color: secondaryTextColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Transactions list
          Flexible(
            child: txs.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: AppSpacing.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: secondaryTextColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có giao dịch nào',
                          style: AppTypography.subhead.copyWith(color: secondaryTextColor),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 32),
                    shrinkWrap: true,
                    itemCount: txs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, idx) {
                      final tx = txs[idx];
                      return _HistoryTransactionRow(
                        tx: tx,
                        userId: userId,
                        onTap: () {
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
    );
  }

  Widget _buildWalletHeaderCard(BuildContext context) {
    // Try to find the wallet object to get actual balance / owner details
    final walletProvider = context.read<WalletProvider>();
    final wallet = walletProvider.wallets.firstWhere(
      (w) => w.id == walletId,
      orElse: () => const Wallet(),
    );

    final isCredit = wallet.isCreditCard;
    final gradient = isCredit
        ? const [Color(0xFFE11D48), Color(0xFF881337)]
        : const [Color(0xFF22D29B), Color(0xFF059669)];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 16,
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
                isCredit ? 'Hạn mức & Dư nợ' : 'Số dư hiện tại',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10,  vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  wallet.ownerName,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isCredit ? formatVND(wallet.currentDebt) : formatVND(wallet.balance),
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          ),
          if (isCredit) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: wallet.creditLimit > 0 ? (wallet.currentDebt / wallet.creditLimit) : 0,
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
          ] else if (wallet.type == 'bank') ...[
            const SizedBox(height: 6),
            Text(
              'Số tài khoản: ${wallet.accountNumber ?? "N/A"}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryHeaderCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final hexColor = categoryColor ?? '#2F7CF6';
    final tint = _parseHexColor(hexColor) ?? AppColors.accent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
        borderRadius: AppRadius.card,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          IconBadge(
            emoji: CategoryIconHelper.resolveIcon(categoryIcon ?? categoryName),
            tint: tint,
            size: 52,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName ?? 'Danh mục',
                  style: AppTypography.subhead.copyWith(color: primaryTextColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  categoryGroup == 'expense'
                      ? 'Nhóm: Chi tiêu'
                      : categoryGroup == 'income'
                          ? 'Nhóm: Thu nhập'
                          : 'Nhóm: Đầu tư & Tiết kiệm',
                  style: AppTypography.caption2.copyWith(color: secondaryTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalCashFlowHeaderCard(BuildContext context, List<TransactionModel> txs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    int totalIncome = 0;
    int totalExpense = 0;
    int totalInvestment = 0;

    for (final tx in txs) {
      if (tx.type == 'income' || tx.type == 'borrowing' || tx.type == 'loan_repayment_received') {
        totalIncome += tx.amount;
      } else if (tx.type == 'expense' || tx.type == 'loan' || tx.type == 'debt_repayment_paid') {
        totalExpense += tx.amount;
      } else if (tx.type == 'investment') {
        totalInvestment += tx.amount;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: AppRadius.card,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng quan dòng tiền tháng này',
            style: AppTypography.caption1.copyWith(
              color: primaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TỔNG THU',
                      style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatVND(totalIncome),
                      style: const TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 28, color: Colors.grey.withOpacity(0.2)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TỔNG CHI',
                      style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatVND(totalExpense),
                      style: const TextStyle(
                        color: Color(0xFFF87171),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (totalInvestment > 0) ...[
                Container(width: 1, height: 28, color: Colors.grey.withOpacity(0.2)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ĐẦU TƯ',
                        style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatVND(totalInvestment),
                        style: const TextStyle(
                          color: Color(0xFF6366F1),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
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
    return '$hour:$min - $dd/$mo/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final isInflow = {'income', 'borrowing', 'loan_repayment_received'}.contains(tx.type);
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
    
    final categoryColorHex = tx.categoryColor ?? '#60A5FA';
    final categoryColorParsed = _parseHexColor(categoryColorHex) ?? AppColors.accent;

    final String title = (tx.note != null && tx.note!.isNotEmpty)
        ? tx.note!
        : (tx.categoryName ?? 'Giao dịch');
    
    final walletLabel = tx.walletName ?? tx.fromWalletName ?? 'Ví';

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.card,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0x0CFFFFFF) : const Color(0xFFF8FAFC),
            borderRadius: AppRadius.card,
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconBadge(
                emoji: CategoryIconHelper.resolveIcon(tx.categoryIcon ?? tx.categoryName),
                tint: categoryColorParsed,
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
                      Icon(
                        arrowIcon,
                        size: 14,
                        color: amountColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        isTransfer ? formatVND(tx.amount) : '$sign${formatVND(tx.amount)}',
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
