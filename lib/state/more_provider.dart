import 'dart:async';
import 'package:flutter/foundation.dart' hide Category;
import '../data/models/wallet.dart';
import '../data/models/category.dart';
import '../data/models/finance_models.dart';
import '../data/models/transaction.dart';
import '../data/services/finance_repository.dart';
import '../data/services/wallet_repository.dart';
import '../data/services/transaction_repository.dart';

class MoreProvider extends ChangeNotifier {
  final _assetRepo = AssetRepository();
  final _loanRepo = LoanRepository();
  final _goalRepo = GoalRepository();
  final _notifRepo = NotificationRepository();
  final _settingsRepo = SettingsRepository();
  final _walletRepo = WalletRepository();
  final _txRepo = TransactionRepository();
  final _categoryRepo = CategoryRepository();

  List<Asset> assets = [];
  List<Loan> loans = [];
  List<Goal> goals = [];
  List<AppNotification> notifications = [];
  AppSettings settings = const AppSettings();
  List<Wallet> wallets = [];
  List<Category> categories = [];
  bool isRefreshing = true;
  String? error;
  final Set<String> _pending = {};
  final Set<String> _failed = {};
  int _generation = 0;
  bool settingsLoaded = false;
  String? settingsError;

  String? _userId;
  String? _familyId;
  final List<StreamSubscription> _subs = [];
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
      assets = [];
      loans = [];
      goals = [];
      notifications = [];
      wallets = [];
      categories = [];
      settings = const AppSettings();
    }
    _userId = userId;
    _familyId = effectiveFamilyId;
    _cancel();
    final generation = ++_generation;
    settingsLoaded = false;
    settingsError = null;
    _pending
      ..clear()
      ..addAll([
        'assets',
        'loans',
        'goals',
        'notifications',
        'wallets',
        'transactions',
        'categories'
      ]);
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
        error = _failed.isEmpty ? null : 'Một số nguồn dữ liệu chưa tải được';
        isRefreshing = _pending.isNotEmpty;
        notifyListeners();
      }, onError: (Object e) {
        if (generation != _generation) return;
        _pending.remove(key);
        _failed.add(key);
        error = 'Không thể tải đầy đủ dữ liệu';
        isRefreshing = _pending.isNotEmpty;
        notifyListeners();
      }));
    }

    watch('assets', _assetRepo.watchAssets(userId, familyId: effectiveFamilyId),
        (v) => assets = v);
    watch('loans', _loanRepo.watchLoans(userId, familyId: effectiveFamilyId),
        (v) => loans = v);
    watch('goals', _goalRepo.watchGoals(userId, familyId: effectiveFamilyId),
        (v) => goals = v);
    watch(
        'notifications',
        _notifRepo.watchNotifications(userId, familyId: effectiveFamilyId),
        (v) => notifications = v);
    List<Wallet> rawWallets = [];
    List<TransactionModel> rawTxs = [];
    void balances() {
      wallets = WalletRepository.computeWalletsWithBalances(rawWallets, rawTxs);
    }

    watch('wallets',
        _walletRepo.watchWallets(userId, familyId: effectiveFamilyId), (v) {
      rawWallets = v;
      balances();
    });
    watch('transactions',
        _txRepo.watchTransactions(userId, familyId: effectiveFamilyId), (v) {
      rawTxs = v;
      balances();
    });
    watch(
        'categories',
        _categoryRepo.watchCategories(userId, familyId: effectiveFamilyId),
        (v) => categories = v);
    _loadSettings(userId);
  }

  Future<void> _loadSettings(String userId) async {
    try {
      final value = await _settingsRepo.getAppSettings(userId);
      if (_userId != userId) return;
      settings = value;
      settingsLoaded = true;
      settingsError = null;
    } catch (_) {
      settingsError = 'Không thể tải cài đặt';
    }
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() op, String okMsg, String errMsg,
      {bool propagate = false}) async {
    try {
      await op();
      _events.add(okMsg);
      return true;
    } catch (e) {
      _events.add(errMsg);
      if (propagate) rethrow;
      return false;
    }
  }

  // Assets
  Future<bool> addAsset(String u, Asset a) => _run(
      () => _assetRepo.createAsset(u, a),
      'Đã thêm tài sản đầu tư',
      'Lỗi thêm tài sản');
  Future<bool> updateAsset(String u, String id, Asset a) => _run(
      () => _assetRepo.updateAsset(u, id, a),
      'Đã cập nhật tài sản',
      'Lỗi cập nhật');
  Future<bool> deleteAsset(String u, String id) =>
      _run(() => _assetRepo.deleteAsset(u, id), 'Đã xóa tài sản', 'Lỗi xóa');

  // Loans
  Future<bool> addLoan(String u, Loan l) => _run(
      () => _loanRepo.createLoan(u, l),
      'Đã tạo khoản vay/cho vay nợ',
      'Lỗi tạo nợ');
  Future<bool> updateLoan(String u, String id, Loan l) => _run(
      () => _loanRepo.updateLoan(u, id, l),
      'Đã cập nhật khoản nợ',
      'Lỗi cập nhật',
      propagate: true);
  Future<bool> deleteLoan(String u, String id) =>
      _run(() => _loanRepo.deleteLoan(u, id), 'Đã xóa khoản vay nợ', 'Lỗi xóa');

  String newRepaymentId(String userId) => _txRepo.newOperationId(userId);
  Future<void> repayLoan(String userId, String loanId, String walletId,
          int amount, String operationId) =>
      _txRepo.recordLoanRepayment(userId,
          loanId: loanId,
          walletId: walletId,
          amount: amount,
          operationId: operationId);

  // Goals
  Future<bool> addGoal(String u, Goal g) => _run(
      () => _goalRepo.createGoal(u, g),
      'Đã thêm mục tiêu tiết kiệm',
      'Lỗi thêm');
  Future<bool> updateGoal(String u, String id, Goal g) => _run(
      () => _goalRepo.updateGoal(u, id, g),
      'Đã cập nhật mục tiêu',
      'Lỗi cập nhật',
      propagate: true);
  Future<bool> deleteGoal(String u, String id) =>
      _run(() => _goalRepo.deleteGoal(u, id), 'Đã xóa mục tiêu', 'Lỗi xóa');

  // Notifications
  Future<void> markNotificationAsRead(String u, String id) =>
      _notifRepo.markAsRead(u, id);
  Future<void> deleteNotification(String u, String id) =>
      _notifRepo.deleteNotification(u, id);

  // Categories
  Future<bool> addCategory(String u, Category c) => _run(
      () => _categoryRepo.createCategory(u, c),
      'Đã thêm danh mục thành công',
      'Lỗi thêm danh mục');
  Future<bool> updateCategory(String u, String id, Category c) => _run(
      () => _categoryRepo.updateCategory(u, id, c),
      'Đã cập nhật danh mục',
      'Lỗi cập nhật danh mục');
  Future<bool> deleteCategory(String u, String id) => _run(
      () => _categoryRepo.deleteCategory(u, id),
      'Đã xóa danh mục thành công',
      'Lỗi xóa danh mục');

  // Settings
  Future<bool> updateSettings(String u, AppSettings s) async {
    try {
      await _settingsRepo.saveAppSettings(u, s);
      settings = s;
      notifyListeners();
      _events.add('Cấu hình cài đặt đã được lưu');
      return true;
    } catch (e) {
      _events.add('Lỗi lưu cài đặt');
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
