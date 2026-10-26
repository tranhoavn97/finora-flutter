import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/glassmorphism_tokens.dart';
import '../catalog_mock_data.dart';
import 'catalog_glass_card.dart';

final NumberFormat _currencyFormat = NumberFormat('#,##0', 'vi_VN');

/// Helper base for Glass Bottom Sheets
Widget _buildGlassSheetContainer({
  required BuildContext context,
  required Widget child,
  double radius = 28.0,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return ClipRRect(
    borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
    child: BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: GlassmorphismTokens.sheetBlur,
        sigmaY: GlassmorphismTokens.sheetBlur,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF141721) : Colors.white)
              .withValues(alpha: isDark ? 0.88 : 0.92),
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: isDark ? 0.20 : 0.85),
              width: GlassmorphismTokens.borderThin,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
              blurRadius: 32,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle pill
                Center(
                  child: Container(
                    width: 38,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// -----------------------------------------------------------------------------
// 1. Transaction Detail Sheet
// -----------------------------------------------------------------------------
void showCatalogTransactionDetailSheet({
  required BuildContext context,
  required CatalogTransactionItem transaction,
  VoidCallback? onEdit,
  VoidCallback? onDelete,
}) {
  HapticFeedback.mediumImpact();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _buildGlassSheetContainer(
        context: sheetContext,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Category Icon + Title + Close
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: transaction.categoryColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: transaction.categoryColor.withValues(alpha: 0.35),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(transaction.icon, color: transaction.categoryColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${transaction.date} • ${transaction.time}',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Amount Display
            CatalogGlassCard(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Số tiền giao dịch',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${transaction.isExpense ? '-' : '+'}${_currencyFormat.format(transaction.amount)} ₫',
                    style: TextStyle(
                      color: transaction.isExpense
                          ? GlassmorphismTokens.expense
                          : GlassmorphismTokens.income,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Details Breakdown
            CatalogGlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _detailRow(
                    label: 'Danh mục',
                    value: transaction.category,
                    isDark: isDark,
                  ),
                  const Divider(height: 20, thickness: 0.5),
                  _detailRow(
                    label: 'Tài khoản / Ví',
                    value: transaction.walletName,
                    isDark: isDark,
                  ),
                  const Divider(height: 20, thickness: 0.5),
                  _detailRow(
                    label: 'Người chi trả',
                    value: transaction.memberTag,
                    isDark: isDark,
                  ),
                  if (transaction.note.isNotEmpty) ...[
                    const Divider(height: 20, thickness: 0.5),
                    _detailRow(
                      label: 'Ghi chú',
                      value: transaction.note,
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Actions: Edit & Delete
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: GlassmorphismTokens.expense.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      onDelete?.call();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã chuyển giao dịch vào Thùng rác 30 ngày'),
                          backgroundColor: GlassmorphismTokens.expense,
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.trash, size: 18, color: GlassmorphismTokens.expense),
                    label: const Text(
                      'Xóa',
                      style: TextStyle(color: GlassmorphismTokens.expense, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: GlassmorphismTokens.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      onEdit?.call();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Chế độ chỉnh sửa giao dịch thành công'),
                          backgroundColor: GlassmorphismTokens.primary,
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.pencil, size: 18, color: Colors.white),
                    label: const Text(
                      'Chỉnh sửa',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Widget _detailRow({required String label, required String value, required bool isDark}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          color: isDark ? Colors.white60 : Colors.black54,
          fontSize: 14,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

// -----------------------------------------------------------------------------
// 2. Wallet Reconcile Sheet
// -----------------------------------------------------------------------------
void showCatalogWalletReconcileSheet({
  required BuildContext context,
  required CatalogWalletItem wallet,
  ValueChanged<int>? onReconciled,
}) {
  HapticFeedback.mediumImpact();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final controller = TextEditingController(text: wallet.balance.toString());

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _buildGlassSheetContainer(
        context: sheetContext,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: GlassmorphismTokens.primary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.circle_check, color: GlassmorphismTokens.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Đối soát số dư thực tế',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          wallet.name,
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Số dư trên sổ FINORA: ${_currencyFormat.format(wallet.balance)} ₫',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Số dư thực tế tại ngân hàng (VNĐ)',
                suffixText: '₫',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: GlassmorphismTokens.primary,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                final newBalance = int.tryParse(controller.text) ?? wallet.balance;
                Navigator.pop(sheetContext);
                onReconciled?.call(newBalance);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã cập nhật số dư đối soát ví: ${_currencyFormat.format(newBalance)} ₫'),
                    backgroundColor: GlassmorphismTokens.income,
                  ),
                );
              },
              child: const Text('Xác nhận & Cân đối số dư', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    },
  );
}

// -----------------------------------------------------------------------------
// 3. Budget AI Analysis Sheet
// -----------------------------------------------------------------------------
void showCatalogBudgetAnalysisSheet({
  required BuildContext context,
  required CatalogBudgetItem budget,
}) {
  HapticFeedback.mediumImpact();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final percent = (budget.spent / budget.limit * 100).toStringAsFixed(1);
      final remaining = budget.limit - budget.spent;

      return _buildGlassSheetContainer(
        context: sheetContext,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9500).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(LucideIcons.sparkles, color: Color(0xFFFF9500), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Phân tích Ngân sách',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        budget.category,
                        style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CatalogGlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tiến độ chi tiêu', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                      Text('$percent%', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (budget.spent / budget.limit).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: isDark ? Colors.white12 : Colors.black12,
                      color: budget.spent > budget.limit ? GlassmorphismTokens.expense : const Color(0xFFFF9500),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Còn lại an toàn: ${_currencyFormat.format(remaining)} ₫',
                          style: TextStyle(
                            color: remaining >= 0 ? GlassmorphismTokens.income : GlassmorphismTokens.expense,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          )),
                      const Text('Mức chi/ngày: ~185.000 ₫', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CatalogGlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(LucideIcons.bot, size: 16, color: GlassmorphismTokens.primary),
                      SizedBox(width: 8),
                      Text('Lời khuyên từ Finora Copilot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bạn đã tiêu dùng $percent% hạn mức khi mới qua 2/3 chu kỳ tháng. '
                    'Để không bị thâm hụt ngân sách, hãy ưu tiên nấu ăn tại nhà và giảm tần suất các bữa tiệc ngoài hàng quán trong tuần cuối cùng.',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: GlassmorphismTokens.primary,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Đã hiểu & Áp dụng', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    },
  );
}

// -----------------------------------------------------------------------------
// 4. Goal Deposit Sheet
// -----------------------------------------------------------------------------
void showCatalogGoalDepositSheet({
  required BuildContext context,
  required CatalogGoalItem goal,
  ValueChanged<int>? onDeposit,
}) {
  HapticFeedback.mediumImpact();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final controller = TextEditingController(text: '5000000');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _buildGlassSheetContainer(
        context: sheetContext,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: goal.color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(goal.icon, color: goal.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tích lũy thêm vào mục tiêu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(goal.title, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(sheetContext)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                labelText: 'Số tiền nạp thêm',
                suffixText: '₫',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            const SizedBox(height: 14),
            // Quick amount chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [500000, 1000000, 2000000, 5000000, 10000000].map((amount) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text('+${_currencyFormat.format(amount)}đ'),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        controller.text = amount.toString();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: GlassmorphismTokens.primary,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                final depositAmount = int.tryParse(controller.text) ?? 5000000;
                Navigator.pop(sheetContext);
                onDeposit?.call(depositAmount);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã nạp ${_currencyFormat.format(depositAmount)} ₫ vào "${goal.title}"'),
                    backgroundColor: GlassmorphismTokens.income,
                  ),
                );
              },
              child: const Text('Xác nhận nạp tiền', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    },
  );
}

// -----------------------------------------------------------------------------
// 5. Loan Repayment Sheet
// -----------------------------------------------------------------------------
void showCatalogLoanRepaymentSheet({
  required BuildContext context,
  required CatalogLoanItem loan,
  ValueChanged<int>? onRepay,
}) {
  HapticFeedback.mediumImpact();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final controller = TextEditingController(text: (loan.remainingAmount ~/ 4).toString());

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final actionTitle = loan.isLending ? 'Thu hồi nợ đã cho vay' : 'Thanh toán trả nợ';

      return _buildGlassSheetContainer(
        context: sheetContext,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: loan.color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(loan.isLending ? LucideIcons.hand_coins : LucideIcons.credit_card, color: loan.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(actionTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(loan.name, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(sheetContext)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Dư nợ hiện tại: ${_currencyFormat.format(loan.remainingAmount)} ₫',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                labelText: 'Số tiền thanh toán đợt này',
                suffixText: '₫',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: loan.color,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                final repayAmount = int.tryParse(controller.text) ?? 0;
                Navigator.pop(sheetContext);
                onRepay?.call(repayAmount);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã ghi nhận thanh toán: ${_currencyFormat.format(repayAmount)} ₫'),
                    backgroundColor: GlassmorphismTokens.income,
                  ),
                );
              },
              child: const Text('Xác nhận thanh toán', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      );
    },
  );
}

// -----------------------------------------------------------------------------
// 6. Generic Add Modal
// -----------------------------------------------------------------------------
void showCatalogAddEntityModal({
  required BuildContext context,
  required String entityName,
  ValueChanged<String>? onCreated,
}) {
  HapticFeedback.lightImpact();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final controller = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _buildGlassSheetContainer(
        context: sheetContext,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Thêm mới $entityName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(sheetContext)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Tên $entityName',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: GlassmorphismTokens.primary,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(sheetContext);
                  onCreated?.call(name);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã tạo $entityName "$name" thành công'),
                      backgroundColor: GlassmorphismTokens.income,
                    ),
                  );
                }
              },
              child: const Text('Lưu thông tin', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    },
  );
}

/// Unified API for showing Glassmorphism 2.0 Catalog Bottom Sheets
class CatalogBottomSheets {
  static void showTransactionDetail(BuildContext context, CatalogTransactionItem transaction) {
    showCatalogTransactionDetailSheet(context: context, transaction: transaction);
  }

  static void showWalletReconciliationSheet(BuildContext context, CatalogWalletItem wallet) {
    showCatalogWalletReconcileSheet(context: context, wallet: wallet);
  }

  static void showAddWalletSheet(BuildContext context) {
    showCatalogAddEntityModal(context: context, entityName: 'Ví tài khoản');
  }

  static void showAiBudgetAnalysisSheet(BuildContext context) {
    showCatalogBudgetAnalysisSheet(context: context, budget: CatalogMockData.budgets.first);
  }

  static void showGoalDepositSheet(BuildContext context, CatalogGoalItem goal) {
    showCatalogGoalDepositSheet(context: context, goal: goal);
  }

  static void showLoanRepaymentSheet(BuildContext context, CatalogLoanItem loan) {
    showCatalogLoanRepaymentSheet(context: context, loan: loan);
  }
}
