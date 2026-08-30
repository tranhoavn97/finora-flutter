import 'package:flutter_test/flutter_test.dart';
import 'package:finora/core/widgets/subject_filter_pill.dart';
import 'package:finora/data/models/transaction.dart';
import 'package:finora/data/models/wallet.dart';
import 'package:finora/data/services/wallet_repository.dart';

void main() {
  group('OwnerFilter Matching Tests', () {
    final walletH = const Wallet(id: 'w1', name: 'VCB Chồng', owner: 'husband', ownerName: 'Chồng');
    final walletW = const Wallet(id: 'w2', name: 'MoMo Vợ', owner: 'wife', ownerName: 'Vợ');
    final walletJ = const Wallet(id: 'w3', name: 'Quỹ chung', owner: 'joint', ownerName: 'Chung');

    final txH = TransactionModel(id: 't1', amount: 50000, type: 'expense', walletId: 'w1', owner: 'husband');
    final txW = TransactionModel(id: 't2', amount: 80000, type: 'expense', walletId: 'w2', owner: 'wife');
    final txJ = TransactionModel(id: 't3', amount: 150000, type: 'expense', walletId: 'w3', owner: 'joint');

    test('OwnerFilter.all matches all wallets and transactions', () {
      expect(OwnerFilter.all.matchWallet(walletH), isTrue);
      expect(OwnerFilter.all.matchWallet(walletW), isTrue);
      expect(OwnerFilter.all.matchWallet(walletJ), isTrue);

      expect(OwnerFilter.all.matchTransaction(txH), isTrue);
      expect(OwnerFilter.all.matchTransaction(txW), isTrue);
      expect(OwnerFilter.all.matchTransaction(txJ), isTrue);
    });

    test('OwnerFilter.husband matches only husband items', () {
      expect(OwnerFilter.husband.matchWallet(walletH), isTrue);
      expect(OwnerFilter.husband.matchWallet(walletW), isFalse);
      expect(OwnerFilter.husband.matchWallet(walletJ), isFalse);

      expect(OwnerFilter.husband.matchTransaction(txH), isTrue);
      expect(OwnerFilter.husband.matchTransaction(txW), isFalse);
      expect(OwnerFilter.husband.matchTransaction(txJ), isFalse);
    });

    test('OwnerFilter.wife matches only wife items', () {
      expect(OwnerFilter.wife.matchWallet(walletH), isFalse);
      expect(OwnerFilter.wife.matchWallet(walletW), isTrue);
      expect(OwnerFilter.wife.matchWallet(walletJ), isFalse);

      expect(OwnerFilter.wife.matchTransaction(txH), isFalse);
      expect(OwnerFilter.wife.matchTransaction(txW), isTrue);
      expect(OwnerFilter.wife.matchTransaction(txJ), isFalse);
    });

    test('OwnerFilter.joint matches only joint/family items', () {
      expect(OwnerFilter.joint.matchWallet(walletH), isFalse);
      expect(OwnerFilter.joint.matchWallet(walletW), isFalse);
      expect(OwnerFilter.joint.matchWallet(walletJ), isTrue);

      expect(OwnerFilter.joint.matchTransaction(txH), isFalse);
      expect(OwnerFilter.joint.matchTransaction(txW), isFalse);
      expect(OwnerFilter.joint.matchTransaction(txJ), isTrue);
    });
  });

  group('Pure Ledger Balance Computation Tests', () {
    test('computes correct wallet balance from initial balance, income, expense, and transfer', () {
      final rawWallets = [
        const Wallet(id: 'w1', name: 'Tiền mặt', type: 'cash', initialBalance: 1000000, balance: 0),
        const Wallet(id: 'w2', name: 'VCB', type: 'bank', initialBalance: 5000000, balance: 0),
      ];

      final txs = [
        TransactionModel(id: 't1', amount: 200000, type: 'expense', walletId: 'w1'),
        TransactionModel(id: 't2', amount: 500000, type: 'income', walletId: 'w1'),
        // Transfer 1.000.000 from VCB (w2) to Cash (w1)
        TransactionModel(
          id: 't3',
          amount: 1000000,
          type: 'transfer',
          fromWalletId: 'w2',
          toWalletId: 'w1',
        ),
      ];

      final computed = WalletRepository.computeWalletsWithBalances(rawWallets, txs);

      final w1 = computed.firstWhere((w) => w.id == 'w1');
      final w2 = computed.firstWhere((w) => w.id == 'w2');

      // w1: initial(1.000.000) - 200.000 + 500.000 + transfer_in(1.000.000) = 2.300.000
      expect(w1.balance, equals(2300000));

      // w2: initial(5.000.000) - transfer_out(1.000.000) = 4.000.000
      expect(w2.balance, equals(4000000));
    });

    test('computes credit card debt and payments accurately', () {
      final rawWallets = [
        const Wallet(
          id: 'card1',
          name: 'Visa Signature',
          type: 'credit_card',
          creditLimit: 50000000,
          initialDebt: 5000000,
          currentDebt: 0,
        ),
        const Wallet(
          id: 'w_bank',
          name: 'Techcombank',
          type: 'bank',
          initialBalance: 20000000,
          balance: 0,
        ),
      ];

      final txs = [
        // Swipe credit card 3.000.000
        TransactionModel(id: 't1', amount: 3000000, type: 'expense', walletId: 'card1'),
        // Pay 2.000.000 from Techcombank to credit card
        TransactionModel(
          id: 't2',
          amount: 2000000,
          type: 'credit_card_payment',
          fromWalletId: 'w_bank',
          toWalletId: 'card1',
          creditCardId: 'card1',
        ),
      ];

      final computed = WalletRepository.computeWalletsWithBalances(rawWallets, txs);

      final card = computed.firstWhere((w) => w.id == 'card1');
      final bank = computed.firstWhere((w) => w.id == 'w_bank');

      // Card debt: initialDebt(5.000.000) + swipe(3.000.000) - payment(2.000.000) = 6.000.000
      expect(card.currentDebt, equals(6000000));

      // Bank: initial(20.000.000) - payment(2.000.000) = 18.000.000
      expect(bank.balance, equals(18000000));
    });
  });
}
