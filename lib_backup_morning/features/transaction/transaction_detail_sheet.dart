import 'package:flutter/material.dart';
import '../../data/models/transaction.dart';
import '../../core/widgets/finora/financial_components.dart';
import 'transaction_detail_screen.dart';
import 'add_transaction_page.dart';

Future<void> showTransactionDetailSheet(BuildContext context,
    {required String userId, required TransactionModel transaction}) async {
  final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
          top: false,
          child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text('Chi tiết giao dịch',
                              style: Theme.of(context).textTheme.titleLarge)),
                      IconButton(
                          tooltip: 'Đóng',
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close))
                    ]),
                    TransactionReceipt(transaction: transaction),
                    if (transaction.loanId != null ||
                        transaction.goalId != null ||
                        transaction.assetId != null)
                      const Text(
                          'Giao dịch có liên kết tài chính. Xem đầy đủ trước khi sửa hoặc xóa.'),
                    const SizedBox(height: 16),
                    FilledButton(
                        onPressed: () => Navigator.pop(sheetContext, 'edit'),
                        child: const Text('Chỉnh sửa')),
                    TextButton(
                        onPressed: () => Navigator.pop(sheetContext, 'detail'),
                        child: const Text('Xem chi tiết đầy đủ')),
                  ]))));
  if (!context.mounted || action == null) return;
  if (action == 'edit' &&
      (transaction.loanId != null ||
          transaction.goalId != null ||
          transaction.assetId != null)) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Giao dịch liên kết cần chỉnh sửa đồng thời với mục tiêu, tài sản hoặc khoản nợ. Chưa hỗ trợ sửa trực tiếp.')));
    return;
  }
  await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => action == 'edit'
          ? AddTransactionPage(userId: userId, existing: transaction)
          : TransactionDetailScreen(userId: userId, transaction: transaction)));
}

/// Financial record detail, not a claim of a successful bank transfer.
class TransactionReceipt extends StatelessWidget {
  final TransactionModel transaction;
  const TransactionReceipt({super.key, required this.transaction});
  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final scheme = Theme.of(context).colorScheme;
    final date = DateTime.fromMillisecondsSinceEpoch(tx.date);
    Widget field(String label, String? value) => value == null ||
            value.trim().isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: LayoutBuilder(builder: (context, box) {
              final large = MediaQuery.textScalerOf(context).scale(16) > 23 ||
                  box.maxWidth < 280;
              final caption = Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant));
              final content = Text(value,
                  textAlign: large ? TextAlign.start : TextAlign.end,
                  style: Theme.of(context).textTheme.bodyMedium);
              return large
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [caption, const SizedBox(height: 4), content])
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Expanded(flex: 2, child: caption),
                          const SizedBox(width: 16),
                          Expanded(flex: 3, child: content)
                        ]);
            }));
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.alphaBlend(
                      scheme.primary.withValues(alpha: .05), scheme.surface),
                  scheme.surface
                ])),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
              child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primary.withValues(alpha: .10)),
                  child: Icon(Icons.receipt_long_outlined,
                      color: scheme.primary, size: 28))),
          const SizedBox(height: 12),
          Text('Giao dịch đã ghi nhận',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: scheme.primary)),
          const SizedBox(height: 4),
          Center(child: MoneyText(tx.amount, size: 28)),
          const SizedBox(height: 8),
          Text('${date.day}/${date.month}/${date.year}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
          const Divider(height: 32),
          field('Nội dung', tx.note),
          field('Danh mục', tx.categoryName),
          field('Ví', tx.walletName),
          field('Từ ví', tx.fromWalletName),
          field('Đến ví', tx.toWalletName ?? tx.creditCardName),
          field('Người sở hữu', tx.ownerName),
          const SizedBox(height: 8),
          Text(
              'Bản ghi trong Finora, không phải biên nhận chuyển tiền ngân hàng.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        ]));
  }
}
