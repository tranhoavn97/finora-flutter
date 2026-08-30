import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../core/utils/date_filter.dart';
import '../core/widgets/subject_filter_pill.dart';
import '../data/models/wallet.dart';
import '../data/models/transaction.dart';
import '../data/models/finance_models.dart';
import '../data/services/wallet_repository.dart';
import '../data/services/transaction_repository.dart';
import '../data/services/finance_repository.dart';

class CategoryMomComparison {
  final String categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final int currentAmount;
  final int previousAmount;
  final double percentageChange;

  const CategoryMomComparison({
    required this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    required this.currentAmount,
    required this.previousAmount,
    required this.percentageChange,
  });
}

class DashboardData {
  final List<Wallet> wallets;
  final List<TransactionModel> recentTransactions;
  final List<TransactionModel> periodTransactions;
  final List<TransactionModel> allTransactions;
  
  // Date filter metrics
  final DateFilterOption selectedDateFilter;
  final DateTime? customDate;
  final String periodLabel;
  final int periodIncome;
  final int periodExpense;
  final int periodNet;

  // Month & Lifetime Net worth metrics
  final int totalWalletBalance;
  final int totalCreditCardDebt;
  final int currentMonthIncome;
  final int currentMonthExpenses;
  final int previousMonthIncome;
  final int previousMonthExpenses;
  final int totalAssetsValue;
  final int totalBorrowed;
  final int totalLent;
  final int goalsCount;
  final OwnerFilter selectedOwner;
  final int aiHealthScore;
  final String aiHealthTier;
  final double emergencyRunwayMonths;
  final double savingsRatePercent;
  final double debtRatioPercent;
  final List<CategoryMomComparison> momCategoryTrends;

  const DashboardData({
    this.wallets = const [],
    this.recentTransactions = const [],
    this.periodTransactions = const [],
    this.allTransactions = const [],
    this.selectedDateFilter = DateFilterOption.today,
    this.customDate,
    this.periodLabel = 'Hôm nay',
    this.periodIncome = 0,
    this.periodExpense = 0,
    this.periodNet = 0,
    this.totalWalletBalance = 0,
    this.totalCreditCardDebt = 0,
    this.currentMonthIncome = 0,
    this.currentMonthExpenses = 0,
    this.previousMonthIncome = 0,
    this.previousMonthExpenses = 0,
    this.totalAssetsValue = 0,
    this.totalBorrowed = 0,
    this.totalLent = 0,
    this.goalsCount = 0,
    this.selectedOwner = OwnerFilter.all,
    this.aiHealthScore = 80,
    this.aiHealthTier = 'Khỏe mạnh 🟢',
    this.emergencyRunwayMonths = 3.0,
    this.savingsRatePercent = 20.0,
    this.debtRatioPercent = 10.0,
    this.momCategoryTrends = const [],
  });
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
  OwnerFilter selectedOwner = OwnerFilter.all;
  DateFilterOption selectedDateFilter = DateFilterOption.today;
  DateTime? customDate;

  String? _userId;
  final List<StreamSubscription> _subs = [];
  List<Wallet> _wallets = [];
  List<TransactionModel> _txs = [];
  List<Budget> _budgets = [];
  List<Asset> _assets = [];
  List<Loan> _loans = [];
  List<Goal> _goals = [];

  void setOwnerFilter(OwnerFilter filter) {
    if (selectedOwner == filter) return;
    selectedOwner = filter;
    _recompute();
  }

  void setDateFilter(DateFilterOption filter, {DateTime? custom}) {
    selectedDateFilter = filter;
    customDate = custom;
    _recompute();
  }

  void load(String userId) {
    if (_userId == userId && _subs.isNotEmpty) return;
    _userId = userId;
    _cancel();
    isLoading = true;
    notifyListeners();
    _subs.add(_walletRepo.watchWallets(userId).listen((v) { _wallets = v; _recompute(); }, onError: _onErr));
    _subs.add(_txRepo.watchTransactions(userId).listen((v) { _txs = v; _recompute(); }, onError: _onErr));
    _subs.add(_budgetRepo.watchBudgets(userId).listen((v) { _budgets = v; _recompute(); }, onError: _onErr));
    _subs.add(_assetRepo.watchAssets(userId).listen((v) { _assets = v; _recompute(); }, onError: _onErr));
    _subs.add(_loanRepo.watchLoans(userId).listen((v) { _loans = v; _recompute(); }, onError: _onErr));
    _subs.add(_goalRepo.watchGoals(userId).listen((v) { _goals = v; _recompute(); }, onError: _onErr));
  }

  void _onErr(Object e) {
    error = 'Có lỗi xảy ra';
    isLoading = false;
    notifyListeners();
  }

  bool _isTxInPeriod(TransactionModel tx) {
    if (customDate != null) {
      final d = DateTime.fromMillisecondsSinceEpoch(tx.date);
      return d.year == customDate!.year && d.month == customDate!.month && d.day == customDate!.day;
    }
    return isDateInFilterOption(tx.date, selectedDateFilter);
  }

  String _computePeriodLabel() {
    final now = DateTime.now();
    if (customDate != null) {
      final cd = customDate!;
      final dd = cd.day.toString().padLeft(2, '0');
      final mm = cd.month.toString().padLeft(2, '0');
      return 'Ngày $dd/$mm/${cd.year}';
    }
    switch (selectedDateFilter) {
      case DateFilterOption.today:
        final dd = now.day.toString().padLeft(2, '0');
        final mm = now.month.toString().padLeft(2, '0');
        return 'Hôm nay ($dd/$mm)';
      case DateFilterOption.yesterday:
        final yest = now.subtract(const Duration(days: 1));
        final dd = yest.day.toString().padLeft(2, '0');
        final mm = yest.month.toString().padLeft(2, '0');
        return 'Hôm qua ($dd/$mm)';
      case DateFilterOption.thisWeek:
        return 'Tuần này';
      case DateFilterOption.lastWeek:
        return 'Tuần trước';
      case DateFilterOption.thisMonth:
        return 'Tháng ${now.month}/${now.year}';
      case DateFilterOption.lastMonth:
        final prev = DateTime(now.year, now.month - 1, 1);
        return 'Tháng ${prev.month}/${prev.year}';
      case DateFilterOption.customMonth:
        return 'Tháng tùy chọn';
      case DateFilterOption.customDate:
        return 'Ngày tùy chọn';
      case DateFilterOption.thisYear:
        return 'Năm ${now.year}';
      case DateFilterOption.allTime:
        return 'Toàn bộ thời gian';
    }
  }

  void _recompute() {
    final uid = _userId;
    if (uid != null) {
      _budgetRepo.ensureBudgets(uid, _budgets, _txs);
    }
    final allComputedWallets = WalletRepository.computeWalletsWithBalances(_wallets, _txs);
    final walletMap = {for (final w in allComputedWallets) w.id: w};

    // Filter wallets by selected owner
    final filteredWallets = allComputedWallets.where((w) => selectedOwner.matchWallet(w)).toList();

    // Filter transactions by selected owner
    final filteredTxs = _txs.where((t) => selectedOwner.matchTransaction(t, walletMap: walletMap)).toList();

    // Filter assets & loans by selected owner
    final filteredAssets = _assets.where((a) => selectedOwner.matchAsset(a, walletMap: walletMap)).toList();
    final filteredLoans = _loans.where((l) => selectedOwner.matchLoan(l, walletMap: walletMap)).toList();

    final now = DateTime.now();
    final curMonthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final prevMonthDate = DateTime(now.year, now.month - 1, 1);
    final prevMonthKey = '${prevMonthDate.year}-${prevMonthDate.month.toString().padLeft(2, '0')}';

    var balance = 0, debt = 0, curIncome = 0, curExpense = 0, prevIncome = 0, prevExpense = 0;
    var assetsVal = 0, borrowed = 0, lent = 0;
    var pIncome = 0, pExpense = 0;

    for (final w in filteredWallets) {
      if (w.isCreditCard) {
        debt += w.currentDebt;
      } else {
        balance += w.balance;
      }
    }

    final curCategoryExpenses = <String, int>{};
    final prevCategoryExpenses = <String, int>{};
    final categoryMeta = <String, (String?, String?)>{};
    final periodTxsList = <TransactionModel>[];

    for (final t in filteredTxs) {
      final tMonthKey = monthKeyOf(t.date);
      final type = WalletRepository.normalizeTransactionType(t.type);

      // Check period filter for dashboard daily/weekly summary
      if (_isTxInPeriod(t)) {
        periodTxsList.add(t);
        if (type == 'income') {
          pIncome += t.amount;
        } else if (type == 'expense') {
          pExpense += t.amount;
        }
      }

      if (tMonthKey == curMonthKey) {
        if (type == 'expense') {
          curExpense += t.amount;
          final cat = t.categoryName ?? 'Khác';
          curCategoryExpenses[cat] = (curCategoryExpenses[cat] ?? 0) + t.amount;
          categoryMeta[cat] = (t.categoryIcon, t.categoryColor);
        } else if (type == 'income') {
          curIncome += t.amount;
        }
      } else if (tMonthKey == prevMonthKey) {
        if (type == 'expense') {
          prevExpense += t.amount;
          final cat = t.categoryName ?? 'Khác';
          prevCategoryExpenses[cat] = (prevCategoryExpenses[cat] ?? 0) + t.amount;
          categoryMeta[cat] = (t.categoryIcon, t.categoryColor);
        } else if (type == 'income') {
          prevIncome += t.amount;
        }
      }
    }

    for (final a in filteredAssets) {
      if (a.status == 'active') assetsVal += a.marketValue;
    }
    for (final l in filteredLoans) {
      if (l.status == 'active' && l.type == 'borrowed') borrowed += l.remainingPrincipal;
      if (l.status == 'active' && l.type == 'lent') lent += l.remainingPrincipal;
    }

    // Build MoM category comparisons
    final allCats = {...curCategoryExpenses.keys, ...prevCategoryExpenses.keys}.toList();
    final momList = <CategoryMomComparison>[];
    for (final cat in allCats) {
      final cur = curCategoryExpenses[cat] ?? 0;
      final prev = prevCategoryExpenses[cat] ?? 0;
      final double pctChange;
      if (prev > 0) {
        pctChange = ((cur - prev) / prev) * 100.0;
      } else if (cur > 0) {
        pctChange = 100.0;
      } else {
        pctChange = 0.0;
      }
      final meta = categoryMeta[cat];
      momList.add(CategoryMomComparison(
        categoryName: cat,
        categoryIcon: meta?.$1,
        categoryColor: meta?.$2,
        currentAmount: cur,
        previousAmount: prev,
        percentageChange: pctChange,
      ));
    }
    momList.sort((a, b) => b.currentAmount.compareTo(a.currentAmount));

    // Calculate AI Health Score (0 - 100)
    final monthlyExpenseBase = max(1, curExpense > 0 ? curExpense : (prevExpense > 0 ? prevExpense : 8000000));
    final runwayMonths = (balance / monthlyExpenseBase).clamp(0.0, 24.0);
    final runwayScore = ((runwayMonths / 6.0) * 40.0).clamp(0.0, 40.0);

    final effectiveIncome = curIncome > 0 ? curIncome : (prevIncome > 0 ? prevIncome : 0);
    final savingsRate = effectiveIncome > 0 ? max(0.0, (effectiveIncome - curExpense) / effectiveIncome * 100.0) : (balance > 10000000 ? 25.0 : 10.0);
    final savingsScore = ((savingsRate / 25.0) * 35.0).clamp(0.0, 35.0);

    final totalAssets = max(1, balance + assetsVal + lent);
    final totalDebt = debt + borrowed;
    final debtRatio = ((totalDebt / totalAssets) * 100.0).clamp(0.0, 100.0);
    final double debtScore;
    if (debtRatio <= 15.0) {
      debtScore = 25.0;
    } else if (debtRatio <= 35.0) {
      debtScore = 18.0;
    } else if (debtRatio <= 60.0) {
      debtScore = 10.0;
    } else {
      debtScore = 5.0;
    }

    final totalScore = (runwayScore + savingsScore + debtScore).round().clamp(10, 100);
    final String tier;
    if (totalScore >= 85) {
      tier = 'Xuất sắc 🏆';
    } else if (totalScore >= 70) {
      tier = 'Khỏe mạnh 🟢';
    } else if (totalScore >= 50) {
      tier = 'Cần lưu ý 🟡';
    } else {
      tier = 'Báo động 🔴';
    }

    // Sort transactions
    final sortedPeriodTxs = List<TransactionModel>.from(periodTxsList)
      ..sort((a, b) => b.date.compareTo(a.date));
    final sortedRecentTxs = List<TransactionModel>.from(filteredTxs)
      ..sort((a, b) => b.date.compareTo(a.date));

    data = DashboardData(
      wallets: filteredWallets,
      recentTransactions: sortedRecentTxs.take(6).toList(),
      periodTransactions: sortedPeriodTxs,
      allTransactions: filteredTxs,
      selectedDateFilter: selectedDateFilter,
      customDate: customDate,
      periodLabel: _computePeriodLabel(),
      periodIncome: pIncome,
      periodExpense: pExpense,
      periodNet: pIncome - pExpense,
      totalWalletBalance: balance,
      totalCreditCardDebt: debt,
      currentMonthIncome: curIncome,
      currentMonthExpenses: curExpense,
      previousMonthIncome: prevIncome,
      previousMonthExpenses: prevExpense,
      totalAssetsValue: assetsVal,
      totalBorrowed: borrowed,
      totalLent: lent,
      goalsCount: _goals.length,
      selectedOwner: selectedOwner,
      aiHealthScore: totalScore,
      aiHealthTier: tier,
      emergencyRunwayMonths: runwayMonths,
      savingsRatePercent: savingsRate,
      debtRatioPercent: debtRatio,
      momCategoryTrends: momList,
    );

    isLoading = false;
    error = null;
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
    _cancel();
    super.dispose();
  }
}
