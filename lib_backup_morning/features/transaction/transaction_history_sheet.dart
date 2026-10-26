import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/date_filter.dart';
import '../../core/widgets/finora/financial_components.dart';
import '../../domain/finance/finance_summary.dart';
import '../../state/transaction_provider.dart';
import 'transaction_detail_sheet.dart';
import 'add_transaction_page.dart';

class TransactionHistorySheet extends StatefulWidget {
  final String userId;
  final String? walletId,
      walletName,
      categoryId,
      categoryName,
      categoryIcon,
      categoryColor,
      categoryGroup;
  final bool embedded;
  const TransactionHistorySheet(
      {super.key,
      required this.userId,
      this.walletId,
      this.walletName,
      this.categoryId,
      this.categoryName,
      this.categoryIcon,
      this.categoryColor,
      this.categoryGroup,
      this.embedded = false});
  @override
  State<TransactionHistorySheet> createState() =>
      _TransactionHistorySheetState();
}

class _TransactionHistorySheetState extends State<TransactionHistorySheet> {
  DateFilterOption _period = DateFilterOption.thisMonth;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TransactionProvider>().load(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TransactionProvider>();
    final txs = p.transactions.where((t) {
      final wallet = widget.walletId == null ||
          [t.walletId, t.fromWalletId, t.toWalletId, t.creditCardId]
              .contains(widget.walletId);
      final category = widget.categoryId != null
          ? t.categoryId == widget.categoryId
          : widget.categoryName == null ||
              t.categoryName == widget.categoryName;
      final group = widget.categoryGroup == null ||
          widget.categoryGroup == 'expense' && FinanceSummary.isExpense(t) ||
          widget.categoryGroup == 'income' && FinanceSummary.isIncome(t) ||
          t.categoryGroup == widget.categoryGroup;
      return wallet &&
          category &&
          group &&
          isDateInFilterOption(t.date, _period);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return Material(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
            top: false,
            child: Column(children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                  child: Row(children: [
                    Expanded(
                        child: Text(
                            widget.embedded
                                ? 'Giao dịch'
                                : widget.walletName ??
                                    widget.categoryName ??
                                    'Lịch sử giao dịch',
                            style: Theme.of(context).textTheme.titleLarge)),
                    if (!widget.embedded) ...[
                      TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddTransactionPage(
                              userId: widget.userId,
                              initialWalletId: widget.walletId,
                              initialCategoryId: widget.categoryId,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Thêm giao dịch'),
                      ),
                      IconButton(
                          tooltip: 'Đóng',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close)),
                    ],
                  ])),
              Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(spacing: 8, runSpacing: 4, children: [
                    for (final period in [
                      DateFilterOption.thisMonth,
                      DateFilterOption.lastMonth,
                      DateFilterOption.allTime
                    ])
                      ChoiceChip(
                          label: Text(period.label),
                          selected: _period == period,
                          onSelected: (_) => setState(() => _period = period))
                  ])),
              Expanded(
                  child: p.isRefreshing
                      ? const Center(child: CircularProgressIndicator())
                      : p.error != null
                          ? FinoraDataMessage(
                              title: 'Chưa tải được dữ liệu',
                              message: p.error!,
                              onRetry: () => p.load(widget.userId, force: true))
                          : txs.isEmpty
                              ? const Center(
                                  child: Text(
                                      'Không có giao dịch trong phạm vi này'))
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: txs.length,
                                  itemBuilder: (c, i) => TransactionRow(
                                      transaction: txs[i],
                                      onTap: () => showTransactionDetailSheet(c,
                                          userId: widget.userId,
                                          transaction: txs[i])))),
            ])));
  }
}
