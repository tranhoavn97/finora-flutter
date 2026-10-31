import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../data/models/transaction.dart';
import '../utils/formatters.dart';
import 'finora_mascot.dart';
import 'finora_member_filter.dart';

/// Modal xác nhận giao dịch dạng Bottom Sheet chuẩn Apple iOS (Không full màn, cách xa StatusBar).
/// Hiệu ứng chuyển cảnh mượt mà dấu tick và mascot nảy đàn hồi (Spring Animation).
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
    final topSafe = MediaQuery.paddingOf(context).top;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: EdgeInsets.only(top: math.max(topSafe + 20.0, 48.0)),
          constraints: BoxConstraints(
            maxHeight: screenH * 0.80,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
              size: 220,
              opacity: isDark ? 0.12 : 0.08,
              alignment: Alignment.bottomRight,
              offset: const Offset(24, 16),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    20,
                    10,
                    20,
                    math.max(MediaQuery.paddingOf(context).bottom, 16.0) +
                        8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Thanh gạt modal phong cách Apple Sheet
                    Center(
                      child: Container(
                        width: 44,
                        height: 4.5,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),

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
                                        ? 'CẬP NHẬT NHẬT KÝ THÀNH CÔNG'
                                        : 'XÁC NHẬN GHI SỔ THÀNH CÔNG',
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
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          children: [
                            // Mascot + Check Badge với Spring Animation nảy mượt mà
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                ScaleTransition(
                                  scale: _scaleAnim,
                                  child: Container(
                                    width: 92,
                                    height: 92,
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
                                        color:
                                            accentColor.withValues(alpha: 0.4),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const FinoraMascotImage(
                                      pose: FinoraMascotPose.celebrate,
                                      size: 72,
                                    ),
                                  ),
                                ),
                                ScaleTransition(
                                  scale: _checkAnim,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: accentColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: cardBg,
                                        width: 2.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accentColor.withValues(
                                              alpha: 0.45),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 17,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            FadeTransition(
                              opacity: _fadeAnim,
                              child: Text(
                                isEdit
                                    ? 'Đã cập nhật giao dịch!'
                                    : 'Đã ghi nhận giao dịch!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 19.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isEdit
                                  ? 'Nhật ký chi tiêu gia đình đã được đồng bộ'
                                  : '$typeLabel · Đã lưu vào sổ chi tiêu',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: textSub,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Thẻ số tiền nổi bật
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(
                                    alpha: isDark ? 0.15 : 0.09),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.35),
                                  width: 1.2,
                                ),
                              ),
                              child: Text(
                                '$signPrefix${formatVND(transaction.amount)}',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                  color: accentColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Bảng kê chi tiết giao dịch (Đã bỏ Mã GD Ngân hàng theo yêu cầu)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                  width: 1.1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                        alpha: isDark ? 0.35 : 0.06),
                                    blurRadius: 22,
                                    offset: const Offset(0, 8),
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
                                        color: accentColor.withValues(
                                            alpha: 0.15),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        CategoryIconHelper
                                            .resolveTransactionIcon(
                                          transactionType: transaction.type,
                                          categoryIcon:
                                              transaction.categoryIcon,
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

                    // Nút bấm hành động
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!isEdit) ...[
                          SizedBox(
                            child: OutlinedButton.icon(
                              key: const ValueKey(
                                  "finora-tx-success-add-another-button"),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                Navigator.of(context).pop(true);
                                widget.onAddAnother?.call();
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
                                minimumSize: const Size.fromHeight(48),
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
                          child: ElevatedButton.icon(
                            key: const ValueKey('finora-tx-success-done-button'),
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
                              minimumSize: const Size.fromHeight(48),
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: accentColor.withValues(alpha: 0.4),
                              shape: const StadiumBorder(),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
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
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: textSub,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
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
