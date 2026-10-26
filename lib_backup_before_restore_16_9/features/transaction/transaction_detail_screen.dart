import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/widgets/vikram_widgets.dart';
import '../../core/widgets/bank_icon.dart';
import '../../data/models/transaction.dart';
import '../../state/transaction_provider.dart';
import 'add_transaction_page.dart';

class TransactionDetailScreen extends StatelessWidget {
  final String userId;
  final TransactionModel transaction;

  const TransactionDetailScreen({
    super.key,
    required this.userId,
    required this.transaction,
  });

  void _handleEdit(BuildContext context) {
    if (transaction.isLinked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Giao dịch được liên kết với ${transaction.linkedReason ?? 'mục khác'}. Vui lòng quản lý từ mục tương ứng để bảo đảm toàn vẹn số dư.',
          ),
          backgroundColor: const Color(0xFFF59E0B),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddTransactionPage(
          userId: userId,
          existing: transaction,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);

    final categories = context.watch<TransactionProvider>().categories;
    final matchingCategory = categories.where((category) =>
        (transaction.categoryId?.isNotEmpty == true &&
            category.id == transaction.categoryId) ||
        (transaction.categoryId?.isNotEmpty != true &&
            category.name == transaction.categoryName));
    final liveCategory =
        matchingCategory.isEmpty ? null : matchingCategory.first;
    final resolvedCategoryIcon = liveCategory?.icon ?? transaction.categoryIcon;
    final resolvedCategoryName = liveCategory?.name ?? transaction.categoryName;
    final resolvedCategoryColor =
        liveCategory?.color ?? transaction.categoryColor;

    final isIncome = transaction.type == 'income' ||
        transaction.type == 'borrowing' ||
        transaction.type == 'loan_repayment_received';
    final sign = isIncome
        ? '+'
        : (TransactionVisuals.isTransfer(transaction.type) ? '' : '-');
    final amountText =
        '$sign${NumberFormat('#,##0', 'vi_VN').format(transaction.amount)} đ';
    final amountColor = TransactionVisuals.colorFor(transaction.type,
        categoryColor: resolvedCategoryColor);

    final txDate = DateTime.fromMillisecondsSinceEpoch(transaction.date);
    final formattedDate =
        '${DateFormat('dd/MM/yyyy').format(txDate)} lúc ${DateFormat('HH:mm').format(txDate)}';

    final note = transaction.note?.trim().isNotEmpty == true
        ? transaction.note!
        : (resolvedCategoryName ?? 'Giao dịch không tên');
    final wallet = transaction.walletName?.trim().isNotEmpty == true
        ? transaction.walletName!
        : 'Tiền mặt';
    final category = resolvedCategoryName?.trim().isNotEmpty == true
        ? resolvedCategoryName!
        : (transaction.type == 'loan' ? 'Cho vay cá nhân' : 'Ăn uống');

    final isLoan = transaction.type == 'loan' ||
        (transaction.note ?? '').toLowerCase().contains('cho vay');

    return PearlMeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // 1. Top Header Row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF161B26).withValues(alpha: 0.75)
                              : Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.white,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark
                                      ? Colors.black
                                      : const Color(0xFF1E293B))
                                  .withValues(alpha: isDark ? 0.20 : 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.chevron_left_rounded,
                            color: primaryTextColor, size: 24),
                      ),
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Chi tiết giao dịch',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: primaryTextColor,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _handleEdit(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: const Icon(Icons.edit_outlined,
                            color: Color(0xFF2563EB), size: 22),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      // 2. Main Transaction Card (Frosted Glass 32px)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 28, horizontal: 20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF161B26).withValues(alpha: 0.75)
                              : Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.white,
                            width: 1.1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark
                                      ? Colors.black
                                      : const Color(0xFF1E293B))
                                  .withValues(alpha: isDark ? 0.25 : 0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Icon in circular light-blue background
                            TransactionIconWidget(
                              type: transaction.type,
                              categoryIcon:
                                  isLoan ? 'handcoins' : resolvedCategoryIcon,
                              categoryName:
                                  resolvedCategoryName ?? transaction.note,
                              categoryColor: resolvedCategoryColor,
                              merchantId: transaction.merchantId,
                              size: 68,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Giao dịch',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              amountText,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: amountColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            const SizedBox(height: 20),

                            // Key-Value Rows
                            _buildDetailRow('Hạng mục', category,
                                primaryTextColor, secondaryTextColor),
                            const SizedBox(height: 16),
                            _buildDetailRow('Tài khoản / Ví', wallet,
                                primaryTextColor, secondaryTextColor),
                            const SizedBox(height: 16),
                            _buildDetailRow('Thời gian', formattedDate,
                                primaryTextColor, secondaryTextColor),
                            const SizedBox(height: 16),
                            _buildDetailRow('Ghi chú', note, primaryTextColor,
                                secondaryTextColor),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 3. Action Buttons Row: Xóa & Chỉnh sửa
                      Builder(
                        builder: (context) {
                          final isLargeFont =
                              MediaQuery.textScalerOf(context).scale(1.0) >
                                  1.25;

                          final deleteBtn = GestureDetector(
                            onTap: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18)),
                                  title: const Text('Xác nhận xóa',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800)),
                                  content: const Text(
                                      'Bạn có chắc chắn muốn xóa giao dịch này không?'),
                                  actions: [
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Hủy'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFEF4444),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      child: const Text('Xóa'),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true && context.mounted) {
                                await context
                                    .read<TransactionProvider>()
                                    .deleteTransaction(userId, transaction);
                                if (context.mounted) Navigator.pop(context);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF161B26).withValues(alpha: 0.75)
                                    : Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFFFCA5A5),
                                  width: 1.2,
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete_outline_rounded,
                                      color: Color(0xFFEF4444), size: 20),
                                  SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Xóa',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFEF4444),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );

                          final editBtn = GestureDetector(
                            onTap: () => _handleEdit(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 10),
                              decoration: BoxDecoration(
                                color: transaction.isLinked
                                    ? (isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFF94A3B8))
                                    : const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  if (!transaction.isLinked)
                                    BoxShadow(
                                      color: const Color(0xFF2563EB)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit_rounded,
                                      color: Colors.white, size: 18),
                                  SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Chỉnh sửa',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );

                          if (isLargeFont) {
                            return Column(
                              children: [
                                editBtn,
                                const SizedBox(height: 12),
                                deleteBtn,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: deleteBtn),
                              const SizedBox(width: 14),
                              Expanded(child: editBtn),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color primaryTextColor,
      Color secondaryTextColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: secondaryTextColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: primaryTextColor,
            ),
          ),
        ),
      ],
    );
  }
}
