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
  List<TransactionModel> get transactions => List.unmodifiable(_rawTxs);
  bool isRefreshing = false;
  String? error;
  final Set<String> _pending = {};
  final Set<String> _failed = {};
  int _generation = 0;

  String? _userId;
  String? _familyId;
  final List<StreamSubscription> _subs = [];
  List<Wallet> _rawWallets = [];
  List<TransactionModel> _rawTxs = [];
  final _events = StreamController<String>.broadcast();
  Stream<String> get events => _events.stream;

  void load(String userId, {String? familyId, bool force = false}) {
    final effectiveFamilyId =
        familyId ?? (_userId == userId ? _familyId : null);
    if (!force &&
        _userId == userId &&
        _familyId == effectiveFamilyId &&
        _subs.isNotEmpty) return;
    if (_userId != userId || _familyId != effectiveFamilyId) {
      wallets = [];
      _rawWallets = [];
      _rawTxs = [];
    }
    _userId = userId;
    _familyId = effectiveFamilyId;
    _cancel();
    final generation = ++_generation;
    _pending
      ..clear()
      ..addAll(['wallets', 'transactions']);
    _failed.clear();
    error = null;
    isRefreshing = true;
    notifyListeners();
    void watch<T>(String key, Stream<T> stream, void Function(T) update) {
      _subs.add(stream.listen((v) {
        if (generation != _generation) return;
        update(v);
        _pending.remove(key);
        _failed.remove(key);
        error = _failed.isEmpty ? null : 'Dữ liệu chưa đầy đủ';
        _recompute();
      }, onError: (Object e) {
        if (generation != _generation) return;
        _pending.remove(key);
        _failed.add(key);
        error = 'Không thể cập nhật số dư';
        isRefreshing = _pending.isNotEmpty;
        notifyListeners();
      }));
    }

    watch(
        'wallets',
        _walletRepo.watchWallets(userId, familyId: effectiveFamilyId),
        (v) => _rawWallets = v);
    watch(
        'transactions',
        _txRepo.watchTransactions(userId, familyId: effectiveFamilyId),
        (v) => _rawTxs = v);
  }

  void _recompute() {
    wallets = WalletRepository.computeWalletsWithBalances(_rawWallets, _rawTxs);
    isRefreshing = _pending.isNotEmpty;
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
      await _walletRepo.createWallet(userId, wallet, familyId: _familyId);
      _events.add('Đã thêm ví/tài khoản thành công');
    } catch (e) {
      _events.add('Lỗi thêm ví');
      rethrow;
    }
  }

  Future<void> updateWallet(String userId, String id, Wallet wallet) async {
    try {
      await _walletRepo.updateWallet(userId, id, wallet, familyId: _familyId);
      _events.add('Đã cập nhật thông tin ví');
    } catch (e) {
      _events.add('Lỗi cập nhật');
    }
  }

  Future<void> deleteWallet(String userId, String id) async {
    try {
      await _walletRepo.deleteWallet(userId, id, familyId: _familyId);
      _events.add('Đã xóa ví tài khoản');
    } catch (e) {
      _events.add('Lỗi xóa ví');
    }
  }

  @override
  void dispose() {
    _generation++;
    _cancel();
    _events.close();
    super.dispose();
  }
}
