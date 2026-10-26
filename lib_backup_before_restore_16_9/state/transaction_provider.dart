import 'dart:async';
import 'package:flutter/foundation.dart' hide Category;
import 'package:shared_preferences/shared_preferences.dart';
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
  DateTime? customStartDate;
  DateTime? customEndDate;
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
  String? _familyId;
  final List<StreamSubscription> _subs = [];
  final _events = StreamController<String>.broadcast();
  String? _restoredForUser;
  Stream<String> get events => _events.stream;

  String get activeDateFilterLabel {
    if (selectedDateFilter == DateFilterOption.customDate &&
        customDate != null) {
      final d = customDate!;
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      return '$dd/$mm/${d.year}';
    }
    if (selectedDateFilter == DateFilterOption.customRange &&
        (customStartDate != null || customEndDate != null)) {
      final s = customStartDate != null
          ? '${customStartDate!.day.toString().padLeft(2, '0')}/${customStartDate!.month.toString().padLeft(2, '0')}'
          : '...';
      final e = customEndDate != null
          ? '${customEndDate!.day.toString().padLeft(2, '0')}/${customEndDate!.month.toString().padLeft(2, '0')}/${customEndDate!.year}'
          : '...';
      return '$s - $e';
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
      final matchesType = selectedType == null ||
          normType == selectedType ||
          (selectedType == 'credit_card_payment' &&
              (normType == 'credit_card_payment' ||
                  normType == 'debt_repayment'));
      final matchesWallet = selectedWalletId == null ||
          selectedWalletId == t.walletId ||
          selectedWalletId == t.fromWalletId ||
          selectedWalletId == t.toWalletId ||
          selectedWalletId == t.creditCardId;
      final matchesDate = isDateInFilterOption(
        t.date,
        selectedDateFilter,
        customDate: customDate,
        customStartDate: customStartDate,
        customEndDate: customEndDate,
        customYear: customYear,
        customMonth: customMonth,
      );
      final isWife = t.creatorTag == 'Vợ' ||
          t.creatorTag?.toLowerCase() == 'wife' ||
          t.ownerName?.toLowerCase() == 'vợ' ||
          t.ownerName?.toLowerCase() == 'wife' ||
          t.owner?.toLowerCase() == 'wife' ||
          t.fromOwner?.toLowerCase() == 'wife' ||
          t.paidByOwner?.toLowerCase() == 'wife' ||
          t.tags.any((tag) =>
              tag.toLowerCase() == 'vợ' || tag.toLowerCase() == 'wife');
      final isHusband = !isWife;

      final matchesMember = selectedMemberTag == null ||
          selectedMemberTag == 'all' ||
          (selectedMemberTag == 'wife' && isWife) ||
          (selectedMemberTag == 'husband' && isHusband);
      return matchesQuery &&
          matchesType &&
          matchesWallet &&
          matchesDate &&
          matchesMember;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  void load(String userId, {String? familyId, bool force = false}) {
    if (!force &&
        _userId == userId &&
        _familyId == familyId &&
        _subs.isNotEmpty) return;
    if (_userId != userId || _familyId != familyId) {
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
    _familyId = familyId;
    _restoreFilters(userId);
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

    watch('transactions', _txRepo.watchTransactions(userId, familyId: familyId),
        (v) => _all = v);
    watch('wallets', _walletRepo.watchWallets(userId, familyId: familyId),
        (v) => _rawWallets = v);
    watch(
        'categories',
        _categoryRepo.watchCategories(userId, familyId: familyId),
        (v) => categories = v);
  }

  void _recomputeWallets() {
    wallets = WalletRepository.computeWalletsWithBalances(_rawWallets, _all);
  }

  void setSelectedType(String? type) {
    selectedType = type;
    _saveFilters();
    notifyListeners();
  }

  void setSelectedWalletId(String? walletId) {
    selectedWalletId = walletId;
    _saveFilters();
    notifyListeners();
  }

  void setSelectedDateFilter(DateFilterOption option) {
    selectedDateFilter = option;
    if (option != DateFilterOption.customDate) customDate = null;
    if (option != DateFilterOption.customRange) {
      customStartDate = null;
      customEndDate = null;
    }
    if (option != DateFilterOption.customMonth) {
      customYear = null;
      customMonth = null;
    }
    _saveFilters();
    notifyListeners();
  }

  void setDateOption(DateFilterOption v) => setSelectedDateFilter(v);

  void setCustomDate(DateTime date) {
    selectedDateFilter = DateFilterOption.customDate;
    customDate = date;
    customStartDate = null;
    customEndDate = null;
    customYear = null;
    customMonth = null;
    _saveFilters();
    notifyListeners();
  }

  void setCustomRange(DateTime start, DateTime end) {
    selectedDateFilter = DateFilterOption.customRange;
    customStartDate = start;
    customEndDate = end;
    customDate = null;
    customYear = null;
    customMonth = null;
    _saveFilters();
    notifyListeners();
  }

  void setCustomMonth(int year, int month) {
    selectedDateFilter = DateFilterOption.customMonth;
    customYear = year;
    customMonth = month;
    customDate = null;
    customStartDate = null;
    customEndDate = null;
    _saveFilters();
    notifyListeners();
  }

  void prevMonth() {
    final now = DateTime.now();
    int currentY = customYear ?? now.year;
    int currentM = customMonth ??
        (selectedDateFilter == DateFilterOption.thisMonth
            ? now.month
            : now.month);
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
    int currentM = customMonth ??
        (selectedDateFilter == DateFilterOption.thisMonth
            ? now.month
            : now.month);
    currentM += 1;
    if (currentM > 12) {
      currentM = 1;
      currentY += 1;
    }
    setCustomMonth(currentY, currentM);
  }

  void setSelectedMemberTag(String? tag) {
    selectedMemberTag = tag == 'all' ? null : tag;
    _saveFilters();
    notifyListeners();
  }

  void setSearchQuery(String q) {
    searchQuery = q;
    _saveFilters();
    notifyListeners();
  }

  Future<void> _restoreFilters(String userId) async {
    if (_restoredForUser == userId) return;
    _restoredForUser = userId;
    final prefs = await SharedPreferences.getInstance();
    if (_userId != userId) return;
    final prefix = 'transaction_filters_$userId';
    searchQuery = prefs.getString('${prefix}_search') ?? searchQuery;
    selectedType = prefs.getString('${prefix}_type');
    selectedWalletId = prefs.getString('${prefix}_wallet');
    selectedMemberTag = prefs.getString('${prefix}_member');
    final dateName = prefs.getString('${prefix}_date');
    if (dateName != null) {
      selectedDateFilter = DateFilterOption.values.firstWhere(
        (option) => option.name == dateName,
        orElse: () => DateFilterOption.thisMonth,
      );
    }
    final customMillis = prefs.getInt('${prefix}_custom_date');
    customDate = customMillis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(customMillis);
    final customStartMillis = prefs.getInt('${prefix}_custom_start_date');
    customStartDate = customStartMillis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(customStartMillis);
    final customEndMillis = prefs.getInt('${prefix}_custom_end_date');
    customEndDate = customEndMillis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(customEndMillis);
    customYear = prefs.getInt('${prefix}_custom_year');
    customMonth = prefs.getInt('${prefix}_custom_month');
    notifyListeners();
  }

  Future<void> _saveFilters() async {
    final userId = _userId;
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'transaction_filters_$userId';
    await prefs.setString('${prefix}_search', searchQuery);
    selectedType == null
        ? await prefs.remove('${prefix}_type')
        : await prefs.setString('${prefix}_type', selectedType!);
    selectedWalletId == null
        ? await prefs.remove('${prefix}_wallet')
        : await prefs.setString('${prefix}_wallet', selectedWalletId!);
    selectedMemberTag == null
        ? await prefs.remove('${prefix}_member')
        : await prefs.setString('${prefix}_member', selectedMemberTag!);
    await prefs.setString('${prefix}_date', selectedDateFilter.name);
    customDate == null
        ? await prefs.remove('${prefix}_custom_date')
        : await prefs.setInt(
            '${prefix}_custom_date', customDate!.millisecondsSinceEpoch);
    customStartDate == null
        ? await prefs.remove('${prefix}_custom_start_date')
        : await prefs.setInt('${prefix}_custom_start_date',
            customStartDate!.millisecondsSinceEpoch);
    customEndDate == null
        ? await prefs.remove('${prefix}_custom_end_date')
        : await prefs.setInt(
            '${prefix}_custom_end_date', customEndDate!.millisecondsSinceEpoch);
    customYear == null
        ? await prefs.remove('${prefix}_custom_year')
        : await prefs.setInt('${prefix}_custom_year', customYear!);
    customMonth == null
        ? await prefs.remove('${prefix}_custom_month')
        : await prefs.setInt('${prefix}_custom_month', customMonth!);
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
    if (memberTag != null)
      selectedMemberTag = memberTag == 'all' ? null : memberTag;
    _saveFilters();
    notifyListeners();
  }

  Future<void> createTransaction(String userId, TransactionModel tx) async {
    try {
      await _txRepo.createTransaction(userId, tx, familyId: _familyId);
      _events.add('Đã thêm giao dịch thành công');
    } catch (e, st) {
      _events.add('Không thể lưu giao dịch. Vui lòng thử lại.');
      rethrow;
    }
  }

  Future<void> updateTransaction(
      String userId, String id, TransactionModel tx) async {
    try {
      await _txRepo.updateTransaction(userId, id, tx, familyId: _familyId);
      _events.add('Đã cập nhật giao dịch');
    } catch (e) {
      _events.add('Không thể cập nhật giao dịch');
      rethrow;
    }
  }

  Future<bool> delete(String userId, String id) async {
    final tx = _all
        .cast<TransactionModel?>()
        .firstWhere((t) => t?.id == id, orElse: () => null);
    if (tx != null) {
      return deleteTransaction(userId, tx);
    }
    return false;
  }

  Future<bool> deleteTransaction(String userId, TransactionModel tx) async {
    try {
      await _txRepo.deleteTransactionAndReverse(userId, tx,
          familyId: _familyId);
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
