import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/widgets/glass_widgets.dart';
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
    if (hex == null) return const Color(0xFF60A5FA);
    var clean = hex.trim().replaceFirst('#', '');
    if (clean.length == 6) clean = 'FF$clean';
    if (clean.length != 8) return const Color(0xFF60A5FA);
    final value = int.tryParse(clean, radix: 16);
    if (value == null) return const Color(0xFF60A5FA);
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
      default:
        return 'Giao dịch';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final isInflow = _inflowTypes.contains(transaction.type);
    final amountColor = isInflow ? const Color(0xFF34D399) : const Color(0xFFF87171);
    final sign = isInflow ? '+' : '-';
    
    final categoryColor = _parseColor(transaction.categoryColor);
    final emoji = CategoryIconHelper.resolveIcon(transaction.categoryIcon);
    final typeLabel = _getTypeLabel(transaction.type);

    return GlassScaffold(
      appBar: GlassTopBar(
        title: 'Chi tiết giao dịch',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Receipt GlassCard
              GlassCard(
                radius: AppRadius.xl,
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Styled Circle Icon
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: categoryColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      typeLabel,
                      style: AppTypography.caption2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: secondaryTextColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Large Amount Display
                    Text(
                      '$sign${formatVND(transaction.amount)}',
                      style: AppTypography.largeTitle.copyWith(
                        color: amountColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, thickness: 1),
                    const SizedBox(height: AppSpacing.md),
                    
                    // Transaction Meta Info Rows
                    _buildInfoRow(
                      context,
                      label: 'Hạng mục',
                      value: transaction.categoryName ?? 'Chưa phân loại',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildInfoRow(
                      context,
                      label: 'Tài khoản/Ví',
                      value: transaction.walletName ?? transaction.fromWalletName ?? 'Ví chính',
                    ),
                    if (transaction.type == 'transfer' && transaction.toWalletName != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _buildInfoRow(
                        context,
                        label: 'Đến ví',
                        value: transaction.toWalletName!,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    _buildInfoRow(
                      context,
                      label: 'Thời gian',
                      value: _formatDateTime(transaction.date),
                    ),
                    const SizedBox(height: AppSpacing.sm),
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
              const SizedBox(height: AppSpacing.xxl),
              
              // Edit/Delete Buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.4),
                        borderRadius: AppRadius.button,
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          width: 1.2,
                        ),
                      ),
                      child: TextButton.icon(
                        onPressed: () async {
                          final confirm = await showConfirmDeleteDialog(
                            context: context,
                            title: 'Xóa giao dịch?',
                            content: 'Bạn có chắc chắn muốn xóa giao dịch này không?',
                          );
                          if (confirm && context.mounted) {
                            context.read<TransactionProvider>().deleteTransaction(userId, transaction);
                            Navigator.of(context).pop(); // Go back to transactions screen
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFF87171),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.button,
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 20),
                        label: Text(
                          'Xóa',
                          style: AppTypography.buttonLabel.copyWith(
                            color: const Color(0xFFF87171),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: GradientButton(
                      onPressed: () {
                        // Open Edit Form
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
                      radius: AppRadius.sm,
                      colors: const [AppColors.accent, AppColors.accentLight],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.edit_outlined, size: 20, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Chỉnh sửa',
                            style: AppTypography.buttonLabel.copyWith(
                              color: Colors.white,
                            ),
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
    );
  }

  Widget _buildInfoRow(BuildContext context, {required String label, required String value, bool isMultiLine = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Row(
      crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.caption1.copyWith(
            color: secondaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: isMultiLine ? 3 : 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption1.copyWith(
              color: primaryTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
