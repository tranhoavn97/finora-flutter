import 'dart:async';
import 'package:flutter/foundation.dart' hide Category;
import '../core/utils/date_filter.dart';
import '../data/models/category.dart';
import '../data/models/finance_models.dart';
import '../data/models/transaction.dart';
import '../data/services/finance_repository.dart';
import '../data/services/transaction_repository.dart';
import '../data/services/wallet_repository.dart';

class BudgetSpentData {
  final Budget budget;
  final int spentAmount;
  final double progress;
  const BudgetSpentData(this.budget, this.spentAmount, this.progress);
}

class BudgetProvider extends ChangeNotifier {
  final _budgetRepo = BudgetRepository();
  final _txRepo = TransactionRepository();
  final _categoryRepo = CategoryRepository();

  List<Category> categories = [];
  List<BudgetSpentData> budgetsWithSpent = [];
  bool isRefreshing = false;

  String? _userId;
  final List<StreamSubscription> _subs = [];
  List<Budget> _budgets = [];
  List<TransactionModel> _txs = [];
  final _events = StreamController<String>.broadcast();
  Stream<String> get events => _events.stream;

  void load(String userId) {
    if (_userId == userId && _subs.isNotEmpty) return;
    _userId = userId;
    _cancel();
    isRefreshing = true;
    notifyListeners();
    _subs.add(_budgetRepo.watchBudgets(userId).listen((v) { _budgets = v; _recompute(); }));
    _subs.add(_txRepo.watchTransactions(userId).listen((v) { _txs = v; _recompute(); }));
    _subs.add(_categoryRepo.watchCategories(userId).listen((v) { categories = v; notifyListeners(); }));
  }

  void _recompute() {
    final monthKey = currentMonthKey();
    budgetsWithSpent = _budgets
        .where((b) => b.monthKey == monthKey && !b.isArchived)
        .map((b) {
      var spent = 0;
      for (final t in _txs) {
        final type = WalletRepository.normalizeTransactionType(t.type);
        if ((type == 'expense' || t.categoryGroup == 'expense') &&
            t.categoryId == b.categoryId &&
            monthKeyOf(t.date) == monthKey) {
          spent += t.amount;
        }
      }
      final progress = b.limitAmount > 0 ? spent / b.limitAmount : 0.0;
      return BudgetSpentData(b, spent, progress);
    }).toList();
    isRefreshing = false;
    notifyListeners();
  }

  Future<void> addBudget(String userId, Budget budget) async {
    try {
      await _budgetRepo.createBudget(userId, budget);
      _events.add('Đã tạo ngân sách chi tiêu');
    } catch (e) {
      _events.add('Lỗi tạo ngân sách');
    }
  }

  Future<void> updateBudget(String userId, String id, Budget budget) async {
    try {
      await _budgetRepo.updateBudget(userId, id, budget);
      _events.add('Đã cập nhật ngân sách');
    } catch (e) {
      _events.add('Lỗi cập nhật');
    }
  }

  Future<void> deleteBudget(String userId, String id) async {
    try {
      await _budgetRepo.deleteBudget(userId, id);
      _events.add('Đã xóa ngân sách');
    } catch (e) {
      _events.add('Lỗi xóa');
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
