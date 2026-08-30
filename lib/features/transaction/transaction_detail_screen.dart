import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/vikram_widgets.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
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

  static const _inflowTypes = {'income', 'borrowing', 'loan_repayment_received'};

  String _formatDateTime(int timestampMs) {
    final d = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final dd = d.day.toString().padLeft(2, '0');
    final mo = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$dd/$mo/${d.year} lúc $hh:$mm';
  }

  Color _parseColor(String? hex) {
    if (hex == null) return AppColors.primary;
    var clean = hex.trim().replaceFirst('#', '');
    if (clean.length == 6) clean = 'FF$clean';
    if (clean.length != 8) return AppColors.primary;
    final value = int.tryParse(clean, radix: 16);
    if (value == null) return AppColors.primary;
    return Color(value);
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'income':
        return 'Thu nhập';
      case 'expense':
        return 'Chi tiêu';
      case 'transfer':
        return 'Chuyển khoản';
      case 'credit_card_payment':
        return 'Thanh toán thẻ tín dụng';
      case 'investment':
        return 'Đầu tư';
      default:
        return 'Giao dịch';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isInflow = _inflowTypes.contains(transaction.type);
    final amountColor = isInflow ? AppColors.success : AppColors.error;
    final sign = isInflow ? '+' : '-';
    
    final categoryColor = _parseColor(transaction.categoryColor);
    final emoji = CategoryIconHelper.resolveIcon(transaction.categoryIcon);
    final typeLabel = _getTypeLabel(transaction.type);

    return PearlMeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassTopBar(
          title: 'Chi tiết giao dịch',
          onBack: () => Navigator.of(context).pop(),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => AddTransactionPage(
                      userId: userId,
                      existing: transaction,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // Receipt FrostedCard
                FrostedCard(
                  radius: 30,
                  padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Styled Icon Badge
                    IconBadge(
                      emoji: emoji,
                      tint: categoryColor,
                      size: 68,
                      radius: 22,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      typeLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: c.textSecondary,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Large Amount Display
                    Text(
                      '$sign${formatVND(transaction.amount)}',
                      style: TextStyle(
                        color: amountColor,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(
                      color: isDark ? const Color(0xFF202D4E) : const Color(0xFFE8EEF8),
                      thickness: 1,
                    ),
                    const SizedBox(height: 16),
                    
                    // Transaction Meta Info Rows
                    _buildInfoRow(
                      context,
                      label: 'Hạng mục',
                      value: transaction.categoryName ?? 'Chưa phân loại',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      label: 'Tài khoản / Ví',
                      value: transaction.walletName ?? transaction.fromWalletName ?? 'Ví chính',
                    ),
                    if (transaction.ownerName != null || transaction.owner != null) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        label: 'Người chi tiêu',
                        value: transaction.ownerName ?? (transaction.owner == 'wife' ? 'Vợ' : 'Chồng'),
                      ),
                    ],
                    if (transaction.type == 'transfer' && transaction.toWalletName != null) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        label: 'Đến ví',
                        value: transaction.toWalletName!,
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      label: 'Thời gian',
                      value: _formatDateTime(transaction.date),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      label: 'Ghi chú',
                      value: (transaction.note != null && transaction.note!.trim().isNotEmpty)
                          ? transaction.note!.trim()
                          : 'Không có ghi chú',
                      isMultiLine: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Edit / Delete Buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF18223D) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      child: TextButton.icon(
                        onPressed: () async {
                          HapticFeedback.selectionClick();
                          final confirm = await showConfirmDeleteDialog(
                            context: context,
                            title: 'Xóa giao dịch?',
                            content: 'Bạn có chắc chắn muốn xóa giao dịch này không?',
                          );
                          if (confirm && context.mounted) {
                            context.read<TransactionProvider>().deleteTransaction(userId, transaction);
                            Navigator.of(context).pop();
                          }
                        },
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 20, color: AppColors.error),
                        label: const Text(
                          'Xóa',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      height: 52,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (_) => AddTransactionPage(
                              userId: userId,
                              existing: transaction,
                            ),
                          ),
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Chỉnh sửa',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildInfoRow(BuildContext context, {required String label, required String value, bool isMultiLine = false}) {
    final c = context.fc;

    return Row(
      crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: c.textSecondary,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: isMultiLine ? 3 : 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: c.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
