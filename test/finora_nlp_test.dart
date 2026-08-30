import 'package:flutter_test/flutter_test.dart';
import 'package:finora/data/models/category.dart';
import 'package:finora/data/models/wallet.dart';
import 'package:finora/data/services/finora_nlp_engine.dart';

void main() {
  group('FinoraNlpEngine Math & Slang Parsing', () {
    test('parses arithmetic addition without units: 15+16+45', () {
      final amount = FinoraNlpEngine.parseMoney('Ăn sáng 15+16+45');
      expect(amount, equals(76000)); // 15.000 + 16.000 + 45.000 = 76.000đ
    });

    test('parses arithmetic addition with k unit: 15+16+45k', () {
      final amount = FinoraNlpEngine.parseMoney('15+16+45k');
      expect(amount, equals(76000));
    });

    test('parses multiple addition with spaces: 50k + 30k + 20k', () {
      final amount = FinoraNlpEngine.parseMoney('Mua đồ 50k + 30k + 20k');
      expect(amount, equals(100000));
    });

    test('parses Vietnamese slang multipliers: tr, củ, chai, lít, xị, lốp, tỷ', () {
      expect(FinoraNlpEngine.parseMoney('Lương 15tr'), equals(15000000));
      expect(FinoraNlpEngine.parseMoney('Tiền thưởng 2 củ'), equals(2000000));
      expect(FinoraNlpEngine.parseMoney('Bán điện thoại 5 chai'), equals(5000000));
      expect(FinoraNlpEngine.parseMoney('Đổ xăng 1 lít'), equals(100000)); // 1 lít = 100k
      expect(FinoraNlpEngine.parseMoney('Nhậu 2 xị'), equals(200000)); // 2 xị = 200k
      expect(FinoraNlpEngine.parseMoney('Mua xe 3 lốp'), equals(300000)); // 3 lốp = 300k
      expect(FinoraNlpEngine.parseMoney('Mua nhà 2 tỷ'), equals(2000000000));
    });

    test('parses dot/comma thousand separators: 50.000, 1,500,000', () {
      expect(FinoraNlpEngine.parseMoney('Ăn tối 50.000 đ'), equals(50000));
      expect(FinoraNlpEngine.parseMoney('Mua laptop 15.500.000đ'), equals(15500000));
    });

    test('extracts clean note without money or filler words', () {
      expect(FinoraNlpEngine.extractCleanNote('Ăn phở bò tái 45k tiền mặt'), equals('Ăn phở bò tái'));
      expect(FinoraNlpEngine.extractCleanNote('Sáng cafe highland 35k Momo'), equals('Highland'));
    });
  });

  group('FinoraNlpEngine Multi-Transaction & Owner Extraction', () {
    final categories = [
      const Category(id: 'cat_food', name: 'Ăn uống', categoryGroup: 'expense'),
      const Category(id: 'cat_transport', name: 'Đi lại', categoryGroup: 'expense'),
      const Category(id: 'cat_salary', name: 'Lương', categoryGroup: 'income'),
      const Category(id: 'cat_shopping', name: 'Mua sắm', categoryGroup: 'expense'),
    ];

    final wallets = [
      const Wallet(id: 'w_cash', name: 'Tiền mặt', type: 'cash', owner: 'husband', ownerName: 'Chồng'),
      const Wallet(id: 'w_momo', name: 'Ví MoMo', type: 'ewallet', owner: 'wife', ownerName: 'Vợ'),
      const Wallet(id: 'w_vcb', name: 'Vietcombank', type: 'bank', owner: 'husband', ownerName: 'Chồng'),
    ];

    test('splits compound multi-transaction message into distinct transactions', () {
      const msg = 'Sáng cafe 35k Momo, trưa ăn cơm 50k tiền mặt, chiều nhận lương 15tr vào VCB';
      final txs = FinoraNlpEngine.extractTransactions(
        message: msg,
        categories: categories,
        wallets: wallets,
      );

      expect(txs.length, equals(3));

      expect(txs[0].amount, equals(35000));
      expect(txs[0].type, equals('expense'));
      expect(txs[0].categoryName, equals('Ăn uống'));
      expect(txs[0].walletName, equals('Ví MoMo'));

      expect(txs[1].amount, equals(50000));
      expect(txs[1].type, equals('expense'));
      expect(txs[1].categoryName, equals('Ăn uống'));
      expect(txs[1].walletName, equals('Tiền mặt'));

      expect(txs[2].amount, equals(15000000));
      expect(txs[2].type, equals('income'));
      expect(txs[2].categoryName, equals('Lương'));
      expect(txs[2].walletName, equals('Vietcombank'));
    });

    test('detects owner tags correctly from phrase', () {
      final txsHusband = FinoraNlpEngine.extractTransactions(
        message: 'Mua áo sơ mi cho chồng 350k',
        categories: categories,
        wallets: wallets,
      );
      expect(txsHusband.first.owner, equals('husband'));
      expect(txsHusband.first.ownerName, equals('Chồng'));

      final txsWife = FinoraNlpEngine.extractTransactions(
        message: 'Mua mỹ phẩm cho vợ 500k',
        categories: categories,
        wallets: wallets,
      );
      expect(txsWife.first.owner, equals('wife'));
      expect(txsWife.first.ownerName, equals('Vợ'));

      final txsJoint = FinoraNlpEngine.extractTransactions(
        message: 'Đi siêu thị gia đình chung 1tr2',
        categories: categories,
        wallets: wallets,
      );
      expect(txsJoint.first.owner, equals('joint'));
      expect(txsJoint.first.ownerName, equals('Chung'));
    });
  });
}
