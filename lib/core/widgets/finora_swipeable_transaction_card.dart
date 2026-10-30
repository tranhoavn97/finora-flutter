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
import 'glass_widgets.dart';

/// Swipeable and Long-pressable transaction card wrapper for Finora.
/// - Swipe Right (startToEnd): Edit transaction (Blue #0284C7 background).
/// - Swipe Left (endToStart): Delete transaction with confirmation dialog (Coral Red #E11D48 background).
/// - Long Press: Haptic feedback + Quick Action Bottom Sheet (Edit / Delete).
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
    return Dismissible(
      key: ValueKey('tx-swipe-${transaction.id}'),
      direction: DismissDirection.horizontal,
      background: _buildSwipeActionBackground(
        alignment: Alignment.centerLeft,
        color: const Color(0xFF0284C7),
        icon: Icons.edit_rounded,
        label: 'Sửa',
        isStart: true,
      ),
      secondaryBackground: _buildSwipeActionBackground(
        alignment: Alignment.centerRight,
        color: const Color(0xFFE11D48),
        icon: Icons.delete_outline_rounded,
        label: 'Xóa',
        isStart: false,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe Right -> Edit
          HapticFeedback.mediumImpact();
          if (onEdit != null) {
            await onEdit!();
          } else {
            await Navigator.of(context).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => AddTransactionPage(
                  userId: userId,
                  existing: transaction,
                ),
              ),
            );
          }
          return false;
        } else if (direction == DismissDirection.endToStart) {
          // Swipe Left -> Delete
          HapticFeedback.mediumImpact();
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
            return true;
          }
          return false;
        }
        return false;
      },
      child: Material(
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
      ),
    );
  }

  Widget _buildSwipeActionBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
    required bool isStart,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isStart
            ? [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
              ]
            : [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white, size: 22),
              ],
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
  final amountColor =
      isIncome ? const Color(0xFF059669) : const Color(0xFFE11D48);
  final amountPrefix = isIncome ? '+' : '−';
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
                        isIncome
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
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

              const SizedBox(height: 18),

              // 2. Action: Chỉnh sửa giao dịch
              InkWell(
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
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(
                      alpha: isDark ? 0.20 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_rounded,
                          color: Color(0xFF0284C7), size: 19),
                      SizedBox(width: 10),
                      Text(
                        'Chỉnh sửa giao dịch',
                        style: TextStyle(
                          color: Color(0xFF0284C7),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 3. Action: Xóa giao dịch này
              InkWell(
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
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D48).withValues(
                      alpha: isDark ? 0.20 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE11D48).withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          color: Color(0xFFE11D48), size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Xóa giao dịch này',
                        style: TextStyle(
                          color: Color(0xFFE11D48),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 4. Cancel button
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
