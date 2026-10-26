import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import '../../../data/models/transaction.dart';
import '../../../domain/finance/finance_summary.dart';
import '../../utils/formatters.dart';

class FinanceColors {
  static Color income(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark
          ? const Color(0xFF65DDB0)
          : const Color(0xFF087A55);
  static Color expense(BuildContext c) => Theme.of(c).colorScheme.error;
}

class MoneyText extends StatelessWidget {
  final int amount;
  final bool hidden;
  final double size;
  final Color? color;
  final String prefix;
  const MoneyText(this.amount,
      {super.key,
      this.hidden = false,
      this.size = 24,
      this.color,
      this.prefix = ''});
  @override
  Widget build(BuildContext context) =>
      Text(hidden ? '•••••• ₫' : '$prefix${formatVND(amount)}',
          semanticsLabel: hidden ? 'Số tiền đã ẩn' : null,
          style: TextStyle(
              fontSize: size,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()]));
}

class SectionHeading extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  const SectionHeading(this.title, {super.key, this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(children: [
        Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        if (onTap != null)
          TextButton(onPressed: onTap, child: const Text('Xem thêm'))
      ]));
}

class IncomeExpensePair extends StatelessWidget {
  final FinanceSummary summary;
  final bool hidden;
  const IncomeExpensePair(this.summary, {super.key, this.hidden = false});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final wide = box.maxWidth >= 280 &&
            MediaQuery.textScalerOf(context).scale(16) < 23;
        Widget metric(String label, int value, Color color) =>
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              MoneyText(value, size: 16, color: color, hidden: hidden)
            ]);
        final items = [
          metric('Thu nhập', summary.income, FinanceColors.income(context)),
          metric('Chi tiêu', summary.expense, FinanceColors.expense(context))
        ];
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (wide)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: items[0]),
              const SizedBox(width: 16),
              Expanded(child: items[1])
            ])
          else ...[items[0], const SizedBox(height: 16), items[1]],
          const Divider(height: 24),
          Text('Chênh lệch thu chi',
              style: Theme.of(context).textTheme.bodySmall),
          MoneyText(summary.net, size: 16, hidden: hidden),
        ]);
      });
}

class TransactionRow extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final bool hidden;
  const TransactionRow(
      {super.key, required this.transaction, this.onTap, this.hidden = false});
  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final scheme = Theme.of(context).colorScheme;
    final income = FinanceSummary.isIncome(tx),
        expense = FinanceSummary.isExpense(tx);
    final color = income
        ? FinanceColors.income(context)
        : expense
            ? FinanceColors.expense(context)
            : scheme.onSurfaceVariant;
    final title = tx.note?.trim().isNotEmpty == true
        ? tx.note!
        : tx.categoryName ?? 'Giao dịch';
    final type = income
        ? 'Thu nhập'
        : expense
            ? 'Chi tiêu'
            : switch (tx.type) {
                'transfer' => 'Chuyển nội bộ',
                'credit_card_payment' => 'Thanh toán thẻ',
                'borrowing' => 'Nhận khoản vay',
                'lending' => 'Cho vay',
                'saving' => 'Đóng góp mục tiêu',
                'investment' => 'Đầu tư',
                'debt_repayment' => 'Trả gốc nợ',
                'loan_repayment_received' => 'Thu gốc nợ',
                _ => 'Giao dịch khác'
              };
    final date = DateTime.fromMillisecondsSinceEpoch(tx.date);
    final metadata = [
      type,
      if (tx.walletName?.isNotEmpty == true) tx.walletName!,
      if (tx.fromWalletName != null)
        '${tx.fromWalletName} → ${tx.toWalletName ?? tx.creditCardName ?? ''}',
      if (tx.ownerName?.isNotEmpty == true) tx.ownerName!,
      '${date.day}/${date.month}/${date.year}'
    ].join(' · ');
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: LayoutBuilder(builder: (context, box) {
              final stack = box.maxWidth < 290 ||
                  MediaQuery.textScalerOf(context).scale(16) > 22;
              final amount = MoneyText(tx.amount,
                  hidden: hidden,
                  size: 14,
                  color: color,
                  prefix: income
                      ? '+'
                      : expense
                          ? '−'
                          : '');
              return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                            color: scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12)),
                        child: Icon(
                            income
                                ? Icons.south_west
                                : expense
                                    ? Icons.north_east
                                    : Icons.swap_horiz,
                            color: color,
                            size: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(title,
                              maxLines: stack ? null : 2,
                              overflow: stack ? null : TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(metadata,
                              maxLines: stack ? null : 2,
                              overflow: stack ? null : TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant)),
                          if (stack) ...[const SizedBox(height: 8), amount]
                        ])),
                    if (!stack) ...[
                      const SizedBox(width: 12),
                      ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: box.maxWidth * .40),
                          child: amount)
                    ]
                  ]);
            })));
  }
}

class FinoraDataMessage extends StatelessWidget {
  final String title, message;
  final VoidCallback? onRetry;
  const FinoraDataMessage(
      {super.key, required this.title, required this.message, this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.info_outline, size: 32),
        const SizedBox(height: 12),
        Text(title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Thử lại'))
      ]));
}

/// Compact shortcut with an independent, accessible tap target.
class FinanceShortcut extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const FinanceShortcut(
      {super.key,
      required this.label,
      required this.icon,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: scheme.primary, size: 22)),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall),
            ])));
  }
}
