import 'dart:async';
import 'package:flutter/foundation.dart' hide Category;
import '../core/utils/date_filter.dart';
import '../data/models/wallet.dart';
import '../data/models/category.dart';
import '../data/models/transaction.dart';
import '../data/services/wallet_repository.dart';
import '../data/services/transaction_repository.dart';
import '../data/services/finance_repository.dart';

class TransactionProvider extends ChangeNotifier {
  final _txRepo = TransactionRepository();
  final _walletRepo = WalletRepository();
  final _categoryRepo = CategoryRepository();

  String searchQuery = '';
  String? selectedType;
  String? selectedWalletId;
  DateFilterOption selectedDateFilter = DateFilterOption.thisMonth;
  bool isRefreshing = false;

  List<Wallet> wallets = [];
  List<Category> categories = [];
  List<TransactionModel> _all = [];
  List<TransactionModel> get transactions => _all;
  List<Wallet> _rawWallets = [];

  String? _userId;
  final List<StreamSubscription> _subs = [];
  final _events = StreamController<String>.broadcast();
  Stream<String> get events => _events.stream;

  List<TransactionModel> get filteredTransactions {
    final q = searchQuery.trim().toLowerCase();
    final list = _all.where((t) {
      final matchesQuery = q.isEmpty ||
          (t.note ?? '').toLowerCase().contains(q) ||
          (t.categoryName ?? '').toLowerCase().contains(q) ||
          t.amount.toString().contains(q);
      final normType = WalletRepository.normalizeTransactionType(t.type);
      final matchesType = selectedType == null || normType == selectedType;
      final matchesWallet = selectedWalletId == null ||
          selectedWalletId == t.walletId ||
          selectedWalletId == t.fromWalletId ||
          selectedWalletId == t.toWalletId ||
          selectedWalletId == t.creditCardId;
      final matchesDate = isDateInFilterOption(t.date, selectedDateFilter);
      return matchesQuery && matchesType && matchesWallet && matchesDate;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  void load(String userId) {
    if (_userId == userId && _subs.isNotEmpty) return;
    _userId = userId;
    _cancel();
    isRefreshing = true;
    notifyListeners();
    _subs.add(_txRepo.watchTransactions(userId).listen((v) {
      _all = v;
      isRefreshing = false;
      _recomputeWallets();
      notifyListeners();
    }, onError: (e) => _events.add('Lỗi tải dữ liệu')));
    
    _subs.add(_walletRepo.watchWallets(userId).listen((raw) {
      _rawWallets = raw;
      _recomputeWallets();
      notifyListeners();
    }));
    _subs.add(_categoryRepo.watchCategories(userId).listen((v) {
      categories = v;
      notifyListeners();
    }));
  }

  void _recomputeWallets() {
    wallets = WalletRepository.computeWalletsWithBalances(_rawWallets, _all);
  }

  void setSearchQuery(String v) { searchQuery = v; notifyListeners(); }
  void setSelectedType(String? v) { selectedType = v; notifyListeners(); }
  void setSelectedWalletId(String? v) { selectedWalletId = v; notifyListeners(); }
  void setSelectedDateFilter(DateFilterOption v) { selectedDateFilter = v; notifyListeners(); }

  Future<void> createTransaction(String userId, TransactionModel tx) async {
    try {
      await _txRepo.createTransaction(userId, tx);
      _events.add('Đã thêm giao dịch thành công');
    } catch (e) {
      debugPrint('CREATE TRANSACTION ERROR: ${e.runtimeType}');
      rethrow;
    }
  }

  Future<void> updateTransaction(String userId, String id, TransactionModel tx) async {
    try {
      await _txRepo.updateTransaction(userId, id, tx);
      _events.add('Đã cập nhật giao dịch');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTransaction(String userId, TransactionModel tx) async {
    try {
      await _txRepo.deleteTransactionAndReverse(userId, tx);
      _events.add('Đã xóa giao dịch thành công');
    } catch (e) {
      _events.add('Lỗi xóa: $e');
    }
  }

  void _cancel() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }

  @override
  void dispose() {
    _cancel();
    _events.close();
    super.dispose();
  }
}
