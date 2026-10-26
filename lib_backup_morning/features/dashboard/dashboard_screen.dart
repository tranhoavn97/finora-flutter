import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/bank_icon.dart';
import '../../data/models/wallet.dart';
import '../../data/models/transaction.dart';
import '../../domain/finance/finance_summary.dart';
import '../../state/dashboard_provider.dart';
import '../../state/budget_provider.dart';
import '../../state/wallet_provider.dart';
import '../../state/widget_style_controller.dart';
import '../../state/transaction_provider.dart';
import '../ai/ai_advisor_screen.dart';
import '../notification/notification_screen.dart';
import '../report/report_screen.dart';
import '../settings/settings_screen.dart';
import '../transaction/add_transaction_page.dart';
import '../transaction/transaction_detail_screen.dart';
import '../wallet/wallet_screen.dart';
import '../goal/goal_screen.dart';
import '../family/family_screen.dart';
import '../../core/widgets/premium_widgets.dart' show GlassCard;
import 'dashboard_theme_painters.dart';

class DashboardScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final VoidCallback? onViewAllTransactions;
  final VoidCallback? onViewWallets;

  const DashboardScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    this.onViewAllTransactions,
    this.onViewWallets,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _obscure = false;
  bool _showInvestmentLoan = false;
  bool _budgetExpanded = false;
  String _period = 'today';
  DateTimeRange? _customRange;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Xin chào buổi sáng';
    if (hour < 14) return 'Xin chào buổi trưa';
    if (hour < 18) return 'Xin chào buổi chiều';
    return 'Xin chào buổi tối';
  }

  String get _periodLabel {
    final now = DateTime.now();
    switch (_period) {
      case 'week':
        return 'Tuần này';
      case 'month':
        return 'Tháng ${DateFormat('MM/yyyy').format(now)}';
      case 'yesterday':
        return 'Hôm qua (${DateFormat('dd/MM').format(now.subtract(const Duration(days: 1)))})';
      case 'last_month':
        return 'Tháng ${DateFormat('MM/yyyy').format(DateTime(now.year, now.month - 1))}';
      case 'month_2':
        return 'Tháng ${DateFormat('MM/yyyy').format(DateTime(now.year, now.month - 2))}';
      case 'month_3':
        return 'Tháng ${DateFormat('MM/yyyy').format(DateTime(now.year, now.month - 3))}';
      case 'year':
        return 'Năm ${now.year}';
      case 'all':
        return 'Tất cả';
      case 'custom':
        final range = _customRange;
        return range == null
            ? 'Tùy chọn'
            : '${DateFormat('dd/MM').format(range.start)} - ${DateFormat('dd/MM').format(range.end)}';
      default:
        return 'Hôm nay';
    }
  }

  bool _isInSelectedPeriod(TransactionModel tx) {
    if (_period == 'all') return true;
    final date = DateTime.fromMillisecondsSinceEpoch(tx.date);
    final day = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    if (_period == 'yesterday') {
      start = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 1));
      end = DateTime(start.year, start.month, start.day, 23, 59, 59, 999);
    } else if (_period == 'week') {
      start = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
    } else if (_period == 'month') {
      start = DateTime(now.year, now.month, 1);
    } else if (_period == 'last_month') {
      start = DateTime(now.year, now.month - 1, 1);
      end = DateTime(now.year, now.month, 0, 23, 59, 59, 999);
    } else if (_period == 'month_2' || _period == 'month_3') {
      final offset = _period == 'month_2' ? 2 : 3;
      start = DateTime(now.year, now.month - offset, 1);
      end = DateTime(now.year, now.month - offset + 1, 0, 23, 59, 59, 999);
    } else if (_period == 'year') {
      start = DateTime(now.year, 1, 1);
    } else if (_period == 'custom' && _customRange != null) {
      start = DateTime(_customRange!.start.year, _customRange!.start.month,
          _customRange!.start.day);
      end = DateTime(_customRange!.end.year, _customRange!.end.month,
          _customRange!.end.day, 23, 59, 59, 999);
    } else {
      start = DateTime(now.year, now.month, now.day);
    }
    return !day.isBefore(start) && !day.isAfter(end);
  }

  Future<void> _applyPeriod(String selected) async {
    if (selected == 'custom') {
      if (!mounted) return;
      final range = await _showCompactDateRangePicker();
      if (range == null) return;
      setState(() {
        _period = selected;
        _customRange = range;
      });
    } else {
      setState(() => _period = selected);
    }
  }

  Future<DateTimeRange?> _showCompactDateRangePicker() async {
    var start = _customRange?.start ?? DateTime.now();
    var end = _customRange?.end ?? start;
    var pickingEnd = false;
    return showDialog<DateTimeRange>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Chọn khoảng thời gian',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setDialogState(() => pickingEnd = false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: !pickingEnd
                                ? const Color(0xFF2563EB)
                                : Colors.black12,
                            width: !pickingEnd ? 2 : 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'Từ: ${DateFormat('dd/MM/yyyy').format(start)}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: !pickingEnd
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF64748B)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setDialogState(() => pickingEnd = true),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: pickingEnd
                                ? const Color(0xFF2563EB)
                                : Colors.black12,
                            width: pickingEnd ? 2 : 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'Đến: ${DateFormat('dd/MM/yyyy').format(end)}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: pickingEnd
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 270,
                width: 300,
                child: CalendarDatePicker(
                  initialDate: pickingEnd ? end : start,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  onDateChanged: (val) {
                    setDialogState(() {
                      if (!pickingEnd) {
                        start = val;
                        if (end.isBefore(start)) end = start;
                        pickingEnd = true;
                      } else {
                        if (val.isBefore(start)) {
                          start = val;
                        } else {
                          end = val;
                        }
                      }
                    });
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                  dialogContext, DateTimeRange(start: start, end: end)),
              child: const Text('Áp dụng'),
            ),
          ],
        ),
      ),
    );
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<DashboardProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    final walletProvider = context.watch<WalletProvider>();
    final txProvider = context.watch<TransactionProvider>();
    WidgetStyleController? widgetStyle;
    try {
      widgetStyle = context.watch<WidgetStyleController>();
    } catch (_) {
      widgetStyle = null;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);

    final computedWalletBalance = walletProvider.wallets
        .where((w) => !w.isCreditCard)
        .fold<int>(0, (sum, w) => sum + w.balance);
    final computedCardDebt = walletProvider.wallets
        .where((w) => w.isCreditCard)
        .fold<int>(0, (sum, w) => sum + w.currentDebt);
    final netAssets = computedWalletBalance +
        d.data.totalAssetsValue +
        d.data.totalLent -
        computedCardDebt -
        d.data.totalBorrowed;

    final displayNet = netAssets;
    final filteredTxs =
        txProvider.transactions.where(_isInSelectedPeriod).toList();
    final displayIncome = filteredTxs
        .where(FinanceSummary.isIncome)
        .fold<int>(0, (sum, tx) => sum + tx.amount);
    final displayExpense = filteredTxs
        .where(FinanceSummary.isExpense)
        .fold<int>(0, (sum, tx) => sum + tx.amount);
    final displayFlow = displayIncome - displayExpense;

    final displayName =
        widget.userName.trim().isEmpty ? 'Bạn' : widget.userName.trim();
    final wallets = walletProvider.wallets;
    final recentTxs = filteredTxs.take(5).toList();
    final monthBudgets = budgetProvider.budgetsWithSpent;
    final budgetLimit =
        monthBudgets.fold<int>(0, (sum, item) => sum + item.budget.limitAmount);
    final budgetSpent =
        monthBudgets.fold<int>(0, (sum, item) => sum + item.spentAmount);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
          children: [
            // 1. Redesigned App Bar (Matching Image 4)
            _buildAppBar(
              displayName: displayName,
              secondaryTextColor: secondaryTextColor,
              primaryTextColor: primaryTextColor,
              isDark: isDark,
            ),
            const SizedBox(height: 14),

            // 2. Total Assets Card (7 Themes matching Image 1)
            _buildTotalAssetCard(
              assetStyle: widgetStyle?.assetStyle ?? 0,
              displayNet: displayNet,
              displayIncome: displayIncome,
              displayExpense: displayExpense,
              displayFlow: displayFlow,
              d: d,
            ),
            const SizedBox(height: 18),

            // 3. Four Quick Action Circular Buttons
            _buildQuickActions(isDark, primaryTextColor),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(6),
              child: Row(children: [
                Expanded(child: _sharedShortcut(
                  'Mục tiêu', 'Tích lũy cho tương lai', Icons.flag_rounded,
                  const Color(0xFF059669), () => _push(GoalScreen(userId: widget.userId)),
                )),
                Container(width: 1, height: 36, color: Theme.of(context).dividerColor),
                Expanded(child: _sharedShortcut(
                  'Gia đình', 'Cùng quản lý chi tiêu', Icons.people_alt_rounded,
                  const Color(0xFF4263EB), () => _push(const FamilyScreen()),
                )),
              ]),
            ),
            const SizedBox(height: 18),

            // 4. Finora AI Assistant Health Card (4 Themes matching Image 3)
            _buildAiAssistantCard(
              assistantStyle: widgetStyle?.assistantStyle ?? 0,
              d: d,
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            const SizedBox(height: 18),

            // 5. Wallets & Accounts Section (Luminous depth & multi-brand gradient)
            _buildWalletSection(
              wallets: wallets,
              isRefreshing: walletProvider.isRefreshing,
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            const SizedBox(height: 18),

            // 6. Monthly Budget Card (4 Themes matching Image 2)
            _buildMonthlyBudgetCard(
              budgetStyle: widgetStyle?.budgetStyle ?? 0,
              budgetLimit: budgetLimit,
              budgetSpent: budgetSpent,
              monthBudgets: monthBudgets,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              isDark: isDark,
            ),
            const SizedBox(height: 18),

            // 7. Recent Transactions / Widget (9 Styles matching Image 5)
            _buildRecentTransactionsWidget(
              historyStyle: widgetStyle?.historyStyle ?? 0,
              recentTxs: recentTxs,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. APP BAR
  // -------------------------------------------------------------
  Widget _buildAppBar({
    required String displayName,
    required Color secondaryTextColor,
    required Color primaryTextColor,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          // Avatar leads the greeting; the decorative app icon is intentionally removed.
          GestureDetector(
            onTap: () => _push(SettingsScreen(userId: widget.userId)),
            child: Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(2.2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFF38BDF8), Color(0xFF8B5CF6)]),
            ),
            child: ClipOval(
              child: widget.userPhotoUrl?.isNotEmpty == true
                  ? CachedNetworkImage(imageUrl: widget.userPhotoUrl!, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _avatarFallback(displayName))
                  : _avatarFallback(displayName),
            ),
          ),
          ),
          const SizedBox(width: 12),

          // Greeting & Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: primaryTextColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),

          // Notification Bell Button with blue unread dot badge
          GestureDetector(
            onTap: () => _push(NotificationScreen(userId: widget.userId)),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 21,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  Positioned(
                    top: 10,
                    right: 11,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. TOTAL ASSETS CARD (7 THEMES)
  // -------------------------------------------------------------
  Widget _buildTotalAssetCard({
    required int assetStyle,
    required int displayNet,
    required int displayIncome,
    required int displayExpense,
    required int displayFlow,
    required DashboardProvider d,
  }) {
    final isLight = assetStyle == 5;
    final isCyberHolo = assetStyle == 6;

    List<Color> bgGradient;
    Color primaryColor;
    Color walletIconBg;
    Color statCardBg;
    Color statCardBorder;
    Color textColor;
    Color subTextColor;

    switch (assetStyle) {
      case 1:
        bgGradient = const [Color(0xFF031024), Color(0xFF072142)];
        primaryColor = const Color(0xFF38BDF8);
        walletIconBg = const Color(0xFF0284C7);
        statCardBg = const Color(0xFF081C38).withValues(alpha: 0.85);
        statCardBorder = const Color(0xFF38BDF8).withValues(alpha: 0.20);
        textColor = Colors.white;
        subTextColor = Colors.white70;
        break;
      case 2:
        bgGradient = const [Color(0xFF0D051A), Color(0xFF1F0B38)];
        primaryColor = const Color(0xFFC084FC);
        walletIconBg = const Color(0xFF9333EA);
        statCardBg = const Color(0xFF160A2A).withValues(alpha: 0.85);
        statCardBorder = const Color(0xFFC084FC).withValues(alpha: 0.20);
        textColor = Colors.white;
        subTextColor = Colors.white70;
        break;
      case 3:
        bgGradient = const [Color(0xFF021719), Color(0xFF062D30)];
        primaryColor = const Color(0xFF2DD4BF);
        walletIconBg = const Color(0xFF0D9488);
        statCardBg = const Color(0xFF042022).withValues(alpha: 0.85);
        statCardBorder = const Color(0xFF2DD4BF).withValues(alpha: 0.20);
        textColor = Colors.white;
        subTextColor = Colors.white70;
        break;
      case 4:
        bgGradient = const [Color(0xFF0B0A08), Color(0xFF181510)];
        primaryColor = const Color(0xFFFBBF24);
        walletIconBg = const Color(0xFFD97706);
        statCardBg = const Color(0xFF14120E).withValues(alpha: 0.85);
        statCardBorder = const Color(0xFFFBBF24).withValues(alpha: 0.20);
        textColor = Colors.white;
        subTextColor = Colors.white70;
        break;
      case 5:
        bgGradient = const [Color(0xFFFFFFFF), Color(0xFFF1F5F9)];
        primaryColor = const Color(0xFF3B82F6);
        walletIconBg = const Color(0xFF3B82F6);
        statCardBg = Colors.white;
        statCardBorder = const Color(0xFFE2E8F0);
        textColor = const Color(0xFF0F172A);
        subTextColor = const Color(0xFF64748B);
        break;
      case 6:
        bgGradient = const [Color(0xFF04121B), Color(0xFF07202C)];
        primaryColor = const Color(0xFF06B6D4);
        walletIconBg = const Color(0xFF0891B2);
        statCardBg = const Color(0xFF051722).withValues(alpha: 0.90);
        statCardBorder = const Color(0xFF06B6D4).withValues(alpha: 0.35);
        textColor = Colors.white;
        subTextColor = Colors.white70;
        break;
      case 0:
      default:
        bgGradient = const [Color(0xFF020617), Color(0xFF1E1B4B)];
        primaryColor = const Color(0xFF818CF8);
        walletIconBg = const Color(0xFF4F46E5);
        statCardBg = const Color(0xFF0B1228).withValues(alpha: 0.82);
        statCardBorder = const Color(0xFF60A5FA).withValues(alpha: 0.18);
        textColor = Colors.white;
        subTextColor = Colors.white70;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: bgGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isLight
              ? const Color(0xFFE2E8F0)
              : Colors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? const Color(0xFF64748B).withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.45),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: _buildThemeBackgroundGraphic(assetStyle, primaryColor),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: walletIconBg.withValues(
                                    alpha: isLight ? 0.95 : 0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: walletIconBg.withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'TỔNG TÀI SẢN',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isLight
                                      ? const Color(0xFF1E293B)
                                      : Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => setState(() => _obscure = !_obscure),
                              child: Icon(
                                _obscure
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: 16,
                                color: isLight
                                    ? const Color(0xFF64748B)
                                    : primaryColor.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      PopupMenuButton<String>(
                        tooltip: 'Chọn khoảng thời gian',
                        offset: const Offset(0, 8),
                        color: isLight ? Colors.white : const Color(0xFF0F172A),
                        elevation: 18,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: isLight
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF60A5FA)
                                    .withValues(alpha: 0.25),
                          ),
                        ),
                        onSelected: _applyPeriod,
                        itemBuilder: (context) => [
                          for (final item in const [
                            ('today', 'Hôm nay'),
                            ('yesterday', 'Hôm qua'),
                            ('week', 'Tuần này'),
                            ('month', 'Tháng này'),
                            ('last_month', 'Tháng trước'),
                            ('year', 'Năm nay'),
                            ('all', 'Tất cả'),
                            ('custom', 'Tùy chọn'),
                          ])
                            PopupMenuItem<String>(
                              value: item.$1,
                              height: 42,
                              child: Row(
                                children: [
                                  Icon(
                                    item.$1 == 'custom'
                                        ? Icons.calendar_month_rounded
                                        : _period == item.$1
                                            ? Icons.check_circle_rounded
                                            : Icons.schedule_rounded,
                                    size: 18,
                                    color: _period == item.$1
                                        ? const Color(0xFF2563EB)
                                        : (isLight
                                            ? Colors.black45
                                            : Colors.white54),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    item.$2,
                                    style: TextStyle(
                                      color: isLight
                                          ? const Color(0xFF0F172A)
                                          : Colors.white,
                                      fontSize: 13,
                                      fontWeight: _period == item.$1
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: isLight
                                ? Colors.black.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isLight
                                  ? const Color(0xFFCBD5E1)
                                  : primaryColor.withValues(alpha: 0.30),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _periodLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 14,
                                color: subTextColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _obscure
                        ? '•••••••• đ'
                        : '${NumberFormat('#,##0', 'vi_VN').format(displayNet)} đ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _build3StatsRow(
                    isLight: isLight,
                    isCyberHolo: isCyberHolo,
                    statCardBg: statCardBg,
                    statCardBorder: statCardBorder,
                    displayIncome: displayIncome,
                    displayExpense: displayExpense,
                    displayFlow: displayFlow,
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => setState(
                        () => _showInvestmentLoan = !_showInvestmentLoan),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Đầu tư & Vay nợ',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isLight
                                    ? const Color(0xFF2563EB)
                                    : primaryColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _showInvestmentLoan
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: isLight
                                  ? const Color(0xFF2563EB)
                                  : primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_showInvestmentLoan) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSpaceMiniCard(
                            Icons.trending_up_rounded,
                            'Tài sản',
                            '${NumberFormat('#,##0', 'vi_VN').format(d.data.totalAssetsValue)} đ',
                            const Color(0xFF38BDF8),
                            isLight,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSpaceMiniCard(
                            Icons.handshake_outlined,
                            'Cho vay',
                            '${NumberFormat('#,##0', 'vi_VN').format(d.data.totalLent)} đ',
                            const Color(0xFFC084FC),
                            isLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeBackgroundGraphic(int assetStyle, Color primaryColor) {
    switch (assetStyle) {
      case 1:
        return CustomPaint(
            painter: NeonWavePainter(primaryColor: primaryColor));
      case 2:
        return CustomPaint(
            painter: EqualizerBarsPainter(primaryColor: primaryColor));
      case 3:
        return CustomPaint(
            painter: EmeraldWavePainter(primaryColor: primaryColor));
      case 4:
        return CustomPaint(
            painter: GoldenMeteorsPainter(primaryColor: primaryColor));
      case 5:
        return const CustomPaint(painter: PastelHorizonPainter());
      case 6:
        return CustomPaint(
            painter: HoloRadarPainter(primaryColor: primaryColor));
      case 0:
      default:
        return Opacity(
          opacity: 0.35,
          child: Image.asset(
            'assets/dashboard/space_overview.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        );
    }
  }

  Widget _build3StatsRow({
    required bool isLight,
    required bool isCyberHolo,
    required Color statCardBg,
    required Color statCardBorder,
    required int displayIncome,
    required int displayExpense,
    required int displayFlow,
  }) {
    if (isLight) {
      return Row(
        children: [
          Expanded(
            child: _buildLightStatPill(
              icon: Icons.south_west_rounded,
              iconColor: const Color(0xFF10B981),
              title: 'Thu vào',
              value: _obscure
                  ? '••••'
                  : '+${NumberFormat('#,##0', 'vi_VN').format(displayIncome)} đ',
              valueColor: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildLightStatPill(
              icon: Icons.north_east_rounded,
              iconColor: const Color(0xFFEF4444),
              title: 'Chi ra',
              value: _obscure
                  ? '••••'
                  : '-${NumberFormat('#,##0', 'vi_VN').format(displayExpense)} đ',
              valueColor: const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildLightStatPill(
              icon: Icons.account_balance_wallet_outlined,
              iconColor: const Color(0xFF3B82F6),
              title: 'Dòng tiền',
              value: _obscure
                  ? '••••'
                  : '${displayFlow >= 0 ? "+" : ""}${NumberFormat('#,##0', 'vi_VN').format(displayFlow)} đ',
              valueColor: displayFlow >= 0
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
            ),
          ),
        ],
      );
    }

    if (isCyberHolo) {
      return Row(
        children: [
          Expanded(
            child: _buildCyberStatPill(
              icon: Icons.south_west_rounded,
              title: 'Thu vào',
              value: _obscure
                  ? '••••'
                  : '+${NumberFormat('#,##0', 'vi_VN').format(displayIncome)} đ',
              valueColor: const Color(0xFF34D399),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCyberStatPill(
              icon: Icons.north_east_rounded,
              title: 'Chi ra',
              value: _obscure
                  ? '••••'
                  : '-${NumberFormat('#,##0', 'vi_VN').format(displayExpense)} đ',
              valueColor: const Color(0xFFF87171),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCyberStatPill(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Dòng tiền',
              value: _obscure
                  ? '••••'
                  : '${displayFlow >= 0 ? "+" : ""}${NumberFormat('#,##0', 'vi_VN').format(displayFlow)} đ',
              valueColor: displayFlow >= 0
                  ? const Color(0xFF34D399)
                  : const Color(0xFFF87171),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.5),
      decoration: BoxDecoration(
        color: statCardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Icon(Icons.south_west_rounded,
                          size: 12, color: Color(0xFF34D399)),
                      SizedBox(width: 3),
                      Text('Thu vào',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _obscure
                        ? '••••'
                        : '+${NumberFormat('#,##0', 'vi_VN').format(displayIncome)} đ',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF34D399)),
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 32, color: Colors.white12),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Icon(Icons.north_east_rounded,
                          size: 12, color: Color(0xFFF87171)),
                      SizedBox(width: 3),
                      Text('Chi ra',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _obscure
                        ? '••••'
                        : '-${NumberFormat('#,##0', 'vi_VN').format(displayExpense)} đ',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF87171)),
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 32, color: Colors.white12),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          size: 12, color: Color(0xFF38BDF8)),
                      SizedBox(width: 3),
                      Text('Dòng tiền',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _obscure
                        ? '••••'
                        : '${displayFlow >= 0 ? "+" : ""}${NumberFormat('#,##0', 'vi_VN').format(displayFlow)} đ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: displayFlow >= 0
                          ? const Color(0xFF34D399)
                          : const Color(0xFFF87171),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLightStatPill({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(icon, size: 12, color: iconColor),
                const SizedBox(width: 3),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCyberStatPill({
    required IconData icon,
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7.5),
      decoration: BoxDecoration(
        color: const Color(0xFF031622).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF06B6D4).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(icon, size: 12, color: const Color(0xFF06B6D4)),
                const SizedBox(width: 3),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. FOUR QUICK ACTIONS
  // -------------------------------------------------------------
  Widget _sharedShortcut(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 9),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(subtitle, style: TextStyle(fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
  }

  Widget _buildQuickActions(bool isDark, Color primaryTextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.add_rounded,
            iconColor: const Color(0xFF0284C7),
            bgColor: const Color(0xFFE0F2FE),
            label: 'Ghi chép',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => AddTransactionPage(userId: widget.userId),
              ),
            ),
            isDark: isDark,
            primaryTextColor: primaryTextColor,
          ),
        ),
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFF0D9488),
            bgColor: const Color(0xFFCCFBF1),
            label: 'Ví & Thẻ',
            onTap: () {
              if (widget.onViewWallets != null) {
                widget.onViewWallets!();
              } else {
                _push(WalletScreen(userId: widget.userId));
              }
            },
            isDark: isDark,
            primaryTextColor: primaryTextColor,
          ),
        ),
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.auto_graph_rounded,
            iconColor: const Color(0xFFD97706),
            bgColor: const Color(0xFFFEF3C7),
            label: 'Báo cáo',
            onTap: () => _push(ReportScreen(userId: widget.userId)),
            isDark: isDark,
            primaryTextColor: primaryTextColor,
          ),
        ),
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.auto_awesome_rounded,
            iconColor: const Color(0xFF2563EB),
            bgColor: const Color(0xFFDBEAFE),
            label: 'AI Finora',
            onTap: () => _push(AiAdvisorScreen(userId: widget.userId)),
            isDark: isDark,
            primaryTextColor: primaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    required Color primaryTextColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: isDark ? .12 : .95),
                  bgColor.withValues(alpha: isDark ? .24 : .92)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? .18 : .95),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: .18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: primaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 4. FINORA AI ASSISTANT CARD (4 THEMES)
  // -------------------------------------------------------------
  Widget _buildAiAssistantCard({
    required int assistantStyle,
    required DashboardProvider d,
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    List<Color> bgGradient;
    Color borderColor;
    Color iconBg;
    Color iconColor;
    Color badgeBg;
    Color badgeColor;
    Color ringColor;
    Color ringBg;
    Color textColor;
    Color subtitleColor;

    switch (assistantStyle) {
      case 1:
        bgGradient = const [Color(0xFF100D24), Color(0xFF221742)];
        borderColor = const Color(0xFFA855F7).withValues(alpha: 0.25);
        iconBg = const Color(0xFF2A1B4E);
        iconColor = const Color(0xFFA855F7);
        badgeBg = const Color(0xFF381A2E);
        badgeColor = const Color(0xFFF43F5E);
        ringColor = const Color(0xFFA855F7);
        ringBg = const Color(0xFF2A1B4E);
        textColor = Colors.white;
        subtitleColor = Colors.white70;
        break;
      case 2:
        bgGradient = const [Color(0xFFF2FAF7), Color(0xFFE4F7EF)];
        borderColor = const Color(0xFF10B981).withValues(alpha: 0.22);
        iconBg = const Color(0xFF10B981);
        iconColor = Colors.white;
        badgeBg = const Color(0xFFFFE4E6);
        badgeColor = const Color(0xFFE11D48);
        ringColor = const Color(0xFF10B981);
        ringBg = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF0F172A);
        subtitleColor = const Color(0xFF64748B);
        break;
      case 3:
        bgGradient = const [Color(0xFF031E24), Color(0xFF07333B)];
        borderColor = const Color(0xFF06B6D4).withValues(alpha: 0.35);
        iconBg = const Color(0xFF0891B2);
        iconColor = Colors.white;
        badgeBg = const Color(0xFF381A2E);
        badgeColor = const Color(0xFFF43F5E);
        ringColor = const Color(0xFF06B6D4);
        ringBg = const Color(0xFF083344);
        textColor = Colors.white;
        subtitleColor = Colors.white70;
        break;
      case 0:
      default:
        bgGradient = const [Color(0xFFFFFFFF), Color(0xFFFFF7F7)];
        borderColor = const Color(0xFFFFE4E6);
        iconBg = const Color(0xFFFFE4E6);
        iconColor = const Color(0xFFE11D48);
        badgeBg = const Color(0xFFFFE4E6);
        badgeColor = const Color(0xFFE11D48);
        ringColor = const Color(0xFFFB7185);
        ringBg = const Color(0xFFFFE4E6);
        textColor = const Color(0xFF0F172A);
        subtitleColor = const Color(0xFF64748B);
        break;
    }

    final healthScore = d.data.aiHealthScore.clamp(0, 100);
    final runway = '${d.data.emergencyRunwayMonths.toStringAsFixed(1)} tháng';
    final savingsRate = '${d.data.savingsRatePercent.round()}%';
    final debtRatio = '${d.data.debtRatioPercent.round()}%';
    final isCyber = assistantStyle == 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: ringColor.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: iconBg,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: iconColor.withValues(alpha: .28), blurRadius: 9, offset: const Offset(0, 4)),
                          const BoxShadow(color: Colors.white24, blurRadius: 2, offset: Offset(-1, -1)),
                        ],
                      ),
                      child: Icon(Icons.edit_note_rounded,
                          color: iconColor, size: 17),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Trợ lí Finora',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
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
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Báo động',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.circle, size: 8, color: badgeColor),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildAiContent(assistantStyle, d, isCyber, ringColor, ringBg,
              textColor, subtitleColor, healthScore, runway, savingsRate, debtRatio),
        ],
      ),
    );
  }

  Widget _buildAiContent(
    int assistantStyle,
    DashboardProvider d,
    bool isCyber,
    Color ringColor,
    Color ringBg,
    Color textColor,
    Color subtitleColor,
    int score,
    String runway,
    String savingsRate,
    String debtRatio,
  ) {
    return Row(
      children: [
        _buildScoreBadge(isCyber, ringColor, ringBg, textColor, score),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricRowsList(
            textColor: textColor,
            subtitleColor: subtitleColor,
            runway: runway,
            savingsRate: savingsRate,
            debtRatio: debtRatio,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreBadge(
    bool isCyber,
    Color ringColor,
    Color ringBg,
    Color textColor,
    int score,
  ) {
    return Container(
      width: 78,
      height: 78,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ringBg.withValues(alpha: 0.45),
        border: Border.all(
          color: ringColor,
          width: isCyber ? 3.5 : 5,
        ),
        boxShadow: isCyber
            ? [
                BoxShadow(
                  color: ringColor.withValues(alpha: 0.4),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$score',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: ringColor,
                height: 1.1,
              ),
            ),
            Text(
              '/100',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: textColor.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRowsList({
    required Color textColor,
    required Color subtitleColor,
    required String runway,
    required String savingsRate,
    required String debtRatio,
  }) {
    return Column(
      children: [
        _buildHealthRowItem(
          icon: Icons.savings_outlined,
          label: 'Tỉ lệ tiết kiệm',
          value: savingsRate,
          iconColor: const Color(0xFF10B981),
          textColor: textColor,
          subtitleColor: subtitleColor,
        ),
        const SizedBox(height: 7),
        _buildHealthRowItem(
          icon: Icons.credit_card_off_outlined,
          label: 'Hệ số nợ',
          value: debtRatio,
          iconColor: const Color(0xFFF59E0B),
          textColor: textColor,
          subtitleColor: subtitleColor,
        ),
        const SizedBox(height: 7),
        _buildHealthRowItem(
          icon: Icons.shield_outlined,
          label: 'Quỹ khẩn cấp',
          value: runway,
          iconColor: const Color(0xFF10B981),
          textColor: textColor,
          subtitleColor: subtitleColor,
        ),
      ],
    );
  }

  Widget _buildHealthRowItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 5. MONTHLY BUDGET CARD (4 THEMES)
  // -------------------------------------------------------------
  Widget _buildMonthlyBudgetCard({
    required int budgetStyle,
    required int budgetLimit,
    required int budgetSpent,
    required List<dynamic> monthBudgets,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required bool isDark,
  }) {
    List<Color> bgGradient;
    Color borderColor;
    Color iconBg;
    Color iconColor;
    Color progressActive;
    Color progressTrack;
    Color textColor;
    Color subTextColor;
    bool hasLeaves = false;

    switch (budgetStyle) {
      case 1:
        bgGradient = const [Color(0xFF181028), Color(0xFF2A1545)];
        borderColor = const Color(0xFFA855F7).withValues(alpha: 0.30);
        iconBg = const Color(0xFF3B1E6D);
        iconColor = const Color(0xFFC084FC);
        progressActive = const Color(0xFFA855F7);
        progressTrack = const Color(0xFF24153C);
        textColor = Colors.white;
        subTextColor = Colors.white70;
        break;
      case 2:
        bgGradient = const [Color(0xFFF0FBF5), Color(0xFFE6F7ED)];
        borderColor = const Color(0xFF10B981).withValues(alpha: 0.25);
        iconBg = const Color(0xFFD1FAE5);
        iconColor = const Color(0xFF10B981);
        progressActive = const Color(0xFF10B981);
        progressTrack = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF0F172A);
        subTextColor = const Color(0xFF64748B);
        hasLeaves = true;
        break;
      case 3:
        bgGradient = const [Color(0xFF141210), Color(0xFF241B10)];
        borderColor = const Color(0xFFF59E0B).withValues(alpha: 0.30);
        iconBg = const Color(0xFF382613);
        iconColor = const Color(0xFFF59E0B);
        progressActive = const Color(0xFFF59E0B);
        progressTrack = const Color(0xFF24180E);
        textColor = Colors.white;
        subTextColor = Colors.white70;
        break;
      case 0:
      default:
        bgGradient = const [Color(0xFFFFFFFF), Color(0xFFF0F9FF)];
        borderColor = const Color(0xFFBAE6FD);
        iconBg = const Color(0xFFE0F2FE);
        iconColor = const Color(0xFF0284C7);
        progressActive = const Color(0xFF0284C7);
        progressTrack = const Color(0xFFE0F2FE);
        textColor = const Color(0xFF0F172A);
        subTextColor = const Color(0xFF64748B);
        break;
    }

    final double progressFraction =
        budgetLimit > 0 ? (budgetSpent / budgetLimit).clamp(0.0, 1.0) : 0.0;
    final int pct = budgetLimit > 0
        ? ((budgetSpent / budgetLimit) * 100).round().clamp(0, 100)
        : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            if (hasLeaves)
              Positioned.fill(
                child: CustomPaint(
                  painter: BotanicalLeavesPainter(leafColor: iconColor),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () =>
                        setState(() => _budgetExpanded = !_budgetExpanded),
                    child: Container(
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: iconBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.pie_chart_rounded,
                                color: iconColor, size: 18),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ngân sách tháng',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: subTextColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '${NumberFormat('#,##0', 'vi_VN').format(budgetSpent)} đ / ${NumberFormat('#,##0', 'vi_VN').format(budgetLimit)} đ',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 46,
                            height: 46,
                            child: CustomPaint(
                              painter: DottedCircleProgressPainter(
                                color: progressActive,
                                progress: progressFraction,
                              ),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '$pct%',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            color: progressActive,
                                            height: 1,
                                          ),
                                        ),
                                        Text(
                                          'đã dùng',
                                          style: TextStyle(
                                            fontSize: 7.5,
                                            fontWeight: FontWeight.w600,
                                            color: subTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _budgetExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: iconColor,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progressFraction,
                      minHeight: 6,
                      backgroundColor: progressTrack,
                      valueColor: AlwaysStoppedAnimation<Color>(progressActive),
                    ),
                  ),
                  if (_budgetExpanded) ...[
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Colors.black12),
                    const SizedBox(height: 10),
                    if (monthBudgets.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Chưa tạo hạn mức cho các mục chi tiêu.',
                          style: TextStyle(fontSize: 12, color: subTextColor),
                        ),
                      )
                    else
                      for (final item in monthBudgets) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: progressActive.withValues(alpha: .14),
                                ),
                                child: Text(item.budget.categoryIcon ?? '🎯',
                                    style: const TextStyle(fontSize: 15)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  item.budget.categoryName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 3,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: item.progress.clamp(0.0, 1.0),
                                    minHeight: 4,
                                    backgroundColor: progressTrack,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      item.progress > 1
                                          ? const Color(0xFFEF4444)
                                          : progressActive,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${NumberFormat('#,##0', 'vi_VN').format(item.spentAmount)} / ${NumberFormat('#,##0', 'vi_VN').format(item.budget.limitAmount)} đ',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: subTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 6. WALLETS & ACCOUNTS (LUMINOUS DEPTH EFFECT)
  // -------------------------------------------------------------
  Widget _buildWalletSection({
    required List<Wallet> wallets,
    required bool isRefreshing,
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Ví & Tài khoản',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: primaryTextColor,
                ),
              ),
            ),
            _pillLink(
              'Xem tất cả',
              Icons.arrow_forward_rounded,
              () => widget.onViewWallets != null
                  ? widget.onViewWallets!()
                  : _push(WalletScreen(userId: widget.userId)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 114,
          child: wallets.isEmpty
              ? Center(
                  child: Text(
                    isRefreshing
                        ? 'Đang tải ví...'
                        : 'Chưa có ví hoặc tài khoản',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: wallets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => _buildLuminousWalletCard(
                    wallet: wallets[i],
                    isDark: isDark,
                    onTap: () => widget.onViewWallets?.call(),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLuminousWalletCard({
    required Wallet wallet,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final colors = _walletColors(wallet.bankCode, isDark);
    final isCredit = wallet.isCreditCard;
    final balance = isCredit ? -wallet.currentDebt : wallet.balance;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 178,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.last.withValues(alpha: 0.32),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
          child: Stack(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 152,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (wallet.bankCode != null)
                          BankIcon(bankCode: wallet.bankCode, size: 24)
                        else
                          const Text('💵', style: TextStyle(fontSize: 18)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            wallet.ownerName,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wallet.name,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${NumberFormat('#,##0', 'vi_VN').format(balance)} đ',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 7. RECENT TRANSACTIONS / WIDGET (9 STYLES MATCHING IMAGE 5)
  // -------------------------------------------------------------
  Widget _buildRecentTransactionsWidget({
    required int historyStyle,
    required List<TransactionModel> recentTxs,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required bool isDark,
  }) {
    List<Color> cardBg;
    Color borderColor;
    Color timelineColor;
    Color itemBg;
    Color itemBorder;
    Color textColor;
    Color subTextColor;
    Color viewAllBg;
    Color viewAllText;
    bool isCyberHex = historyStyle == 4;
    bool isStarTimeline = historyStyle == 7;
    bool isAmberWarm = historyStyle == 5;
    bool isGreenLeaves = historyStyle == 2;

    switch (historyStyle) {
      case 1:
        cardBg = const [Color(0xFF0C1033), Color(0xFF161F58)];
        borderColor = const Color(0xFF38BDF8).withValues(alpha: 0.35);
        timelineColor = const Color(0xFF38BDF8);
        itemBg = const Color(0xFF131C4D).withValues(alpha: 0.85);
        itemBorder = const Color(0xFF38BDF8).withValues(alpha: 0.25);
        textColor = Colors.white;
        subTextColor = Colors.white70;
        viewAllBg = const Color(0xFF1D2866);
        viewAllText = const Color(0xFF38BDF8);
        break;
      case 2:
        cardBg = const [Color(0xFFF0FDF4), Color(0xFFE8FAF0)];
        borderColor = const Color(0xFF10B981).withValues(alpha: 0.25);
        timelineColor = const Color(0xFF10B981);
        itemBg = Colors.white;
        itemBorder = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF0F172A);
        subTextColor = const Color(0xFF64748B);
        viewAllBg = const Color(0xFFD1FAE5);
        viewAllText = const Color(0xFF059669);
        break;
      case 3:
        cardBg = const [Color(0xFFFAF5FF), Color(0xFFF3E8FF)];
        borderColor = const Color(0xFF9333EA).withValues(alpha: 0.20);
        timelineColor = const Color(0xFF9333EA);
        itemBg = Colors.white;
        itemBorder = const Color(0xFFE9D5FF);
        textColor = const Color(0xFF0F172A);
        subTextColor = const Color(0xFF64748B);
        viewAllBg = const Color(0xFFF3E8FF);
        viewAllText = const Color(0xFF7E22CE);
        break;
      case 4:
        cardBg = const [Color(0xFF04151B), Color(0xFF0B252E)];
        borderColor = const Color(0xFF14B8A6).withValues(alpha: 0.35);
        timelineColor = const Color(0xFF14B8A6);
        itemBg = const Color(0xFF071E25);
        itemBorder = const Color(0xFF14B8A6).withValues(alpha: 0.35);
        textColor = Colors.white;
        subTextColor = Colors.white70;
        viewAllBg = const Color(0xFF0F323D);
        viewAllText = const Color(0xFF2DD4BF);
        break;
      case 5:
        cardBg = const [Color(0xFFFFFBEB), Color(0xFFFEF3C7)];
        borderColor = const Color(0xFFF59E0B).withValues(alpha: 0.25);
        timelineColor = const Color(0xFFF59E0B);
        itemBg = Colors.white;
        itemBorder = const Color(0xFFFDE68A);
        textColor = const Color(0xFF0F172A);
        subTextColor = const Color(0xFF64748B);
        viewAllBg = const Color(0xFFFEF3C7);
        viewAllText = const Color(0xFFD97706);
        break;
      case 6:
        cardBg = const [Color(0xFFF0F9FF), Color(0xFFE0F2FE)];
        borderColor = const Color(0xFF0284C7).withValues(alpha: 0.25);
        timelineColor = const Color(0xFF0284C7);
        itemBg = Colors.white;
        itemBorder = const Color(0xFFBAE6FD);
        textColor = const Color(0xFF0F172A);
        subTextColor = const Color(0xFF64748B);
        viewAllBg = const Color(0xFFE0F2FE);
        viewAllText = const Color(0xFF0284C7);
        break;
      case 7:
        cardBg = const [Color(0xFFFDF2F8), Color(0xFFFCE7F3)];
        borderColor = const Color(0xFFEC4899).withValues(alpha: 0.22);
        timelineColor = const Color(0xFFEC4899);
        itemBg = Colors.white;
        itemBorder = const Color(0xFFFBCFE8);
        textColor = const Color(0xFF0F172A);
        subTextColor = const Color(0xFF64748B);
        viewAllBg = const Color(0xFFFCE7F3);
        viewAllText = const Color(0xFFDB2777);
        break;
      case 8:
        cardBg = const [Color(0xFF121214), Color(0xFF1E1E22)];
        borderColor = const Color(0xFF3F3F46);
        timelineColor = const Color(0xFFEF4444);
        itemBg = const Color(0xFF18181B);
        itemBorder = const Color(0xFF27272A);
        textColor = Colors.white;
        subTextColor = Colors.white60;
        viewAllBg = const Color(0xFF27272A);
        viewAllText = Colors.white70;
        break;
      case 0:
      default:
        cardBg = const [Color(0xFFFFFFFF), Color(0xFFF8FAFC)];
        borderColor = const Color(0xFFE2E8F0);
        timelineColor = const Color(0xFF2563EB);
        itemBg = const Color(0xFFF8FAFC);
        itemBorder = const Color(0xFFE2E8F0);
        textColor = const Color(0xFF0F172A);
        subTextColor = const Color(0xFF64748B);
        viewAllBg = const Color(0xFFEFF6FF);
        viewAllText = const Color(0xFF2563EB);
        break;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: cardBg,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            if (isGreenLeaves)
              Positioned.fill(
                child: CustomPaint(
                  painter: BotanicalLeavesPainter(leafColor: timelineColor),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Lịch sử gần đây',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: widget.onViewAllTransactions ??
                            () => _push(ReportScreen(userId: widget.userId)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: viewAllBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Xem tất cả',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: viewAllText,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded,
                                  size: 12, color: viewAllText),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (recentTxs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Chưa có giao dịch trong $_periodLabel',
                          style: TextStyle(fontSize: 13, color: subTextColor),
                        ),
                      ),
                    )
                  else
                    for (int i = 0; i < recentTxs.length; i++) ...[
                      _buildTimelineTxItem(
                        tx: recentTxs[i],
                        isLast: i == recentTxs.length - 1,
                        timelineColor: timelineColor,
                        itemBg: itemBg,
                        itemBorder: itemBorder,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        isCyberHex: isCyberHex,
                        isStarTimeline: isStarTimeline,
                        isAmberWarm: isAmberWarm,
                      ),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineTxItem({
    required TransactionModel tx,
    required bool isLast,
    required Color timelineColor,
    required Color itemBg,
    required Color itemBorder,
    required Color textColor,
    required Color subTextColor,
    required bool isCyberHex,
    required bool isStarTimeline,
    required bool isAmberWarm,
  }) {
    final isIncome = FinanceSummary.isIncome(tx);
    final isExpense = FinanceSummary.isExpense(tx);
    final amountColor = isIncome
        ? const Color(0xFF10B981)
        : isExpense
            ? const Color(0xFFEF4444)
            : const Color(0xFF3B82F6);
    final amountPrefix = isIncome ? '+' : isExpense ? '-' : '';
    final ownerLabel = tx.ownerName ??
        (tx.tags.contains('Vợ') ? 'Vợ' : tx.tags.contains('Chồng') ? 'Chồng' : null);
    final dateStr = DateFormat('dd/MM/yyyy')
        .format(DateTime.fromMillisecondsSinceEpoch(tx.date));
    final iconChar = CategoryIconHelper.resolveTransactionIcon(
      transactionType: tx.type,
      categoryIcon: tx.categoryIcon,
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned(
                    top: 14,
                    bottom: 0,
                    child: Container(
                      width: 1.5,
                      color: timelineColor.withValues(alpha: 0.35),
                    ),
                  ),
                Positioned(
                  top: 14,
                  child: isStarTimeline
                      ? Icon(Icons.star_rounded, size: 14, color: timelineColor)
                      : Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: timelineColor,
                            boxShadow: [
                              BoxShadow(
                                color: timelineColor.withValues(alpha: 0.4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TransactionDetailScreen(
                      userId: widget.userId,
                      transaction: tx,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
                decoration: BoxDecoration(
                  color: itemBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: itemBorder, width: 1),
                ),
                child: Row(
                  children: [
                    if (isCyberHex)
                      SizedBox(
                        width: 34,
                        height: 34,
                        child: CustomPaint(
                          painter: HexagonBorderPainter(
                            strokeColor: const Color(0xFF06B6D4),
                            fillColor:
                                const Color(0xFF06B6D4).withValues(alpha: 0.15),
                          ),
                          child: Center(
                            child: Text(iconChar,
                                style: const TextStyle(fontSize: 16)),
                          ),
                        ),
                      )
                    else if (isAmberWarm)
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              const Color(0xFFF59E0B).withValues(alpha: 0.20),
                          border: Border.all(
                              color: const Color(0xFFF59E0B), width: 1.5),
                        ),
                        child: Center(
                          child: Text(iconChar,
                              style: const TextStyle(fontSize: 16)),
                        ),
                      )
                    else
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: timelineColor.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(iconChar,
                              style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.note?.isNotEmpty == true
                                ? tx.note!
                                : (tx.categoryName ?? 'Giao dịch'),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(children: [
                            Flexible(
                              child: Text(
                                tx.categoryName ?? 'Chưa phân loại',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: subTextColor),
                              ),
                            ),
                            if (ownerLabel != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: timelineColor.withValues(alpha: .12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(ownerLabel,
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: timelineColor)),
                              ),
                            ],
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              '$amountPrefix${NumberFormat('#,##0', 'vi_VN').format(tx.amount)} đ',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: amountColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: subTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // HELPERS
  // -------------------------------------------------------------
  Widget _buildSpaceMiniCard(
      IconData icon, String label, String value, Color accent, bool isLight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.white
            : const Color(0xFF0B1428).withValues(alpha: .78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: .28)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: accent, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isLight ? const Color(0xFF64748B) : Colors.white60,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isLight ? const Color(0xFF0F172A) : Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillLink(String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: const Color(0xFF2563EB).withValues(alpha: .10),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5.5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 13, color: const Color(0xFF2563EB)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback(String name) => Container(
        color: const Color(0xFF0EA5E9),
        alignment: Alignment.center,
        child: Text(
          name.trim().isEmpty ? 'H' : name.trim()[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      );

  List<Color> _walletColors(String? code, bool isDark) {
    final key = (code ?? '').toLowerCase();
    if (key.contains('tech') || key == 'tcb') {
      return const [Color(0xFF7F1D1D), Color(0xFFDC2626), Color(0xFFEF4444)];
    }
    if (key.contains('vp') || key == 'vpb') {
      return const [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF10B981)];
    }
    if (key.contains('mb')) {
      return const [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF3B82F6)];
    }
    if (key.contains('vcb') || key.contains('vietcom')) {
      return const [Color(0xFF064E3B), Color(0xFF059669), Color(0xFF14B8A6)];
    }
    if (key.contains('momo')) {
      return const [Color(0xFF701A75), Color(0xFFA21CAF), Color(0xFFD946EF)];
    }
    if (key.contains('bidv')) {
      return const [Color(0xFF064E3B), Color(0xFF0D9488), Color(0xFF10B981)];
    }
    return isDark
        ? const [Color(0xFF0F172A), Color(0xFF1E3A5F), Color(0xFF0284C7)]
        : const [Color(0xFF0F4C81), Color(0xFF0284C7), Color(0xFF38BDF8)];
  }
}
