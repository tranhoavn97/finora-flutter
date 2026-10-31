import 'dart:ui';
import 'finora_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/transaction.dart';
import '../../features/transaction/add_transaction_page.dart';
import '../../features/transaction/transaction_detail_sheet.dart';
import '../../state/transaction_provider.dart';
import 'finora_transaction_success_modal.dart';
import 'glass_widgets.dart';

/// Card giao dịch Finora:
/// - Chạm: Mở xem chi tiết giao dịch.
/// - Nhấn giữ: Mở Modal hành động nhanh phong cách iOS 27 Glass (Xem chi tiết, Sửa, Sao chép, Xem biên lai, Xóa).
/// - Đã loại bỏ vuốt trái/phải để tránh quẹt nhầm khi cuộn danh sách.
class FinoraSwipeableTransactionCard extends StatelessWidget {
  final String userId;
  final TransactionModel transaction;
  final Widget child;
  final double borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final Future<void> Function()? onEdit;

  const FinoraSwipeableTransactionCard({
    super.key,
    required this.userId,
    required this.transaction,
    required this.child,
    this.borderRadius = 18.0,
    this.onTap,
    this.onDeleted,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap ??
            () => showTransactionDetailSheet(
                  context,
                  userId: userId,
                  transaction: transaction,
                ),
        onLongPress: () {
          HapticFeedback.heavyImpact();
          showFinoraTransactionQuickSheet(
            context,
            userId: userId,
            transaction: transaction,
            onDeleted: onDeleted,
            onEdit: onEdit,
          );
        },
        child: child,
      ),
    );
  }
}

/// Displays an Executive Bento Quick Action Bottom Sheet on long-press
void showFinoraTransactionQuickSheet(
  BuildContext context, {
  required String userId,
  required TransactionModel transaction,
  VoidCallback? onDeleted,
  Future<void> Function()? onEdit,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final isIncome = transaction.type == 'income';
  final isTransfer = transaction.type == 'transfer';
  final isCardPayment = transaction.type == 'credit_card_payment';
  final amountColor = (isTransfer || isCardPayment)
      ? const Color(0xFF0284C7)
      : (isIncome ? const Color(0xFF10B981) : const Color(0xFFE11D48));
  final amountPrefix =
      (isTransfer || isCardPayment) ? '⇄ ' : (isIncome ? '+' : '−');
  final title = transaction.note?.trim().isNotEmpty == true
      ? transaction.note!
      : (transaction.categoryName ?? 'Giao dịch');

  final txDate = DateTime.fromMillisecondsSinceEpoch(
    transaction.date > 0
        ? transaction.date
        : (transaction.createdAt > 0
            ? transaction.createdAt
            : DateTime.now().millisecondsSinceEpoch),
  );
  final dateStr = DateFormat('HH:mm · dd/MM/yyyy').format(txDate);
  final walletStr = transaction.walletName ?? 'Ví chính';

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetCtx) {
      return GlassBottomSheet(
        showHandle: true,
        radius: 28,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.paddingOf(sheetCtx).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Transaction preview card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: amountColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: amountColor.withValues(alpha: 0.28),
                          width: 1.0,
                        ),
                      ),
                      child: Icon(
                        isTransfer || isCardPayment
                            ? Icons.swap_horiz_rounded
                            : (isIncome
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded),
                        color: amountColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$walletStr · $dateStr',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$amountPrefix${formatVND(transaction.amount)} ₫',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: amountColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Action: Xem chi tiết
              _buildActionRow(
                icon: Icons.visibility_outlined,
                iconColor: const Color(0xFF059669),
                title: 'Xem chi tiết giao dịch',
                subtitle: 'Xem đầy đủ thời gian, ví, người chi và ghi chú',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  showTransactionDetailSheet(
                    context,
                    userId: userId,
                    transaction: transaction,
                  );
                },
              ),

              const SizedBox(height: 8),

              // 3. Action: Chỉnh sửa giao dịch
              _buildActionRow(
                icon: Icons.edit_rounded,
                iconColor: const Color(0xFF0284C7),
                title: 'Chỉnh sửa giao dịch',
                subtitle: 'Thay đổi số tiền, danh mục, ví nguồn hoặc ghi chú',
                isDark: isDark,
                onTap: () async {
                  HapticFeedback.selectionClick();
                  Navigator.pop(sheetCtx);
                  if (onEdit != null) {
                    await onEdit();
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => AddTransactionPage(
                          userId: userId,
                          existing: transaction,
                        ),
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 8),

              // 4. Action: Sao chép / Nhân bản giao dịch
              _buildActionRow(
                icon: Icons.copy_rounded,
                iconColor: const Color(0xFF8B5CF6),
                title: 'Sao chép / Tạo tương tự',
                subtitle: 'Mở form thêm giao dịch với thông tin điền sẵn',
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(sheetCtx);
                  final clonedTx = transaction.copyWith(
                    id: '', // New transaction
                    date: DateTime.now().millisecondsSinceEpoch,
                    createdAt: DateTime.now().millisecondsSinceEpoch,
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => AddTransactionPage(
                        userId: userId,
                        existing: null,
                        initialType: clonedTx.type,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 8),

              // 5. Action: Xem biên lai giao dịch
              _buildActionRow(
                icon: Icons.receipt_rounded,
                iconColor: const Color(0xFFD97706),
                title: 'Xem biên lai chi tiêu',
                subtitle: 'Mở biên lai chứng từ điện tử Finora',
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(sheetCtx);
                  FinoraTransactionSuccessModal.show(
                    context,
                    transaction: transaction,
                    isEdit: true,
                  );
                },
              ),

              const SizedBox(height: 8),

              // 6. Action: Xóa giao dịch này
              _buildActionRow(
                icon: Icons.delete_outline_rounded,
                iconColor: const Color(0xFFE11D48),
                title: 'Xóa giao dịch này',
                subtitle: 'Hoàn trả số dư ví và cập nhật lại báo cáo',
                isDark: isDark,
                isDanger: true,
                onTap: () async {
                  HapticFeedback.selectionClick();
                  Navigator.pop(sheetCtx);
                  final confirmed = await showConfirmDeleteDialog(
                    context: context,
                    title: 'Xóa giao dịch này?',
                    content:
                        'Số dư ví và báo cáo liên quan sẽ được tự động cập nhật lại ngay sau khi xóa.',
                  );
                  if (confirmed == true && context.mounted) {
                    await context
                        .read<TransactionProvider>()
                        .delete(userId, transaction.id);
                    if (context.mounted) {
                      FinoraNotice.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã xóa giao dịch thành công.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                    onDeleted?.call();
                  }
                },
              ),

              const SizedBox(height: 12),

              // Cancel button
              SizedBox(
                height: 44,
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetCtx),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Đóng',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildActionRow({
  required IconData icon,
  required Color iconColor,
  required String title,
  required String subtitle,
  required bool isDark,
  required VoidCallback onTap,
  bool isDanger = false,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isDanger
              ? const Color(0xFFE11D48).withValues(alpha: isDark ? 0.15 : 0.08)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDanger
                ? const Color(0xFFE11D48).withValues(alpha: 0.35)
                : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: isDark ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDanger
                          ? const Color(0xFFE11D48)
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 11,
                      color: isDanger
                          ? const Color(0xFFE11D48).withValues(alpha: 0.8)
                          : (isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
          ],
        ),
      ),
    ),
  );
}
