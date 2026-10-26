import 'dart:async';
import '../models/wallet.dart';
import '../models/transaction.dart';
import '../models/coerce.dart';
import 'supabase_bridge.dart';

/// users/{userId}/wallets
class WalletRepository {
  Stream<List<Wallet>> watchWallets(String userId, {String? familyId}) {
    return SupabaseBridge.watchUserCollection(
      userId: userId,
      collection: 'wallets',
    ).map((rows) => rows
        .where((data) => data['deletedAt'] == null)
        .map((data) => Wallet.fromMap(data['id'].toString(), data))
        .toList());
  }

  Future<List<Wallet>> getWallets(String userId, {String? familyId}) async {
    final rows = await SupabaseBridge.loadUserCollection(
        userId: userId, collection: 'wallets');
    return rows
        .where((data) => data['deletedAt'] == null)
        .map((data) => Wallet.fromMap(data['id'].toString(), data))
        .toList();
  }

  Future<String> createWallet(String userId, Wallet wallet,
      {String? familyId}) async {
    final ts = DateTime.now().toUtc().toIso8601String();
    final Map<String, dynamic> data;
    if (wallet.isCreditCard) {
      data = {
        'userId': userId,
        'name': wallet.name,
        'type': wallet.type,
        'owner': wallet.owner,
        'ownerName': wallet.ownerName,
        'bankCode': wallet.bankCode,
        'bankName': wallet.bankName,
        'accountNumber': wallet.accountNumber,
        'themeColor': wallet.themeColor,
        'creditLimit': wallet.creditLimit,
        'initialDebt': wallet.initialDebt,
        'currentDebt': wallet.initialDebt,
        'statementDay': wallet.statementDay,
        'paymentDueDay': wallet.paymentDueDay,
        'minimumPaymentPercent': wallet.minimumPaymentPercent,
        'balance': 0,
        'initialBalance': 0,
        'createdAt': ts,
        'updatedAt': ts,
      };
    } else {
      data = {
        'userId': userId,
        'name': wallet.name,
        'type': wallet.type,
        'owner': wallet.owner,
        'ownerName': wallet.ownerName,
        'bankCode': wallet.bankCode,
        'bankName': wallet.bankName,
        'accountNumber': wallet.accountNumber,
        'themeColor': wallet.themeColor,
        'initialBalance': wallet.initialBalance,
        'balance': wallet.initialBalance,
        'createdAt': ts,
        'updatedAt': ts,
      };
    }
    final id = SupabaseBridge.newDocumentId();
    await SupabaseBridge.saveUserDocument(
      userId: userId,
      collection: 'wallets',
      documentId: id,
      data: removeNulls(data),
      replace: true,
    );
    return id;
  }

  Future<void> updateWallet(String userId, String walletId, Wallet wallet,
      {String? familyId}) async {
    final base = {
      'name': wallet.name,
      'type': wallet.type,
      'owner': wallet.owner,
      'ownerName': wallet.ownerName,
      'bankCode': wallet.bankCode,
      'bankName': wallet.bankName,
      'accountNumber': wallet.accountNumber,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
    if (wallet.isCreditCard) {
      await SupabaseBridge.saveUserDocument(
        userId: userId,
        collection: 'wallets',
        documentId: walletId,
        data: removeNulls({
          ...base,
          'creditLimit': wallet.creditLimit,
          'statementDay': wallet.statementDay,
          'paymentDueDay': wallet.paymentDueDay,
          'minimumPaymentPercent': wallet.minimumPaymentPercent,
          'themeColor': wallet.themeColor,
        }),
      );
    } else {
      final rows = await SupabaseBridge.loadUserCollection(
          userId: userId, collection: 'wallets');
      final raw = rows.where((row) => row['id'] == walletId).firstOrNull;
      final old = raw == null ? null : Wallet.fromMap(walletId, raw);
      final diff = old == null ? 0 : wallet.initialBalance - old.initialBalance;
      await SupabaseBridge.saveUserDocument(
        userId: userId,
        collection: 'wallets',
        documentId: walletId,
        data: removeNulls({
          ...base,
          'initialBalance': wallet.initialBalance,
          'balance': old == null ? wallet.balance : old.balance + diff,
        }),
      );
    }
  }

  Future<void> deleteWallet(String userId, String walletId,
      {String? familyId}) async {
    await SupabaseBridge.deleteUserDocument(
      userId: userId,
      collection: 'wallets',
      documentId: walletId,
    );
  }

  static String normalizeTransactionType(String type) {
    final t = type.toLowerCase().trim();
    switch (t) {
      case 'income':
      case 'interest_income':
        return 'income';
      case 'expense':
      case 'interest_expense':
        return 'expense';
      case 'transfer':
        return 'transfer';
      case 'saving':
        return 'saving';
      case 'borrowing':
      case 'borrow':
      case 'debt':
        return 'borrowing';
      case 'lending':
      case 'lend':
      case 'loan':
        return 'lending';
      case 'debt_repayment':
      case 'loan_repayment_sent':
        return 'debt_repayment';
      case 'loan_repayment_received':
        return 'loan_repayment_received';
      case 'credit_card_payment':
        return 'credit_card_payment';
      case 'investment':
        return 'investment';
      default:
        return t;
    }
  }

  /// Pure ledger computation — derives current balances/debts from transactions.
  /// Mirrors WalletRepositoryImpl.computeWalletsWithBalances.
  static List<Wallet> computeWalletsWithBalances(
      List<Wallet> wallets, List<TransactionModel> transactions) {
    final byId = {for (final w in wallets) w.id: w};
    final balanceDelta = <String, int>{};
    final debtDelta = <String, int>{};

    void addBalance(String id, int v) =>
        balanceDelta[id] = (balanceDelta[id] ?? 0) + v;
    void addDebt(String id, int v) => debtDelta[id] = (debtDelta[id] ?? 0) + v;

    const plusBalanceTypes = {'income', 'borrowing', 'loan_repayment_received'};
    const minusBalanceTypes = {
      'expense',
      'saving',
      'lending',
      'debt_repayment'
    };
    const plusDebtTypes = {'expense', 'lending', 'debt_repayment', 'saving'};
    const minusDebtTypes = {'income', 'borrowing', 'loan_repayment_received'};
    const investGain = {'sell', 'payout', 'interest'};

    for (final tx in transactions) {
      final amount = tx.amount;
      final type = normalizeTransactionType(tx.type);
      switch (type) {
        case 'transfer':
          final from = byId[tx.fromWalletId];
          final to = byId[tx.toWalletId];
          if (from != null) {
            from.isCreditCard
                ? addDebt(from.id, amount)
                : addBalance(from.id, -amount);
          }
          if (to != null) {
            to.isCreditCard
                ? addDebt(to.id, -amount)
                : addBalance(to.id, amount);
          }
          break;
        case 'credit_card_payment':
          final from = byId[tx.fromWalletId];
          final cardId = tx.creditCardId ?? tx.toWalletId;
          final card = cardId == null ? null : byId[cardId];
          if (from != null) {
            from.isCreditCard
                ? addDebt(from.id, amount)
                : addBalance(from.id, -amount);
          }
          if (card != null) addDebt(card.id, -amount);
          break;
        case 'investment':
          final w = byId[tx.walletId];
          if (w != null) {
            final action = tx.investmentAction;
            if (w.isCreditCard) {
              if (investGain.contains(action)) {
                addDebt(w.id, -amount);
              } else if (action == 'update_value') {
                // no effect
              } else {
                addDebt(w.id, amount);
              }
            } else {
              if (investGain.contains(action)) {
                addBalance(w.id, amount);
              } else if (action == 'update_value') {
                // no effect
              } else {
                addBalance(w.id, -amount);
              }
            }
          }
          break;
        default:
          // Legacy web records can keep the source wallet only in
          // `fromWalletId`. The web ledger deliberately falls back to it.
          final effectiveWalletId = tx.walletId ?? tx.fromWalletId;
          final w = byId[effectiveWalletId];
          if (w != null) {
            if (w.isCreditCard) {
              if (plusDebtTypes.contains(type)) {
                addDebt(w.id, amount);
              } else if (minusDebtTypes.contains(type)) {
                addDebt(w.id, -amount);
              } else if (type == 'loan_adjustment') {
                if (tx.direction == 'out') {
                  addDebt(w.id, amount);
                } else if (tx.direction == 'in') {
                  addDebt(w.id, -amount);
                }
              }
            } else {
              if (plusBalanceTypes.contains(type)) {
                addBalance(w.id, amount);
              } else if (minusBalanceTypes.contains(type)) {
                addBalance(w.id, -amount);
              } else if (type == 'loan_adjustment') {
                if (tx.direction == 'in') {
                  addBalance(w.id, amount);
                } else if (tx.direction == 'out') {
                  addBalance(w.id, -amount);
                }
              }
            }
          }
      }
    }

    return wallets.map((w) {
      if (w.isCreditCard) {
        // Match the web migration rule: without a reliable baseline, the
        // persisted debt is already the current value and must not be replayed.
        if (!w.hasInitialDebt) {
          return w.copyWith(
            currentDebt: w.currentDebt,
            balance: 0,
          );
        }
        final newDebt =
            (w.initialDebt + (debtDelta[w.id] ?? 0)).clamp(0, 1 << 62);
        return w.copyWith(
          currentDebt: newDebt,
          balance: w.creditLimit - newDebt,
        );
      }
      // Old wallets created before the derived-balance model have only a
      // persisted `balance`. Web keeps that value until its migration writes
      // an initial baseline; Flutter must do the same to avoid double replay.
      if (!w.hasInitialBalance) return w.copyWith(balance: w.balance);
      final newBal = w.initialBalance + (balanceDelta[w.id] ?? 0);
      return w.copyWith(balance: newBal);
    }).toList();
  }
}
