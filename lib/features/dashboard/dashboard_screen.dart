import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/utils/date_filter.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/widgets/custom_date_picker_dialog.dart';
import '../../core/widgets/transaction_filter_sheet.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/subject_filter_pill.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../../state/dashboard_provider.dart';
import '../asset/asset_screen.dart';
import '../budget/budget_screen.dart';
import '../notification/notification_screen.dart';
import '../transaction/add_transaction_page.dart';
import '../transaction/transaction_detail_screen.dart';
import '../wallet/wallet_screen.dart';
import '../ai/ai_advisor_screen.dart';
import '../loan/loan_screen.dart';
import '../report/report_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final VoidCallback? onViewAllTransactions;

  const DashboardScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    this.onViewAllTransactions,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _obscureBalance = false;
  bool _isInvestmentExpanded = false;
  DateTime _selectedDate = DateTime.now();
  String _dateLabel =
      'Hôm nay (' + DateFormat('dd/MM').format(DateTime.now()) + ')';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DashboardProvider>().load(widget.userId);
    });
  }

  void _openDateFilter() async {
    final picked =
        await CustomDatePickerSheet.show(context, initialDate: _selectedDate);
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        final now = DateTime.now();
        if (picked.year == now.year &&
            picked.month == now.month &&
            picked.day == now.day) {
          _dateLabel = 'Hôm nay (' + DateFormat('dd/MM').format(picked) + ')';
        } else {
          _dateLabel = DateFormat('dd/MM/yyyy').format(picked);
        }
      });
      if (mounted) {
        context
            .read<DashboardProvider>()
            .setDateFilter(DateFilterOption.customDate, custom: picked);
      }
    }
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  DateTime _parseTxDate(int timestamp) {
    if (timestamp <= 0) return DateTime.now();
    if (timestamp > 100000000000) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<DashboardProvider>();
    final d = provider.data;

    final totalBalance = d.totalWalletBalance;
    final income = d.periodIncome;
    final expense = d.periodExpense;
    final netFlow = d.periodNet;
    final txList = d.recentTransactions;
    final wallets = d.wallets;
    final comparisonPercent = d.previousMonthExpenses == 0
        ? 0.0
        : (d.currentMonthExpenses - d.previousMonthExpenses) /
            d.previousMonthExpenses *
            100;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
          child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            provider.load(widget.userId);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(isDark),
                const SizedBox(height: 16),
                _buildHeroCard(totalBalance, income, expense, netFlow,
                    txList.length, comparisonPercent),
                const SizedBox(height: 10),
                SubjectFilterPill(
                  selected: provider.selectedOwner,
                  onSelected: provider.setOwnerFilter,
                ),
                const SizedBox(height: 20),
                _buildQuickActions(isDark),
                const SizedBox(height: 20),
                _buildHealthScoreCard(d, isDark),
                const SizedBox(height: 24),
                _buildWalletsSection(wallets, isDark),
                const SizedBox(height: 24),
                _buildRecentTransactionsSection(txList, isDark),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      )),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF38BDF8), Color(0xFF6366F1)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2),
          child: ClipOval(
            child: widget.userPhotoUrl != null
                ? Image.network(
                    widget.userPhotoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildAvatarFallback(),
                  )
                : _buildAvatarFallback(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chào, ' +
                    (widget.userName.isNotEmpty ? widget.userName : 'Hoà Trần'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tài chính thông minh Finora AI',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => _push(NotificationScreen(userId: widget.userId)),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border.all(
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  size: 22,
                ),
                Positioned(
                  top: 9,
                  right: 10,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF06B6D4),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: const Color(0xFF3B82F6),
      child: const Center(
        child: Icon(Icons.person, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildHeroCard(num totalBalance, num income, num expense, num netFlow,
      int txCount, double comparisonPercent) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B3357),
            Color(0xFF155E75),
            Color(0xFF2563A9),
            Color(0xFF3294B8),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0891B2).withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng tài sản khả dụng',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: _openDateFilter,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _dateLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _obscureBalance
                      ? '•••••••• đ'
                      : Formatters.formatCurrency(totalBalance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              IconButton(
                onPressed: () =>
                    setState(() => _obscureBalance = !_obscureBalance),
                icon: Icon(
                  _obscureBalance
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(
                        comparisonPercent <= 0
                            ? Icons.trending_down_rounded
                            : Icons.trending_up_rounded,
                        color: const Color(0xFF34D399),
                        size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${comparisonPercent > 0 ? '+' : ''}${comparisonPercent.toStringAsFixed(1)}% chi tiêu so tháng trước',
                      style: const TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$txCount giao dịch',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildColumnStat(
                      'Thu vào',
                      Formatters.formatCurrency(income),
                      const Color(0xFF10B981),
                      Icons.check_circle_outline),
                ),
                Container(width: 1, height: 28, color: Colors.white12),
                Expanded(
                  child: _buildColumnStat(
                      'Chi ra',
                      Formatters.formatCurrency(expense),
                      const Color(0xFFF87171),
                      Icons.arrow_upward_rounded),
                ),
                Container(width: 1, height: 28, color: Colors.white12),
                Expanded(
                  child: _buildColumnStat(
                      'Dòng tiền',
                      Formatters.formatCurrency(netFlow),
                      const Color(0xFF38BDF8),
                      Icons.sync_alt_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () =>
                setState(() => _isInvestmentExpanded = !_isInvestmentExpanded),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Đầu tư & Vay nợ',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isInvestmentExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isInvestmentExpanded) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () => _push(AssetScreen(userId: widget.userId)),
                    child: const Column(
                      children: [
                        Text('Tài sản đầu tư',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 11)),
                        SizedBox(height: 2),
                        Text('68.000.000 đ',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 24, color: Colors.white24),
                  GestureDetector(
                    onTap: () => _push(LoanScreen(userId: widget.userId)),
                    child: const Column(
                      children: [
                        Text('Cho vay / Nợ',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 11)),
                        SizedBox(height: 2),
                        Text('8.100.000 đ',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildColumnStat(
      String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Row(
      children: [
        _buildActionItem(
          icon: Icons.add_rounded,
          label: 'Ghi chép',
          bgColor: const Color(0xFFE0F2FE),
          iconColor: const Color(0xFF0284C7),
          onTap: () => _push(AddTransactionPage(userId: widget.userId)),
          isDark: isDark,
        ),
        _buildActionItem(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Ví & Thẻ',
          bgColor: const Color(0xFFD1FAE5),
          iconColor: const Color(0xFF059669),
          onTap: () => _push(WalletScreen(userId: widget.userId)),
          isDark: isDark,
        ),
        _buildActionItem(
          icon: Icons.insights_rounded,
          label: 'Báo cáo',
          bgColor: const Color(0xFFFEF3C7),
          iconColor: const Color(0xFFD97706),
          onTap: () => _push(ReportScreen(userId: widget.userId)),
          isDark: isDark,
        ),
        _buildActionItem(
          icon: Icons.auto_awesome_rounded,
          label: 'AI Finora',
          bgColor: const Color(0xFFEEF2FF),
          iconColor: const Color(0xFF4F46E5),
          onTap: () => _push(AiAdvisorScreen(userId: widget.userId)),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 88,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isDark
                  ? bgColor.withValues(alpha: 0.13)
                  : Colors.white.withValues(alpha: .76),
              border: Border.all(
                color: isDark
                    ? iconColor.withValues(alpha: .20)
                    : Colors.white.withValues(alpha: .90),
              ),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 21),
                ),
                const SizedBox(height: 7),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHealthScoreCard(DashboardData d, bool isDark) {
    final score = d.aiHealthScore > 0 ? d.aiHealthScore : 92;
    final runway = d.emergencyRunwayMonths > 0
        ? d.emergencyRunwayMonths.toStringAsFixed(1)
        : '4.8';
    final savings = d.savingsRatePercent > 0
        ? d.savingsRatePercent.toInt().toString()
        : '46';
    final debt =
        d.debtRatioPercent > 0 ? d.debtRatioPercent.toInt().toString() : '1';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shield_outlined,
                        color: Color(0xFF059669), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Sức khỏe tài chính\nFinora AI',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Xuất sắc 🏆',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                        value: (score / 100).clamp(0.0, 1.0),
                        strokeWidth: 6,
                        backgroundColor:
                            isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF059669)),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$score',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF059669),
                          ),
                        ),
                        const Text(
                          '/100',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildIndicatorRow('Quỹ khẩn cấp', '$runway tháng', isDark),
                    const SizedBox(height: 6),
                    _buildIndicatorRow('Tỷ lệ tích lũy', '$savings%', isDark),
                    const SizedBox(height: 6),
                    _buildIndicatorRow('Tỷ lệ nợ/tài sản', '$debt%', isDark),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF059669), size: 14),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsSection(
      List<TransactionModel> transactions, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Giao dịch gần đây',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () {
                if (widget.onViewAllTransactions != null) {
                  widget.onViewAllTransactions!();
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0891B2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Text(
                      'Tất cả',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: .86)
                  : Colors.white.withValues(alpha: .72),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                'Chưa có giao dịch nào trong ngày',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
            ),
          )
        else
          Column(
            children: transactions
                .take(4)
                .map((tx) => _buildTransactionCard(tx, isDark))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildTransactionCard(TransactionModel tx, bool isDark) {
    final isExpense = tx.type == 'expense';
    final isIncome = tx.type == 'income';
    final color = isExpense
        ? const Color(0xFFEF4444)
        : (isIncome ? const Color(0xFF10B981) : const Color(0xFF3B82F6));
    final prefix = isExpense ? '-' : (isIncome ? '+' : '');
    final txDate = _parseTxDate(tx.date);
    final ownerColor = tx.owner == 'wife'
        ? const Color(0xFFEC4899)
        : tx.owner == 'husband'
            ? const Color(0xFF2563EB)
            : const Color(0xFF0F766E);

    return GestureDetector(
      onTap: () => _push(
          TransactionDetailScreen(userId: widget.userId, transaction: tx)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B)
              : ownerColor.withValues(alpha: .05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFF334155)
                : ownerColor.withValues(alpha: .11),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  CategoryIconHelper.resolveTransactionIcon(
                    transactionType: tx.type,
                    categoryIcon: tx.categoryIcon,
                    categoryName: tx.categoryName,
                    note: tx.note,
                  ),
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          tx.note?.isNotEmpty == true
                              ? tx.note!
                              : (tx.categoryName ?? 'Giao dịch'),
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'HÔM NAY',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (tx.walletName ?? 'Tiết Kiệm Chồng') +
                        ' • ' +
                        DateFormat('HH:mm').format(txDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  prefix + Formatters.formatCurrency(tx.amount),
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isExpense ? 'đã chi' : 'thu về',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletsSection(List<Wallet> wallets, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ví & Tài khoản',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () => _push(WalletScreen(userId: widget.userId)),
              child: Text(
                'Xem tất cả (' + wallets.length.toString() + ') >',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: wallets.isNotEmpty ? wallets.length : 2,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (wallets.isEmpty) {
                if (index == 0) {
                  return _buildWalletMiniCard(
                      'Tiền mặt', 228000, 'cash', 'husband', isDark);
                } else {
                  return _buildWalletMiniCard(
                      'Chi tiêu Chồng', 13736777, 'tcb', 'husband', isDark);
                }
              }
              final w = wallets[index];
              return _buildWalletMiniCard(
                  w.name, w.balance, w.bankCode, w.owner, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWalletMiniCard(
      String name, int balance, String? bankCode, String owner, bool isDark) {
    final ownerLabel =
        owner == 'husband' ? 'Chồng' : (owner == 'wife' ? 'Vợ' : 'Chung');

    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              BankIcon(bankCode: bankCode ?? '', size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ownerLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              Text(
                Formatters.formatCurrency(balance),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
