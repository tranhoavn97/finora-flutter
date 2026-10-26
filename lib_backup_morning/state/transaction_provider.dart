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
  String? selectedMemberTag;
  DateFilterOption selectedDateFilter = DateFilterOption.thisMonth;
  DateTime? customDate;
  int? customYear;
  int? customMonth;
  bool isRefreshing = false;
  String? error;
  final Set<String> _pending = {};
  final Set<String> _failed = {};
  int _generation = 0;

  List<Wallet> wallets = [];
  List<Category> categories = [];
  List<TransactionModel> _all = [];
  List<TransactionModel> get transactions => _all;
  List<Wallet> _rawWallets = [];

  String? _userId;
  final List<StreamSubscription> _subs = [];
  final _events = StreamController<String>.broadcast();
  Stream<String> get events => _events.stream;

  String get activeDateFilterLabel {
    if (selectedDateFilter == DateFilterOption.customDate && customDate != null) {
      final d = customDate!;
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      return '$dd/$mm/${d.year}';
    }
    if (selectedDateFilter == DateFilterOption.customMonth &&
        customYear != null &&
        customMonth != null) {
      return 'Tháng $customMonth/$customYear';
    }
    return selectedDateFilter.label;
  }

  DateFilterOption get selectedDateOption => selectedDateFilter;

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
      final matchesDate = isDateInFilterOption(
        t.date,
        selectedDateFilter,
        customDate: customDate,
        customYear: customYear,
        customMonth: customMonth,
      );
      final matchesMember = selectedMemberTag == null ||
          selectedMemberTag == 'all' ||
          t.creatorTag == selectedMemberTag ||
          t.ownerName == selectedMemberTag ||
          t.tags.contains(selectedMemberTag);
      return matchesQuery && matchesType && matchesWallet && matchesDate && matchesMember;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  void load(String userId, {bool force = false}) {
    if (!force && _userId == userId && _subs.isNotEmpty) return;
    if (_userId != userId) {
      _all = [];
      _rawWallets = [];
      wallets = [];
      categories = [];
      searchQuery = '';
      selectedType = null;
      selectedWalletId = null;
      selectedMemberTag = null;
    }
    _userId = userId;
    _cancel();
    final generation = ++_generation;
    _pending
      ..clear()
      ..addAll(['transactions', 'wallets', 'categories']);
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
        error = _failed.isEmpty ? null : 'Không thể tải đủ dữ liệu';
        isRefreshing = _pending.isNotEmpty;
        _recomputeWallets();
        notifyListeners();
      }, onError: (Object e) {
        if (generation != _generation) return;
        _pending.remove(key);
        _failed.add(key);
        error = 'Không thể tải giao dịch, ví hoặc danh mục';
        isRefreshing = _pending.isNotEmpty;
        notifyListeners();
      }));
    }

    watch('transactions', _txRepo.watchTransactions(userId), (v) => _all = v);
    watch('wallets', _walletRepo.watchWallets(userId), (v) => _rawWallets = v);
    watch('categories', _categoryRepo.watchCategories(userId),
        (v) => categories = v);
  }

  void _recomputeWallets() {
    wallets = WalletRepository.computeWalletsWithBalances(_rawWallets, _all);
  }

  void setSelectedType(String? type) {
    selectedType = type;
    notifyListeners();
  }

  void setSelectedWalletId(String? walletId) {
    selectedWalletId = walletId;
    notifyListeners();
  }

  void setSelectedDateFilter(DateFilterOption option) {
    selectedDateFilter = option;
    if (option != DateFilterOption.customDate) customDate = null;
    if (option != DateFilterOption.customMonth) {
      customYear = null;
      customMonth = null;
    }
    notifyListeners();
  }

  void setDateOption(DateFilterOption v) => setSelectedDateFilter(v);

  void setCustomDate(DateTime date) {
    selectedDateFilter = DateFilterOption.customDate;
    customDate = date;
    customYear = null;
    customMonth = null;
    notifyListeners();
  }

  void setCustomMonth(int year, int month) {
    selectedDateFilter = DateFilterOption.customMonth;
    customYear = year;
    customMonth = month;
    customDate = null;
    notifyListeners();
  }

  void prevMonth() {
    final now = DateTime.now();
    int currentY = customYear ?? now.year;
    int currentM = customMonth ?? (selectedDateFilter == DateFilterOption.thisMonth ? now.month : now.month);
    currentM -= 1;
    if (currentM < 1) {
      currentM = 12;
      currentY -= 1;
    }
    setCustomMonth(currentY, currentM);
  }

  void nextMonth() {
    final now = DateTime.now();
    int currentY = customYear ?? now.year;
    int currentM = customMonth ?? (selectedDateFilter == DateFilterOption.thisMonth ? now.month : now.month);
    currentM += 1;
    if (currentM > 12) {
      currentM = 1;
      currentY += 1;
    }
    setCustomMonth(currentY, currentM);
  }

  void setSelectedMemberTag(String? tag) {
    selectedMemberTag = tag == 'all' ? null : tag;
    notifyListeners();
  }

  void setSearchQuery(String q) {
    searchQuery = q;
    notifyListeners();
  }

  void applyFilters({
    String? query,
    DateFilterOption? date,
    String? type,
    String? walletId,
    String? memberTag,
  }) {
    if (query != null) searchQuery = query;
    if (date != null) selectedDateFilter = date;
    if (type != null) selectedType = type == 'all' ? null : type;
    if (walletId != null) selectedWalletId = walletId;
    if (memberTag != null) selectedMemberTag = memberTag == 'all' ? null : memberTag;
    notifyListeners();
  }

  Future<void> createTransaction(String userId, TransactionModel tx) async {
    try {
      await _txRepo.createTransaction(userId, tx);
      _events.add('Đã thêm giao dịch thành công');
    } catch (e, st) {
      _events.add('Không thể lưu giao dịch. Vui lòng thử lại.');
      rethrow;
    }
  }

  Future<void> updateTransaction(
      String userId, String id, TransactionModel tx) async {
    try {
      await _txRepo.updateTransaction(userId, id, tx);
      _events.add('Đã cập nhật giao dịch');
    } catch (e) {
      _events.add('Không thể cập nhật giao dịch');
      rethrow;
    }
  }

  Future<bool> delete(String userId, String id) async {
    final tx = _all.cast<TransactionModel?>().firstWhere((t) => t?.id == id, orElse: () => null);
    if (tx != null) {
      return deleteTransaction(userId, tx);
    }
    return false;
  }

  Future<bool> deleteTransaction(String userId, TransactionModel tx) async {
    try {
      await _txRepo.deleteTransactionAndReverse(userId, tx);
      _events.add('Đã xóa giao dịch thành công');
      return true;
    } catch (e) {
      _events.add('Không thể xóa giao dịch');
      return false;
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
    _generation++;
    _cancel();
    _events.close();
    super.dispose();
  }
}
