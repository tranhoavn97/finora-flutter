import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/wallet.dart';
import '../models/transaction.dart';
import '../models/coerce.dart';

/// users/{userId}/wallets
class WalletRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'ai-studio-2b22d4a0-9f50-4bbc-a8ed-f26d36b92339',
  );

  CollectionReference<Map<String, dynamic>> _col(String scopeId) =>
      _db.collection('families').doc(scopeId).collection('wallets');

  Stream<List<Wallet>> watchWallets(String userId) {
    return _col(userId).snapshots().map((snap) =>
        snap.docs.map((d) => Wallet.fromMap(d.id, d.data())).toList());
  }

  Future<List<Wallet>> getWallets(String userId) async {
    final snap = await _col(userId).get();
    return snap.docs.map((d) => Wallet.fromMap(d.id, d.data())).toList();
  }

  Future<String> createWallet(String userId, Wallet wallet) async {
    final ts = FieldValue.serverTimestamp();
    final Map<String, dynamic> data;
    if (wallet.isCreditCard) {
      data = {
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
    final ref = await _col(userId).add(removeNulls(data));
    return ref.id;
  }

  Future<void> updateWallet(String userId, String walletId, Wallet wallet) async {
    final ref = _col(userId).doc(walletId);
    final base = {
      'name': wallet.name,
      'type': wallet.type,
      'owner': wallet.owner,
      'ownerName': wallet.ownerName,
      'bankCode': wallet.bankCode,
      'bankName': wallet.bankName,
      'accountNumber': wallet.accountNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (wallet.isCreditCard) {
      await ref.update(removeNulls({
        ...base,
        'creditLimit': wallet.creditLimit,
        'statementDay': wallet.statementDay,
        'paymentDueDay': wallet.paymentDueDay,
        'minimumPaymentPercent': wallet.minimumPaymentPercent,
        'themeColor': wallet.themeColor,
      }));
    } else {
      final snap = await ref.get();
      final old = Wallet.fromMap(snap.id, snap.data());
      final diff = wallet.initialBalance - old.initialBalance;
      await ref.update(removeNulls({
        ...base,
        'initialBalance': wallet.initialBalance,
        'balance': old.balance + diff,
      }));
    }
  }

  Future<void> deleteWallet(String userId, String walletId) async {
    await _col(userId).doc(walletId).delete();
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

    void addBalance(String id, int v) => balanceDelta[id] = (balanceDelta[id] ?? 0) + v;
    void addDebt(String id, int v) => debtDelta[id] = (debtDelta[id] ?? 0) + v;

    const plusBalanceTypes = {'income', 'borrowing', 'loan_repayment_received'};
    const minusBalanceTypes = {'expense', 'saving', 'lending', 'debt_repayment'};
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
            from.isCreditCard ? addDebt(from.id, amount) : addBalance(from.id, -amount);
          }
          if (to != null) {
            to.isCreditCard ? addDebt(to.id, -amount) : addBalance(to.id, amount);
          }
          break;
        case 'credit_card_payment':
          final from = byId[tx.fromWalletId];
          final cardId = tx.creditCardId ?? tx.toWalletId;
          final card = cardId == null ? null : byId[cardId];
          if (from != null) {
            from.isCreditCard ? addDebt(from.id, amount) : addBalance(from.id, -amount);
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
          final w = byId[tx.walletId];
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
        return w.copyWith(balance: 0, currentDebt: w.initialDebt + (debtDelta[w.id] ?? 0));
      }
      return w.copyWith(balance: w.initialBalance + (balanceDelta[w.id] ?? 0));
    }).toList();
  }
}
