import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/utils/date_filter.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/widgets/custom_date_picker_dialog.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../../data/models/finance_models.dart';
import '../../state/dashboard_provider.dart';
import '../../state/more_provider.dart';
import '../../state/budget_provider.dart';
import '../../state/widget_style_controller.dart';
import 'dashboard_theme_painters.dart';
import '../budget/budget_screen.dart';
import '../notification/notification_screen.dart';
import '../transaction/add_transaction_page.dart';
import '../transaction/transaction_detail_screen.dart';
import '../wallet/wallet_screen.dart';
import '../asset/asset_screen.dart';
import '../loan/loan_screen.dart';
import '../category/category_screen.dart';
import '../report/report_screen.dart';

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
  bool _obscureBalance = false;
  bool _isBudgetExpanded = false;
  int _selectedWealthTab = 0; // 0: Ví & Thẻ, 1: Đầu tư, 2: Cho vay
  DateTime _selectedDate = DateTime.now();
  String _dateLabel =
      'Hôm nay (${DateFormat('dd/MM').format(DateTime.now())})';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DashboardProvider>().load(widget.userId);
      context.read<MoreProvider>().load(widget.userId);
      context.read<BudgetProvider>().load(widget.userId);
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
          _dateLabel = 'Hôm nay (${DateFormat('dd/MM').format(picked)})';
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

  void _openHeroThemePicker(BuildContext context) {
    final styleCtrl = context.read<WidgetStyleController>();
    final currentStyle = styleCtrl.assetStyle;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.paddingOf(ctx).bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đổi giao diện Tổng tài sản',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.red, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              for (final preset in WidgetStyleController.assetPresets)
                GestureDetector(
                  onTap: () {
                    styleCtrl.setAssetStyle(preset.id);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: preset.gradientColors,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: currentStyle == preset.id
                            ? const Color(0xFF38BDF8)
                            : Colors.white.withValues(alpha: 0.15),
                        width: currentStyle == preset.id ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: preset.accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  preset.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: preset.isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  preset.subtitle,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: preset.isDark
                                        ? Colors.white70
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (currentStyle == preset.id)
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF38BDF8), size: 20),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
          child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            provider.load(widget.userId);
            context.read<MoreProvider>().load(widget.userId);
            context.read<BudgetProvider>().load(widget.userId);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, MediaQuery.paddingOf(context).bottom + 104),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(isDark),
                const SizedBox(height: 16),
                _buildHeroCard(provider, totalBalance, income, expense, netFlow, isDark),
                const SizedBox(height: 22),
                _buildBudgetSection(isDark),
                const SizedBox(height: 22),
                _buildHealthScoreCard(d, isDark),
                const SizedBox(height: 24),
                _buildWealthTabsSection(d, isDark),
                const SizedBox(height: 24),
                _buildRecentTransactionsSection(txList, isDark),
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
                'Chào, ${widget.userName.isNotEmpty ? widget.userName : 'Hoà Trần'}',
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
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.8, -0.6),
              radius: 1.2,
              colors: [
                const Color(0xFF6366F1).withValues(alpha: 0.22),
                Colors.transparent,
              ],
            ),
          ),
        );
    }
  }

  Widget _buildHeroCard(DashboardProvider provider, num totalBalance, num income,
      num expense, num netFlow, bool isDark) {
    final styleCtrl = context.watch<WidgetStyleController>();
    final assetStyle = styleCtrl.assetStyle;
    final preset = WidgetStyleController.assetPresets.firstWhere(
      (p) => p.id == assetStyle,
      orElse: () => WidgetStyleController.assetPresets[0],
    );
    final isLightCard = assetStyle == 5;
    final cardPrimary = preset.accentColor;
    final cardBgGradient = preset.gradientColors;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cardBgGradient,
        ),
        border: Border.all(
          color: isLightCard
              ? const Color(0xFFCBD5E1)
              : Colors.white.withValues(alpha: 0.16),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isLightCard
                ? const Color(0xFF64748B).withValues(alpha: 0.15)
                : cardPrimary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: _buildThemeBackgroundGraphic(assetStyle, cardPrimary),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Top Header Row: Title on Left, Dropdown Scope + Date Pill + Theme Palette on Right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: isLightCard
                                  ? const Color(0xFF3B82F6).withValues(alpha: 0.14)
                                  : Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 13,
                              color: isLightCard
                                  ? const Color(0xFF2563EB)
                                  : Colors.white,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'TỔNG TÀI SẢN',
                            style: TextStyle(
                              color: isLightCard
                                  ? const Color(0xFF334155)
                                  : Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      // Actions: Scope Dropdown + Date Pill + Theme Palette
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Scope dropdown pill
                          _buildScopeDropdownPill(provider, isLightCard),
                          const SizedBox(width: 6),
                          // Date filter pill
                          _buildDateFilterPill(isLightCard),
                          const SizedBox(width: 6),
                          // Theme button
                          _buildThemeSwitcherButton(isLightCard),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 2. Balance row with tiny eye button right next to it
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _obscureBalance
                                ? '•••••••• đ'
                                : Formatters.formatCurrency(totalBalance),
                            style: TextStyle(
                              color: isLightCard
                                  ? const Color(0xFF0F172A)
                                  : Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _obscureBalance = !_obscureBalance);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: isLightCard
                                ? Colors.black.withValues(alpha: 0.08)
                                : Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _obscureBalance
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: isLightCard
                                ? const Color(0xFF475569)
                                : Colors.white.withValues(alpha: 0.90),
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 3. 3-Stat Subbar (Thu vào | Chi ra | Dòng tiền)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isLightCard
                          ? Colors.white.withValues(alpha: 0.85)
                          : Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isLightCard
                            ? const Color(0xFFCBD5E1)
                            : Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildColumnStat(
                            'Thu vào',
                            Formatters.formatCurrency(income),
                            const Color(0xFF10B981),
                            Icons.check_circle_outline,
                            isLightCard,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: isLightCard ? Colors.black12 : Colors.white12,
                        ),
                        Expanded(
                          child: _buildColumnStat(
                            'Chi ra',
                            Formatters.formatCurrency(expense),
                            const Color(0xFFEF4444),
                            Icons.arrow_upward_rounded,
                            isLightCard,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: isLightCard ? Colors.black12 : Colors.white12,
                        ),
                        Expanded(
                          child: _buildColumnStat(
                            'Dòng tiền',
                            Formatters.formatCurrency(netFlow),
                            const Color(0xFF38BDF8),
                            Icons.sync_alt_rounded,
                            isLightCard,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Subtle separator
                  Container(
                    height: 0.8,
                    color: isLightCard
                        ? Colors.black.withValues(alpha: 0.06)
                        : Colors.white.withValues(alpha: 0.12),
                  ),
                  const SizedBox(height: 12),

                  // 5. 4 Circular Quick Action Buttons Inside Hero Card
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeroRoundAction(
                        label: 'Ghi chép',
                        icon: Icons.edit_calendar_rounded,
                        glowColor: const Color(0xFF6366F1),
                        gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        isLightCard: isLightCard,
                        onTap: () => _push(AddTransactionPage(userId: widget.userId)),
                      ),
                      _buildHeroRoundAction(
                        label: 'Danh mục',
                        icon: Icons.grid_view_rounded,
                        glowColor: const Color(0xFF10B981),
                        gradient: const [Color(0xFF059669), Color(0xFF10B981)],
                        isLightCard: isLightCard,
                        onTap: () => _push(CategoryScreen(userId: widget.userId)),
                      ),
                      _buildHeroRoundAction(
                        label: 'Báo cáo',
                        icon: Icons.donut_large_rounded,
                        glowColor: const Color(0xFFF59E0B),
                        gradient: const [Color(0xFFD97706), Color(0xFFF59E0B)],
                        isLightCard: isLightCard,
                        onTap: () => _push(ReportScreen(userId: widget.userId)),
                      ),
                      _buildHeroRoundAction(
                        label: 'Ví & Thẻ',
                        icon: Icons.account_balance_wallet_rounded,
                        glowColor: const Color(0xFF0EA5E9),
                        gradient: const [Color(0xFF0284C7), Color(0xFF38BDF8)],
                        isLightCard: isLightCard,
                        onTap: () => _push(WalletScreen(userId: widget.userId)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeDropdownPill(DashboardProvider provider, bool isLightCard) {
    final current = provider.selectedOwner;
    final label = current == OwnerFilter.husband
        ? 'Chồng'
        : (current == OwnerFilter.wife ? 'Vợ' : 'Tất cả');
    final icon = current == OwnerFilter.husband
        ? Icons.person_rounded
        : (current == OwnerFilter.wife
            ? Icons.person_outline_rounded
            : Icons.people_alt_rounded);

    return PopupMenuButton<OwnerFilter>(
      tooltip: 'Lọc chủ sở hữu',
      offset: const Offset(0, 30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isLightCard
              ? const Color(0xFFCBD5E1)
              : Colors.white.withValues(alpha: 0.20),
        ),
      ),
      color: isLightCard ? Colors.white : const Color(0xFF1E1B4B),
      onSelected: (filter) {
        HapticFeedback.selectionClick();
        provider.setOwnerFilter(filter);
      },
      itemBuilder: (context) => [
        _buildScopeMenuItem(OwnerFilter.all, 'Tất cả', Icons.people_alt_rounded,
            current == OwnerFilter.all, isLightCard),
        _buildScopeMenuItem(OwnerFilter.husband, 'Chồng', Icons.person_rounded,
            current == OwnerFilter.husband, isLightCard),
        _buildScopeMenuItem(OwnerFilter.wife, 'Vợ', Icons.person_outline_rounded,
            current == OwnerFilter.wife, isLightCard),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
        decoration: BoxDecoration(
          color: isLightCard
              ? Colors.black.withValues(alpha: 0.05)
              : const Color(0xFF1E1B4B).withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLightCard
                ? const Color(0xFFCBD5E1)
                : Colors.white.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 12,
                color: isLightCard ? const Color(0xFF2563EB) : Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isLightCard ? const Color(0xFF0F172A) : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isLightCard ? const Color(0xFF64748B) : Colors.white70,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<OwnerFilter> _buildScopeMenuItem(OwnerFilter value, String title,
      IconData icon, bool isSelected, bool isLightCard) {
    return PopupMenuItem<OwnerFilter>(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : (isLightCard ? const Color(0xFF64748B) : Colors.white70)),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : (isLightCard ? const Color(0xFF0F172A) : Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterPill(bool isLightCard) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openDateFilter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
        decoration: BoxDecoration(
          color: isLightCard
              ? Colors.black.withValues(alpha: 0.05)
              : const Color(0xFF1E1B4B).withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLightCard
                ? const Color(0xFFCBD5E1)
                : Colors.white.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _dateLabel,
              style: TextStyle(
                color: isLightCard ? const Color(0xFF0F172A) : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isLightCard ? const Color(0xFF64748B) : Colors.white70,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSwitcherButton(bool isLightCard) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        _openHeroThemePicker(context);
      },
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: isLightCard
              ? Colors.black.withValues(alpha: 0.05)
              : const Color(0xFF1E1B4B).withValues(alpha: 0.65),
          shape: BoxShape.circle,
          border: Border.all(
            color: isLightCard
                ? const Color(0xFFCBD5E1)
                : Colors.white.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        child: Icon(
          Icons.palette_outlined,
          color: isLightCard ? const Color(0xFF2563EB) : Colors.white,
          size: 14,
        ),
      ),
    );
  }

  Widget _buildHeroRoundAction({
    required String label,
    required IconData icon,
    required Color glowColor,
    required List<Color> gradient,
    required bool isLightCard,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Center(
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isLightCard
                  ? const Color(0xFF1E293B)
                  : Colors.white.withValues(alpha: 0.90),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnStat(
      String label, String value, Color color, IconData icon, bool isLightCard) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isLightCard
                    ? const Color(0xFF64748B)
                    : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetSection(bool isDark) {
    final budgetProvider = context.watch<BudgetProvider>();
    final budgets = budgetProvider.budgetsWithSpent;

    final int totalLimit = budgets.isNotEmpty
        ? budgets.fold(0, (sum, b) => sum + b.budget.limitAmount)
        : 10000000;
    final int totalSpent = budgets.isNotEmpty
        ? budgets.fold(0, (sum, b) => sum + b.spentAmount)
        : 6450000;

    final double rate = totalLimit > 0
        ? (totalSpent / totalLimit).clamp(0.0, 1.0)
        : 0.0;
    final int percent = (rate * 100).toInt();
    final int remaining = totalLimit - totalSpent;
    final String monthText = DateFormat('MM/yyyy').format(DateTime.now());
    final isOver = totalSpent > totalLimit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Title Header with Unified Pill Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hạn mức & Ngân sách chi tiêu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            FinoraSectionActionPill(
              label: 'Quản lý',
              onTap: () => _push(BudgetScreen(userId: widget.userId)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Dual-Layer Expandable Budget Card (matching user reference image)
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _isBudgetExpanded = !_isBudgetExpanded);
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0C1324),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFF1E293B),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // TOP LAYER: Floating Light/Squircle Card (Like BMW i7 card)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Thumbnail icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.pie_chart_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),

                      // Info Left
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isOver
                                        ? const Color(0xFFFEE2E2)
                                        : const Color(0xFFD1FAE5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isOver ? '● Vượt hạn mức' : '● Đang kiểm soát',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isOver
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFF059669),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Ngân sách Tháng $monthText',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: Formatters.formatCurrency(totalSpent),
                                    style: const TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' / ${Formatters.formatCurrency(totalLimit)}',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white60
                                          : const Color(0xFF64748B),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Metric Right + Expand/Collapse Button
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Đã dùng ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white60
                                      : const Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                '$percent%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: isOver
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF2563EB),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Circular toggle button
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2563EB),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isBudgetExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF475569)
                                    : const Color(0xFFCBD5E1),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              '${budgets.isNotEmpty ? budgets.length : 2} HẠN MỨC',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF475569),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // BOTTOM LAYER: Connected Dark Glass with Neon Glowing Progress
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section Subtitle
                      const Text(
                        'TIẾN ĐỘ CHI TIÊU',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Percent + Remaining row with fire badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$percent%',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                remaining >= 0
                                    ? 'Khả dụng ${Formatters.formatCurrency(remaining)}'
                                    : 'Vượt ${Formatters.formatCurrency(-remaining)}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: remaining >= 0
                                      ? const Color(0xFF38BDF8)
                                      : const Color(0xFFF87171),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.20),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Text('🔥', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Glowing Neon Progress Slider
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.centerLeft,
                        children: [
                          // Background Track
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          // Gradient Progress Bar
                          FractionallySizedBox(
                            widthFactor: rate.clamp(0.02, 1.0),
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF06B6D4),
                                    Color(0xFF6366F1),
                                    Color(0xFFF59E0B),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF06B6D4).withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Glowing Indicator Node
                          Align(
                            alignment: Alignment(-1.0 + (rate.clamp(0.05, 0.95) * 2.0), 0.0),
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF38BDF8),
                                  width: 3.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // EXPANDABLE CONTENT (List of categories)
                      if (_isBudgetExpanded) ...[
                        const SizedBox(height: 16),
                        Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'CHI TIẾT NGÂN SÁCH DANH MỤC',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: Colors.white60,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (budgets.isEmpty)
                          Column(
                            children: [
                              _buildBudgetCategoryItem(
                                title: 'Chi tiêu sinh hoạt',
                                spent: 3820000,
                                limit: 5000000,
                                icon: Icons.shopping_bag_outlined,
                                color: const Color(0xFF10B981),
                              ),
                              const SizedBox(height: 8),
                              _buildBudgetCategoryItem(
                                title: 'Ăn uống & Cà phê',
                                spent: 2630000,
                                limit: 5000000,
                                icon: Icons.restaurant_outlined,
                                color: const Color(0xFFF59E0B),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: budgets.map((b) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: _buildBudgetCategoryItem(
                                  title: b.budget.categoryName,
                                  spent: b.spentAmount,
                                  limit: b.budget.limitAmount,
                                  icon: Icons.pie_chart_outline_rounded,
                                  color: const Color(0xFF38BDF8),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetCategoryItem({
    required String title,
    required int spent,
    required int limit,
    required IconData icon,
    required Color color,
  }) {
    final double itemRate = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final int itemPercent = (itemRate * 100).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Text(
                '${Formatters.formatCurrency(spent)} / ${Formatters.formatCurrency(limit)} ($itemPercent%)',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: itemRate,
              minHeight: 4,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
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

  Widget _buildWealthTabsSection(DashboardData d, bool isDark) {
    final wallets = d.wallets;
    final more = context.watch<MoreProvider>();
    final realAssets = more.assets;
    final realLoans = more.loans;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _wealthTabPill(0, 'Ví & Thẻ (${wallets.length})', isDark),
                      _wealthTabPill(1, 'Đầu tư (${realAssets.length})', isDark),
                      _wealthTabPill(2, 'Cho vay (${realLoans.length})', isDark),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FinoraSectionActionPill(
              label: 'Xem tất cả',
              onTap: () {
                if (_selectedWealthTab == 0) {
                  if (widget.onViewWallets != null) {
                    widget.onViewWallets!();
                  } else {
                    _push(WalletScreen(userId: widget.userId));
                  }
                } else if (_selectedWealthTab == 1) {
                  _push(AssetScreen(userId: widget.userId));
                } else {
                  _push(LoanScreen(userId: widget.userId));
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 124,
          child: _selectedWealthTab == 0
              ? _buildWalletsList(wallets, isDark)
              : (_selectedWealthTab == 1
                  ? _buildInvestmentsList(realAssets, isDark)
                  : _buildLoansList(realLoans, isDark)),
        ),
      ],
    );
  }

  Widget _wealthTabPill(int index, String title, bool isDark) {
    final isSelected = _selectedWealthTab == index;
    final gradient = index == 0
        ? const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)])
        : (index == 1
            ? const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10B981)])
            : const LinearGradient(
                colors: [Color(0xFFD97706), Color(0xFFF59E0B)]));

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedWealthTab = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: isSelected
              ? null
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white60 : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletsList(List<Wallet> wallets, bool isDark) {
    return ListView.separated(
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
    );
  }

  Widget _buildInvestmentsList(List<Asset> assets, bool isDark) {
    if (assets.isEmpty) {
      return GestureDetector(
        onTap: () => _push(AssetScreen(userId: widget.userId)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chưa có tài sản đầu tư nào',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const Text(
                    'Nhấn để thêm Vàng, Cổ phiếu, BĐS, Tiết kiệm...',
                    style: TextStyle(fontSize: 11, color: Color(0xFF10B981)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: assets.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final asset = assets[index];
        final val = asset.marketValue > 0 ? asset.marketValue : asset.purchasePrice;
        final profitText = asset.profitLossPercent != 0.0
            ? '${asset.profitLossPercent > 0 ? '+' : ''}${asset.profitLossPercent.toStringAsFixed(1)}%'
            : (asset.unit != null ? '${asset.quantity} ${asset.unit}' : 'Đang nắm giữ');

        return _buildGenericMiniCard(
          title: asset.name,
          amount: Formatters.formatCurrency(val),
          subtext: profitText,
          emoji: asset.assetIcon ?? '📈',
          owner: 'Tài sản',
          isDark: isDark,
          subtextColor: asset.profitLossPercent >= 0
              ? const Color(0xFF10B981)
              : const Color(0xFFEF4444),
          onTap: () => _push(AssetScreen(userId: widget.userId)),
        );
      },
    );
  }

  Widget _buildLoansList(List<Loan> loans, bool isDark) {
    if (loans.isEmpty) {
      return GestureDetector(
        onTap: () => _push(LoanScreen(userId: widget.userId)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: Color(0xFFF59E0B)),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chưa có khoản cho vay / nợ nào',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const Text(
                    'Nhấn để thêm sổ tay ghi nợ & cho vay...',
                    style: TextStyle(fontSize: 11, color: Color(0xFFF59E0B)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: loans.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final loan = loans[index];
        final remaining = loan.amount - loan.paidAmount;
        final isLent = loan.type == 'lent';
        final sub = loan.dueDate != null
            ? 'Hạn: ${DateFormat('dd/MM/yy').format(DateTime.fromMillisecondsSinceEpoch(loan.dueDate!))}'
            : (isLent ? 'Đã cho vay' : 'Đang nợ');

        return _buildGenericMiniCard(
          title: loan.personName.isNotEmpty
              ? loan.personName
              : (loan.name ?? 'Khoản vay'),
          amount: Formatters.formatCurrency(remaining),
          subtext: sub,
          emoji: isLent ? '🤝' : '💳',
          owner: isLent ? 'Cho vay' : 'Vay nợ',
          isDark: isDark,
          subtextColor: isLent
              ? const Color(0xFF059669)
              : const Color(0xFFE11D48),
          onTap: () => _push(LoanScreen(userId: widget.userId)),
        );
      },
    );
  }

  Widget _buildGenericMiniCard({
    required String title,
    required String amount,
    required String subtext,
    required String emoji,
    required String owner,
    required bool isDark,
    required Color subtextColor,
    required VoidCallback onTap,
  }) {
    final ownerLabel = owner == 'husband'
        ? 'Chồng'
        : (owner == 'wife'
            ? 'Vợ'
            : (owner == 'Cho vay' || owner == 'Vay nợ' || owner == 'Tài sản'
                ? owner
                : 'Chung'));
    final tagBg = owner == 'Vay nợ'
        ? const Color(0xFFFEE2E2)
        : (owner == 'wife'
            ? const Color(0xFFFCE7F3)
            : const Color(0xFFDBEAFE));
    final tagColor = owner == 'Vay nợ'
        ? const Color(0xFFDC2626)
        : (owner == 'wife'
            ? const Color(0xFFDB2777)
            : const Color(0xFF2563EB));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 175,
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
                Text(emoji, style: const TextStyle(fontSize: 17)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tagBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ownerLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: tagColor,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      subtext,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: subtextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
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
            FinoraSectionActionPill(
              label: 'Tất cả',
              onTap: () {
                if (widget.onViewAllTransactions != null) {
                  widget.onViewAllTransactions!();
                }
              },
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
            LiquidGlassCircleIcon(
              emoji: CategoryIconHelper.resolveTransactionIcon(
                transactionType: tx.type,
                categoryIcon: tx.categoryIcon,
                categoryName: tx.categoryName,
                note: tx.note,
              ),
              tint: color,
              size: 44,
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
                    '${tx.walletName ?? 'Tiết Kiệm Chồng'} • ${DateFormat('HH:mm').format(txDate)}',
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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    prefix + Formatters.formatCurrency(tx.amount),
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
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
}

/// Unified Pill Action Button for section headers (e.g. "Quản lý >", "Xem tất cả >", "Tất cả >")
class FinoraSectionActionPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const FinoraSectionActionPill({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4.5),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF38BDF8).withValues(alpha: 0.12)
              : const Color(0xFF0284C7).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? const Color(0xFF38BDF8).withValues(alpha: 0.35)
                : const Color(0xFF0284C7).withValues(alpha: 0.22),
            width: 0.9,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
            ),
          ],
        ),
      ),
    );
  }
}
