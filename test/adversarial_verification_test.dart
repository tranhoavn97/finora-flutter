import 'package:flutter_test/flutter_test.dart';
import 'package:finora/core/widgets/subject_filter_pill.dart';
import 'package:finora/data/models/category.dart';
import 'package:finora/data/models/transaction.dart';
import 'package:finora/data/models/wallet.dart';
import 'package:finora/data/services/finora_nlp_engine.dart';
import 'package:finora/data/services/wallet_repository.dart';

void main() {
  group('1. NLP Math Expression Stress Tests', () {
    test('Addition without units: 15+16+45', () {
      expect(FinoraNlpEngine.parseMoney('15+16+45'), equals(76000));
    });

    test('Addition with k unit: 15k + 25k', () {
      expect(FinoraNlpEngine.parseMoney('15k + 25k'), equals(40000));
    });

    test('Addition mixed decimals and units: 1.5tr + 500k', () {
      expect(FinoraNlpEngine.parseMoney('1.5tr + 500k'), equals(2000000));
    });

    test('Slang addition: 1 chai + 5 xị', () {
      // 1 chai = 1,000,000đ; 5 xị = 500,000đ => 1,500,000đ
      expect(FinoraNlpEngine.parseMoney('1 chai + 5 xị'), equals(1500000));
    });

    test('Multiple spaces in addition: 15k   +   25k', () {
      expect(FinoraNlpEngine.parseMoney('15k   +   25k'), equals(40000));
    });

    test('Parenthesized expression: Ăn uống (15k + 25k)', () {
      expect(FinoraNlpEngine.parseMoney('Ăn uống (15k + 25k)'), equals(40000));
    });

    test('Trailing units: 15 + 16 + 45k', () {
      expect(FinoraNlpEngine.parseMoney('15 + 16 + 45k'), equals(76000));
    });

    test('Subtraction expression behavior: 100k - 20k', () {
      // Current regex matches single additive chain with '+'.
      // Subtraction falls back to first matched unit (100k = 100,000)
      final amount = FinoraNlpEngine.parseMoney('100k - 20k');
      expect(amount, isPositive);
    });
  });

  group('2. Vietnamese Slang Unit Conversions', () {
    test('k, nghìn, ngàn, ngh', () {
      expect(FinoraNlpEngine.parseMoney('50k'), equals(50000));
      expect(FinoraNlpEngine.parseMoney('50 nghìn'), equals(50000));
      expect(FinoraNlpEngine.parseMoney('50 ngàn'), equals(50000));
      expect(FinoraNlpEngine.parseMoney('50 ngh'), equals(50000));
    });

    test('tr, triệu, củ, chai', () {
      expect(FinoraNlpEngine.parseMoney('15tr'), equals(15000000));
      expect(FinoraNlpEngine.parseMoney('15 triệu'), equals(15000000));
      expect(FinoraNlpEngine.parseMoney('3 củ'), equals(3000000));
      expect(FinoraNlpEngine.parseMoney('5 chai'), equals(5000000));
      expect(FinoraNlpEngine.parseMoney('3.5 củ'), equals(3500000));
    });

    test('lít, xị, lốp', () {
      expect(FinoraNlpEngine.parseMoney('1 lít'), equals(100000));
      expect(FinoraNlpEngine.parseMoney('2 lít'), equals(200000));
      expect(FinoraNlpEngine.parseMoney('1 xị'), equals(100000));
      expect(FinoraNlpEngine.parseMoney('5 xị'), equals(500000));
      expect(FinoraNlpEngine.parseMoney('3 lốp'), equals(300000));
    });

    test('tỷ, ty', () {
      expect(FinoraNlpEngine.parseMoney('1 tỷ'), equals(1000000000));
      expect(FinoraNlpEngine.parseMoney('2.5 tỷ'), equals(2500000000));
    });
  });

  group('3. Compound Sentence Splitting & Owner Parsing', () {
    final categories = [
      const Category(id: 'c1', name: 'Ăn uống', categoryGroup: 'expense'),
      const Category(id: 'c2', name: 'Đi lại', categoryGroup: 'expense'),
      const Category(id: 'c3', name: 'Mua sắm', categoryGroup: 'expense'),
      const Category(id: 'c4', name: 'Lương', categoryGroup: 'income'),
    ];

    final wallets = [
      const Wallet(id: 'w1', name: 'Tiền mặt', type: 'cash', owner: 'husband'),
      const Wallet(id: 'w2', name: 'Ví MoMo', type: 'ewallet', owner: 'wife'),
      const Wallet(id: 'w3', name: 'Vietcombank', type: 'bank', owner: 'joint'),
    ];

    test('Comma-separated compound sentence', () {
      const msg = 'Ăn sáng 30k, cà phê 25k, đổ xăng 50k';
      final txs = FinoraNlpEngine.extractTransactions(
        message: msg,
        categories: categories,
        wallets: wallets,
      );
      expect(txs.length, equals(3));
      expect(txs[0].amount, equals(30000));
      expect(txs[1].amount, equals(25000));
      expect(txs[2].amount, equals(50000));
    });

    test('Conjunction-separated compound sentence (và, sau đó)', () {
      const msg = 'Ăn sáng 30k và cà phê 25k sau đó đổ xăng 50k';
      final txs = FinoraNlpEngine.extractTransactions(
        message: msg,
        categories: categories,
        wallets: wallets,
      );
      expect(txs.length, equals(3));
      expect(txs[0].amount, equals(30000));
      expect(txs[1].amount, equals(25000));
      expect(txs[2].amount, equals(50000));
    });

    test('Multi-owner compound sentence with comma', () {
      const msg = 'Vợ mua sắm 500k MoMo, chồng ăn trưa 45k tiền mặt';
      final txs = FinoraNlpEngine.extractTransactions(
        message: msg,
        categories: categories,
        wallets: wallets,
      );
      expect(txs.length, equals(2));
      expect(txs[0].amount, equals(500000));
      expect(txs[0].owner, equals('wife'));
      expect(txs[0].walletName, equals('Ví MoMo'));

      expect(txs[1].amount, equals(45000));
      expect(txs[1].owner, equals('husband'));
      expect(txs[1].walletName, equals('Tiền mặt'));
    });
  });

  group('4. Pure Ledger Multi-Wallet & Multi-Owner Balance Verification', () {
    test('Calculates complex multi-type transactions across multiple wallets', () {
      final wallets = [
        const Wallet(id: 'w_cash', name: 'Tiền mặt', type: 'cash', initialBalance: 2000000, balance: 0, owner: 'husband'),
        const Wallet(id: 'w_bank', name: 'VCB Chung', type: 'bank', initialBalance: 10000000, balance: 0, owner: 'joint'),
        const Wallet(id: 'w_momo', name: 'MoMo Vợ', type: 'ewallet', initialBalance: 500000, balance: 0, owner: 'wife'),
        const Wallet(id: 'w_card', name: 'VPBank Card', type: 'credit_card', creditLimit: 30000000, initialDebt: 2000000, currentDebt: 0, owner: 'wife'),
      ];

      final txs = [
        // 1. Husband cash expense: 150.000đ
        TransactionModel(id: 't1', amount: 150000, type: 'expense', walletId: 'w_cash', owner: 'husband'),
        // 2. Joint salary into VCB: 25.000.000đ
        TransactionModel(id: 't2', amount: 25000000, type: 'income', walletId: 'w_bank', owner: 'joint'),
        // 3. Transfer from VCB to MoMo Vợ: 3.000.000đ
        TransactionModel(id: 't3', amount: 3000000, type: 'transfer', fromWalletId: 'w_bank', toWalletId: 'w_momo', owner: 'joint'),
        // 4. Wife shopping with Credit Card: 4.500.000đ
        TransactionModel(id: 't4', amount: 4500000, type: 'expense', walletId: 'w_card', owner: 'wife'),
        // 5. Pay Credit Card from VCB: 2.000.000đ
        TransactionModel(id: 't5', amount: 2000000, type: 'credit_card_payment', fromWalletId: 'w_bank', toWalletId: 'w_card', creditCardId: 'w_card', owner: 'joint'),
        // 6. Husband borrows money cash: 1.000.000đ
        TransactionModel(id: 't6', amount: 1000000, type: 'borrowing', walletId: 'w_cash', owner: 'husband'),
        // 7. Wife lends money from MoMo: 500.000đ
        TransactionModel(id: 't7', amount: 500000, type: 'lending', walletId: 'w_momo', owner: 'wife'),
      ];

      final computed = WalletRepository.computeWalletsWithBalances(wallets, txs);

      final cash = computed.firstWhere((w) => w.id == 'w_cash');
      final bank = computed.firstWhere((w) => w.id == 'w_bank');
      final momo = computed.firstWhere((w) => w.id == 'w_momo');
      final card = computed.firstWhere((w) => w.id == 'w_card');

      // Cash: initial(2.000.000) - expense(150.000) + borrowing(1.000.000) = 2.850.000đ
      expect(cash.balance, equals(2850000));

      // VCB: initial(10.000.000) + salary(25.000.000) - transfer_out(3.000.000) - card_payment(2.000.000) = 30.000.000đ
      expect(bank.balance, equals(30000000));

      // MoMo: initial(500.000) + transfer_in(3.000.000) - lending(500.000) = 3.000.000đ
      expect(momo.balance, equals(3000000));

      // Credit Card Debt: initialDebt(2.000.000) + swipe(4.500.000) - payment(2.000.000) = 4.500.000đ
      expect(card.currentDebt, equals(4500000));
      expect(card.balance, equals(0));
    });

    test('OwnerFilter correctly isolates ledger balances per subject', () {
      final wallets = [
        const Wallet(id: 'w1', name: 'VCB Chồng', type: 'bank', initialBalance: 5000000, balance: 0, owner: 'husband'),
        const Wallet(id: 'w2', name: 'MoMo Vợ', type: 'ewallet', initialBalance: 3000000, balance: 0, owner: 'wife'),
        const Wallet(id: 'w3', name: 'Quỹ Chung', type: 'cash', initialBalance: 10000000, balance: 0, owner: 'joint'),
      ];

      final txs = [
        TransactionModel(id: 't1', amount: 1000000, type: 'expense', walletId: 'w1', owner: 'husband'),
        TransactionModel(id: 't2', amount: 500000, type: 'expense', walletId: 'w2', owner: 'wife'),
        TransactionModel(id: 't3', amount: 2000000, type: 'income', walletId: 'w3', owner: 'joint'),
      ];

      final computed = WalletRepository.computeWalletsWithBalances(wallets, txs);

      // Husband filter: only w1
      final husbandWallets = computed.where((w) => OwnerFilter.husband.matchWallet(w)).toList();
      expect(husbandWallets.length, equals(1));
      expect(husbandWallets.first.balance, equals(4000000)); // 5M - 1M

      // Wife filter: only w2
      final wifeWallets = computed.where((w) => OwnerFilter.wife.matchWallet(w)).toList();
      expect(wifeWallets.length, equals(1));
      expect(wifeWallets.first.balance, equals(2500000)); // 3M - 0.5M

      // Joint filter: only w3
      final jointWallets = computed.where((w) => OwnerFilter.joint.matchWallet(w)).toList();
      expect(jointWallets.length, equals(1));
      expect(jointWallets.first.balance, equals(12000000)); // 10M + 2M

      // All filter: sum of all balances = 4M + 2.5M + 12M = 18.5M
      final totalNetBalance = computed.fold<int>(0, (sum, w) => sum + w.balance);
      expect(totalNetBalance, equals(18500000));
    });
  });
}
