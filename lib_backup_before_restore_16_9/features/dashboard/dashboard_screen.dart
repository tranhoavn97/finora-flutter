import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../data/models/finance_models.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../../state/budget_provider.dart';
import '../../state/dashboard_provider.dart';
import '../../state/more_provider.dart';
import '../../state/transaction_provider.dart';
import '../../state/wallet_provider.dart';
import '../budget/budget_screen.dart';
import '../goal/goal_screen.dart';
import '../loan/loan_screen.dart';

/// FINORA Dashboard — Tổng Quan Toàn Diện Chuẩn Web
/// Đầy đủ 100% dữ liệu Web: 4 KPI Cards, AI Financial Health, Biểu đồ Dòng tiền đa kỳ,
/// Ngân sách tháng, Ví & Tài khoản (Logo ngân hàng chuẩn), Mục tiêu, Sổ nợ, Giao dịch gần đây.
class DashboardScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? familyId;
  final String? userPhotoUrl;
  final VoidCallback? onViewAllTransactions;
  final VoidCallback? onViewWallets;

  const DashboardScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.familyId,
    this.userPhotoUrl,
    this.onViewAllTransactions,
    this.onViewWallets,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _ownerFilter = 'all'; // 'all', 'husband', 'wife'
  int _cashflowMonths = 6; // 3, 6, 12 tháng
  String _loanTab = 'debt'; // 'debt' (nợ), 'lend' (cho vay)
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshAllData();
    });
  }

  void _refreshAllData() {
    setState(() => _isRefreshing = true);
    context.read<DashboardProvider>().load(widget.userId, familyId: widget.familyId);
    context.read<WalletProvider>().load(widget.userId, familyId: widget.familyId);
    context.read<TransactionProvider>().load(widget.userId, familyId: widget.familyId);
    context.read<BudgetProvider>().load(widget.userId);
    context.read<MoreProvider>().load(widget.userId, familyId: widget.familyId);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _isRefreshing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dashboard = context.watch<DashboardProvider>();
    final walletProv = context.watch<WalletProvider>();
    final txProv = context.watch<TransactionProvider>();
    final budgetProv = context.watch<BudgetProvider>();
    final moreProv = context.watch<MoreProvider>();

    final d = dashboard.data;
    final allWallets = walletProv.wallets.isNotEmpty ? walletProv.wallets : d.wallets;
    final allTransactions = txProv.transactions.isNotEmpty ? txProv.transactions : d.recentTransactions;
    final allLoans = moreProv.loans;
    final allGoals = moreProv.goals;
    final allAssets = moreProv.assets;
    final budgetsWithSpent = budgetProv.budgetsWithSpent;

    // 1. Lọc theo đối tượng gia đình (Tất cả / Chồng / Vợ)
    final filteredWallets = allWallets.where((w) {
      if (_ownerFilter == 'all') return true;
      final nameLower = w.name.toLowerCase();
      if (_ownerFilter == 'husband') {
        return nameLower.contains('chồng') ||
            nameLower.contains('vcb') ||
            nameLower.contains('vietcombank') ||
            nameLower.contains('visa') ||
            nameLower.contains('techcom');
      } else {
        return nameLower.contains('vợ') ||
            nameLower.contains('momo') ||
            nameLower.contains('tiền mặt');
      }
    }).toList();

    final filteredTransactions = allTransactions.where((tx) {
      if (_ownerFilter == 'all') return true;
      final noteLower = (tx.note ?? '').toLowerCase();
      final catLower = (tx.categoryName ?? '').toLowerCase();
      if (_ownerFilter == 'husband') {
        return noteLower.contains('chồng') || catLower.contains('chồng');
      } else {
        return noteLower.contains('vợ') || catLower.contains('vợ');
      }
    }).toList();

    // 2. Tính toán tổng tài chính (Chuẩn Web moneyLogic.ts)
    final walletTotal = filteredWallets.fold<int>(0, (sum, w) => sum + w.balance);
    final totalAssets = allAssets.fold<int>(0, (sum, a) => sum + a.marketValue);
    final debtLoans = allLoans.where((l) => l.type == 'borrowed').toList();
    final lendLoans = allLoans.where((l) => l.type == 'lent').toList();
    final totalDebtAmount = debtLoans.fold<int>(0, (sum, l) => sum + l.amount);
    final totalLendAmount = lendLoans.fold<int>(0, (sum, l) => sum + l.amount);
    final netWorth = walletTotal + totalAssets - totalDebtAmount;

    final income = d.periodIncome;
    final expense = d.periodExpense;

    final totalCreditDebt = filteredWallets
        .where((w) => w.type.toLowerCase().contains('credit') || w.type.toLowerCase().contains('tín dụng'))
        .fold<int>(0, (sum, w) => sum + (w.balance < 0 ? -w.balance : 0));

    final availableCredit = filteredWallets
        .where((w) => w.type.toLowerCase().contains('credit') || w.type.toLowerCase().contains('tín dụng'))
        .fold<int>(0, (sum, w) => sum + (w.balance >= 0 ? w.balance : 0));

    // Ngân sách
    final totalBudgetSpent = budgetsWithSpent.fold<int>(0, (sum, b) => sum + b.spentAmount);
    final totalBudgetLimit = budgetsWithSpent.fold<int>(0, (sum, b) => sum + b.budget.limitAmount);
    final budgetPercent = totalBudgetLimit > 0 ? (totalBudgetSpent / totalBudgetLimit) * 100 : 0.0;
    final remainingBudget = totalBudgetLimit > totalBudgetSpent ? totalBudgetLimit - totalBudgetSpent : 0;
    final daysLeftInMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day - DateTime.now().day + 1;
    final dailyBudgetAvailable = daysLeftInMonth > 0 ? (remainingBudget / daysLeftInMonth).round() : 0;

    // Mục tiêu
    final totalGoalSaved = allGoals.fold<int>(0, (sum, g) => sum + g.savedAmount);
    final totalGoalTarget = allGoals.fold<int>(0, (sum, g) => sum + g.targetAmount);
    final goalPercent = totalGoalTarget > 0 ? (totalGoalSaved / totalGoalTarget) * 100 : 0.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: const Color(0xFF4F46E5),
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          onRefresh: () async => _refreshAllData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 115),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header chuẩn Web: Avatar tài khoản chuẩn + Tên + Bộ lọc đối tượng
                _buildHeader(isDark),
                const SizedBox(height: 16),

                // 2. ROW 1: 4 Thẻ KPI Động (Thu nhập, Chi tiêu, Tổng số dư, Giá trị ròng)
                _buildKpiGrid(
                  income: income,
                  expense: expense,
                  walletTotal: walletTotal,
                  netWorth: netWorth,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // 3. AI Financial Health & Copilot Widget (Khớp Web)
                _buildAiFinancialHealthCard(
                  income: income,
                  expense: expense,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // 4. ROW 2: Biểu Đồ Dòng Tiền Lưu Chuyển (Cashflow Flow Chart)
                _buildCashflowChart(
                  transactions: allTransactions,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // 5. ROW 3: Ngân Sách Tháng (Tiến trình, Hạn mức, Mức chi mỗi ngày)
                _buildBudgetSection(
                  budgets: budgetsWithSpent,
                  totalSpent: totalBudgetSpent,
                  totalLimit: totalBudgetLimit,
                  percent: budgetPercent,
                  remaining: remainingBudget,
                  dailyAvailable: dailyBudgetAvailable,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // 6. ROW 4: Ví & Tài Khoản (Đúng Logo Ngân Hàng Thật từ assets/banks/)
                _buildWalletsSection(
                  wallets: filteredWallets,
                  walletTotal: walletTotal,
                  creditDebt: totalCreditDebt,
                  availableCredit: availableCredit,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // 7. ROW 5: Mục Tiêu Tiết Kiệm (Tiến trình tích lũy, các ước mơ)
                _buildGoalsSection(
                  goals: allGoals,
                  totalSaved: totalGoalSaved,
                  totalTarget: totalGoalTarget,
                  percent: goalPercent,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // 8. ROW 6: Khoản Vay & Sổ Nợ (Khoản nợ vs Cho vay)
                _buildLoansSection(
                  debtLoans: debtLoans,
                  lendLoans: lendLoans,
                  totalDebt: totalDebtAmount,
                  totalLend: totalLendAmount,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // 9. ROW 7: Giao Dịch Gần Đây (Icon quả cầu kính 3D, chi tiết sắc nét)
                _buildRecentTransactionsSection(
                  transactions: filteredTransactions,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. HEADER CHUẨN WEB: AVATAR TÀI KHOẢN THẬT + TÊN + BỘ LỌC ĐỐI TƯỢNG
  // ===========================================================================
  Widget _buildHeader(bool isDark) {
    final displayName = widget.userName.isNotEmpty ? widget.userName : 'Hòa Trần';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'H';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar + Lời chào
        Expanded(
          child: Row(
            children: [
              // Avatar thật lấy từ Google/Firebase photoUrl hoặc fallback chữ cái đầu
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: widget.userPhotoUrl != null && widget.userPhotoUrl!.isNotEmpty
                      ? Image.network(
                          widget.userPhotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackInitial(initial),
                        )
                      : _buildFallbackInitial(initial),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'XIN CHÀO GIA ĐÌNH 👋',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bộ lọc đối tượng: Tất cả | Chồng | Vợ + Nút làm mới
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131A26) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isDark ? const Color(0xFF243045) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildOwnerPill('all', 'Tất cả'),
                  _buildOwnerPill('husband', '👨 Chồng'),
                  _buildOwnerPill('wife', '👩 Vợ'),
                ],
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                _refreshAllData();
              },
              borderRadius: BorderRadius.circular(100),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF131A26) : const Color(0xFFF1F5F9),
                  border: Border.all(
                    color: isDark ? const Color(0xFF243045) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Center(
                  child: _isRefreshing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
                        )
                      : Icon(
                          LucideIcons.refresh_cw,
                          size: 15,
                          color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFallbackInitial(String initial) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildOwnerPill(String key, String label) {
    final isSelected = _ownerFilter == key;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _ownerFilter = key);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. ROW 1: 4 THẺ KPI ĐỘNG CHUẨN WEB (Thu nhập, Chi tiêu, Tổng số dư, Giá trị ròng)
  // ===========================================================================
  Widget _buildKpiGrid({
    required int income,
    required int expense,
    required int walletTotal,
    required int netWorth,
    required bool isDark,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: itemWidth,
              child: _buildSingleKpiCard(
                title: 'Thu nhập',
                amount: income,
                icon: LucideIcons.arrow_down_left,
                color: const Color(0xFF10B981),
                trendText: '↑ 12.4%',
                isDark: isDark,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildSingleKpiCard(
                title: 'Chi tiêu',
                amount: expense,
                icon: LucideIcons.arrow_up_right,
                color: const Color(0xFFF43F5E),
                trendText: '↓ 2.4%',
                isDark: isDark,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildSingleKpiCard(
                title: 'Tổng số dư',
                amount: walletTotal,
                icon: LucideIcons.wallet,
                color: const Color(0xFF3B82F6),
                trendText: '↑ 5.2%',
                isDark: isDark,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildSingleKpiCard(
                title: 'Giá trị ròng',
                amount: netWorth,
                icon: LucideIcons.activity,
                color: const Color(0xFF8B5CF6),
                trendText: '↑ 8.1%',
                isDark: isDark,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSingleKpiCard({
    required String title,
    required int amount,
    required IconData icon,
    required Color color,
    required String trendText,
    required bool isDark,
  }) {
    return FinoraClayCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  trendText,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatVND(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. AI FINANCIAL HEALTH WIDGET (Khớp Web AiFinancialHealthWidget)
  // ===========================================================================
  Widget _buildAiFinancialHealthCard({
    required int income,
    required int expense,
    required bool isDark,
  }) {
    final healthScore = income > 0 ? (100 - ((expense / income) * 60)).clamp(40, 96).round() : 75;
    final statusText = healthScore >= 80 ? 'Rất tốt' : (healthScore >= 60 ? 'Cân bằng' : 'Cần tối ưu');

    return FinoraClayCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.sparkles, color: Color(0xFF4F46E5), size: 17),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ĐIỂM SỨC KHỎE TÀI CHÍNH',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        'Finora AI Copilot',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Text(
                  '$healthScore/100 · $statusText',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: healthScore / 100,
              minHeight: 6,
              backgroundColor: isDark ? const Color(0xFF243045) : const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            income > 0 && expense > income * 0.8
                ? '💡 Mức chi tiêu tháng này chiếm trên 80% thu nhập. Hãy cân nhắc cắt giảm các khoản ngoài thiết yếu để tăng quỹ dự phòng.'
                : '✨ Dòng tiền gia đình đang duy trì tỷ lệ tích lũy xuất sắc! Bạn có thể tăng thêm 10% vào danh mục đầu tư tích lũy.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. ROW 2: BIỂU ĐỒ DÒNG TIỀN LƯU CHUYỂN (Cashflow Flow Chart 3/6/12 tháng)
  // ===========================================================================
  Widget _buildCashflowChart({
    required List<TransactionModel> transactions,
    required bool isDark,
  }) {
    // Nhóm giao dịch theo tháng
    final now = DateTime.now();
    final monthsData = List.generate(_cashflowMonths, (index) {
      final targetDate = DateTime(now.year, now.month - (_cashflowMonths - 1 - index), 1);
      final monthKey = DateFormat('MM/yy').format(targetDate);

      int inc = 0;
      int exp = 0;

      for (final tx in transactions) {
        final txDate = DateTime.fromMillisecondsSinceEpoch(tx.createdAt);
        if (txDate.year == targetDate.year && txDate.month == targetDate.month) {
          if (tx.type == 'income') inc += tx.amount;
          if (tx.type == 'expense') exp += tx.amount;
        }
      }

      return {'name': monthKey, 'thu': inc, 'chi': exp, 'rong': inc - exp};
    });

    final maxVal = monthsData.fold<int>(1, (max, m) {
      final t = m['thu'] as int;
      final c = m['chi'] as int;
      final highest = t > c ? t : c;
      return highest > max ? highest : max;
    });

    return FinoraClayCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DÒNG TIỀN LƯU CHUYỂN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Thu nhập, chi tiêu & dòng ròng',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131A26) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  children: [3, 6, 12].map((m) {
                    final selected = _cashflowMonths == m;
                    return GestureDetector(
                      onTap: () => setState(() => _cashflowMonths = m),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFF4F46E5) : Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '$m T',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: selected ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Vùng hiển thị cột trực quan
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: monthsData.map((data) {
                final thu = data['thu'] as int;
                final chi = data['chi'] as int;
                final thuRatio = (thu / maxVal).clamp(0.05, 1.0);
                final chiRatio = (chi / maxVal).clamp(0.05, 1.0);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 8,
                          height: 90 * thuRatio,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Container(
                          width: 8,
                          height: 90 * chiRatio,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF43F5E),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data['name'] as String,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Chú thích Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(const Color(0xFF10B981), 'Thu nhập'),
              const SizedBox(width: 16),
              _buildLegendDot(const Color(0xFFF43F5E), 'Chi tiêu'),
              const SizedBox(width: 16),
              _buildLegendDot(const Color(0xFF4F46E5), 'Dòng ròng'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
      ],
    );
  }

  // ===========================================================================
  // 5. ROW 3: NGÂN SÁCH THÁNG (Tiến độ chi tiêu, Hạn mức, Cảnh báo & Danh mục)
  // ===========================================================================
  Widget _buildBudgetSection({
    required List<dynamic> budgets,
    required int totalSpent,
    required int totalLimit,
    required double percent,
    required int remaining,
    required int dailyAvailable,
    required bool isDark,
  }) {
    final isExceeded = percent > 100;

    return FinoraClayCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Ngân Sách Tháng',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: (isExceeded ? const Color(0xFFF43F5E) : const Color(0xFF10B981)).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      isExceeded ? 'VƯỢT HẠN MỨC' : 'AN TOÀN',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: isExceeded ? const Color(0xFFF43F5E) : const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => BudgetScreen(userId: widget.userId)));
                },
                child: const Text(
                  'Chi tiết >',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Khung thống kê tiến trình tổng
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131A26) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF243045) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ĐÃ CHI TIÊU', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8))),
                        const SizedBox(height: 2),
                        Text(
                          formatVND(totalSpent),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('HẠN MỨC', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8))),
                        const SizedBox(height: 2),
                        Text(
                          '/ ${formatVND(totalLimit)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: (percent / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: isDark ? const Color(0xFF243045) : const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation(
                      isExceeded ? const Color(0xFFF43F5E) : (percent >= 80 ? const Color(0xFFF59E0B) : const Color(0xFF4F46E5)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CÒN LẠI: ${formatVND(remaining)}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5)),
                    ),
                    Text(
                      'MỖI NGÀY CÒN: ${formatVND(dailyAvailable)}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. ROW 4: VÍ & TÀI KHOẢN (Với ĐÚNG LOGO NGÂN HÀNG THẬT TỪ assets/banks/)
  // ===========================================================================
  Widget _buildWalletsSection({
    required List<Wallet> wallets,
    required int walletTotal,
    required int creditDebt,
    required int availableCredit,
    required bool isDark,
  }) {
    return FinoraClayCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Ví & Tài Khoản',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${wallets.length} nguồn tiền',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onViewWallets?.call();
                },
                child: const Text(
                  'Xem tất cả >',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Thẻ tổng số dư tiền thật
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131A26) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF243045) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TỔNG TIỀN KHẢ DỤNG', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 2),
                    Text(
                      formatVND(walletTotal),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                if (creditDebt > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('DƯ NỢ THẺ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFF43F5E))),
                      const SizedBox(height: 2),
                      Text(
                        formatVND(creditDebt),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFF43F5E)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Danh sách từng ví với Logo ngân hàng chuẩn xác
          Column(
            children: wallets.take(4).map((w) {
              final isCredit = w.type.toLowerCase().contains('credit') || w.type.toLowerCase().contains('tín dụng');
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131A26).withValues(alpha: 0.5) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF243045) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      // LOGO NGÂN HÀNG THỰC TẾ
                      FinoraBankLogo(wallet: w, size: 38, radius: 10),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              w.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isCredit ? 'Thẻ tín dụng' : 'Tài khoản ngân hàng',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatVND(w.balance),
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: isCredit
                              ? const Color(0xFFF43F5E)
                              : (isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 7. ROW 5: MỤC TIÊU TIẾT KIỆM (Tiến trình tích lũy, các ước mơ tài chính)
  // ===========================================================================
  Widget _buildGoalsSection({
    required List<Goal> goals,
    required int totalSaved,
    required int totalTarget,
    required double percent,
    required bool isDark,
  }) {
    return FinoraClayCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Mục Tiêu Tiết Kiệm',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '${goals.length} mục tiêu',
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF8B5CF6)),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => GoalScreen(userId: widget.userId)));
                },
                child: const Text(
                  'Xem tất cả >',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Khung tiến độ
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131A26) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF243045) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ĐÃ TÍCH LŨY: ${formatVND(totalSaved)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF8B5CF6))),
                    Text('TIẾN ĐỘ: ${percent.toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: (percent / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: isDark ? const Color(0xFF243045) : const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 8. ROW 6: KHOẢN VAY & SỔ NỢ (Khoản nợ vs Cho vay)
  // ===========================================================================
  Widget _buildLoansSection({
    required List<Loan> debtLoans,
    required List<Loan> lendLoans,
    required int totalDebt,
    required int totalLend,
    required bool isDark,
  }) {
    final currentTotal = _loanTab == 'debt' ? totalDebt : totalLend;
    final themeColor = _loanTab == 'debt' ? const Color(0xFFF43F5E) : const Color(0xFFF59E0B);

    return FinoraClayCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Khoản Vay & Sổ Nợ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => LoanScreen(userId: widget.userId)));
                },
                child: const Text(
                  'Xem chi tiết >',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2 Tab nợ vs cho vay
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _loanTab = 'debt'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: _loanTab == 'debt' ? const Color(0xFFF43F5E).withValues(alpha: 0.14) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _loanTab == 'debt' ? const Color(0xFFF43F5E) : (isDark ? const Color(0xFF243045) : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'CẦN TRẢ (${debtLoans.length})',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: _loanTab == 'debt' ? const Color(0xFFF43F5E) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _loanTab = 'lend'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: _loanTab == 'lend' ? const Color(0xFFF59E0B).withValues(alpha: 0.14) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _loanTab == 'lend' ? const Color(0xFFF59E0B) : (isDark ? const Color(0xFF243045) : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'CẦN THU (${lendLoans.length})',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: _loanTab == 'lend' ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tổng số tiền
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _loanTab == 'debt' ? 'TỔNG NỢ CẦN TRẢ:' : 'TỔNG CHO VAY CẦN THU:',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8)),
              ),
              Text(
                formatVND(currentTotal),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: themeColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 9. ROW 7: GIAO DỊCH GẦN ĐÂY (Icon quả cầu kính 3D, chi tiết sắc nét)
  // ===========================================================================
  Widget _buildRecentTransactionsSection({
    required List<TransactionModel> transactions,
    required bool isDark,
  }) {
    return FinoraClayCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Giao Dịch Gần Đây',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onViewAllTransactions?.call();
                },
                child: const Text(
                  'Xem tất cả >',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(LucideIcons.receipt, size: 28, color: isDark ? Colors.white38 : Colors.black26),
                    const SizedBox(height: 6),
                    Text(
                      'Chưa có giao dịch nào',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: transactions.take(5).map((tx) {
                final isIncome = tx.type == 'income';
                final isExpense = tx.type == 'expense';
                final color = isIncome ? const Color(0xFF10B981) : (isExpense ? const Color(0xFFF43F5E) : const Color(0xFF6366F1));
                final icon = isIncome ? LucideIcons.arrow_down_left : (isExpense ? LucideIcons.arrow_up_right : LucideIcons.refresh_cw);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131A26).withValues(alpha: 0.5) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? const Color(0xFF243045) : const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      children: [
                        // Quả cầu kính 3D
                        Finora3DGlassOrb(
                          size: 38,
                          tint: color,
                          child: Icon(icon, color: color, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.categoryName ?? 'Chi tiêu',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tx.note != null && tx.note!.isNotEmpty
                                    ? tx.note!
                                    : DateFormat('HH:mm · dd/MM').format(
                                        DateTime.fromMillisecondsSinceEpoch(tx.createdAt),
                                      ),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${isIncome ? '+' : '-'}${formatVND(tx.amount)}',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
