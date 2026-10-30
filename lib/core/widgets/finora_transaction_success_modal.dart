import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../data/models/transaction.dart';
import '../utils/formatters.dart';
import 'finora_mascot.dart';
import 'finora_member_filter.dart';

/// Modal xác nhận toàn màn hình (Full-Screen Receipt Modal) khi thêm mới hoặc chỉnh sửa giao dịch thành công.
class FinoraTransactionSuccessModal extends StatelessWidget {
  final TransactionModel transaction;
  final bool isEdit;
  final String? walletName;
  final String? destinationWalletName;
  final String? spenderTag; // 'husband', 'wife', 'joint'
  final String? bankTransactionCode;
  final VoidCallback? onAddAnother;

  const FinoraTransactionSuccessModal({
    super.key,
    required this.transaction,
    this.isEdit = false,
    this.walletName,
    this.destinationWalletName,
    this.spenderTag,
    this.bankTransactionCode,
    this.onAddAnother,
  });

  static Future<bool?> show(
    BuildContext context, {
    required TransactionModel transaction,
    bool isEdit = false,
    String? walletName,
    String? destinationWalletName,
    String? spenderTag,
    String? bankTransactionCode,
    VoidCallback? onAddAnother,
  }) async {
    if (!context.mounted) return false;
    HapticFeedback.heavyImpact();
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SizedBox(
          width: double.infinity,
          height: MediaQuery.sizeOf(ctx).height,
          child: FinoraTransactionSuccessModal(
            transaction: transaction,
            isEdit: isEdit,
            walletName: walletName,
            destinationWalletName: destinationWalletName,
            spenderTag: spenderTag,
            bankTransactionCode: bankTransactionCode,
            onAddAnother: onAddAnother,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = transaction.type == 'income' ||
        transaction.type == 'loan_repayment_received';
    final isTransfer = transaction.type == 'transfer';
    final isCardPayment = transaction.type == 'credit_card_payment';
    final Color accentColor = (isTransfer || isCardPayment)
        ? const Color(0xFF0284C7)
        : (isIncome ? const Color(0xFF10B981) : const Color(0xFFF43F5E));

    final String signPrefix =
        (isTransfer || isCardPayment) ? '⇄ ' : (isIncome ? '+' : '-');
    final String typeLabel = isCardPayment
        ? 'Thanh toán thẻ tín dụng'
        : (isTransfer
            ? 'Chuyển khoản nội bộ'
            : (isIncome ? 'Khoản thu nhập' : 'Khoản chi tiêu'));

    String resolvedSpender = spenderTag ?? transaction.owner ?? 'joint';
    if (resolvedSpender.isEmpty) {
      if (transaction.tags.contains('spender:husband') ||
          transaction.tags.contains('husband')) {
        resolvedSpender = 'husband';
      } else if (transaction.tags.contains('spender:wife') ||
          transaction.tags.contains('wife')) {
        resolvedSpender = 'wife';
      } else {
        resolvedSpender = 'joint';
      }
    }
    final String spenderLabel = resolvedSpender == 'husband'
        ? 'Chồng'
        : (resolvedSpender == 'wife' ? 'Vợ' : 'Chung (Cả hai vợ chồng)');

    final String effectiveBankCode =
        (bankTransactionCode?.trim().isNotEmpty ?? false)
            ? bankTransactionCode!.trim()
            : (transaction.bankTransactionCode?.trim() ?? '');

    final int tsMs = transaction.date > 0
        ? transaction.date
        : (transaction.createdAt > 0
            ? transaction.createdAt
            : DateTime.now().millisecondsSinceEpoch);
    final String timeStr = DateFormat('HH:mm · dd/MM/yyyy')
        .format(DateTime.fromMillisecondsSinceEpoch(tsMs));

    final String catDisplay =
        (transaction.categoryName?.trim().isNotEmpty ?? false)
            ? transaction.categoryName!.trim()
            : (isTransfer
                ? 'Chuyển khoản'
                : (isCardPayment ? 'Trả thẻ tín dụng' : 'Giao dịch'));

    final String? merchantDisplay =
        (transaction.merchantName?.trim().isNotEmpty ?? false)
            ? transaction.merchantName!.trim()
            : null;

    final String noteDisplay = transaction.note?.trim() ?? '';

    final String sourceWalletDisplay =
        walletName ?? transaction.walletName ?? transaction.fromWalletName ?? 'Ví chính';
    final String? destWalletDisplay =
        destinationWalletName ?? transaction.toWalletName ?? transaction.creditCardName;

    final Color bgStart =
        isDark ? const Color(0xFF07111E) : const Color(0xFFF3F8F6);
    final Color bgEnd =
        isDark ? const Color(0xFF0D1E2D) : const Color(0xFFFFFFFF);
    final Color cardBg = isDark ? const Color(0xFF131F33) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color textSub =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgStart, bgEnd],
          ),
        ),
        child: Stack(
          children: [
            // Linh thú chìm lớn góc dưới phải
            FinoraAmbientMascotWatermark(
              pose: FinoraMascotPose.celebrate,
              size: 240,
              opacity: isDark ? 0.12 : 0.09,
              alignment: Alignment.bottomRight,
              offset: const Offset(28, 18),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 15,
                                  color: accentColor,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    isEdit
                                        ? 'BIÊN LAI CẬP NHẬT SỔ CÁI'
                                        : 'BIÊN LAI GHI SỔ THÀNH CÔNG',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.6,
                                      color: accentColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Đóng',
                          onPressed: () => Navigator.of(context).pop(),
                          style: IconButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                            shape: const CircleBorder(),
                          ),
                          icon: Icon(
                            Icons.close_rounded,
                            color: textPrimary,
                            size: 20,
                          ),
                        ),
                      ],
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            // Mascot + Check Badge
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 96,
                                  height: 96,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        accentColor.withValues(
                                            alpha: isDark ? 0.28 : 0.18),
                                        accentColor.withValues(alpha: 0.03),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: accentColor.withValues(alpha: 0.4),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const FinoraMascotImage(
                                    pose: FinoraMascotPose.celebrate,
                                    size: 76,
                                  ),
                                ),
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: cardBg,
                                      width: 2.2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Đã ghi nhận giao dịch!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isEdit
                                  ? 'Đã cập nhật giao dịch · $typeLabel'
                                  : typeLabel,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: textSub,
                              ),
                            ),
                            const SizedBox(height: 14),
                            // Big Amount Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(
                                    alpha: isDark ? 0.15 : 0.09),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.35),
                                  width: 1.2,
                                ),
                              ),
                              child: Text(
                                '$signPrefix${formatVND(transaction.amount)}',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                  color: accentColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Receipt Card
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                  width: 1.1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: isDark ? 0.35 : 0.06),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _buildReceiptRow(
                                    label: 'Danh mục',
                                    value: catDisplay,
                                    iconWidget: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: accentColor.withValues(alpha: 0.15),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        CategoryIconHelper.resolveTransactionIcon(
                                          transactionType: transaction.type,
                                          categoryIcon: transaction.categoryIcon,
                                          categoryName: catDisplay,
                                          note: noteDisplay,
                                        ),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    textPrimary: textPrimary,
                                    textSub: textSub,
                                  ),
                                  if (merchantDisplay != null) ...[
                                    _buildDivider(isDark),
                                    _buildReceiptRow(
                                      label: 'Nơi mua / Đơn vị',
                                      value: merchantDisplay,
                                      textPrimary: textPrimary,
                                      textSub: textSub,
                                    ),
                                  ],
                                  _buildDivider(isDark),
                                  _buildReceiptRow(
                                    label: (isTransfer || isCardPayment)
                                        ? 'Từ ví → Đến ví'
                                        : 'Ví nguồn',
                                    value: (isTransfer || isCardPayment) &&
                                            destWalletDisplay != null
                                        ? '${formatShortWalletName(sourceWalletDisplay)} → ${formatShortWalletName(destWalletDisplay)}'
                                        : sourceWalletDisplay,
                                    textPrimary: textPrimary,
                                    textSub: textSub,
                                  ),
                                  _buildDivider(isDark),
                                  _buildReceiptRow(
                                    label: 'Người chi tiêu',
                                    value: spenderLabel,
                                    iconWidget: FinoraMemberAvatar(
                                      member: resolvedSpender == 'joint'
                                          ? null
                                          : resolvedSpender,
                                      size: 24,
                                      isDark: isDark,
                                      showRing: true,
                                    ),
                                    textPrimary: textPrimary,
                                    textSub: textSub,
                                  ),
                                  _buildDivider(isDark),
                                  _buildReceiptRow(
                                    label: 'Thời gian',
                                    value: timeStr,
                                    textPrimary: textPrimary,
                                    textSub: textSub,
                                  ),
                                  if (effectiveBankCode.isNotEmpty) ...[
                                    _buildDivider(isDark),
                                    _buildReceiptRow(
                                      label: 'Mã GD Ngân hàng',
                                      value: effectiveBankCode,
                                      textPrimary: const Color(0xFF0284C7),
                                      textSub: textSub,
                                      isMono: true,
                                    ),
                                  ],
                                  if (noteDisplay.isNotEmpty) ...[
                                    _buildDivider(isDark),
                                    _buildReceiptRow(
                                      label: 'Ghi chú riêng',
                                      value: noteDisplay,
                                      textPrimary: textPrimary,
                                      textSub: textSub,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Action Buttons
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (!isEdit) ...[
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  Navigator.of(context).pop(true);
                                  onAddAnother?.call();
                                },
                                icon: Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 18,
                                  color: accentColor,
                                ),
                                label: Text(
                                  'Ghi tiếp',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: textPrimary,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  shape: const StadiumBorder(),
                                  side: BorderSide(
                                    color: accentColor.withValues(alpha: 0.45),
                                    width: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              key: const ValueKey(
                                  'finora-tx-success-done-button'),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).pop(false);
                              },
                              icon: const Icon(
                                Icons.check_circle_rounded,
                                size: 19,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Hoàn tất & Đóng',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14.5,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: accentColor.withValues(alpha: 0.4),
                                shape: const StadiumBorder(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Divider(
        height: 1,
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildReceiptRow({
    required String label,
    required String value,
    required Color textPrimary,
    required Color textSub,
    Widget? iconWidget,
    bool isMono = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: textSub,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (iconWidget != null) ...[
                iconWidget,
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    fontFamily: isMono ? 'monospace' : null,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
