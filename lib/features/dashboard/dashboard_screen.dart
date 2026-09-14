import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/utils/date_filter.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/widgets/custom_date_picker_dialog.dart';
import '../../core/widgets/morph_icon.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/widgets/subject_filter_pill.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../../data/models/finance_models.dart';
import '../../state/dashboard_provider.dart';
import '../../state/more_provider.dart';
import '../../state/budget_provider.dart';
import '../../state/widget_style_controller.dart';
import '../../state/theme_studio_controller.dart';
import '../../state/transaction_provider.dart';
import '../../data/services/finora_nlp_engine.dart';
import 'dashboard_theme_painters.dart';
import '../ai/ai_advisor_screen.dart';
import '../budget/budget_screen.dart';
import '../notification/notification_screen.dart';
import '../transaction/add_transaction_page.dart';
import '../transaction/transaction_detail_screen.dart';
import '../wallet/wallet_screen.dart';
import '../asset/asset_screen.dart';
import '../loan/loan_screen.dart';
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
  final String _dateLabel = 'Hôm nay';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.read<DashboardProvider>();
    final currentOption = provider.selectedDateFilter;

    final result = await showModalBottomSheet<String>(
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
                    'Chọn mốc thời gian',
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
              _buildDateOptionTile(
                ctx,
                title: 'Hôm nay',
                subtitle: 'Số liệu thu chi trong ngày',
                icon: Icons.today_rounded,
                color: const Color(0xFF3B82F6),
                isSelected: currentOption == DateFilterOption.today &&
                    provider.customDate == null,
                isDark: isDark,
                onTap: () => Navigator.pop(ctx, 'today'),
              ),
              _buildDateOptionTile(
                ctx,
                title: 'Hôm qua',
                subtitle: 'Giao dịch ngày hôm qua',
                icon: Icons.history_toggle_off_rounded,
                color: const Color(0xFF6366F1),
                isSelected: currentOption == DateFilterOption.yesterday &&
                    provider.customDate == null,
                isDark: isDark,
                onTap: () => Navigator.pop(ctx, 'yesterday'),
              ),
              _buildDateOptionTile(
                ctx,
                title: 'Tuần này',
                subtitle: 'Tính từ đầu tuần đến nay',
                icon: Icons.date_range_rounded,
                color: const Color(0xFF0EA5E9),
                isSelected: currentOption == DateFilterOption.thisWeek &&
                    provider.customDate == null,
                isDark: isDark,
                onTap: () => Navigator.pop(ctx, 'thisWeek'),
              ),
              _buildDateOptionTile(
                ctx,
                title: 'Tháng này',
                subtitle:
                    'Tháng hiện tại (${DateTime.now().month}/${DateTime.now().year})',
                icon: Icons.calendar_month_rounded,
                color: const Color(0xFF10B981),
                isSelected: currentOption == DateFilterOption.thisMonth &&
                    provider.customDate == null,
                isDark: isDark,
                onTap: () => Navigator.pop(ctx, 'thisMonth'),
              ),
              _buildDateOptionTile(
                ctx,
                title: 'Năm nay',
                subtitle: 'Tổng hợp cả năm ${DateTime.now().year}',
                icon: Icons.calendar_today_rounded,
                color: const Color(0xFFF59E0B),
                isSelected: currentOption == DateFilterOption.thisYear &&
                    provider.customDate == null,
                isDark: isDark,
                onTap: () => Navigator.pop(ctx, 'thisYear'),
              ),
              _buildDateOptionTile(
                ctx,
                title: 'Chọn ngày cụ thể...',
                subtitle: provider.customDate != null
                    ? 'Đang chọn: ${DateFormat('dd/MM/yyyy').format(provider.customDate!)}'
                    : 'Xem số liệu của một ngày bất kỳ',
                icon: Icons.edit_calendar_rounded,
                color: const Color(0xFF8B5CF6),
                isSelected: provider.customDate != null,
                isDark: isDark,
                onTap: () => Navigator.pop(ctx, 'custom'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || result == null) return;

    if (result == 'today') {
      provider.setDateFilter(DateFilterOption.today);
    } else if (result == 'yesterday') {
      provider.setDateFilter(DateFilterOption.yesterday);
    } else if (result == 'thisWeek') {
      provider.setDateFilter(DateFilterOption.thisWeek);
    } else if (result == 'thisMonth') {
      provider.setDateFilter(DateFilterOption.thisMonth);
    } else if (result == 'thisYear') {
      provider.setDateFilter(DateFilterOption.thisYear);
    } else if (result == 'custom') {
      final picked = await CustomDatePickerSheet.show(context,
          initialDate: provider.customDate ?? _selectedDate);
      if (picked != null && mounted) {
        _selectedDate = picked;
        provider.setDateFilter(DateFilterOption.customDate, custom: picked);
      }
    }
  }

  Widget _buildDateOptionTile(
    BuildContext ctx, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.22 : 0.10)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
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
    final studio = context.watch<ThemeStudioController>();
    final d = provider.data;

    final totalBalance = d.totalWalletBalance;
    final income = d.periodIncome;
    final expense = d.periodExpense;
    final netFlow = d.periodNet;
    final txList = d.recentTransactions;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            provider.load(widget.userId);
            context.read<MoreProvider>().load(widget.userId);
            context.read<BudgetProvider>().load(widget.userId);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              studio.getCardPadding(studio.dashboardDensity) * 0.7,
              10,
              studio.getCardPadding(studio.dashboardDensity) * 0.7,
              136,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(isDark),
                const SizedBox(height: 16),
                _buildHeroCard(provider, totalBalance, income, expense, netFlow,
                    isDark, studio),
                const SizedBox(height: 14),
                _buildQuickActionsRow(isDark),
                if (studio.showQuickLog) ...[
                  const SizedBox(height: 12),
                  _buildAiQuickLogBar(isDark, studio),
                ],
                const SizedBox(height: 18),
                if (studio.showAiInsight) ...[
                  // 1. Đẩy widget Sức khoẻ AI lên trên (theo yêu cầu người dùng và chuẩn web)
                  _buildHealthScoreCard(d, isDark),
                  const SizedBox(height: 20),
                ],
                // 2. Widget Hạn mức & Ngân sách thiết kế gọn hơn, chuẩn dữ liệu web
                _buildBudgetSection(d, isDark),
                const SizedBox(height: 24),
                _buildWealthTabsSection(d, isDark),
                const SizedBox(height: 24),
                _buildRecentTransactionsSection(txList, isDark),
              ],
            ),
          ),
        ),
      ),
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
                const Color(0xFF005FEA).withValues(alpha: 0.22),
                Colors.transparent,
              ],
            ),
          ),
        );
    }
  }

  Widget _buildHeroCard(
      DashboardProvider provider,
      num totalBalance,
      num income,
      num expense,
      num netFlow,
      bool isDark,
      ThemeStudioController studio) {
    final styleCtrl = context.watch<WidgetStyleController>();
    final assetStyle = styleCtrl.assetStyle;
    final preset = WidgetStyleController.assetPresets.firstWhere(
      (p) => p.id == assetStyle,
      orElse: () => WidgetStyleController.assetPresets[0],
    );
    final isCustomStudioPalette =
        studio.palette != AppColorPalette.oceanicSapphire;
    final cardPrimary = isCustomStudioPalette
        ? studio.currentPaletteMeta.primary
        : preset.accentColor;
    final cardBgGradient = isCustomStudioPalette
        ? studio.currentPaletteMeta.heroGradient
        : preset.gradientColors;
    final isLightCard = !isCustomStudioPalette && assetStyle == 5;
    final cardPadding = studio.getCardPadding(studio.dashboardDensity);
    final cardRadius = studio.getCardRadius(studio.dashboardDensity);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
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
        boxShadow: studio.cardShadows(
          isLightCard ? const Color(0xFF64748B) : cardPrimary,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.20,
                  child: _buildThemeBackgroundGraphic(assetStyle, cardPrimary),
                ),
              ),
            ),
            // Top-right ambient light glow
            Positioned(
              top: -24,
              right: -24,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      cardPrimary.withValues(alpha: isLightCard ? 0.12 : 0.30),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Top Header Row: Title & badge on Left | Scope + Date filters on Right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Title
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4.5),
                            decoration: BoxDecoration(
                              color: isLightCard
                                  ? const Color(0xFF3B82F6)
                                      .withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 12,
                              color: isLightCard
                                  ? const Color(0xFF2563EB)
                                  : Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'TỔNG TÀI SẢN',
                            style: TextStyle(
                              color: isLightCard
                                  ? const Color(0xFF334155)
                                  : Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      // Actions: Scope Dropdown + Date Pill (Zero overflow risk)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildScopeDropdownPill(provider, isLightCard),
                          const SizedBox(width: 5),
                          _buildDateFilterPill(provider, isLightCard),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 2. Balance row + Eye toggle button + Theme button side by side
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
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
                      // Eye button
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _obscureBalance = !_obscureBalance);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(7.5),
                          decoration: BoxDecoration(
                            color: isLightCard
                                ? Colors.black.withValues(alpha: 0.07)
                                : Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isLightCard
                                  ? Colors.black.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.15),
                              width: 0.8,
                            ),
                          ),
                          child: MorphIcon(
                            icon: _obscureBalance
                                ? LucideIcons.eye_off
                                : LucideIcons.eye,
                            color: isLightCard
                                ? const Color(0xFF475569)
                                : Colors.white.withValues(alpha: 0.92),
                            size: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Theme palette button
                      _buildThemeSwitcherButton(isLightCard),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 3. 3-Stat Subbar (Thu vào | Chi ra | Dòng tiền)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                            Icons.arrow_downward_rounded,
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
                            Icons.swap_vert_rounded,
                            isLightCard,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsRow(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildQuickActionItem(
          label: 'Ghi chép',
          icon: Icons.edit_calendar_rounded,
          color: const Color(0xFF005FEA),
          bgColor: const Color(0xFFE0F2FE),
          isDark: isDark,
          isHero: true,
          onTap: () => _push(AddTransactionPage(userId: widget.userId)),
        ),
        _buildQuickActionItem(
          label: 'Ví & Thẻ',
          icon: Icons.account_balance_wallet_rounded,
          color: const Color(0xFF0EA5E9),
          bgColor: const Color(0xFFE0F2FE),
          isDark: isDark,
          onTap: () {
            if (widget.onViewWallets != null) {
              widget.onViewWallets!();
            } else {
              _push(WalletScreen(userId: widget.userId));
            }
          },
        ),
        _buildQuickActionItem(
          label: 'Báo cáo',
          icon: Icons.donut_large_rounded,
          color: const Color(0xFFD97706),
          bgColor: const Color(0xFFFEF3C7),
          isDark: isDark,
          onTap: () => _push(ReportScreen(userId: widget.userId)),
        ),
        _buildQuickActionItem(
          label: 'AI Finora',
          icon: Icons.auto_awesome_rounded,
          color: const Color(0xFF10B981),
          bgColor: const Color(0xFFD1FAE5),
          isDark: isDark,
          onTap: () => _push(AiAdvisorScreen(userId: widget.userId)),
        ),
      ],
    );
  }

  Widget _buildQuickActionItem({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required bool isDark,
    bool isHero = false,
    required VoidCallback onTap,
  }) {
    return _QuickActionItemWidget(
      label: label,
      icon: icon,
      color: color,
      bgColor: bgColor,
      isDark: isDark,
      isHero: isHero,
      onTap: onTap,
    );
  }

  Widget _buildAiQuickLogBar(bool isDark, ThemeStudioController studio) {
    final primary = studio.primaryColor;

    return InkWell(
      onTap: () => _showAiQuickLogModal(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF1E293B) : Colors.white)
              .withValues(alpha: isDark ? 0.92 : 0.98),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primary.withValues(alpha: isDark ? 0.32 : 0.18),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: isDark ? 0.12 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome_rounded, color: primary, size: 15),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Nhập nhanh với AI ("Ăn trưa 45k", "Đổ xăng 70k Momo")...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic_none_rounded, size: 13, color: primary),
                  const SizedBox(width: 3),
                  Text(
                    'Ghi nhanh',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAiQuickLogModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txProvider = context.read<TransactionProvider>();
    final controller = TextEditingController();
    List<SmartTransactionParsed> drafts = [];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final primary = context.read<ThemeStudioController>().primaryColor;

          void onAnalyze(String text) {
            final parsed = FinoraNlpEngine.extractTransactions(
              message: text,
              categories: txProvider.categories,
              wallets: txProvider.wallets,
            ).where((d) => d.type == 'income' || d.type == 'expense').toList();
            setModalState(() {
              drafts = parsed;
            });
          }

          return Container(
            padding: EdgeInsets.fromLTRB(
                16, 14, 16, MediaQuery.of(ctx).viewInsets.bottom + 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF94A3B8).withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.auto_awesome_rounded,
                          color: primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ghi chép siêu tốc bằng Finora AI',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Gõ câu nói tự nhiên, AI tự bóc tách số tiền, danh mục và tài khoản.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: Ăn trưa 45k Momo, Đổ xăng 70k VCB...',
                    hintStyle: const TextStyle(
                        fontSize: 13.5, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.send_rounded, color: primary),
                      onPressed: () => onAnalyze(controller.text),
                    ),
                  ),
                  onChanged: (val) => onAnalyze(val),
                  onSubmitted: (val) => onAnalyze(val),
                ),
                const SizedBox(height: 10),
                // Gợi ý câu mẫu
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      'Ăn trưa 45k',
                      'Cà phê sáng 35k Momo',
                      'Đổ xăng 70k VCB',
                      'Lương 25tr chuyển khoản',
                    ].map((sample) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () {
                            controller.text = sample;
                            onAnalyze(sample);
                          },
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              sample,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (drafts.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: primary.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline_rounded,
                                size: 16, color: primary),
                            const SizedBox(width: 6),
                            Text(
                              'AI đã hiểu (${drafts.length} giao dịch):',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...drafts.map((d) {
                          final isExpense = d.type == 'expense';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        d.note,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        '${d.categoryName ?? "Khác"} • ${d.walletName ?? "Ví chính"}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isExpense ? "-" : "+"}${formatVND(d.amount)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: isExpense
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      for (final draft in drafts) {
                        final cat = txProvider.categories.firstWhere(
                          (c) =>
                              FinoraNlpEngine.normalize(c.name) ==
                              FinoraNlpEngine.normalize(
                                  draft.categoryName ?? ''),
                          orElse: () => txProvider.categories.first,
                        );
                        final wal = txProvider.wallets.firstWhere(
                          (w) =>
                              FinoraNlpEngine.normalize(w.name) ==
                              FinoraNlpEngine.normalize(draft.walletName ?? ''),
                          orElse: () => txProvider.wallets.first,
                        );
                        await txProvider.createTransaction(
                          widget.userId,
                          TransactionModel(
                            userId: widget.userId,
                            amount: draft.amount,
                            type: draft.type,
                            date: draft.date,
                            note: draft.note,
                            categoryId: cat.id,
                            categoryName: cat.name,
                            categoryIcon: cat.icon,
                            categoryColor: cat.color,
                            categoryGroup: cat.categoryGroup,
                            walletId: wal.id,
                            walletName: wal.name,
                            owner: draft.owner ?? wal.owner,
                            ownerName: draft.ownerName ?? wal.ownerName,
                            creatorTag: 'Finora AI',
                            tags: ['Finora AI'],
                          ),
                        );
                      }
                      if (ctx.mounted) Navigator.pop(sheetCtx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Đã ghi chép thành công ${drafts.length} giao dịch vào sổ!'),
                            backgroundColor: const Color(0xFF059669),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Xác nhận lưu vào sổ',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScopeDropdownPill(DashboardProvider provider, bool isLightCard) {
    final current = provider.selectedOwner;
    final label = current == OwnerFilter.husband
        ? 'Chồng'
        : (current == OwnerFilter.wife ? 'Vợ' : 'Tất cả');
    final dotColor = current == OwnerFilter.husband
        ? const Color(0xFF173B70)
        : (current == OwnerFilter.wife
            ? const Color(0xFFDB2777)
            : (isLightCard ? const Color(0xFF6366F1) : Colors.white));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        _openOwnerFilterModal();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isLightCard
              ? Colors.black.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLightCard
                ? const Color(0xFFCBD5E1)
                : Colors.white.withValues(alpha: 0.20),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isLightCard ? const Color(0xFF0F172A) : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 1),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isLightCard ? const Color(0xFF64748B) : Colors.white70,
              size: 13,
            ),
          ],
        ),
      ),
    );
  }

  void _openOwnerFilterModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.read<DashboardProvider>();
    final current = provider.selectedOwner;

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
                    color: Colors.grey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chọn chủ sở hữu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded,
                          size: 18,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildOwnerFilterCardItem(
                ctx,
                filter: OwnerFilter.all,
                title: 'Tất cả thành viên',
                subtitle: 'Xem dữ liệu tổng hợp cả Vợ & Chồng',
                accentColor: const Color(0xFF6366F1),
                isSelected: current == OwnerFilter.all,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  provider.setOwnerFilter(OwnerFilter.all);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 10),
              _buildOwnerFilterCardItem(
                ctx,
                filter: OwnerFilter.husband,
                title: 'Chồng',
                subtitle: 'Chỉ xem ví và giao dịch của Chồng',
                accentColor: const Color(0xFF173B70),
                isSelected: current == OwnerFilter.husband,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  provider.setOwnerFilter(OwnerFilter.husband);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 10),
              _buildOwnerFilterCardItem(
                ctx,
                filter: OwnerFilter.wife,
                title: 'Vợ',
                subtitle: 'Chỉ xem ví và giao dịch của Vợ',
                accentColor: const Color(0xFFDB2777),
                isSelected: current == OwnerFilter.wife,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  provider.setOwnerFilter(OwnerFilter.wife);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOwnerFilterCardItem(
    BuildContext ctx, {
    required OwnerFilter filter,
    required String title,
    required String subtitle,
    required Color accentColor,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: isDark ? 0.20 : 0.10)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? accentColor
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: .30),
                    blurRadius: 7,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                          : (isDark ? Colors.white : const Color(0xFF1E293B)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterPill(DashboardProvider provider, bool isLightCard) {
    final rawLabel = provider.data.periodLabel.isNotEmpty
        ? provider.data.periodLabel
        : _dateLabel;

    // Shorten cleanly for the pill so it never truncates with ellipsis
    final String label;
    if (rawLabel.startsWith('Hôm nay')) {
      label = 'Hôm nay';
    } else if (rawLabel.startsWith('Hôm qua')) {
      label = 'Hôm qua';
    } else if (rawLabel.startsWith('Toàn bộ')) {
      label = 'Tất cả';
    } else if (rawLabel.startsWith('Tháng ')) {
      label = rawLabel.replaceFirst('Tháng ', 'T');
    } else if (rawLabel.length > 10) {
      label = rawLabel.substring(0, 10);
    } else {
      label = rawLabel;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openDateFilter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: isLightCard
              ? Colors.black.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLightCard
                ? const Color(0xFFCBD5E1)
                : Colors.white.withValues(alpha: 0.20),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 10,
              color: isLightCard ? const Color(0xFF2563EB) : Colors.white70,
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                color: isLightCard ? const Color(0xFF0F172A) : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 1),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isLightCard ? const Color(0xFF64748B) : Colors.white70,
              size: 13,
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
        padding: const EdgeInsets.all(7.5),
        decoration: BoxDecoration(
          color: isLightCard
              ? Colors.black.withValues(alpha: 0.07)
              : Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: isLightCard
                ? Colors.black.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.15),
            width: 0.8,
          ),
        ),
        child: Icon(
          Icons.palette_outlined,
          color: isLightCard ? const Color(0xFF2563EB) : Colors.white,
          size: 15,
        ),
      ),
    );
  }

  Widget _buildColumnStat(String label, String value, Color color,
      IconData icon, bool isLightCard) {
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
                color: isLightCard ? const Color(0xFF64748B) : Colors.white70,
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

  Widget _buildBudgetSection(DashboardData d, bool isDark) {
    final budgets = context.watch<BudgetProvider>().budgetsWithSpent;
    final totalLimit =
        budgets.fold<int>(0, (sum, b) => sum + b.budget.limitAmount);
    final totalSpent = budgets.fold<int>(0, (sum, b) => sum + b.spentAmount);
    final remaining = totalLimit - totalSpent;
    final progress =
        totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0.0;
    const accent = Color(0xFF0D9488);
    final percentInt = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0F262B), Color(0xFF131D24)]
              : const [Color(0xFFF0FDFA), Color(0xFFFFFFFF)],
        ),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.30 : 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.12 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.30),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.donut_large_rounded,
                  size: 19,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ngân sách chi tiêu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      budgets.isEmpty
                          ? 'Chưa thiết lập hạn mức'
                          : '$percentInt% ngân sách đã dùng',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: remaining < 0
                            ? const Color(0xFFE11D48)
                            : (isDark
                                ? const Color(0xFF2DD4BF)
                                : const Color(0xFF0D9488)),
                      ),
                    ),
                  ],
                ),
              ),
              FinoraSectionActionPill(
                label: budgets.isEmpty ? 'Thiết lập' : 'Chi tiết',
                onTap: () => _push(BudgetScreen(userId: widget.userId)),
              ),
              if (budgets.isNotEmpty) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: () =>
                      setState(() => _isBudgetExpanded = !_isBudgetExpanded),
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedRotation(
                    turns: _isBudgetExpanded ? .5 : 0,
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeInOutCubic,
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(Icons.keyboard_arrow_down_rounded, size: 22),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                budgets.isEmpty
                    ? 'Bắt đầu từ một danh mục'
                    : (remaining < 0 ? 'Vượt ngân sách' : 'Còn lại'),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
              Text(
                budgets.isEmpty ? '0 đ' : formatVND(remaining.abs()),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: remaining < 0
                      ? const Color(0xFFE11D48)
                      : (isDark
                          ? const Color(0xFF5EEAD4)
                          : const Color(0xFF0F766E)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: accent.withValues(alpha: .15),
              color: remaining < 0 ? const Color(0xFFE11D48) : accent,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đã chi: ${formatVND(totalSpent)}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
              Text(
                'Hạn mức: ${formatVND(totalLimit)}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            child: budgets.isNotEmpty && _isBudgetExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      children: [
                        for (final b in budgets)
                          Builder(builder: (context) {
                            final cats = context
                                .read<MoreProvider>()
                                .categories
                                .where((c) => c.id == b.budget.categoryId);
                            final cat = cats.isEmpty ? null : cats.first;
                            return _buildBudgetCategoryItem(
                              title: cat?.name ?? b.budget.categoryName,
                              spent: b.spentAmount,
                              limit: b.budget.limitAmount,
                              icon: cat?.icon ??
                                  b.budget.categoryIcon ??
                                  'wallet',
                              color: BankIconRegistry.parseThemeColor(
                                cat?.color ?? b.budget.categoryColor,
                                fallback: accent,
                              ),
                              isDark: isDark,
                            );
                          }),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCategoryItem({
    required String title,
    required int spent,
    required int limit,
    required String icon,
    required Color color,
    required bool isDark,
  }) {
    final double itemRate = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final int itemPercent = (itemRate * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8.5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: CategoryIconWidget(
                        icon: icon,
                        categoryName: title,
                        size: 28,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$itemPercent%',
                  style: TextStyle(
                    color: color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: itemRate,
              minHeight: 4.5,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đã dùng: ${Formatters.formatCurrency(spent)}',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Hạn mức: ${Formatters.formatCurrency(limit)}',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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

    final tier = d.aiHealthTier.isNotEmpty ? d.aiHealthTier : 'Xuất sắc 🏆';

    return GestureDetector(
      onTap: () => _push(AiAdvisorScreen(userId: widget.userId)),
      child: FloatingGlassCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        radius: 22,
        blur: 20,
        glow: true,
        glowColor: const Color(0xFF10B981),
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
                  child: Text(
                    tier,
                    style: const TextStyle(
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
                      _buildIndicatorRow(
                          'Quỹ khẩn cấp', '$runway tháng', isDark),
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
        // 1. Hàng Ví & Tài khoản (Theo ảnh mẫu)
        _buildWealthRowHeader(
          title: 'Ví & Tài khoản',
          count: wallets.length,
          showIcon: true,
          icon: Icons.account_balance_wallet_rounded,
          gradientColors: const [Color(0xFF0284C7), Color(0xFF38BDF8)],
          isDark: isDark,
          onViewAll: () {
            if (widget.onViewWallets != null) {
              widget.onViewWallets!();
            } else {
              _push(WalletScreen(userId: widget.userId));
            }
          },
        ),
        const SizedBox(height: 10),
        _buildWalletsList(wallets, isDark),

        const SizedBox(height: 22),

        // 2. Hàng Đầu tư (Dạng widget tổng số tiền đầu tư)
        _buildWealthRowHeader(
          title: 'Đầu tư',
          count: realAssets.length,
          icon: Icons.trending_up_rounded,
          gradientColors: const [Color(0xFF059669), Color(0xFF10B981)],
          isDark: isDark,
          onViewAll: () => _push(AssetScreen(userId: widget.userId)),
        ),
        const SizedBox(height: 10),
        _buildInvestmentSummaryWidget(realAssets, isDark),

        const SizedBox(height: 22),

        // 3. Hàng Cho vay & Sổ nợ (2 widget: Tổng cho vay & Đang nợ)
        _buildWealthRowHeader(
          title: 'Cho vay & Sổ nợ',
          count: realLoans.length,
          icon: Icons.handshake_rounded,
          gradientColors: const [Color(0xFFD97706), Color(0xFFF59E0B)],
          isDark: isDark,
          onViewAll: () => _push(LoanScreen(userId: widget.userId)),
        ),
        const SizedBox(height: 10),
        _buildLoansSummaryWidgets(realLoans, isDark),
      ],
    );
  }

  Widget _buildWealthRowHeader({
    required String title,
    required int count,
    IconData? icon,
    List<Color>? gradientColors,
    required bool isDark,
    required VoidCallback onViewAll,
    bool showIcon = true,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon && icon != null && gradientColors != null) ...[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            if (showIcon) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ],
        ),
        FinoraSectionActionPill(
          label: 'Xem tất cả',
          onTap: onViewAll,
        ),
      ],
    );
  }

  Widget _buildInvestmentSummaryWidget(List<Asset> assets, bool isDark) {
    final totalInvestment = assets.fold<double>(
      0,
      (sum, a) => sum + (a.marketValue > 0 ? a.marketValue : a.purchasePrice),
    );
    final totalCost = assets.fold<double>(0, (sum, a) => sum + a.purchasePrice);
    final totalGain = totalInvestment - totalCost;
    final gainPercent = totalCost > 0 ? (totalGain / totalCost) * 100 : 0.0;
    final hasGain = gainPercent != 0;

    // Luxury matte card colors (no glossy neon glare)
    final cardBg = isDark ? const Color(0xFF111C30) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF1E2D4A) : const Color(0xFFE2E8F0);
    const emeraldAccent = Color(0xFF0D9488); // Deep forest teal-emerald
    final emeraldBadgeBg = isDark
        ? const Color(0xFF0D9488).withValues(alpha: 0.18)
        : const Color(0xFF0D9488).withValues(alpha: 0.08);

    return GestureDetector(
      onTap: () => _push(AssetScreen(userId: widget.userId)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: cardBorder,
            width: 0.9,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A)
                  .withValues(alpha: isDark ? 0.28 : 0.04),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: Icon + Title + Category Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: emeraldBadgeBg,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        CupertinoIcons.chart_pie_fill,
                        color: isDark ? const Color(0xFF2DD4BF) : emeraldAccent,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      'Tổng giá trị đầu tư',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: emeraldBadgeBg,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: (isDark ? const Color(0xFF2DD4BF) : emeraldAccent)
                          .withValues(alpha: 0.20),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${assets.length} danh mục',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? const Color(0xFF2DD4BF) : emeraldAccent,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 10.5,
                        color: isDark ? const Color(0xFF2DD4BF) : emeraldAccent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2. High-contrast Amount + Mini Sparkline Chart
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _obscureBalance
                            ? '••••••••'
                            : Formatters.formatCurrency(
                                totalInvestment.toInt()),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (hasGain)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (gainPercent >= 0
                                        ? const Color(0xFF0D9488)
                                        : const Color(0xFFE11D48))
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    gainPercent >= 0
                                        ? CupertinoIcons.arrow_up_right
                                        : CupertinoIcons.arrow_down_right,
                                    size: 10.5,
                                    color: gainPercent >= 0
                                        ? (isDark
                                            ? const Color(0xFF2DD4BF)
                                            : const Color(0xFF0D9488))
                                        : const Color(0xFFE11D48),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${gainPercent >= 0 ? '+' : ''}${gainPercent.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: gainPercent >= 0
                                          ? (isDark
                                              ? const Color(0xFF2DD4BF)
                                              : const Color(0xFF0D9488))
                                          : const Color(0xFFE11D48),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'Lãi: ${Formatters.formatCurrency(totalGain.toInt())}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          'Tích lũy & danh mục tài sản sinh lời',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                ),

                // Apple-style Mini Sparkline Trend Chart
                SizedBox(
                  width: 92,
                  height: 44,
                  child: CustomPaint(
                    painter: _InvestmentSparklinePainter(
                      lineColor: isDark
                          ? const Color(0xFF2DD4BF)
                          : const Color(0xFF0D9488),
                      fillColor: (isDark
                              ? const Color(0xFF2DD4BF)
                              : const Color(0xFF0D9488))
                          .withValues(alpha: 0.15),
                      isGain: gainPercent >= 0,
                    ),
                  ),
                ),
              ],
            ),

            // 3. Multi-color Asset Allocation Segmented Bar & Legend
            const SizedBox(height: 14),
            _buildAssetAllocationBar(assets, totalInvestment, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetAllocationBar(
      List<Asset> assets, double total, bool isDark) {
    final palette = [
      const Color(0xFF0D9488), // Forest Teal
      const Color(0xFF2563EB), // Royal Sapphire
      const Color(0xFFF59E0B), // Warm Amber
      const Color(0xFF8B5CF6), // Rich Violet
      const Color(0xFF06B6D4), // Sky Cyan
    ];

    final items = <({String name, double val, double pct, Color color})>[];

    if (assets.isNotEmpty && total > 0) {
      for (int i = 0; i < assets.length; i++) {
        final a = assets[i];
        final val =
            (a.marketValue > 0 ? a.marketValue : a.purchasePrice).toDouble();
        final pct = (val / total).clamp(0.01, 1.0);
        final color = palette[i % palette.length];
        final name = a.name.isNotEmpty ? a.name : 'Mục ${i + 1}';
        items.add((name: name, val: val, pct: pct, color: color));
      }
      items.sort((a, b) => b.val.compareTo(a.val));
    } else {
      // Elegant diversified breakdown fallback
      items.addAll([
        (name: 'Vàng SJC', val: 30000000, pct: 0.44, color: palette[0]),
        (name: 'Cổ phiếu', val: 24000000, pct: 0.35, color: palette[1]),
        (name: 'Tiết kiệm', val: 14000000, pct: 0.21, color: palette[2]),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Segmented Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 6,
            color: isDark ? const Color(0xFF1E2D4A) : const Color(0xFFF1F5F9),
            child: Row(
              children: items.map((item) {
                final flex = (item.pct * 1000).clamp(1, 1000).toInt();
                return Expanded(
                  flex: flex,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 0.8),
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 9),

        // 2. Legend Row (top 3 categories)
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: items.take(3).map((item) {
            final percentText = '${(item.pct * 100).toStringAsFixed(0)}%';
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6.5,
                  height: 6.5,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4.5),
                Text(
                  '${item.name} ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                Text(
                  percentText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLoansSummaryWidgets(List<Loan> loans, bool isDark) {
    final lentLoans = loans.where((l) => l.type == 'lent').toList();
    final borrowedLoans = loans.where((l) => l.type != 'lent').toList();

    final totalLent = lentLoans.fold<int>(
      0,
      (sum, l) => sum + (l.amount - l.paidAmount).clamp(0, l.amount),
    );
    final totalBorrowed = borrowedLoans.fold<int>(
      0,
      (sum, l) => sum + (l.amount - l.paidAmount).clamp(0, l.amount),
    );

    // Luxury matte twin cards styling
    final cardBg = isDark ? const Color(0xFF111C30) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF1E2D4A) : const Color(0xFFE2E8F0);

    const lentColor = Color(0xFF0D9488); // Forest Emerald
    const borrowedColor = Color(0xFFE11D48); // Deep Ruby Crimson

    return Row(
      children: [
        // Card 2: Đã cho vay
        Expanded(
          child: GestureDetector(
            onTap: () => _push(LoanScreen(userId: widget.userId)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: cardBorder,
                  width: 0.9,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A)
                        .withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Icon + Title + Chevron
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: lentColor.withValues(
                                  alpha: isDark ? 0.20 : 0.09),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              CupertinoIcons.arrow_up_right,
                              color:
                                  isDark ? const Color(0xFF2DD4BF) : lentColor,
                              size: 13,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'Đã cho vay',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 12,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),

                  // Amount
                  Text(
                    _obscureBalance
                        ? '••••••••'
                        : Formatters.formatCurrency(totalLent),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: isDark ? const Color(0xFF2DD4BF) : lentColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Subtitle
                  Text(
                    '${lentLoans.length} khoản cần thu',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Card 3: Đang nợ
        Expanded(
          child: GestureDetector(
            onTap: () => _push(LoanScreen(userId: widget.userId)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: cardBorder,
                  width: 0.9,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A)
                        .withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Icon + Title + Chevron
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: borrowedColor.withValues(
                                  alpha: isDark ? 0.20 : 0.09),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              CupertinoIcons.arrow_down_left,
                              color: isDark
                                  ? const Color(0xFFFB7185)
                                  : borrowedColor,
                              size: 13,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'Đang nợ',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 12,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),

                  // Amount
                  Text(
                    _obscureBalance
                        ? '••••••••'
                        : Formatters.formatCurrency(totalBorrowed),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: totalBorrowed > 0
                          ? (isDark ? const Color(0xFFFB7185) : borrowedColor)
                          : (isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF0F172A)),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Subtitle
                  Text(
                    '${borrowedLoans.length} khoản phải trả',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletsList(List<Wallet> wallets, bool isDark) {
    if (wallets.isEmpty) {
      return GlassCard(
          child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Chưa có ví hoặc tài khoản. Thêm ví để bắt đầu.'),
      ));
    }
    return SizedBox(
      height: 136,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        itemCount: wallets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final wallet = wallets[index];
          return _buildWalletMiniCard(
            wallet.name,
            wallet.isCreditCard ? wallet.currentDebt : wallet.balance,
            wallet.bankCode ?? wallet.type,
            wallet.owner,
            isDark,
            bankName: wallet.bankName,
            themeColor: wallet.themeColor,
            isCreditCard: wallet.isCreditCard,
          );
        },
      ),
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
        final val =
            asset.marketValue > 0 ? asset.marketValue : asset.purchasePrice;
        final profitText = asset.profitLossPercent != 0.0
            ? '${asset.profitLossPercent > 0 ? '+' : ''}${asset.profitLossPercent.toStringAsFixed(1)}%'
            : (asset.unit != null
                ? '${asset.quantity} ${asset.unit}'
                : 'Đang nắm giữ');

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
          subtextColor:
              isLent ? const Color(0xFF059669) : const Color(0xFFE11D48),
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
    final isWife = owner == 'wife';
    final ownerLabel =
        owner == 'Cho vay' || owner == 'Vay nợ' || owner == 'Tài sản'
            ? owner
            : (isWife ? 'Vợ' : 'Chồng');
    final tagColor = owner == 'Vay nợ'
        ? const Color(0xFFDC2626)
        : owner == 'Cho vay'
            ? const Color(0xFF059669)
            : owner == 'Tài sản'
                ? const Color(0xFF7C3AED)
                : isWife
                    ? const Color(0xFFDB2777)
                    : const Color(0xFF173B70);
    final tagBg = tagColor.withValues(alpha: isDark ? 0.20 : 0.12);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 175,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.white.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.90),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
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

  List<Color> _getBankCardGradient({
    String? bankCode,
    String? bankName,
    required String name,
    String? themeColor,
  }) {
    final clean = '${bankCode ?? ''} ${bankName ?? ''} $name'
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');

    if (clean.contains('cash') ||
        clean.contains('tienmat') ||
        clean.contains('tiềnmặt')) {
      // Chuẩn xanh Tiền mặt trong ảnh người dùng (sampled: #0F63A1 -> #0B7CBE -> #22ACEB):
      return const [Color(0xFF0F63A1), Color(0xFF0B7CBE), Color(0xFF22ACEB)];
    }
    if (clean.contains('tcb') ||
        clean.contains('techcombank') ||
        clean.contains('techcom')) {
      // Chuẩn đỏ Techcombank trong ảnh người dùng (sampled: #9E1B20 -> #CA2624 -> #E4333A):
      return const [Color(0xFF9E1B20), Color(0xFFCA2624), Color(0xFFE4333A)];
    }
    if (clean.contains('mb') ||
        clean.contains('mbbank') ||
        clean.contains('tietkiem') ||
        clean.contains('tiếtkiệm')) {
      // Chuẩn xanh MB Bank trong ảnh người dùng (sampled: #1B45B0 -> #224DD7 -> #3677EF):
      return const [Color(0xFF1B45B0), Color(0xFF224DD7), Color(0xFF3677EF)];
    }
    if (clean.contains('vcb') || clean.contains('vietcombank')) {
      return const [Color(0xFF0B5E28), Color(0xFF16A34A), Color(0xFF4ADE80)];
    }
    if (clean.contains('bidv')) {
      return const [Color(0xFF00564B), Color(0xFF00796B), Color(0xFF00A896)];
    }
    if (clean.contains('ctg') ||
        clean.contains('vtb') ||
        clean.contains('vietinbank')) {
      return const [Color(0xFF003865), Color(0xFF005BAA), Color(0xFF0088FF)];
    }
    if (clean.contains('acb')) {
      return const [Color(0xFF0A3D91), Color(0xFF0F56B3), Color(0xFF2563EB)];
    }
    if (clean.contains('vpb') || clean.contains('vpbank')) {
      return const [Color(0xFF006837), Color(0xFF00904B), Color(0xFF10B981)];
    }
    if (clean.contains('tpb') || clean.contains('tpbank')) {
      return const [Color(0xFF581C87), Color(0xFF7E22CE), Color(0xFFA855F7)];
    }
    if (clean.contains('stb') || clean.contains('sacombank')) {
      return const [Color(0xFF004080), Color(0xFF0058A8), Color(0xFF0077CC)];
    }
    if (clean.contains('timo')) {
      return const [Color(0xFF4318FF), Color(0xFF6B46C1), Color(0xFF7928CA)];
    }
    if (clean.contains('momo')) {
      return const [Color(0xFF830051), Color(0xFFA50064), Color(0xFFD81B60)];
    }
    if (clean.contains('zalo')) {
      return const [Color(0xFF0052CC), Color(0xFF0088FF), Color(0xFF38B6FF)];
    }
    if (clean.contains('cake')) {
      return const [Color(0xFFB71C1C), Color(0xFFFF424E)];
    }
    if (clean.contains('vib')) {
      return const [Color(0xFF003C78), Color(0xFF0072CE)];
    }
    if (clean.contains('hdb') || clean.contains('hdbank')) {
      return const [Color(0xFF9E1B20), Color(0xFFCA2624), Color(0xFFE4333A)];
    }

    if (themeColor != null && themeColor.isNotEmpty) {
      final base = BankIconRegistry.parseThemeColor(themeColor);
      return [
        base,
        HSLColor.fromColor(base)
            .withLightness(
                (HSLColor.fromColor(base).lightness + 0.15).clamp(0.0, 1.0))
            .toColor(),
      ];
    }

    return const [Color(0xFF0F63A1), Color(0xFF0B7CBE), Color(0xFF22ACEB)];
  }

  Widget _buildWalletMiniCard(
    String name,
    int balance,
    String? bankCode,
    String owner,
    bool isDark, {
    String? bankName,
    String? themeColor,
    bool isCreditCard = false,
  }) {
    final isWifeWallet = owner == 'wife' || name.toLowerCase().contains('vợ');
    final ownerLabel = isWifeWallet
        ? 'Vợ'
        : owner == 'husband'
            ? 'Chồng'
            : 'Chung';

    final gradient = _getBankCardGradient(
      bankCode: bankCode,
      bankName: bankName,
      name: name,
      themeColor: themeColor,
    );

    // Tự động nhận diện ngân hàng nếu bankCode rỗng nhưng tên ví là Techcombank, MB Bank, v.v.
    var effectiveCode = bankCode;
    if (effectiveCode == null || effectiveCode.isEmpty) {
      final clean = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (clean.contains('tietkiem') ||
          clean.contains('tiếtkiệm') ||
          clean.contains('mb')) {
        effectiveCode = 'mbbank';
      } else if (clean.contains('tcb') || clean.contains('techcom')) {
        effectiveCode = 'tcb';
      }
    }

    final brand =
        BankIconRegistry.resolve(effectiveCode ?? bankName, bankName: name);
    final isCash = brand.code == 'cash' ||
        name.toLowerCase().contains('tiền mặt') ||
        name.toLowerCase().contains('tien mat');

    return GestureDetector(
      onTap: () {
        if (widget.onViewWallets != null) {
          widget.onViewWallets!();
        } else {
          _push(WalletScreen(userId: widget.userId));
        }
      },
      child: Container(
        width: 238,
        height: 136,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: isDark ? 0.40 : 0.26),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: [ Logo ngân hàng / 💵 ]  [ Tên ví ] [ Contactless icon ]
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isCash
                        ? const Text('💵', style: TextStyle(fontSize: 16))
                        : BankIcon(
                            bankCode: brand.code,
                            bankName: name,
                            size: 22,
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.2,
                      height: 1.15,
                    ),
                  ),
                ),
                Icon(
                  Icons.contactless_rounded,
                  color: Colors.white.withValues(alpha: 0.60),
                  size: 20,
                ),
              ],
            ),
            // Middle: [ Amount ]
            Row(
              children: [
                if (isCreditCard) ...[
                  Text(
                    'Dư nợ  ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: .72),
                    ),
                  ),
                ],
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _obscureBalance
                          ? '••••••••'
                          : Formatters.formatCurrency(balance),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Bottom Row: [ Tag: Chồng (xanh) / Vợ (hồng) ]  [ Chevron > ]
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: owner == 'husband'
                        ? const Color(0xFF173B70).withValues(alpha: 0.92)
                        : (owner == 'wife'
                            ? const Color(0xFFDB2777).withValues(alpha: 0.88)
                            : Colors.white.withValues(alpha: 0.22)),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    ownerLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsSection(
      List<TransactionModel> transactions, bool isDark) {
    final displayList = transactions.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF005FEA), Color(0xFF0284C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF005FEA).withValues(alpha: 0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  'Giao dịch gần đây',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0284C7).withValues(alpha: 0.18)
                        : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${transactions.length} GD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? const Color(0xFF38BDF8)
                          : const Color(0xFF0284C7),
                    ),
                  ),
                ),
              ],
            ),
            FinoraSectionActionPill(
              label: 'Xem tất cả',
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.035),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF005FEA).withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Color(0xFF005FEA),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Chưa có giao dịch gần đây',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ghi lại chi tiêu hoặc thu nhập ngay hôm nay',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () => _push(AddTransactionPage(userId: widget.userId)),
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF005FEA), Color(0xFF0284C7)],
                      ),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF005FEA).withValues(alpha: 0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Ghi chép ngay',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.035),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < displayList.length; i++) ...[
                    if (i == 0 ||
                        DateFormat('dd/MM/yyyy')
                                .format(_parseTxDate(displayList[i].date)) !=
                            DateFormat('dd/MM/yyyy')
                                .format(_parseTxDate(displayList[i - 1].date)))
                      _buildTimelineDateHeader(
                        _parseTxDate(displayList[i].date),
                        isDark,
                        isFirstDate: i == 0,
                      ),
                    _buildTimelineTransactionItem(
                      displayList[i],
                      isDark,
                      isLastOverall: i == displayList.length - 1,
                    ),
                  ],
                  if (transactions.length > 8) ...[
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFF1F5F9),
                    ),
                    InkWell(
                      onTap: () {
                        if (widget.onViewAllTransactions != null) {
                          widget.onViewAllTransactions!();
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Xem tất cả ${transactions.length} giao dịch',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF005FEA),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                CupertinoIcons.chevron_right,
                                size: 14,
                                color: Color(0xFF005FEA),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimelineDateHeader(
    DateTime date,
    bool isDark, {
    required bool isFirstDate,
  }) {
    return Stack(
      children: [
        // Connecting vertical rail through date header
        Positioned(
          left: 36,
          top: isFirstDate ? 25 : 0,
          bottom: 0,
          width: 2,
          child: Container(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            children: [
              SizedBox(
                width: 42,
                height: 26,
                child: Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF005FEA),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF005FEA).withValues(alpha: 0.35),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A).withValues(alpha: 0.65)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155).withValues(alpha: 0.6)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 11,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _formatRecentDateLabel(date),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                        color: isDark
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineTransactionItem(
    TransactionModel tx,
    bool isDark, {
    required bool isLastOverall,
  }) {
    return Stack(
      children: [
        // Timeline vertical rail
        Positioned(
          left: 36,
          top: 0,
          bottom: isLastOverall ? null : 0,
          height: isLastOverall ? 30 : null,
          width: 2,
          child: Container(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
        ),
        _buildTransactionRowItem(tx, isDark),
      ],
    );
  }

  String _formatRecentDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);
    final dateStr = DateFormat('dd/MM/yyyy').format(date);

    if (checkDate == today) {
      return 'Hôm nay • $dateStr';
    } else if (checkDate == yesterday) {
      return 'Hôm qua • $dateStr';
    }
    return dateStr;
  }

  Widget _buildTransactionRowItem(TransactionModel tx, bool isDark) {
    final categories = context.watch<MoreProvider>().categories;
    final matchingCategory = categories.cast<dynamic>().firstWhere(
          (category) =>
              (tx.categoryId?.isNotEmpty == true &&
                  category?.id == tx.categoryId) ||
              (tx.categoryId?.isNotEmpty != true &&
                  tx.categoryName?.isNotEmpty == true &&
                  category?.name == tx.categoryName),
          orElse: () => null,
        );
    final resolvedCategoryIcon = matchingCategory?.icon ?? tx.categoryIcon;
    final resolvedCategoryName = matchingCategory?.name ?? tx.categoryName;
    final resolvedCategoryColor = matchingCategory?.color ?? tx.categoryColor;
    final isExpense = TransactionVisuals.isOutflow(tx.type) &&
        !TransactionVisuals.isTransfer(tx.type);
    final isIncome = TransactionVisuals.isInflow(tx.type);
    final color = isExpense
        ? const Color(0xFFDC2626)
        : (isIncome ? const Color(0xFF059669) : const Color(0xFF0284C7));
    final prefix = isExpense ? '-' : (isIncome ? '+' : '');
    final txDate = _parseTxDate(tx.date);

    final isWife = tx.creatorTag == 'Vợ' ||
        tx.creatorTag?.toLowerCase() == 'wife' ||
        tx.ownerName?.toLowerCase() == 'vợ' ||
        tx.ownerName?.toLowerCase() == 'wife' ||
        tx.owner?.toLowerCase() == 'wife' ||
        tx.fromOwner?.toLowerCase() == 'wife' ||
        tx.paidByOwner?.toLowerCase() == 'wife' ||
        tx.tags.any(
            (tag) => tag.toLowerCase() == 'vợ' || tag.toLowerCase() == 'wife');
    final isHusband = !isWife;
    final isAi = tx.tags.contains('Finora AI') || tx.creatorTag == 'AI';

    return InkWell(
      onTap: () => _push(
          TransactionDetailScreen(userId: widget.userId, transaction: tx)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              height: 42,
              child: Center(
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TransactionIconWidget(
                    type: tx.type,
                    categoryIcon: resolvedCategoryIcon,
                    categoryName: resolvedCategoryName ?? tx.note,
                    categoryColor: resolvedCategoryColor,
                    merchantId: tx.merchantId,
                    size: 38,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.note?.isNotEmpty == true
                        ? tx.note!
                        : (tx.categoryName ?? 'Giao dịch'),
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 3,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Tag Ví
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 11,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            tx.walletName ?? 'Ví chính',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                      // Tag Vợ / Chồng
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isHusband
                              ? (isDark
                                  ? const Color(0xFF0284C7)
                                      .withValues(alpha: 0.22)
                                  : const Color(0xFFE0F2FE))
                              : (isDark
                                  ? const Color(0xFFDB2777)
                                      .withValues(alpha: 0.22)
                                  : const Color(0xFFFCE7F3)),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          isHusband ? 'Chồng' : 'Vợ',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: isHusband
                                ? (isDark
                                    ? const Color(0xFF38BDF8)
                                    : const Color(0xFF0284C7))
                                : (isDark
                                    ? const Color(0xFFF472B6)
                                    : const Color(0xFFDB2777)),
                          ),
                        ),
                      ),
                      if (isAi)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF005FEA).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome_rounded,
                                  size: 9, color: Color(0xFF0284C7)),
                              SizedBox(width: 2),
                              Text(
                                'AI',
                                style: TextStyle(
                                  color: Color(0xFF0284C7),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        DateFormat('HH:mm').format(txDate),
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              isDark ? Colors.white54 : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
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
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isExpense
                        ? const Color(0xFFDC2626)
                            .withValues(alpha: isDark ? 0.20 : 0.08)
                        : (isIncome
                            ? const Color(0xFF059669)
                                .withValues(alpha: isDark ? 0.20 : 0.08)
                            : const Color(0xFF0284C7)
                                .withValues(alpha: isDark ? 0.20 : 0.08)),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isExpense
                          ? const Color(0xFFDC2626)
                              .withValues(alpha: isDark ? 0.35 : 0.18)
                          : (isIncome
                              ? const Color(0xFF059669)
                                  .withValues(alpha: isDark ? 0.35 : 0.18)
                              : const Color(0xFF0284C7)
                                  .withValues(alpha: isDark ? 0.35 : 0.18)),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4.5,
                        height: 4.5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 3.5),
                      Text(
                        isExpense ? 'Đã chi' : (isIncome ? 'Thu về' : 'Chuyển'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
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

/// Unified Apple UI Pill Action Button for section headers ("Xem tất cả >")
/// Designed according to Apple Human Interface Guidelines:
/// - Exact golden ratio pill shape (BorderRadius.circular(100))
/// - Subtle translucent frosted glass container with hairline retina border
/// - Crisp Cupertino chevron right
/// - Smooth iOS-style spring scale and opacity micro-interaction on tap
class FinoraSectionActionPill extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const FinoraSectionActionPill({
    super.key,
    this.label = 'Xem tất cả',
    required this.onTap,
  });

  @override
  State<FinoraSectionActionPill> createState() =>
      _FinoraSectionActionPillState();
}

class _FinoraSectionActionPillState extends State<FinoraSectionActionPill> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Clean label: remove any trailing raw arrows so it's always unified
    final cleanLabel = widget.label
        .replaceAll('>', '')
        .replaceAll('→', '')
        .replaceAll('↗', '')
        .trim();

    // Apple HIG Blue / Accent palette
    final textColor =
        isDark ? const Color(0xFF38BDF8) : const Color(0xFF007AFF);
    final bgColor = isDark
        ? const Color(0xFF007AFF).withValues(alpha: 0.15)
        : const Color(0xFF007AFF).withValues(alpha: 0.08);
    final borderColor = isDark
        ? const Color(0xFF38BDF8).withValues(alpha: 0.28)
        : const Color(0xFF007AFF).withValues(alpha: 0.18);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.75 : 1.0,
          duration: const Duration(milliseconds: 130),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.5, vertical: 4.5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: borderColor,
                width: 0.8,
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  cleanLabel,
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 3.0),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 11.0,
                  color: textColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mini Sparkline Trend Painter for Investment Card
class _InvestmentSparklinePainter extends CustomPainter {
  final Color lineColor;
  final Color fillColor;
  final bool isGain;

  const _InvestmentSparklinePainter({
    required this.lineColor,
    required this.fillColor,
    this.isGain = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final width = size.width;
    final height = size.height;

    // Smooth Bezier Curve points
    final points = isGain
        ? [
            Offset(0, height * 0.85),
            Offset(width * 0.20, height * 0.68),
            Offset(width * 0.42, height * 0.74),
            Offset(width * 0.65, height * 0.38),
            Offset(width * 0.84, height * 0.44),
            Offset(width - 4, height * 0.16),
          ]
        : [
            Offset(0, height * 0.20),
            Offset(width * 0.25, height * 0.35),
            Offset(width * 0.50, height * 0.30),
            Offset(width * 0.75, height * 0.65),
            Offset(width - 4, height * 0.85),
          ];

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final ctrl1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final ctrl2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, p1.dx, p1.dy);
    }

    // Gradient Area Fill Under Curve
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, height)
      ..lineTo(0, height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          fillColor,
          fillColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Stroke line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // End point glowing dot
    final lastPoint = points.last;
    final dotBgPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(lastPoint, 5.0, dotBgPaint);

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(lastPoint, 2.8, dotPaint);

    final dotCorePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(lastPoint, 1.2, dotCorePaint);
  }

  @override
  bool shouldRepaint(covariant _InvestmentSparklinePainter oldDelegate) =>
      oldDelegate.lineColor != lineColor || oldDelegate.isGain != isGain;
}

class _QuickActionItemWidget extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool isDark;
  final bool isHero;
  final VoidCallback onTap;

  const _QuickActionItemWidget({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.isDark,
    this.isHero = false,
    required this.onTap,
  });

  @override
  State<_QuickActionItemWidget> createState() => _QuickActionItemWidgetState();
}

class _QuickActionItemWidgetState extends State<_QuickActionItemWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final color = widget.color;
    final isHero = widget.isHero;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isDark
                        ? color.withValues(alpha: isHero ? 0.38 : 0.26)
                        : (isHero
                            ? const Color(0xFFE0F2FE)
                            : widget.bgColor.withValues(alpha: 0.95)),
                    isDark ? const Color(0xFF1E293B) : Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: isDark
                      ? color.withValues(alpha: isHero ? 0.55 : 0.32)
                      : (isHero
                          ? color.withValues(alpha: 0.40)
                          : color.withValues(alpha: 0.20)),
                  width: isHero ? 1.8 : 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(
                        alpha: isDark
                            ? (isHero ? 0.30 : 0.18)
                            : (isHero ? 0.24 : 0.12)),
                    blurRadius: isHero ? 14 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle top light sheen
                  Positioned(
                    top: 2,
                    left: 6,
                    right: 6,
                    height: 1.5,
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            Colors.white.withValues(alpha: isDark ? 0.25 : 0.6),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                  Icon(
                    widget.icon,
                    color: isDark ? (isHero ? Colors.white : color) : color,
                    size: 26,
                  ),
                  if (isHero)
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Container(
                        width: 6.5,
                        height: 6.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFF005FEA),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isDark ? const Color(0xFF1E293B) : Colors.white,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHero ? FontWeight.w800 : FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
