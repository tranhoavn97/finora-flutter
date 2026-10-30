import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/fresh_design.dart';
import '../../core/widgets/finora/financial_components.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../data/models/finance_models.dart';
import '../../state/more_provider.dart';
import '../../state/transaction_provider.dart';
import '../transaction/transaction_detail_sheet.dart';

class FreshGoalDetail extends StatelessWidget {
  final String userId;
  final Goal initial;
  final ValueChanged<Goal> onDeposit, onEdit;
  const FreshGoalDetail(
      {super.key,
      required this.userId,
      required this.initial,
      required this.onDeposit,
      required this.onEdit});
  @override
  Widget build(BuildContext context) {
    final goals = context.watch<MoreProvider>().goals;
    final goal = goals.where((g) => g.id == initial.id).firstOrNull;
    if (goal == null)
      return GlassScaffold(
          appBar: GlassTopBar(
              title: 'Mục tiêu', onBack: () => Navigator.pop(context)),
          body: Center(
              child: Text('Mục tiêu này không còn trong danh sách hiện tại.')));
    final txs = context
            .watch<TransactionProvider?>()
            ?.transactions
            .where((tx) => tx.goalId == goal.id)
            .toList() ??
        [];
    final progress = goal.targetAmount > 0
        ? (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final date = goal.targetDate == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(goal.targetDate!);
    return GlassScaffold(
      appBar: GlassTopBar(
          title: 'Hành trình mục tiêu',
          onBack: () => Navigator.pop(context),
          actions: [
            IconButton(
                tooltip: 'Chỉnh sửa mục tiêu',
                onPressed: () => onEdit(goal),
                icon: const Icon(Icons.edit_outlined))
          ]),
      body: ListView(
          padding: EdgeInsets.fromLTRB(
              16, GlassScaffold.topInset(context, 8), 16, 110),
          children: [
            FreshPageIntro(
                eyebrow: 'TỪNG BƯỚC MỘT',
                title: goal.name,
                subtitle: date == null
                    ? 'Mục tiêu chưa có ngày kết thúc.'
                    : 'Ngày mục tiêu: ${date.day}/${date.month}/${date.year}',
                trailing: FioMascot(size: 72, celebrate: progress >= 1)),
            FreshPanel(
                color: FreshColors.tint(context),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Đã tích lũy', style: TextStyle(fontSize: 13)),
                      const SizedBox(height: 8),
                      MoneyText(goal.savedAmount, size: 30),
                      const SizedBox(height: 4),
                      const Text('Mục tiêu', style: TextStyle(fontSize: 12)),
                      MoneyText(goal.targetAmount, size: 18),
                      const SizedBox(height: 20),
                      ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: LinearProgressIndicator(
                              value: progress, minHeight: 8)),
                      const SizedBox(height: 10),
                      Text('${(progress * 100).round()}% hoàn thành',
                          style: const TextStyle(fontSize: 12)),
                    ])),
            const SizedBox(height: 24),
            const Text('Những khoản góp được liên kết',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (txs.isEmpty)
              const FreshPanel(
                  child: Text(
                      'Chưa có giao dịch liên kết để hiển thị. Số đã tích lũy ở trên là số liệu mục tiêu hiện tại.'))
            else
              FreshPanel(
                  child: Column(children: [
                for (final tx in txs)
                  TransactionRow(
                      transaction: tx,
                      onTap: () => showTransactionDetailSheet(context,
                          userId: userId, transaction: tx))
              ])),
          ]),
      bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
              onPressed: () => onDeposit(goal),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Góp tiền cho mục tiêu'))),
    );
  }
}
