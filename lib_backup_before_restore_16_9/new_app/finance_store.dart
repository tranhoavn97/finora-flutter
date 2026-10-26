import 'dart:async';
import 'package:flutter/foundation.dart';

import '../data/models/transaction.dart';
import '../data/models/wallet.dart';
import '../data/services/transaction_repository.dart';
import '../data/services/wallet_repository.dart';

class FinanceStore extends ChangeNotifier {
  FinanceStore(this.userId);
  final String userId;
  final _transactionsRepo = TransactionRepository();
  final _walletsRepo = WalletRepository();
  StreamSubscription<List<TransactionModel>>? _txSub;
  StreamSubscription<List<Wallet>>? _walletSub;
  List<TransactionModel> transactions = const [];
  List<Wallet> wallets = const [];
  List<Wallet> _sourceWallets = const [];
  bool loading = true;
  String? error;

  int get income => _monthTransactions
      .where((t) => t.type == 'income')
      .fold(0, (v, t) => v + t.amount);
  int get expense => _monthTransactions
      .where((t) => t.type == 'expense')
      .fold(0, (v, t) => v + t.amount);
  int get balance =>
      wallets.where((w) => !w.isCreditCard).fold(0, (v, w) => v + w.balance);
  int get debt =>
      wallets.where((w) => w.isCreditCard).fold(0, (v, w) => v + w.currentDebt);
  int get netWorth => balance - debt;

  List<TransactionModel> get _monthTransactions {
    final n = DateTime.now();
    return transactions.where((t) {
      final d = DateTime.fromMillisecondsSinceEpoch(t.date);
      return d.year == n.year && d.month == n.month;
    }).toList();
  }

  void start() {
    _txSub = _transactionsRepo.watchTransactions(userId).listen((value) {
      transactions = value;
      _deriveWallets();
      loading = false;
      notifyListeners();
    }, onError: _fail);
    _walletSub = _walletsRepo.watchWallets(userId).listen((value) {
      _sourceWallets = value;
      _deriveWallets();
      loading = false;
      notifyListeners();
    }, onError: _fail);
  }

  void _deriveWallets() => wallets =
      WalletRepository.computeWalletsWithBalances(_sourceWallets, transactions);
  void _fail(Object e) {
    error = e.toString();
    loading = false;
    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel transaction) => _transactionsRepo
      .createTransaction(userId, transaction.copyWith(userId: userId));
  Future<void> deleteTransaction(TransactionModel transaction) =>
      _transactionsRepo.deleteTransactionAndReverse(userId, transaction);
  Future<void> addWallet(Wallet wallet) =>
      _walletsRepo.createWallet(userId, wallet);
  Future<void> deleteWallet(Wallet wallet) =>
      _walletsRepo.deleteWallet(userId, wallet.id);

  @override
  void dispose() {
    _txSub?.cancel();
    _walletSub?.cancel();
    super.dispose();
  }
}
