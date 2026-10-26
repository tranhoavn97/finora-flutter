import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:finora/data/models/wallet.dart';
import 'package:finora/data/models/transaction.dart';
import 'package:finora/data/models/coerce.dart';
import 'package:finora/data/services/wallet_repository.dart';
import 'package:finora/data/services/transaction_repository.dart';
import 'package:finora/state/wallet_provider.dart';

class _WalletStream extends WalletRepository {
  final values = StreamController<List<Wallet>>.broadcast(sync: true);
  @override
  Stream<List<Wallet>> watchWallets(String userId, {String? familyId}) =>
      values.stream;
}

class _TransactionStream extends TransactionRepository {
  final values = StreamController<List<TransactionModel>>.broadcast(sync: true);
  @override
  Stream<List<TransactionModel>> watchTransactions(String userId,
          {String? familyId}) =>
      values.stream;
}

Wallet cash(String id, {String name = 'Tiền mặt', String owner = 'husband'}) =>
    Wallet.fromMap(id, {
      'name': name,
      'owner': owner,
      'initialBalance': 1000000,
      'balance': 1000000,
    });

List<Wallet> compute(
        List<Wallet> wallets, List<TransactionModel> transactions) =>
    WalletRepository.computeWalletsWithBalances(wallets, transactions);

void main() {
  test(
      'wallet stream arriving before ledger never publishes a false opening balance',
      () async {
    final wr = _WalletStream();
    final tr = _TransactionStream();
    final provider =
        WalletProvider(walletRepository: wr, transactionRepository: tr);
    provider.load('sample');
    wr.values.add([cash('a')]);
    expect(provider.hasLoadedBalances, isFalse);
    expect(provider.wallets, isEmpty);
    tr.values.add([const TransactionModel(walletId: 'a', amount: 250000)]);
    expect(provider.wallets.single.balance, 750000);
    expect(provider.hasLoadedBalances, isTrue);
    expect(provider.isRefreshing, isFalse);
    provider.dispose();
    await wr.values.close();
    await tr.values.close();
  });

  test('failed refresh retains last complete balance until ledger recovers',
      () async {
    final wr = _WalletStream();
    final tr = _TransactionStream();
    final provider =
        WalletProvider(walletRepository: wr, transactionRepository: tr);
    provider.load('sample');
    tr.values.add([const TransactionModel(walletId: 'a', amount: 250000)]);
    expect(provider.wallets, isEmpty);
    wr.values.add([cash('a')]);
    provider.load('sample', force: true);
    wr.values.add([
      Wallet.fromMap('a', {'initialBalance': 2000000})
    ]);
    tr.values.addError(StateError('offline'));
    expect(provider.error, isNotNull);
    expect(provider.wallets.single.balance, 750000);
    tr.values.add([const TransactionModel(walletId: 'a', amount: 500000)]);
    expect(provider.error, isNull);
    expect(provider.wallets.single.balance, 1500000);
    provider.load('another-account');
    expect(provider.wallets, isEmpty);
    expect(provider.hasLoadedBalances, isFalse);
    provider.dispose();
    await wr.values.close();
    await tr.values.close();
  });
  test('cash balance includes income, expenses, transfers and repayments once',
      () {
    final wallets = [cash('a'), cash('b', name: 'Ngân hàng')];
    final txs = [
      const TransactionModel(type: 'income', walletId: 'a', amount: 500000),
      const TransactionModel(type: 'expense', walletId: 'a', amount: 120000),
      const TransactionModel(
          type: 'transfer', fromWalletId: 'a', toWalletId: 'b', amount: 200000),
      const TransactionModel(
          type: 'debt_repayment', walletId: 'a', amount: 80000),
    ];
    final result = compute(wallets, txs);
    expect(result[0].balance, 1100000);
    expect(result[1].balance, 1200000);
    expect(compute(result, txs).map((w) => w.balance), [1100000, 1200000]);
  });

  for (final opening in [null, '', 'not-a-number']) {
    test('unusable legacy opening $opening does not replay from zero', () {
      final wallet =
          Wallet.fromMap('a', {'balance': 907000, 'initialBalance': opening});
      expect(wallet.hasInitialBalance, isFalse);
      expect(
          compute([
            wallet
          ], [
            const TransactionModel(walletId: 'a', amount: 150000)
          ]).single.balance,
          907000);
    });
  }

  test('zero is a valid opening balance', () {
    final wallet =
        Wallet.fromMap('a', {'initialBalance': 0, 'balance': 999999});
    expect(
        compute([
          wallet
        ], [
          const TransactionModel(walletId: 'a', type: 'income', amount: 10000)
        ]).single.balance,
        10000);
  });

  test('null raw baseline falls back to valid opening balance', () {
    final wallet = Wallet.fromMap(
        'a', {'rawInitialBalance': null, 'initialBalance': 1000000});
    expect(
        compute([
          wallet
        ], [
          const TransactionModel(walletId: 'a', amount: 10000)
        ]).single.balance,
        990000);
  });

  test('numeric strings are parsed as money, never as dates', () {
    expect(toMoneyValue('1000000.0'), 1000000);
    expect(toMoneyValue('1e6'), 1000000);
    expect(toMoneyValue('2026-10-15'), 0);
    expect(tryMoneyValue(double.nan), isNull);
    final wallet = Wallet.fromMap('a', {'initialBalance': '1000000.0'});
    final tx =
        TransactionModel.fromMap('tx', {'walletId': 'a', 'amount': '250000.0'});
    expect(compute([wallet], [tx]).single.balance, 750000);
    expect(toLongValue('2026-10-15T00:00:00Z'), greaterThan(0));
  });

  for (final action in ['buy', 'sell', 'payout', 'interest', 'update_value']) {
    test('investment $action supports legacy source wallet field', () {
      final result = compute([
        cash('a')
      ], [
        TransactionModel(
            type: 'investment',
            walletId: '',
            fromWalletId: 'a',
            amount: 100000,
            investmentAction: action)
      ]);
      final expected = action == 'update_value'
          ? 1000000
          : action == 'buy'
              ? 900000
              : 1100000;
      expect(result.single.balance, expected);
    });
  }

  test('blank wallet id uses legacy source id for ordinary expenses', () {
    expect(
        compute([
          cash('a')
        ], [
          const TransactionModel(
              walletId: ' ', fromWalletId: 'a', amount: 100000)
        ]).single.balance,
        900000);
  });

  test('same wallet name resolves by explicit owner regardless of list order',
      () {
    final wallets = [cash('h'), cash('w', owner: 'wife')];
    for (final order in [wallets, wallets.reversed.toList()]) {
      final result = compute(order, [
        const TransactionModel(
            walletName: 'Tiền mặt', owner: 'husband', amount: 100000)
      ]);
      expect(result.firstWhere((w) => w.id == 'h').balance, 900000);
      expect(result.firstWhere((w) => w.id == 'w').balance, 1000000);
    }
  });

  test('ambiguous names without attribution do not debit an arbitrary wallet',
      () {
    final result = compute([
      cash('h'),
      cash('w', owner: 'wife')
    ], [
      const TransactionModel(walletName: 'Tiền mặt', amount: 100000),
    ]);
    expect(result.map((w) => w.balance), [1000000, 1000000]);
  });

  test('stable wallet id outranks stale name and transaction author', () {
    final result = compute([
      cash('h'),
      cash('w', owner: 'wife')
    ], [
      const TransactionModel(
          walletId: 'w',
          walletName: 'Tiền mặt',
          owner: 'husband',
          amount: 100000),
    ]);
    expect(result.map((w) => w.balance), [1000000, 900000]);
  });

  test('legacy credit card uses stored usedAmount without double replay', () {
    final card = Wallet.fromMap('c', {
      'type': 'credit_card',
      'usedAmount': '350000.0',
      'initialDebt': null,
      'creditLimit': 1000000
    });
    expect(
        compute([card], [const TransactionModel(walletId: 'c', amount: 100000)])
            .single
            .currentDebt,
        350000);
    final zeroDebt = Wallet.fromMap(
        'c', {'type': 'credit_card', 'currentDebt': 0, 'usedAmount': 350000});
    expect(zeroDebt.currentDebt, 0);
  });

  test('card payment reduces source cash and card debt once', () {
    final card = Wallet.fromMap('c',
        {'type': 'credit_card', 'initialDebt': 500000, 'creditLimit': 1000000});
    final result = compute([
      cash('a'),
      card
    ], [
      const TransactionModel(
          type: 'credit_card_payment',
          fromWalletId: 'a',
          creditCardId: '',
          toWalletId: 'c',
          amount: 200000),
    ]);
    expect(result[0].balance, 800000);
    expect(result[1].currentDebt, 300000);
  });

  test('editing legacy wallet metadata does not inject a zero baseline', () {
    final legacy = Wallet.fromMap('a', {'balance': 907000});
    expect(WalletRepository.cashBalanceUpdate(legacy, cash('a')), isEmpty);
    final normal = cash('a');
    expect(WalletRepository.cashBalanceUpdate(normal, normal), isEmpty);
  });

  test('explicit opening adjustment updates both raw and regular baselines',
      () {
    final old = Wallet.fromMap('a', {
      'rawInitialBalance': 1000000,
      'initialBalance': 1000000,
      'balance': 800000
    });
    final edited = Wallet.fromMap('a', {'initialBalance': 1200000});
    final patch = WalletRepository.cashBalanceUpdate(old, edited,
        hasRawInitialBalance: true);
    expect(patch, {
      'initialBalance': 1200000,
      'rawInitialBalance': 1200000,
      'balance': 1000000
    });
  });
}
