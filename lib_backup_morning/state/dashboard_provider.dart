import '../domain/finance/finance_summary.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/utils/date_filter.dart';
import '../data/models/wallet.dart';
import '../data/models/transaction.dart';
import '../data/models/finance_models.dart';
import '../data/services/wallet_repository.dart';
import '../data/services/transaction_repository.dart';
import '../data/services/finance_repository.dart';
import '../core/widgets/subject_filter_pill.dart';

class DashboardData {
  final List<Wallet> wallets;
  final List<TransactionModel> recentTransactions;
  final List<TransactionModel> allTransactions;
  final int totalWalletBalance;
  final int totalCreditCardDebt;
  final int currentMonthIncome;
  final int currentMonthExpenses;
  final int totalAssetsValue;
  final int totalBorrowed;
  final int totalLent;
  final int goalsCount;

  final int periodIncome;
  final int periodExpense;
  final int periodNet;
  final String periodLabel;
  final OwnerFilter selectedOwner;
  final int aiHealthScore;
  final double emergencyRunwayMonths;
  final double savingsRatePercent;
  final double debtRatioPercent;

  const DashboardData({
    this.wallets = const [],
    this.recentTransactions = const [],
    this.allTransactions = const [],
    this.totalWalletBalance = 0,
    this.totalCreditCardDebt = 0,
    this.currentMonthIncome = 0,
    this.currentMonthExpenses = 0,
    this.totalAssetsValue = 0,
    this.totalBorrowed = 0,
    this.totalLent = 0,
    this.goalsCount = 0,
    int? periodIncome,
    int? periodExpense,
    int? periodNet,
    this.periodLabel = 'Tháng này',
    this.selectedOwner = OwnerFilter.all,
    this.aiHealthScore = 0,
    this.emergencyRunwayMonths = 0,
    this.savingsRatePercent = 0,
    this.debtRatioPercent = 0,
  })  : periodIncome = periodIncome ?? currentMonthIncome,
        periodExpense = periodExpense ?? currentMonthExpenses,
        periodNet = periodNet ?? (currentMonthIncome - currentMonthExpenses);
}

class DashboardProvider extends ChangeNotifier {
  final _walletRepo = WalletRepository();
  final _txRepo = TransactionRepository();
  final _budgetRepo = BudgetRepository();
  final _assetRepo = AssetRepository();
  final _loanRepo = LoanRepository();
  final _goalRepo = GoalRepository();

  bool isLoading = true;
  String? error;
  DashboardData data = const DashboardData();

  String? _userId;
  final List<StreamSubscription> _subs = [];
  List<Wallet> _wallets = [];
  List<TransactionModel> _txs = [];
  List<Budget> _budgets = [];
  List<Asset> _assets = [];
  List<Loan> _loans = [];
  List<Goal> _goals = [];

  final Set<String> _pending = {};
  final Set<String> _failed = {};
  int _generation = 0;
  void load(String userId, {bool force = false}) {
    if (!force && _userId == userId && _subs.isNotEmpty) return;
    if (_userId != userId) {
      data = const DashboardData();
      _wallets = [];
      _txs = [];
      _budgets = [];
      _assets = [];
      _loans = [];
      _goals = [];
    }
    _userId = userId;
    _cancel();
    final generation = ++_generation;
    _pending
      ..clear()
      ..addAll(
          ['wallets', 'transactions', 'budgets', 'assets', 'loans', 'goals']);
    _failed.clear();
    error = null;
    isLoading = true;
    notifyListeners();
    void watch<T>(String key, Stream<T> stream, void Function(T) update) {
      _subs.add(stream.listen((value) {
        if (generation != _generation) return;
        update(value);
        _pending.remove(key);
        _failed.remove(key);
        error =
            _failed.isEmpty ? null : 'Không thể cập nhật một số nguồn dữ liệu';
        _recompute();
      }, onError: (Object e) {
        if (generation != _generation) return;
        _pending.remove(key);
        _failed.add(key);
        _onErr(e);
      }));
    }

    watch('wallets', _walletRepo.watchWallets(userId), (v) => _wallets = v);
    watch('transactions', _txRepo.watchTransactions(userId), (v) => _txs = v);
    watch('budgets', _budgetRepo.watchBudgets(userId), (v) => _budgets = v);
    watch('assets', _assetRepo.watchAssets(userId), (v) => _assets = v);
    watch('loans', _loanRepo.watchLoans(userId), (v) => _loans = v);
    watch('goals', _goalRepo.watchGoals(userId), (v) => _goals = v);
  }

  void _onErr(Object e) {
    error = 'Có lỗi xảy ra';
    isLoading = _pending.isNotEmpty;
    notifyListeners();
  }

  void _recompute() {
    final uid = _userId;
    if (uid != null) {
      _budgetRepo.ensureBudgets(uid, _budgets, _txs);
    }
    final computed =
        WalletRepository.computeWalletsWithBalances(_wallets, _txs);
    final monthKey = currentMonthKey();
    var balance = 0,
        debt = 0,
        income = 0,
        expense = 0,
        assetsVal = 0,
        borrowed = 0,
        lent = 0;
    for (final w in computed) {
      if (w.isCreditCard) {
        debt += w.currentDebt;
      } else {
        balance += w.balance;
      }
    }
    for (final t in _txs) {
      if (monthKeyOf(t.date) == monthKey) {
        if (FinanceSummary.isExpense(t)) expense += t.amount;
        if (FinanceSummary.isIncome(t)) income += t.amount;
      }
    }
    for (final a in _assets) {
      if (a.status == 'active') assetsVal += a.marketValue;
    }
    for (final l in _loans) {
      if (l.status == 'active' && l.type == 'borrowed')
        borrowed += l.remainingPrincipal;
      if (l.status == 'active' && l.type == 'lent')
        lent += l.remainingPrincipal;
    }
    final recent = [..._txs]..sort((a, b) => b.date.compareTo(a.date));
    final netWorth = balance + assetsVal + lent - debt - borrowed;
    final emergencyRunway = expense > 0 ? balance / expense : 0.0;
    final savingsRate = income > 0 ? ((income - expense) / income * 100) : 0.0;
    final debtRatio = netWorth > 0 ? ((debt + borrowed) / netWorth * 100) : 0.0;
    final runwayScore = (emergencyRunway / 6 * 35).clamp(0, 35).round();
    final savingsScore = (savingsRate.clamp(0, 30) / 30 * 35).round();
    final debtScore = (30 - debtRatio.clamp(0, 100) * .3).clamp(0, 30).round();

    data = DashboardData(
      wallets: computed,
      recentTransactions: recent.take(5).toList(),
      allTransactions: _txs,
      totalWalletBalance: balance,
      totalCreditCardDebt: debt,
      currentMonthIncome: income,
      currentMonthExpenses: expense,
      totalAssetsValue: assetsVal,
      totalBorrowed: borrowed,
      totalLent: lent,
      goalsCount: _goals.where((g) => g.status == 'active').length,
      aiHealthScore: runwayScore + savingsScore + debtScore,
      emergencyRunwayMonths: emergencyRunway,
      savingsRatePercent: savingsRate,
      debtRatioPercent: debtRatio,
    );
    isLoading = _pending.isNotEmpty;
    notifyListeners();
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
    super.dispose();
  }
}
