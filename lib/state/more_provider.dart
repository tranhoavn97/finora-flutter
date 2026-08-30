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
  bool isRefreshing = false;

  String? _userId;
  final List<StreamSubscription> _subs = [];
  final _events = StreamController<String>.broadcast();
  Stream<String> get events => _events.stream;

  void load(String userId) {
    if (_userId == userId && _subs.isNotEmpty) return;
    _userId = userId;
    _cancel();
    isRefreshing = true;
    notifyListeners();
    _subs.add(_assetRepo.watchAssets(userId).listen((v) { assets = v; notifyListeners(); }));
    _subs.add(_loanRepo.watchLoans(userId).listen((v) { loans = v; notifyListeners(); }));
    _subs.add(_goalRepo.watchGoals(userId).listen((v) { goals = v; notifyListeners(); }));
    _subs.add(_notifRepo.watchNotifications(userId).listen((v) { notifications = v; notifyListeners(); }));
    List<Wallet> rawWallets = [];
    List<TransactionModel> rawTxs = [];
    void recompute() {
      wallets = WalletRepository.computeWalletsWithBalances(rawWallets, rawTxs);
      notifyListeners();
    }

    _subs.add(_walletRepo.watchWallets(userId).listen((raw) {
      rawWallets = raw;
      recompute();
    }));
    _subs.add(_txRepo.watchTransactions(userId).listen((txs) {
      rawTxs = txs;
      recompute();
    }));
    _subs.add(_categoryRepo.watchCategories(userId).listen((v) { categories = v; notifyListeners(); }));
    _loadSettings(userId);
    isRefreshing = false;
  }

  Future<void> _loadSettings(String userId) async {
    settings = await _settingsRepo.getAppSettings(userId);
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() op, String okMsg, String errMsg) async {
    try {
      await op();
      _events.add(okMsg);
    } catch (e) {
      _events.add(errMsg);
    }
  }

  // Assets
  Future<void> addAsset(String u, Asset a) => _run(() => _assetRepo.createAsset(u, a), 'Đã thêm tài sản đầu tư', 'Lỗi thêm tài sản');
  Future<void> updateAsset(String u, String id, Asset a) => _run(() => _assetRepo.updateAsset(u, id, a), 'Đã cập nhật tài sản', 'Lỗi cập nhật');
  Future<void> deleteAsset(String u, String id) => _run(() => _assetRepo.deleteAsset(u, id), 'Đã xóa tài sản', 'Lỗi xóa');

  // Loans
  Future<void> addLoan(String u, Loan l) => _run(() => _loanRepo.createLoan(u, l), 'Đã tạo khoản vay/cho vay nợ', 'Lỗi tạo nợ');
  Future<void> updateLoan(String u, String id, Loan l) => _run(() => _loanRepo.updateLoan(u, id, l), 'Đã cập nhật khoản nợ', 'Lỗi cập nhật');
  Future<void> deleteLoan(String u, String id) => _run(() => _loanRepo.deleteLoan(u, id), 'Đã xóa khoản vay nợ', 'Lỗi xóa');

  // Goals
  Future<void> addGoal(String u, Goal g) => _run(() => _goalRepo.createGoal(u, g), 'Đã thêm mục tiêu tiết kiệm', 'Lỗi thêm');
  Future<void> updateGoal(String u, String id, Goal g) => _run(() => _goalRepo.updateGoal(u, id, g), 'Đã cập nhật mục tiêu', 'Lỗi cập nhật');
  Future<void> deleteGoal(String u, String id) => _run(() => _goalRepo.deleteGoal(u, id), 'Đã xóa mục tiêu', 'Lỗi xóa');
  Future<void> setGoalStatus(String u, String id, String status) => _run(
      () => _goalRepo.setGoalStatus(u, id, status),
      status == 'paused' ? 'Đã tạm dừng mục tiêu' : status == 'completed' ? 'Đã hoàn thành mục tiêu' : 'Đã tiếp tục mục tiêu',
      'Lỗi cập nhật trạng thái');
  Future<void> depositToGoal(String u, Goal goal, Wallet wallet, int amount, {String? note}) => _run(
      () => _goalRepo.depositToGoal(
          userId: u, goal: goal, walletId: wallet.id, walletName: wallet.name,
          owner: wallet.owner, ownerName: wallet.ownerName, amount: amount, note: note),
      'Đã chuyển tiền vào mục tiêu', 'Lỗi chuyển tiền');
  Future<void> deleteGoalWithTransactions(String u, String id) => _run(
      () => _goalRepo.deleteGoalWithTransactions(u, id),
      'Đã xóa mục tiêu và hoàn tiền ví', 'Lỗi xóa mục tiêu');

  // Notifications
  Future<void> markNotificationAsRead(String u, String id) => _notifRepo.markAsRead(u, id);
  Future<void> deleteNotification(String u, String id) => _notifRepo.deleteNotification(u, id);

  // Categories
  Future<void> addCategory(String u, Category c) => _run(() => _categoryRepo.createCategory(u, c), 'Đã thêm danh mục thành công', 'Lỗi thêm danh mục');
  Future<void> updateCategory(String u, String id, Category c) => _run(() => _categoryRepo.updateCategory(u, id, c), 'Đã cập nhật danh mục', 'Lỗi cập nhật danh mục');
  Future<void> deleteCategory(String u, String id) => _run(() => _categoryRepo.deleteCategory(u, id), 'Đã xóa danh mục thành công', 'Lỗi xóa danh mục');

  // Settings
  Future<void> updateSettings(String u, AppSettings s) async {
    try {
      await _settingsRepo.saveAppSettings(u, s);
      settings = s;
      notifyListeners();
      _events.add('Cấu hình cài đặt đã được lưu');
    } catch (e) {
      _events.add('Lỗi lưu cài đặt');
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
