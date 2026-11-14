import 'package:finora/data/models/transaction.dart';
import 'package:finora/data/models/wallet.dart';
import 'package:finora/data/services/wallet_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TransactionModel tx({
    required String id,
    required String type,
    required int amount,
    String? walletId,
    String? walletName,
    String? fromWalletId,
    String? fromWalletName,
    String? toWalletId,
    String? toWalletName,
    String? creditCardId,
    String? creditCardName,
    String? owner,
    String? fromOwner,
    String? toOwner,
  }) =>
      TransactionModel(
        id: id,
        type: type,
        amount: amount,
        categoryId: 'cat',
        categoryName: 'Chuyển khoản',
        walletId: walletId,
        walletName: walletName,
        fromWalletId: fromWalletId,
        fromWalletName: fromWalletName,
        toWalletId: toWalletId,
        toWalletName: toWalletName,
        creditCardId: creditCardId,
        creditCardName: creditCardName,
        owner: owner,
        fromOwner: fromOwner,
        toOwner: toOwner,
        date: 1700000000000,
        createdAt: 1700000000000,
      );

  test('transfers using walletId-only or fromWalletId compute identical balances',
      () {
    final wallets = [
      Wallet.fromMap('ncb_1', {
        'name': 'NCB',
        'type': 'bank',
        'owner': 'husband',
        'rawInitialBalance': 2734539,
        'initialBalance': 2734539,
        'balance': 2734539,
      }),
      Wallet.fromMap('vcb_1', {
        'name': 'Vietcombank',
        'type': 'bank',
        'owner': 'wife',
        'rawInitialBalance': 1000000,
        'initialBalance': 1000000,
        'balance': 1000000,
      }),
    ];

    final txList = [
      // App notification transfer where only walletId + toWalletId were set
      tx(
        id: 't1',
        type: 'transfer',
        amount: 500000,
        walletId: 'NCB_1', // case-insensitive id check
        walletName: 'NCB',
        toWalletId: 'vcb_1',
        toWalletName: 'Vietcombank',
      ),
      // Web transfer with explicit fromWalletId + walletId
      tx(
        id: 't2',
        type: 'transfer',
        amount: 200000,
        fromWalletId: 'vcb_1',
        walletId: 'vcb_1',
        fromWalletName: 'Vietcombank',
        toWalletId: 'ncb_1',
        toWalletName: 'NCB',
      ),
    ];

    final computed = WalletRepository.computeWalletsWithBalances(wallets, txList);
    expect(computed[0].balance, 2734539 - 500000 + 200000);
    expect(computed[1].balance, 1000000 + 500000 - 200000);
  });

  test('transfers with duplicate wallet names disambiguate via owner keys', () {
    final wallets = [
      Wallet.fromMap('cash_h', {
        'name': 'Tiền mặt',
        'type': 'cash',
        'owner': 'husband',
        'initialBalance': 2000000,
        'balance': 2000000,
      }),
      Wallet.fromMap('cash_w', {
        'name': 'Tiền mặt',
        'type': 'cash',
        'owner': 'wife',
        'initialBalance': 500000,
        'balance': 500000,
      }),
    ];

    final computed = WalletRepository.computeWalletsWithBalances(wallets, [
      tx(
        id: 't_name',
        type: 'transfer',
        amount: 300000,
        fromWalletName: 'Tiền mặt',
        fromOwner: 'Chồng',
        toWalletName: 'Tiền mặt',
        toOwner: 'Vợ',
      ),
    ]);
    expect(computed[0].balance, 1700000);
    expect(computed[1].balance, 800000);
  });

  test('explicit balance/debt edits support legacy & rawInitial wallets cleanly',
      () {
    final legacyCash = Wallet.fromMap('legacy_c', {'balance': 900000});
    final editedLegacyCash = legacyCash.copyWith(balance: 1500000);
    expect(
      WalletRepository.cashBalanceUpdate(legacyCash, editedLegacyCash),
      {'balance': 1500000},
    );

    final oldCard = Wallet.fromMap('cc_1', {
      'type': 'credit_card',
      'creditLimit': 30000000,
      'rawInitialDebt': 2000000,
      'initialDebt': 2000000,
      'currentDebt': 3500000,
    });
    final editedCard = Wallet(
      id: 'cc_1',
      name: 'Thẻ tín dụng',
      type: 'credit_card',
      creditLimit: 30000000,
      initialDebt: 2500000,
      hasInitialDebt: true,
      currentDebt: 4000000,
      createdAt: 1,
      updatedAt: 2,
    );
    expect(
      WalletRepository.creditDebtUpdate(oldCard, editedCard,
          hasRawInitialDebt: true),
      {
        'initialDebt': 2500000,
        'rawInitialDebt': 2500000,
        'currentDebt': 4000000,
      },
    );
  });
}
