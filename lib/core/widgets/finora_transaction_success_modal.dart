import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../data/models/transaction.dart';
import '../utils/formatters.dart';
import 'bank_icon.dart';
import 'finora_mascot.dart';
import 'finora_member_filter.dart';

/// Modal xác nhận giao dịch dạng Floating Card cao cấp chuẩn iOS (Không full màn, cách xa StatusBar).
/// Hiệu ứng chuyển cảnh mượt mà dấu tick và mascot nảy đàn hồi (Spring Animation).
/// Hiển thị trọn vẹn icon danh mục (TransactionIconWidget) và logo ngân hàng (BankIcon).
class FinoraTransactionSuccessModal extends StatefulWidget {
  final TransactionModel transaction;
  final bool isEdit;
  final String? walletName;
  final String? destinationWalletName;
  final String? spenderTag; // 'husband', 'wife', 'joint'
  final VoidCallback? onAddAnother;

  const FinoraTransactionSuccessModal({
    super.key,
    required this.transaction,
    this.isEdit = false,
    this.walletName,
    this.destinationWalletName,
    this.spenderTag,
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
    final screenH = MediaQuery.sizeOf(context).height;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            math.max(bottomSafe, 12.0) + 8.0,
          ),
          constraints: BoxConstraints(
            maxHeight: math.min(screenH * 0.72, 560.0),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: FinoraTransactionSuccessModal(
              transaction: transaction,
              isEdit: isEdit,
              walletName: walletName,
              destinationWalletName: destinationWalletName,
              spenderTag: spenderTag,
              onAddAnother: onAddAnother,
            ),
          ),
        );
      },
    );
  }

  @override
  State<FinoraTransactionSuccessModal> createState() =>
      _FinoraTransactionSuccessModalState();
}

class _FinoraTransactionSuccessModalState
    extends State<FinoraTransactionSuccessModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _checkAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.75, curve: Curves.elasticOut),
    );

    _checkAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final isEdit = widget.isEdit;
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

    String resolvedSpender =
        widget.spenderTag ?? transaction.owner ?? 'joint';
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

    final String sourceWalletDisplay = widget.walletName ??
        transaction.walletName ??
        transaction.fromWalletName ??
        'Ví chính';
    final String? destWalletDisplay = widget.destinationWalletName ??
        transaction.toWalletName ??
        transaction.creditCardName;

    final Color bgStart =
        isDark ? const Color(0xFF07111E) : const Color(0xFFF3F8F6);
    final Color bgEnd =
        isDark ? const Color(0xFF0D1E2D) : const Color(0xFFFFFFFF);
    final Color cardBg = isDark ? const Color(0xFF131F33) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color textSub =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : accentColor.withValues(alpha: 0.25),
          width: 1.2,
        ),
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
            size: 200,
            opacity: isDark ? 0.12 : 0.08,
            alignment: Alignment.bottomRight,
            offset: const Offset(20, 12),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Apple Sheet pill handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),

                // Top bar with status chip and close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
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
                              size: 14,
                              color: accentColor,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                isEdit
                                    ? 'CẬP NHẬT NHẬT KÝ THÀNH CÔNG'
                                    : 'XÁC NHẬN GHI SỔ THÀNH CÔNG',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
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
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(6),
                      ),
                      icon: Icon(
                        Icons.close_rounded,
                        color: textPrimary,
                        size: 18,
                      ),
                    ),
                  ],
                ),

                // Content scrollable
                Flexible(
                  child: SingleChildScrollView(
                    
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Mascot + Check Badge with spring animation
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            ScaleTransition(
                              scale: _scaleAnim,
                              child: Container(
                                width: 80,
                                height: 80,
                                padding: const EdgeInsets.all(6),
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
                                    color:
                                        accentColor.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: const FinoraMascotImage(
                                  pose: FinoraMascotPose.celebrate,
                                  size: 64,
                                ),
                              ),
                            ),
                            ScaleTransition(
                              scale: _checkAnim,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: cardBg,
                                    width: 2.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withValues(
                                          alpha: 0.45),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: Text(
                            isEdit
                                ? 'Đã cập nhật giao dịch!'
                                : 'Đã ghi nhận giao dịch!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isEdit
                              ? 'Nhật ký chi tiêu gia đình đã được đồng bộ'
                              : '$typeLabel · Đã lưu vào sổ chi tiêu',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textSub,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Amount Card
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(
                                alpha: isDark ? 0.15 : 0.09),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            '$signPrefix${formatVND(transaction.amount)}',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                              color: accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Receipt Details Table
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                              width: 1.1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                    alpha: isDark ? 0.30 : 0.05),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Danh mục (Full category icon/logo using TransactionIconWidget)
                              _buildReceiptRow(
                                label: 'Danh mục',
                                value: catDisplay,
                                iconWidget: TransactionIconWidget(
                                  type: transaction.type,
                                  categoryIcon: transaction.categoryIcon,
                                  categoryName: catDisplay,
                                  categoryColor: transaction.categoryColor,
                                  merchantId: transaction.merchantId,
                                  merchantName: transaction.merchantName,
                                  size: 26,
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
                              // Ví nguồn (Full bank icon badge)
                              _buildReceiptRow(
                                label: (isTransfer || isCardPayment)
                                    ? 'Từ ví → Đến ví'
                                    : 'Ví nguồn',
                                value: (isTransfer || isCardPayment) &&
                                        destWalletDisplay != null
                                    ? '${formatShortWalletName(sourceWalletDisplay)} → ${formatShortWalletName(destWalletDisplay)}'
                                    : sourceWalletDisplay,
                                iconWidget: (isTransfer || isCardPayment) && destWalletDisplay != null
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ClipOval(
                                            child: BankIcon(
                                              bankName: sourceWalletDisplay,
                                              size: 22,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            child: Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 13,
                                              color: textSub,
                                            ),
                                          ),
                                          ClipOval(
                                            child: BankIcon(
                                              bankName: destWalletDisplay,
                                              size: 22,
                                            ),
                                          ),
                                        ],
                                      )
                                    : ClipOval(
                                        child: BankIcon(
                                          bankName: sourceWalletDisplay,
                                          size: 24,
                                        ),
                                      ),
                                textPrimary: textPrimary,
                                textSub: textSub,
                              ),
                              _buildDivider(isDark),
                              // Người chi tiêu
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
                              // Thời gian
                              _buildReceiptRow(
                                label: 'Thời gian',
                                value: timeStr,
                                textPrimary: textPrimary,
                                textSub: textSub,
                              ),
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

                // Action buttons
                const SizedBox(height: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isEdit) ...[
                      SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          key: const ValueKey("finora-tx-success-add-another-button"),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(context).pop(true);
                            widget.onAddAnother?.call();
                          },
                          icon: Icon(
                            Icons.add_circle_outline_rounded,
                            size: 17,
                            color: accentColor,
                          ),
                          label: Text(
                            'Ghi tiếp',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
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
                      const SizedBox(height: 8),
                    ],
                    SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        key: const ValueKey('finora-tx-success-done-button'),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop(false);
                        },
                        icon: const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Hoàn tất & Đóng',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: accentColor.withValues(alpha: 0.35),
                          shape: const StadiumBorder(),
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

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textSub,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (iconWidget != null) ...[
                iconWidget,
                const SizedBox(width: 7),
              ],
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
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
