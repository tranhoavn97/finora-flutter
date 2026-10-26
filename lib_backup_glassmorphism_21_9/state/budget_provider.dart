import '../domain/finance/finance_summary.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' hide Category;
import '../core/utils/date_filter.dart';
import '../data/models/category.dart';
import '../data/models/finance_models.dart';
import '../data/models/transaction.dart';
import '../data/services/finance_repository.dart';
import '../data/services/transaction_repository.dart';

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
  String? error;
  final Set<String> _pending = {};
  final Set<String> _failed = {};
  int _generation = 0;

  String? _userId;
  String? _familyId;
  final List<StreamSubscription> _subs = [];
  List<Budget> _budgets = [];
  List<TransactionModel> _txs = [];
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
      _budgets = [];
      _txs = [];
      categories = [];
      budgetsWithSpent = [];
    }
    _userId = userId;
    _familyId = effectiveFamilyId;
    _cancel();
    final generation = ++_generation;
    _pending
      ..clear()
      ..addAll(['budgets', 'transactions', 'categories']);
    _failed.clear();
    error = null;
    isRefreshing = true;
    notifyListeners();
    void watch<T>(String key, Stream<T> stream, void Function(T) update) {
      _subs.add(stream.listen((value) {
        if (generation != _generation) return;
        update(value);
        _pending.remove(key);
        _failed.remove(key);
        error = _failed.isEmpty ? null : 'Không thể tải đầy đủ ngân sách';
        _recompute();
      }, onError: (Object e) {
        if (generation != _generation) return;
        _pending.remove(key);
        _failed.add(key);
        error = 'Không thể tải đầy đủ ngân sách';
        isRefreshing = _pending.isNotEmpty;
        notifyListeners();
      }));
    }

    watch(
        'budgets',
        _budgetRepo.watchBudgets(userId, familyId: effectiveFamilyId),
        (v) => _budgets = v);
    watch(
        'transactions',
        _txRepo.watchTransactions(userId, familyId: effectiveFamilyId),
        (v) => _txs = v);
    watch(
        'categories',
        _categoryRepo.watchCategories(userId, familyId: effectiveFamilyId),
        (v) => categories = v);
  }

  void _recompute() {
    final monthKey = currentMonthKey();
    var currentBudgets = _budgets
        .where((b) =>
            (b.monthKey == monthKey || b.monthKey.trim().isEmpty) &&
            !b.isArchived)
        .toList();
    if (currentBudgets.isEmpty) {
      // Tự động sử dụng ngân sách định kỳ đang hoạt động (đồng bộ chuẩn web)
      currentBudgets = _budgets.where((b) => !b.isArchived).toList();
    }

    // Personal and family scopes can contain the same logical budget under
    // different Firestore document IDs. Keep only the newest visible budget
    // per category, matching the web behavior without deleting user data.
    final uniqueBudgets = <String, Budget>{};
    for (final budget in currentBudgets) {
      final normalizedName = budget.categoryName.trim().toLowerCase();
      final key = normalizedName.isNotEmpty
          ? normalizedName
          : 'category:${budget.categoryId}';
      final existing = uniqueBudgets[key];
      if (existing == null ||
          budget.updatedAt > existing.updatedAt ||
          (budget.updatedAt == existing.updatedAt &&
              budget.createdAt > existing.createdAt)) {
        uniqueBudgets[key] = budget;
      }
    }
    currentBudgets = uniqueBudgets.values.toList();

    budgetsWithSpent = currentBudgets.map((b) {
      var spent = 0;
      for (final t in _txs) {
        final matchCategory = t.categoryId == b.categoryId ||
            (t.categoryName != null &&
                b.categoryName.isNotEmpty &&
                t.categoryName!.trim().toLowerCase() ==
                    b.categoryName.trim().toLowerCase());
        if (FinanceSummary.isExpense(t) &&
            matchCategory &&
            monthKeyOf(t.date) == monthKey) {
          spent += t.amount;
        }
      }
      final progress = b.limitAmount > 0 ? spent / b.limitAmount : 0.0;
      return BudgetSpentData(b, spent, progress);
    }).toList();
    isRefreshing = _pending.isNotEmpty;
    notifyListeners();
  }

  Future<void> addBudget(String userId, Budget budget) async {
    try {
      final normalizedName = budget.categoryName.trim().toLowerCase();
      final existing = _budgets.where((item) {
        final sameCategory = (budget.categoryId.isNotEmpty &&
                item.categoryId == budget.categoryId) ||
            (normalizedName.isNotEmpty &&
                item.categoryName.trim().toLowerCase() == normalizedName);
        final samePeriod = item.monthKey == budget.monthKey ||
            (item.monthKey.isEmpty && budget.monthKey.isEmpty);
        return sameCategory && samePeriod && !item.isArchived;
      }).toList();
      if (existing.isNotEmpty) {
        await _budgetRepo.updateBudget(userId, existing.first.id, budget,
            familyId: _familyId);
        _events.add('Đã cập nhật ngân sách hiện có');
      } else {
        await _budgetRepo.createBudget(userId, budget, familyId: _familyId);
        _events.add('Đã tạo ngân sách chi tiêu');
      }
    } catch (e) {
      _events.add('Lỗi tạo ngân sách');
    }
  }

  Future<void> updateBudget(String userId, String id, Budget budget) async {
    try {
      await _budgetRepo.updateBudget(userId, id, budget, familyId: _familyId);
      _events.add('Đã cập nhật ngân sách');
    } catch (e) {
      _events.add('Lỗi cập nhật');
    }
  }

  Future<void> deleteBudget(String userId, String id) async {
    try {
      await _budgetRepo.deleteBudget(userId, id, familyId: _familyId);
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
    _generation++;
    _cancel();
    _events.close();
    super.dispose();
  }
}
