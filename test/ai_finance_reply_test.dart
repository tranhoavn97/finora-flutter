import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finora/data/models/wallet.dart';
import 'package:finora/data/models/transaction.dart';
import 'package:finora/data/services/ai_finance_reply.dart';
import 'package:finora/data/services/finora_nlp_engine.dart';
import 'package:finora/features/ai/widgets/ai_markdown_view.dart';

void main() {
  final now = DateTime(2026, 10, 10);
  final wallets = [
    const Wallet(name: 'Tiền mặt', balance: 10000000),
    const Wallet(
        name: 'GOLD',
        type: 'credit_card',
        balance: 20000000,
        currentDebt: 3000000,
        creditLimit: 20000000)
  ];
  final transactions = [
    TransactionModel(
        id: 'income',
        type: 'income',
        amount: 70000,
        date: now.millisecondsSinceEpoch),
    TransactionModel(
        id: 'expense',
        type: 'expense',
        amount: 11592410,
        categoryName: 'Ăn uống',
        date: now.millisecondsSinceEpoch),
    TransactionModel(
        id: 'prior',
        type: 'expense',
        amount: 1000000,
        categoryName: 'Ăn uống',
        date: DateTime(2026, 9, 5).millisecondsSinceEpoch)
  ];
  AiFinanceReply? reply(String prompt, {String previous = ''}) =>
      AiFinanceReply.build(
          prompt: prompt,
          transactions: transactions,
          wallets: wallets,
          budgets: [],
          now: now,
          previousPrompt: previous);
  test('wallet totals exclude credit limit and report debt separately', () {
    final r = reply('💰 Kiểm tra số dư từng ví')!;
    expect(r.text, contains('10.000.000'));
    expect(r.text, contains('3.000.000'));
    expect(r.text, contains('7.000.000'));
    expect(r.text, isNot(contains('30.000.000')));
    expect(r.chips, isNot(contains('Kiểm tra số dư từng ví')));
  });
  test('credit and allocation quick prompts have distinct reports', () {
    expect(reply('💳 Rà soát nợ thẻ tín dụng')!.text, contains('GOLD'));
    expect(reply('💳 Rà soát nợ thẻ tín dụng')!.text, contains('17.000.000'));
    final allocation = reply('⚡ Phân bổ dòng tiền an toàn')!.text;
    expect(allocation, contains('35.000'));
    expect(allocation, isNot(contains('12.000.000')));
  });
  test('budget query is a budget report rather than negative savings rate', () {
    expect(reply('ngân sách')!.text, contains('chưa thiết lập ngân sách'));
    expect(reply('Cơ cấu thu chi tháng này')!.text, contains('Thâm hụt'));
    expect(reply('Cơ cấu thu chi tháng này')!.text, isNot(contains('-16461%')));
    expect(reply('🛡️ Đặt ngân sách cho khoản này')!.text,
        contains('Chưa có dữ liệu nào'));
  });
  test('comparison follows last category and includes full previous month', () {
    final r = reply('So sánh với tháng trước',
        previous: 'Chi tiết ăn uống tháng này')!;
    expect(r.text, contains('Ăn uống'));
    expect(r.text, contains('1.000.000'));
  });
  test(
      'numeric simulations and suggested queries cannot become transaction drafts',
      () {
    for (final prompt in [
      'Mô phỏng số dư 30 ngày',
      'Mẹo cắt giảm 10% chi phí',
      'Rà soát nợ thẻ tín dụng'
    ]) {
      expect(FinoraNlpEngine.isFinancialQuery(prompt), isTrue);
    }
    expect(reply('Mô phỏng số dư 30 ngày')!.text, contains('Giả định'));
  });
  test('unsupported open conversation remains available to model', () {
    expect(reply('Tôi đang phân vân giữa hai kế hoạch'), isNull);
  });
  testWidgets('reports render large money rows at narrow widths in both themes',
      (tester) async {
    for (final dark in [false, true]) {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SizedBox(
                  width: 240,
                  child: FinoraMarkdownView(
                      text: reply('Kiểm tra số dư từng ví')!.text,
                      baseStyle: const TextStyle(fontSize: 14),
                      primaryAccent: Colors.blue,
                      isDark: dark)))));
      expect(tester.takeException(), isNull);
      expect(find.text('10.000.000 ₫'), findsNWidgets(2));
    }
  });
}

