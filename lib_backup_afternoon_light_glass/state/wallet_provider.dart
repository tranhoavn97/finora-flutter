import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models/wallet.dart';
import '../data/models/transaction.dart';
import '../data/services/wallet_repository.dart';
import '../data/services/transaction_repository.dart';

class WalletProvider extends ChangeNotifier {
  final _walletRepo = WalletRepository();
  final _txRepo = TransactionRepository();

  List<Wallet> wallets = [];
  bool isRefreshing = false;

  String? _userId;
  final List<StreamSubscription> _subs = [];
  List<Wallet> _rawWallets = [];
  List<TransactionModel> _rawTxs = [];
  final _events = StreamController<String>.broadcast();
  Stream<String> get events => _events.stream;

  void load(String userId) {
    if (_userId == userId && _subs.isNotEmpty) return;
    _userId = userId;
    _cancel();
    isRefreshing = true;
    notifyListeners();

    _subs.add(_walletRepo.watchWallets(userId).listen((raw) {
      _rawWallets = raw;
      _recompute();
    }, onError: (e) {
      isRefreshing = false;
      _events.add('Lỗi tải ví');
      notifyListeners();
    }));

    _subs.add(_txRepo.watchTransactions(userId).listen((txs) {
      _rawTxs = txs;
      _recompute();
    }));
  }

  void _recompute() {
    wallets = WalletRepository.computeWalletsWithBalances(_rawWallets, _rawTxs);
    isRefreshing = false;
    notifyListeners();
  }

  void _cancel() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }

  Future<void> addWallet(String userId, Wallet wallet) async {
    try {
      await _walletRepo.createWallet(userId, wallet);
      _events.add('Đã thêm ví/tài khoản thành công');
    } catch (e) {
      _events.add('Lỗi thêm ví');
    }
  }

  Future<void> updateWallet(String userId, String id, Wallet wallet) async {
    try {
      await _walletRepo.updateWallet(userId, id, wallet);
      _events.add('Đã cập nhật thông tin ví');
    } catch (e) {
      _events.add('Lỗi cập nhật');
    }
  }

  Future<void> deleteWallet(String userId, String id) async {
    try {
      await _walletRepo.deleteWallet(userId, id);
      _events.add('Đã xóa ví tài khoản');
    } catch (e) {
      _events.add('Lỗi xóa ví');
    }
  }

  @override
  void dispose() {
    _cancel();
    _events.close();
    super.dispose();
  }
}
