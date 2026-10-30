import 'package:flutter_test/flutter_test.dart';
import 'package:finora/data/models/category.dart';
import 'package:finora/data/models/finance_models.dart';
import 'package:finora/data/models/transaction.dart';
import 'package:finora/data/models/wallet.dart';
import 'package:finora/data/services/local_assistant_service.dart';

void main() {
  final now = DateTime(2026, 10, 30, 14);
  const categories = [
    Category(id: 'food', name: 'Ăn uống'),
    Category(id: 'ride', name: 'Đi lại')
  ];
  const wallets = [Wallet(id: 'cash', name: 'Tiền mặt')];
  TransactionModel tx(
          String id, int amount, int day, String category, String note,
          {int month = 10, String? merchant}) =>
      TransactionModel(
          id: id,
          type: 'expense',
          amount: amount,
          date: DateTime(2026, month, day, 10).millisecondsSinceEpoch,
          categoryId: category == 'Ăn uống' ? 'food' : 'ride',
          categoryName: category,
          note: note,
          walletId: 'cash',
          walletName: 'Tiền mặt',
          merchantName: merchant);
  final rows = [
    tx('a', 45000, 30, 'Ăn uống', 'Ăn trưa'),
    tx('b', 30000, 30, 'Đi lại', 'Xe ôm'),
    tx('c', 20000, 29, 'Ăn uống', 'Cà phê', merchant: 'Highlands'),
    tx('d', 10000, 20, 'Ăn uống', 'Cà phê'),
    tx('prior', 15000, 15, 'Ăn uống', 'Ăn sáng', month: 9)
  ];
  LocalAssistantReply answer(String prompt,
          {String previous = '', bool budgetsReady = true}) =>
      LocalAssistantService.reply(
          prompt: prompt,
          transactions: rows,
          wallets: wallets,
          categories: categories,
          dataReady: true,
          now: now,
          previousPrompt: previous,
          budgetsReady: budgetsReady,
          budgets: const [
            Budget(
                id: 'b',
                categoryId: 'food',
                categoryName: 'Ăn uống',
                monthKey: '2026-10',
                limitAmount: 60000)
          ]);
  test('asks what was spent: returns actual items instead of a monthly summary',
      () {
    final r = answer('Hôm nay tôi đã tiêu những gì?');
    expect(r.text, contains('Ăn trưa'));
    expect(r.text, contains('Xe ôm'));
    expect(r.text, contains('75.000'));
    expect(r.text, isNot(contains('Highlands')));
    expect(r.transactions, isEmpty);
  });
  test('three-turn follow-up keeps category and changes the day', () {
    final first = answer('Ăn uống tháng này chi bao nhiêu?');
    final second = answer('Còn hôm qua?', previous: first.contextPrompt!);
    expect(second.text, contains('20.000'));
    expect(second.text, contains('Ăn uống'));
    expect(second.text, isNot(contains('30.000')));
    final third = answer('Liệt kê chi tiết', previous: second.contextPrompt!);
    expect(third.text, contains('Cà phê'));
    expect(third.text, isNot(contains('Ăn trưa')));
  });
  test(
      'why spending increased explains category contributions without inventing causes',
      () {
    final r = answer('Vì sao chi tăng tháng này?');
    expect(r.text, contains('60.000'));
    expect(r.text, contains('30.000'));
    expect(r.text, contains('15.000'));
    expect(r.text, contains('chưa thể kết luận nguyên nhân'));
  });
  test('budget question ending with khong uses actual limit and expense', () {
    final r = answer('Ngân sách ăn uống tháng này có vượt không?');
    expect(r.text, contains('75.000'));
    expect(r.text, contains('60.000'));
    expect(r.text, contains('125%'));
    expect(r.text, contains('15.000'));
    expect(r.transactions, isEmpty);
    expect(answer('Ngân sách ăn uống', budgetsReady: false).text,
        contains('chưa tải xong'));
  });
  test('merchant, coffee and explicit month filters produce different results',
      () {
    expect(answer('Chi tại Highlands tháng này bao nhiêu?').text,
        contains('20.000'));
    expect(answer('Cà phê tháng này chi bao nhiêu?').text, contains('30.000'));
    expect(
        answer('Ăn uống tháng 9/2026 chi bao nhiêu?').text, contains('15.000'));
    expect(
        answer('Chi ngày 31/02/2026 bao nhiêu?').text, contains('chưa hợp lệ'));
    final merchant = answer('Chi tại Highlands tháng này bao nhiêu?');
    final detail = answer('Liệt kê chi tiết', previous: merchant.contextPrompt!);
    expect(detail.text, contains('20.000'));
    expect(detail.text, isNot(contains('10.000')));
    expect(answer('Chi tại Quán Chưa Lưu bao nhiêu?').text, contains('chưa tìm thấy'));
  });
  test('savings guidance contains actual largest notes and quantified scenario',
      () {
    final r = answer('Gợi ý cắt giảm chi tiêu tháng này');
    expect(r.text, contains('Ăn trưa'));
    expect(r.text, contains('7.500'));
    expect(r.text, contains('kịch bản'));
    expect(r.text, isNot(contains('chênh lệch')));
  });
  test('missing amount is clarified and the next answer completes the draft',
      () {
    final first = answer('Ăn trưa');
    expect(first.text, contains('số tiền'));
    expect(first.transactions, isEmpty);
    final second = answer('45k', previous: first.contextPrompt!);
    expect(second.transactions.single.amount, 45000);
    expect(second.transactions.single.type, 'expense');
  });
}
