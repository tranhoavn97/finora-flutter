import 'package:flutter_test/flutter_test.dart';
import 'package:finora/data/models/category.dart';
import 'package:finora/data/models/wallet.dart';
import 'package:finora/data/services/finora_nlp_engine.dart';

void main() {
  final wallets = [
    const Wallet(
        id: 'spend_h',
        name: 'Chi tiêu của chồng',
        owner: 'husband',
        ownerName: 'Chồng'),
    const Wallet(
        id: 'save_h',
        name: 'Tiết kiệm của chồng',
        owner: 'husband',
        ownerName: 'Chồng'),
  ];

  test('captures breakfast expense with date, category, note and wallet', () {
    final result = FinoraNlpEngine.extractTransactions(
      message: 'Hôm nay ăn sáng hết 40k ví chi tiêu của chồng',
      categories: Category.defaults,
      wallets: wallets,
    ).single;
    final now = DateTime.now();
    final date = DateTime.fromMillisecondsSinceEpoch(result.date!);

    expect(result.type, 'expense');
    expect(result.amount, 40000);
    expect(result.categoryName, 'Ăn uống');
    expect(result.walletName, 'Chi tiêu của chồng');
    expect(result.owner, 'husband');
    expect(result.note.toLowerCase(), contains('ăn sáng'));
    expect((date.year, date.month, date.day), (now.year, now.month, now.day));
  });

  test('captures compact salary amount and custom employer category', () {
    final categories = [
      ...Category.defaults,
      const Category(
          id: 'windmedia',
          name: 'Windmedia',
          icon: 'banknote',
          categoryGroup: 'income')
    ];
    final result = FinoraNlpEngine.extractTransactions(
      message: 'Nhận lương Windmedia 14tr350, ví tiết kiệm của chồng',
      categories: categories,
      wallets: wallets,
    ).single;

    expect(result.type, 'income');
    expect(result.amount, 14350000);
    expect(result.categoryName, 'Windmedia');
    expect(result.walletName, 'Tiết kiệm của chồng');
    expect(result.owner, 'husband');
    expect(result.note.toLowerCase(), contains('lương windmedia'));
  });
}
