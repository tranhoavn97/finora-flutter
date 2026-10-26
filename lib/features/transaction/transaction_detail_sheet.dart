import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/finora_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../../data/services/wallet_repository.dart';
import '../../state/transaction_provider.dart';
import '../../state/wallet_provider.dart';
import 'add_transaction_page.dart';

/// Modal Chi Tiết Giao Dịch phong cách Sổ kế toán tối giản (2026 Ledger Receipt)
Future<void> showTransactionDetailSheet(
  BuildContext context, {
  required String userId,
  required TransactionModel transaction,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final action = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (sheetContext) => Container(
      decoration: BoxDecoration(
        color: FinoraTokens.surface(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: FinoraTokens.line(isDark),
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: _TransactionDetailModalContent(
          userId: userId,
          transaction: transaction,
        ),
      ),
    ),
  );

  if (!context.mounted || action == null) return;

  if (action == 'edit') {
    if (transaction.loanId != null ||
        transaction.goalId != null ||
        transaction.assetId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Giao dịch liên kết cần chỉnh sửa từ mục tương ứng (Mục tiêu, Khoản nợ, Tài sản).',
          ),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddTransactionPage(userId: userId, existing: transaction),
      ),
    );
  } else if (action == 'delete') {
    final confirm = await showConfirmDeleteDialog(
      context: context,
      title: 'Xóa giao dịch này?',
      content:
          'Số dư ví và báo cáo liên quan sẽ được tự động cập nhật lại ngay sau khi xóa.',
    );
    if (confirm && context.mounted) {
      await context.read<TransactionProvider>().delete(userId, transaction.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa giao dịch thành công.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _TransactionDetailModalContent extends StatelessWidget {
  final String userId;
  final TransactionModel transaction;

  const _TransactionDetailModalContent({
    required this.userId,
    required this.transaction,
  });

  Wallet? _resolveWallet(
    List<Wallet> wallets,
    String? targetId,
    String? targetName,
  ) {
    if (wallets.isEmpty) return null;
    if (targetId != null && targetId.trim().isNotEmpty) {
      for (final w in wallets) {
        if (w.id == targetId) return w;
      }
    }
    if (targetName != null && targetName.trim().isNotEmpty) {
      final norm = targetName.trim().toLowerCase();
      for (final w in wallets) {
        if (w.name.trim().toLowerCase() == norm ||
            (w.bankName?.trim().toLowerCase() == norm)) {
          return w;
        }
      }
    }
    return null;
  }

  String? _resolveBankCode(Wallet? wallet, String? fallbackName) {
    final rawCode = wallet?.bankCode?.trim();
    if (rawCode != null && rawCode.isNotEmpty) {
      return rawCode;
    }
    final combined = [
      wallet?.bankName,
      wallet?.name,
      fallbackName,
    ].whereType<String>().join(' ').toLowerCase();
    if (combined.contains('mb') ||
        combined.contains('tiết kiệm') ||
        combined.contains('tiet kiem')) {
      return 'mbbank';
    }
    if (combined.contains('techcom') || combined.contains('tcb')) {
      return 'tcb';
    }
    if (combined.contains('vietcom') || combined.contains('vcb')) {
      return 'vcb';
    }
    if (combined.contains('tiền mặt') || combined.contains('tien mat')) {
      return 'cash';
    }
    final typeCode = wallet?.type.trim();
    if (typeCode != null && typeCode.isNotEmpty) {
      return typeCode;
    }
    return null;
  }

  bool _resolveIsWife(TransactionModel tx, Wallet? matchingWallet) {
    final candidates = <String?>[
      tx.owner,
      tx.creatorTag,
      matchingWallet?.owner,
      tx.ownerName,
      tx.creatorName,
      tx.fromOwner,
      tx.paidByOwner,
      ...tx.tags,
      matchingWallet?.ownerName,
    ];
    for (final raw in candidates) {
      if (raw == null) continue;
      final v = raw.trim().toLowerCase();
      if (v.isEmpty) continue;
      if (v == 'wife' ||
          v == 'vợ' ||
          v == 'vo' ||
          v == 'female' ||
          v == 'bà xã' ||
          v.contains('vợ') ||
          v.contains('wife')) {
        return true;
      }
      if (v == 'husband' ||
          v == 'chồng' ||
          v == 'chong' ||
          v == 'male' ||
          v == 'ông xã' ||
          v.contains('chồng') ||
          v.contains('husband')) {
        return false;
      }
    }
    return matchingWallet?.owner.trim().toLowerCase() == 'wife';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txProvider = Provider.of<TransactionProvider?>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider?>(context, listen: false);
    final allWallets = <Wallet>[
      ...?txProvider?.wallets,
      ...?walletProvider?.wallets,
    ];
    final tx = transaction;

    final matchingWallet = _resolveWallet(
      allWallets,
      tx.walletId ?? tx.fromWalletId,
      tx.walletName ?? tx.fromWalletName,
    );
    final sourceBankCode = _resolveBankCode(
      matchingWallet,
      tx.walletName ?? tx.fromWalletName,
    );
    final sourceBankName = matchingWallet?.bankName ??
        matchingWallet?.name ??
        tx.walletName ??
        tx.fromWalletName;

    final destWallet = _resolveWallet(
      allWallets,
      tx.toWalletId ?? tx.creditCardId,
      tx.toWalletName ?? tx.creditCardName,
    );
    final destBankCode = _resolveBankCode(
      destWallet,
      tx.toWalletName ?? tx.creditCardName,
    );
    final destBankName = destWallet?.bankName ??
        destWallet?.name ??
        tx.toWalletName ??
        tx.creditCardName;

    final normType = WalletRepository.normalizeTransactionType(tx.type);
    final isInflow =
        {'income', 'borrowing', 'loan_repayment_received'}.contains(normType);
    final isTransfer = normType == 'transfer';

    // Ledger Theme Semantics based on Transaction Type
    final Color amountColor;
    final String sign;
    final String statusBadgeText;

    if (isTransfer) {
      amountColor = FinoraTokens.ink(isDark);
      statusBadgeText = 'Chuyển khoản nội bộ';
      sign = '';
    } else if (isInflow) {
      amountColor = isDark ? FinoraTokens.posGreenDark : FinoraTokens.posGreen;
      statusBadgeText = normType == 'borrowing'
          ? 'Khoản đi vay'
          : 'Đã hoàn tất · Thu nhập';
      sign = '+';
    } else {
      amountColor = isDark ? FinoraTokens.negRedDark : FinoraTokens.negRed;
      statusBadgeText = normType == 'loan'
          ? 'Khoản cho vay'
          : 'Đã hoàn tất · Chi tiêu';
      sign = '−';
    }

    final date = DateTime.fromMillisecondsSinceEpoch(
      tx.date > 100000000000 ? tx.date : tx.date * 1000,
    );
    final formattedTime = DateFormat('HH:mm').format(date);
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);
    final weekdayName = _getWeekdayVietnamese(date.weekday);

    final hasCustomNote = tx.note != null && tx.note!.trim().isNotEmpty;
    final displayTitle = hasCustomNote ? tx.note!.trim() : (tx.categoryName ?? 'Giao dịch');
    final isWife = _resolveIsWife(tx, matchingWallet);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        0,
        8,
        0,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. TOP SHEET DRAG HANDLE
          Center(
            child: Container(
              width: 36,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? FinoraTokens.paperLine2Dark : FinoraTokens.paperLine2Light,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Header Row with Title and Close Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const SizedBox(width: 32),
                Expanded(
                  child: Text(
                    'Chi tiết giao dịch',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'BeVietnamPro',
                      color: FinoraTokens.ink(isDark),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: FinoraTokens.surface2(isDark),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: FinoraTokens.line(isDark),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: FinoraTokens.ink(isDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. HERO RECEIPT BLOCK (Editorial Minimalist)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Category Tile 52x52
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: FinoraTokens.surface2(isDark),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: FinoraTokens.line(isDark),
                      width: 1.0,
                    ),
                  ),
                  child: Center(
                    child: CategoryIconBadge(
                      icon: tx.categoryIcon,
                      categoryName: tx.categoryName,
                      size: 28,
                      isDark: isDark,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Big Hero Amount with Tabular Figures
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$sign${formatVND(tx.amount)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'BeVietnamPro',
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: amountColor,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Note or Category Title
                Text(
                  displayTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'BeVietnamPro',
                    color: FinoraTokens.ink(isDark),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: FinoraTokens.surface2(isDark),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: FinoraTokens.line(isDark),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    statusBadgeText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'BeVietnamPro',
                      color: FinoraTokens.inkSecondary(isDark),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. DETAILED LEDGER RECEIPT POD
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FinoraTokens.surface2(isDark),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: FinoraTokens.line(isDark),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Row 1: Category
                _buildReceiptRow(
                  isDark: isDark,
                  label: 'Danh mục',
                  valueWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CategoryIconBadge(
                        icon: tx.categoryIcon,
                        categoryName: tx.categoryName,
                        size: 20,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          tx.categoryName ?? 'Chưa phân loại',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'BeVietnamPro',
                            color: FinoraTokens.ink(isDark),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                _buildHairlineDivider(isDark),

                // Row 2: Source Wallet
                _buildReceiptRow(
                  isDark: isDark,
                  label: isTransfer ? 'Từ ví nguồn' : 'Nguồn tiền',
                  valueWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BankIcon(
                        bankCode: sourceBankCode,
                        bankName: sourceBankName,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          matchingWallet?.name ??
                              tx.walletName ??
                              tx.fromWalletName ??
                              'Tiền mặt',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'BeVietnamPro',
                            color: FinoraTokens.ink(isDark),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Row 2.1: Destination Wallet (if Transfer)
                if (isTransfer &&
                    (tx.toWalletName != null ||
                        tx.creditCardName != null ||
                        destWallet != null)) ...[
                  _buildHairlineDivider(isDark),
                  _buildReceiptRow(
                    isDark: isDark,
                    label: 'Đến ví nhận',
                    valueWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BankIcon(
                          bankCode: destBankCode,
                          bankName: destBankName,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            destWallet?.name ??
                                tx.toWalletName ??
                                tx.creditCardName ??
                                'Ví đích',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'BeVietnamPro',
                              color: FinoraTokens.ink(isDark),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                _buildHairlineDivider(isDark),

                // Row 3: Timestamp
                _buildReceiptRow(
                  isDark: isDark,
                  label: 'Thời gian',
                  value: '$formattedTime · $weekdayName $formattedDate',
                  isTabular: true,
                ),

                _buildHairlineDivider(isDark),

                // Row 4: Member
                _buildReceiptRow(
                  isDark: isDark,
                  label: 'Người chi',
                  value: isWife ? 'Thảo Linh (Vợ)' : 'Hòa Trần (Chồng)',
                ),

                // Row 5: Custom Note (if present)
                if (hasCustomNote && tx.categoryName != null) ...[
                  _buildHairlineDivider(isDark),
                  _buildReceiptRow(
                    isDark: isDark,
                    label: 'Ghi chú',
                    value: tx.note!,
                  ),
                ],
              ],
            ),
          ),

          // Financial Link Notice (if any)
          if (tx.loanId != null || tx.goalId != null || tx.assetId != null) ...[
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: (isDark ? FinoraTokens.warnAmberDark : FinoraTokens.warnAmber)
                    .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (isDark ? FinoraTokens.warnAmberDark : FinoraTokens.warnAmber)
                      .withValues(alpha: 0.30),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.link_rounded,
                    color: isDark ? FinoraTokens.warnAmberDark : FinoraTokens.warnAmber,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tx.goalId != null
                          ? 'Giao dịch liên kết đóng góp vào Mục tiêu tài chính.'
                          : (tx.loanId != null
                              ? 'Giao dịch liên kết theo dõi Khoản vay / Sổ nợ.'
                              : 'Giao dịch liên kết dòng tiền Tài sản tích lũy.'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? FinoraTokens.warnAmberDark : FinoraTokens.warnAmber,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // 4. ACTION BUTTONS ROW (Edit Primary + Delete Danger Outline)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Edit Button (Flexible 1)
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context, 'edit');
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: FinoraTokens.ink(isDark),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_rounded,
                              size: 16,
                              color: isDark ? FinoraTokens.paperBgDark : Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Chỉnh sửa',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'BeVietnamPro',
                                color: isDark ? FinoraTokens.paperBgDark : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Delete Button (Compact 44x44 danger button)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context, 'delete');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF261314)
                            : const Color(0xFFFDF3F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF5A2222)
                              : const Color(0xFFF3C8C5),
                          width: 1.0,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: isDark ? FinoraTokens.negRedDark : FinoraTokens.negRed,
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
    );
  }

  Widget _buildReceiptRow({
    required bool isDark,
    required String label,
    String? value,
    Widget? valueWidget,
    bool isTabular = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'BeVietnamPro',
              color: FinoraTokens.inkSecondary(isDark),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: valueWidget ??
                  Text(
                    value ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'BeVietnamPro',
                      fontFeatures: isTabular ? const [FontFeature.tabularFigures()] : null,
                      color: FinoraTokens.ink(isDark),
                    ),
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHairlineDivider(bool isDark) {
    return Divider(
      height: 18,
      thickness: 0.8,
      color: FinoraTokens.line(isDark),
    );
  }

  String _getWeekdayVietnamese(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Thứ Hai';
      case DateTime.tuesday:
        return 'Thứ Ba';
      case DateTime.wednesday:
        return 'Thứ Tư';
      case DateTime.thursday:
        return 'Thứ Năm';
      case DateTime.friday:
        return 'Thứ Sáu';
      case DateTime.saturday:
        return 'Thứ Bảy';
      case DateTime.sunday:
        return 'Chủ Nhật';
      default:
        return '';
    }
  }
}
