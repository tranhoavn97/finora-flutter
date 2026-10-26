import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/utils/date_filter.dart';
import '../data/models/wallet.dart';
import '../data/models/transaction.dart';
import '../data/models/finance_models.dart';
import '../data/services/wallet_repository.dart';
import '../data/services/transaction_repository.dart';
import '../data/services/finance_repository.dart';
import 'budget_provider.dart' show BudgetSpentData;

class AiFinancialMetrics {
  final int healthScore;
  final String healthTier;
  final double runwayMonths;
  final int savingsRate;
  final int debtToIncomeRatio;
  final int dailyBurnRate;
  final int projectedMonthEndBalance;
  final int needsAmount;
  final int wantsAmount;
  final int savingsAmount;
  final int needsPercent;
  final int wantsPercent;
  final int savingsPercent;

  const AiFinancialMetrics({
    this.healthScore = 50,
    this.healthTier = 'Ổn định',
    this.runwayMonths = 0.0,
    this.savingsRate = 0,
    this.debtToIncomeRatio = 0,
    this.dailyBurnRate = 0,
    this.projectedMonthEndBalance = 0,
    this.needsAmount = 0,
    this.wantsAmount = 0,
    this.savingsAmount = 0,
    this.needsPercent = 50,
    this.wantsPercent = 30,
    this.savingsPercent = 20,
  });
}

class DashboardData {
  final List<Wallet> wallets;
  final List<TransactionModel> recentTransactions;
  final List<TransactionModel> allTransactions;
  final List<BudgetSpentData> budgetsWithSpent;
  final List<Loan> activeLoans;
  final AiFinancialMetrics aiMetrics;
  final int totalWalletBalance;
  final int totalCreditCardDebt;
  final int currentMonthIncome;
  final int currentMonthExpenses;
  final int previousMonthExpenses;
  final int totalAssetsValue;
  final int totalBorrowed;
  final int totalLent;
  final int totalAssets;
  final int totalDebts;
  final int netWorth;
  final int netCashflow;
  final int goalsCount;

  const DashboardData({
    this.wallets = const [],
    this.recentTransactions = const [],
    this.allTransactions = const [],
    this.budgetsWithSpent = const [],
    this.activeLoans = const [],
    this.aiMetrics = const AiFinancialMetrics(),
    this.totalWalletBalance = 0,
    this.totalCreditCardDebt = 0,
    this.currentMonthIncome = 0,
    this.currentMonthExpenses = 0,
    this.previousMonthExpenses = 0,
    this.totalAssetsValue = 0,
    this.totalBorrowed = 0,
    this.totalLent = 0,
    this.totalAssets = 0,
    this.totalDebts = 0,
    this.netWorth = 0,
    this.netCashflow = 0,
    this.goalsCount = 0,
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

  String? _userId;
  final List<StreamSubscription> _subs = [];
  List<Wallet> _wallets = [];
  List<TransactionModel> _txs = [];
  List<Budget> _budgets = [];
  List<Asset> _assets = [];
  List<Loan> _loans = [];
  List<Goal> _goals = [];

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

  void _recompute() {
    final uid = _userId;
    if (uid != null) {
      _budgetRepo.ensureBudgets(uid, _budgets, _txs);
    }
    final computed = WalletRepository.computeWalletsWithBalances(_wallets, _txs);
    
    // 100% parity with Web moneyLogic.ts:
    // walletTotal: sum of balances of non-credit cards
    // creditCardDebt: sum of currentDebt of credit cards
    var walletTotal = 0;
    var creditCardDebt = 0;
    for (final w in computed) {
      if (w.isCreditCard) {
        creditCardDebt += w.currentDebt;
      } else {
        walletTotal += w.balance;
      }
    }

    // Assets market value
    var assetsVal = 0;
    for (final a in _assets) {
      if (a.status == 'active') assetsVal += a.marketValue;
    }

    // Loans: lent (receivables) and borrowed (liabilities)
    var borrowed = 0;
    var lent = 0;
    for (final l in _loans) {
      if (l.status == 'active' && l.type == 'borrowed') borrowed += l.remainingPrincipal;
      if (l.status == 'active' && l.type == 'lent') lent += l.remainingPrincipal;
    }

    // Unlinked transactions parity (Web moneyLogic.ts lines 53-72)
    var unlinkedSavings = 0;
    var unlinkedReceivables = 0;
    var unlinkedLiabilities = 0;

    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    final prevMonthDate = DateTime(currentYear, currentMonth - 1, 1);
    final prevYear = prevMonthDate.year;
    final prevMonth = prevMonthDate.month;

    var curIncome = 0;
    var curExpense = 0;
    var prevExpense = 0;

    for (final t in _txs) {
      final d = DateTime.fromMillisecondsSinceEpoch(t.date);
      final isCurrent = d.year == currentYear && d.month == currentMonth;
      final isPrev = d.year == prevYear && d.month == prevMonth;

      final normType = WalletRepository.normalizeTransactionType(t.type);
      if (normType == 'income') {
        if (isCurrent) curIncome += t.amount;
      } else if (normType == 'expense') {
        if (isCurrent) curExpense += t.amount;
        if (isPrev) prevExpense += t.amount;
      }

      // Unlinked handling
      if (t.loanId == null || t.loanId!.isEmpty) {
        if (t.type == 'saving') {
          unlinkedSavings += t.amount;
        } else if (t.type == 'lending') {
          unlinkedReceivables += t.amount;
        } else if (t.type == 'loan_repayment_received') {
          unlinkedReceivables -= t.amount;
        } else if (t.type == 'borrowing' || t.type == 'debt') {
          unlinkedLiabilities += t.amount;
        } else if (t.type == 'debt_repayment') {
          unlinkedLiabilities -= t.amount;
        }
      }
    }

    if (unlinkedReceivables < 0) unlinkedReceivables = 0;
    if (unlinkedLiabilities < 0) unlinkedLiabilities = 0;

    final finalReceivables = lent + unlinkedReceivables;
    final finalLiabilities = borrowed + unlinkedLiabilities;
    final totalAssets = walletTotal + assetsVal + finalReceivables + unlinkedSavings;
    final totalDebts = finalLiabilities + creditCardDebt;
    final netWorth = totalAssets - totalDebts;
    final netCashflow = curIncome - curExpense;

    final recent = [..._txs]..sort((a, b) => b.date.compareTo(a.date));

    // Budgets with spent for current month
    final monthKey = currentMonthKey();
    final activeBudgets = _budgets.where((b) => b.monthKey == monthKey && !b.isArchived).toList();
    final budgetsWithSpent = activeBudgets.map((b) {
      var spent = 0;
      for (final t in _txs) {
        final type = WalletRepository.normalizeTransactionType(t.type);
        if ((type == 'expense' || t.categoryGroup == 'expense') &&
            t.categoryId == b.categoryId &&
            monthKeyOf(t.date) == monthKey) {
          spent += t.amount;
        }
      }
      final progress = b.limitAmount > 0 ? (spent / b.limitAmount) : 0.0;
      return BudgetSpentData(b, spent, progress);
    }).toList();

    // Active loans
    final activeLoans = _loans.where((l) => l.status == 'active').toList();

    // AI Financial Metrics (100% parity with Web aiCopilotService.ts computeLocalFinancialMetrics)
    var liquidCash = 0;
    for (final w in computed) {
      if (!w.isCreditCard && w.balance > 0) {
        liquidCash += w.balance;
      }
    }

    final daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;
    final currentDay = now.day.clamp(1, 31);
    final projectedMonthExpense = (curExpense / currentDay) * daysInMonth;
    final estimatedMonthlyExpense = [projectedMonthExpense, curExpense.toDouble(), 3000000.0]
        .reduce((a, b) => a > b ? a : b);
    final runwayMonths = double.parse((liquidCash / estimatedMonthlyExpense).toStringAsFixed(1));

    final savingsRate = curIncome > 0
        ? (((curIncome - curExpense) / curIncome) * 100).round().clamp(0, 100)
        : 0;
    final debtToIncomeRatio = curIncome > 0
        ? ((totalDebts / (curIncome * 12)) * 100).round()
        : 0;

    // 50/30/20 breakdown
    var needsSpend = 0;
    var wantsSpend = 0;
    var savingsSpend = 0;
    final needsRegex = RegExp(r'ăn|uống|cơm|phở|nhà|thuê|điện|nước|xăng|xe|y tế|thuốc|học', caseSensitive: false);
    final wantsRegex = RegExp(r'mua sắm|quần áo|du lịch|giải trí|cafe|trà sữa|làm đẹp', caseSensitive: false);

    for (final t in _txs) {
      final d = DateTime.fromMillisecondsSinceEpoch(t.date);
      if (d.year == currentYear && d.month == currentMonth) {
        final normType = WalletRepository.normalizeTransactionType(t.type);
        if (normType == 'expense') {
          final cat = t.categoryName ?? '';
          if (needsRegex.hasMatch(cat)) {
            needsSpend += t.amount;
          } else if (wantsRegex.hasMatch(cat)) {
            wantsSpend += t.amount;
          } else {
            needsSpend += t.amount;
          }
        } else if (t.type == 'transfer' || t.categoryGroup == 'investment') {
          savingsSpend += t.amount;
        }
      }
    }

    final totalTracked = [needsSpend + wantsSpend + savingsSpend, curExpense, 1]
        .reduce((a, b) => a > b ? a : b);
    final needsPercent = ((needsSpend / totalTracked) * 100).round();
    final wantsPercent = ((wantsSpend / totalTracked) * 100).round();
    final savingsPercent = ((savingsSpend / totalTracked) * 100).round();

    // Calculate Health Score (0 - 100)
    var score = 50; // baseline
    if (runwayMonths >= 6) {
      score += 20;
    } else if (runwayMonths >= 3) {
      score += 15;
    } else if (runwayMonths >= 1) {
      score += 5;
    } else {
      score -= 15;
    }

    if (savingsRate >= 25) {
      score += 15;
    } else if (savingsRate >= 15) {
      score += 10;
    } else if (savingsRate >= 5) {
      score += 5;
    } else if (curIncome > 0 && curExpense > curIncome) {
      score -= 15;
    }

    if (totalDebts == 0) {
      score += 15;
    } else if (debtToIncomeRatio < 30) {
      score += 10;
    } else if (debtToIncomeRatio < 50) {
      score += 0;
    } else {
      score -= 15;
    }

    score = score.clamp(10, 100);

    String healthTier = 'Ổn định';
    if (score >= 85) {
      healthTier = 'Xuất sắc';
    } else if (score >= 70) {
      healthTier = 'Khỏe mạnh';
    } else if (score >= 50) {
      healthTier = 'Ổn định';
    } else if (score >= 35) {
      healthTier = 'Cần chú ý';
    } else {
      healthTier = 'Báo động';
    }

    final aiMetrics = AiFinancialMetrics(
      healthScore: score,
      healthTier: healthTier,
      runwayMonths: runwayMonths,
      savingsRate: savingsRate,
      debtToIncomeRatio: debtToIncomeRatio,
      dailyBurnRate: (curExpense / currentDay).round(),
      projectedMonthEndBalance: [0, liquidCash + (curIncome - curExpense)].reduce((a, b) => a > b ? a : b),
      needsAmount: needsSpend,
      wantsAmount: wantsSpend,
      savingsAmount: savingsSpend,
      needsPercent: needsPercent,
      wantsPercent: wantsPercent,
      savingsPercent: savingsPercent,
    );

    data = DashboardData(
      wallets: computed,
      recentTransactions: recent.take(5).toList(),
      allTransactions: _txs,
      budgetsWithSpent: budgetsWithSpent,
      activeLoans: activeLoans,
      aiMetrics: aiMetrics,
      totalWalletBalance: walletTotal,
      totalCreditCardDebt: creditCardDebt,
      currentMonthIncome: curIncome,
      currentMonthExpenses: curExpense,
      previousMonthExpenses: prevExpense,
      totalAssetsValue: assetsVal,
      totalBorrowed: finalLiabilities,
      totalLent: finalReceivables,
      totalAssets: totalAssets,
      totalDebts: totalDebts,
      netWorth: netWorth,
      netCashflow: netCashflow,
      goalsCount: _goals.where((g) => g.status == 'active').length,
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
