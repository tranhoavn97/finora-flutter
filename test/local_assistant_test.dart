import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:finora/data/models/category.dart';
import 'package:finora/data/models/transaction.dart';
import 'package:finora/data/models/wallet.dart';
import 'package:finora/data/services/local_assistant_service.dart';
import 'package:finora/features/ai/ai_advisor_screen.dart';
import 'package:finora/state/transaction_provider.dart';

class LocalTestLedger extends TransactionProvider {
  final writes = <TransactionModel>[];
  LocalTestLedger() {
    isRefreshing = false;
    wallets = const [Wallet(id: 'cash', name: 'Tiền mặt', balance: 700000)];
    categories = const [Category(id: 'food', name: 'Ăn uống')];
  }
  @override
  Future<void> load(String userId,
      {String? familyId, bool force = false}) async {}
  @override
  Future<void> createTransaction(String userId, TransactionModel tx) async {
    writes.add(tx);
  }
}

void main() {
  final now = DateTime(2026, 10, 30, 14);
  const wallets = [
    Wallet(id: 'cash', name: 'Tiền mặt', balance: 700000),
    Wallet(id: 'bank', name: 'Ngân hàng', balance: 2000000),
    Wallet(
        id: 'card',
        name: 'Thẻ',
        type: 'credit_card',
        creditLimit: 9000000,
        currentDebt: 300000),
  ];
  const categories = [
    Category(id: 'food', name: 'Ăn uống'),
    Category(id: 'salary', name: 'Lương', categoryGroup: 'income')
  ];
  final ledger = [
    TransactionModel(
        id: 'today',
        type: 'expense',
        amount: 45000,
        categoryName: 'Ăn uống',
        walletId: 'cash',
        date: now.millisecondsSinceEpoch),
    TransactionModel(
        id: 'yesterday',
        type: 'expense',
        amount: 90000,
        categoryName: 'Ăn uống',
        walletId: 'bank',
        date: DateTime(2026, 10, 29, 10).millisecondsSinceEpoch),
    TransactionModel(
        id: 'salary',
        type: 'income',
        amount: 5000000,
        categoryName: 'Lương',
        walletId: 'bank',
        date: DateTime(2026, 10, 1).millisecondsSinceEpoch),
    TransactionModel(
        id: 'prior',
        type: 'expense',
        amount: 80000,
        categoryName: 'Ăn uống',
        walletId: 'cash',
        date: DateTime(2026, 9, 20).millisecondsSinceEpoch),
    TransactionModel(
        id: 'transfer',
        type: 'transfer',
        amount: 999999,
        date: now.millisecondsSinceEpoch),
  ];
  LocalAssistantReply reply(String prompt,
          {bool ready = true,
          List<TransactionModel>? rows,
          String previous = ''}) =>
      LocalAssistantService.reply(
          prompt: prompt,
          transactions: rows ?? ledger,
          wallets: wallets,
          categories: categories,
          dataReady: ready,
          now: now,
          previousPrompt: previous);

  test('explicit amount and date produce drafts, no default wallet', () {
    final draft = reply('Hôm qua ăn trưa 45k').transactions.single;
    expect(draft.amount, 45000);
    expect(draft.type, 'expense');
    expect(draft.walletName, isNull);
    expect(DateTime.fromMillisecondsSinceEpoch(draft.date),
        DateTime(2026, 10, 29, 12));
    final paid = reply('Chi ăn uống 50.000đ Tiền mặt').transactions.single;
    expect(paid.walletName, 'Tiền mặt');
    expect(paid.categoryName, 'Ăn uống');
    expect(paid.amount, 50000);
    expect(reply('Nhận lương 2tr5').transactions.single.amount, 2500000);
    expect(reply('Chi 50đ').transactions.single.amount, 50);
    expect(reply('Mua sữa 50k').transactions.single.amount, 50000);
    expect(reply('Mua cháo 30k').transactions.single.amount, 30000);
    expect(reply('Nhận lương 8tr ví tiết kiệm').transactions.single.amount,
        8000000);
    expect(reply('Chi 50 nghìn').transactions.single.amount, 50000);
    expect(reply('Nhận lương 1,5tr').transactions.single.amount, 1500000);
  });
  test('batch is all-or-nothing and does not split decimal commas', () {
    expect(reply('Ăn trưa 45k\nNhận lương 2tr5').transactions, hasLength(2));
    expect(reply('Ăn trưa 45k, cafe 20k').transactions, hasLength(2));
    for (final text in ['Ăn trưa 45k\nMua sách', 'Chi 50k+20k']) {
      expect(reply(text).transactions, isEmpty, reason: text);
    }
  });
  test(
      'questions, plans, negatives and unsupported operations never become expenses',
      () {
    for (final text in [
      'Tiết kiệm 2tr',
      'Ăn uống đã chi 50k chưa?',
      'Ví dụ ăn trưa 50k',
      'Ngày mai mua sách 50k',
      'Chưa nhận lương 8tr',
      'Chuyển tiền 500k',
      'Trả nợ 500k',
      'Vay 500k',
      'Xóa giao dịch 50k',
      'Ăn trưa ngày 30/10',
      'Mua 2 quyển sách',
      'Số tài khoản 1234567890'
    ]) {
      expect(reply(text).transactions, isEmpty, reason: text);
    }
  });
  test('invalid and future dates and negative amounts are rejected', () {
    for (final text in [
      'Chi 50k ngày 31/02/2026',
      'Chi 50k ngày 31/10/2026',
      'Chi -50k',
      'Chi 0đ',
      'Chi 50k ngày 20/10/25',
      'Chi 1.234,50đ',
      'Chi 1.234k'
    ]) {
      expect(reply(text).transactions, isEmpty, reason: text);
    }
    expect(reply('Chi 50k ngày 20/10/2026').transactions.single.date,
        DateTime(2026, 10, 20, 12).millisecondsSinceEpoch);
  });
  test('daily, previous month and week reports use distinct real scopes', () {
    expect(reply('Thu chi hôm nay').text, contains('45.000'));
    expect(reply('Thu chi hôm nay').text, isNot(contains('90.000')));
    expect(reply('Thu chi hôm qua').text, contains('90.000'));
    expect(reply('Thu chi tháng trước').text, contains('80.000'));
    expect(reply('Thu chi tuần này').text, contains('135.000'));
    expect(reply('Thu chi tuần này').text, isNot(contains('5.000.000')));
    final month = reply('Thu chi tháng này').text;
    expect(month, contains('5.000.000'));
    expect(month, contains('135.000'));
    expect(month, isNot(contains('999.999')));
  });
  test('category and wallet reports do not substitute global totals', () {
    expect(reply('Ăn uống tháng này chi bao nhiêu?').text, contains('135.000'));
    expect(reply('Thu chi Tiền mặt tháng này').text, contains('45.000'));
    expect(
        reply('Thu chi Tiền mặt tháng này').text, isNot(contains('135.000')));
    expect(
        reply('Chi tiêu Đi lại tháng này').text, contains('Chưa có giao dịch'));
    final comparison =
        reply('So sánh với tháng trước', previous: 'Ăn uống tháng này').text;
    expect(comparison, contains('Ăn uống'));
    expect(comparison, contains('80.000'));
    expect(comparison, contains('55.000'));
  });
  test('empty, incomplete and unsupported periods do not invent financial data',
      () {
    expect(reply('Thu chi tháng này', rows: []).text,
        contains('Chưa có giao dịch'));
    final incomeOnly = reply('Thu chi tháng này',
            rows: ledger.where((t) => t.type == 'income').toList())
        .text;
    expect(incomeOnly, contains('5.000.000'));
    expect(incomeOnly, contains('Chưa có khoản chi'));
    expect(incomeOnly, isNot(contains('Chưa có giao dịch')));
    expect(reply('Thu chi tháng này', ready: false).text,
        contains('Chưa đủ dữ liệu'));
    expect(reply('Ăn trưa 45k', ready: false).transactions, isEmpty);
    expect(reply('Thu chi tháng 9').text, contains('80.000'));
    expect(
        reply('Thu chi ngày 20/10/2026').text, contains('Chưa có giao dịch'));
    expect(reply('Số dư tháng trước').text, contains('Chưa hỗ trợ'));
    expect(
        reply('Hướng dẫn', ready: false).text, contains('không phải ChatGPT'));
  });
  test('wallet balances exclude credit limit and disclose ledger source', () {
    final text = reply('Số dư từng ví').text;
    expect(text, contains('2.700.000'));
    expect(text, contains('300.000'));
    expect(text, isNot(contains('11.700.000')));
    expect(text, contains('không phải truy vấn số dư trực tiếp'));
  });
  testWidgets(
      'local chat works without Firebase/API and only saves on confirmation',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = LocalTestLedger();
    addTearDown(provider.dispose);
    await tester.pumpWidget(ChangeNotifierProvider<TransactionProvider>.value(
        value: provider,
        child: const MaterialApp(home: AiAdvisorScreen(userId: 'local-test'))));
    await tester.pumpAndSettle();
    expect(find.text('Miễn phí • Xử lý trên máy'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Ăn trưa 45k Tiền mặt');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
    expect(provider.writes, isEmpty);
    expect(find.text('FINORA · Trên máy'), findsOneWidget);
    expect(find.text('Bản nháp giao dịch Finora'), findsOneWidget);
    final save = find.text('Xác nhận lưu');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(provider.writes, hasLength(1));
    expect(provider.writes.single.amount, 45000);
    expect(provider.writes.single.walletId, 'cash');
    expect(provider.writes.single.categoryId, 'food');
    expect(tester.takeException(), isNull);
  });
}
