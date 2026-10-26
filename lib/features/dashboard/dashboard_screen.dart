import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/utils/date_filter.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/widgets/finora_mascot.dart';
import '../../core/widgets/finora_motion.dart';
import '../../core/widgets/custom_date_picker_dialog.dart';
import '../../core/widgets/morph_icon.dart';
import '../../core/widgets/finora_privacy_mask.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/liquid_glass/liquid_glass_card.dart';
import '../../core/widgets/subject_filter_pill.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../../data/models/finance_models.dart';
import '../../domain/finance/transaction_member.dart';
import '../../state/dashboard_provider.dart';
import '../../state/more_provider.dart';
import '../../state/budget_provider.dart';
import '../../state/widget_style_controller.dart';
import '../../state/theme_studio_controller.dart';
import '../../state/transaction_provider.dart';
import '../../data/services/finora_nlp_engine.dart';
import 'dashboard_theme_painters.dart';
import 'bento_luxury_deck_card.dart';
import 'net_worth_modern_deck_card.dart';
import 'zenvest_glass_deck_card.dart';
import '../ai/ai_advisor_screen.dart';
import '../notification/notification_screen.dart';
import '../planning/planning_hub_screen.dart';
import '../transaction/add_transaction_page.dart';
import '../transaction/transaction_detail_sheet.dart';
import '../wallet/wealth_hub_screen.dart';
import '../wallet/wallet_screen.dart';
import '../qr_pay/qr_scanner_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? familyId;
  final String? userPhotoUrl;
  final VoidCallback? onViewAllTransactions;
  final VoidCallback? onViewWallets;
  final VoidCallback? onViewAssets;
  final VoidCallback? onViewLoans;
  final VoidCallback? onViewPlanning;

  const DashboardScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.familyId,
    this.userPhotoUrl,
    this.onViewAllTransactions,
    this.onViewWallets,
    this.onViewAssets,
    this.onViewLoans,
    this.onViewPlanning,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _obscureBalance = false;
  bool _isBudgetExpanded = false;
  DateTime _selectedDate = DateTime.now();
  final String _dateLabel = 'Hôm nay';
  final ScrollController _recentTxScrollController = ScrollController();
  final ScrollController _mainScrollController = ScrollController();
  bool _isAppBarVisible = true;
  bool _isCollapsedHeader = false;

  @override
  void initState() {
    super.initState();
    _mainScrollController.addListener(() {
      if (_mainScrollController.hasClients) {
        final isCollapsed = _mainScrollController.offset > 240;
        if (isCollapsed != _isCollapsedHeader) {
          setState(() => _isCollapsedHeader = isCollapsed);
        }
      }
      final direction = _mainScrollController.position.userScrollDirection;
      if (direction == ScrollDirection.reverse && _isAppBarVisible) {
        setState(() => _isAppBarVisible = false);
      } else if (direction == ScrollDirection.forward && !_isAppBarVisible) {
        setState(() => _isAppBarVisible = true);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final studio = context.read<ThemeStudioController>();
      if (mounted && _obscureBalance != studio.isPrivacyShieldActive) {
        setState(() => _obscureBalance = studio.isPrivacyShieldActive);
      }
      context
          .read<DashboardProvider>()
          .load(widget.userId, familyId: widget.familyId);
      context
          .read<MoreProvider>()
          .load(widget.userId, familyId: widget.familyId);
      context
          .read<BudgetProvider>()
          .load(widget.userId, familyId: widget.familyId);
    });
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.familyId != widget.familyId) {
      context
          .read<DashboardProvider>()
          .load(widget.userId, familyId: widget.familyId);
      context
          .read<MoreProvider>()
          .load(widget.userId, familyId: widget.familyId);
      context
          .read<BudgetProvider>()
          .load(widget.userId, familyId: widget.familyId);
    }
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _recentTxScrollController.dispose();
    super.dispose();
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
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                  width: 1.0,
                ),
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
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
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
                    color: const Color(0xFF005FEA),
                    isSelected: provider.customDate != null,
                    isDark: isDark,
                    onTap: () => Navigator.pop(ctx, 'custom'),
                  ),
                ],
              ),
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
              ? color.withValues(alpha: isDark ? 0.20 : 0.12)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.035)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.07)),
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
                    color: color.withValues(alpha: isDark ? 0.20 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: color.withValues(alpha: isDark ? 0.35 : 0.25),
                    ),
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
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color:
                            isDark ? Colors.white70 : const Color(0xFF64748B),
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



  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _navigateToAssets() {
    if (widget.onViewAssets != null) {
      widget.onViewAssets!();
    } else {
      _push(WealthHubScreen(
        userId: widget.userId,
        familyId: widget.familyId,
        initialTabIndex: 2,
      ));
    }
  }

  void _navigateToLoans() {
    if (widget.onViewLoans != null) {
      widget.onViewLoans!();
    } else {
      _push(WealthHubScreen(
        userId: widget.userId,
        familyId: widget.familyId,
        initialTabIndex: 3,
      ));
    }
  }

  void _navigateToPlanning() {
    if (widget.onViewPlanning != null) {
      widget.onViewPlanning!();
    } else {
      _push(PlanningHubScreen(
        userId: widget.userId,
        familyId: widget.familyId,
      ));
    }
  }

  DateTime _parseTxDate(int timestamp) {
    if (timestamp <= 0) return DateTime.now();
    if (timestamp > 100000000000) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }

  Widget _buildGlassCardContainer({
    required Widget child,
    required ThemeStudioController studio,
    required bool isDark,
    double? radius,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? color,
    Gradient? gradient,
    Border? border,
    List<BoxShadow>? shadows,
  }) {
    final effectiveRadius = radius ?? studio.cardCornerRadius;
    final widgetDec = studio.getWidgetCardDecoration(
      isDark: isDark,
      customRadius: effectiveRadius,
      customBg: color,
      customBorder: border,
    );
    final effectiveBorder = border ??
        (studio.borderGlowStyle == CardBorderGlowStyle.none
            ? null
            : (widgetDec.border ?? studio.getCardBorder(isDark)));
    final effectiveShadows = shadows ??
        (widgetDec.boxShadow ??
            [
              ...studio.getGlowShadows(isDark),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.035),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ]);
    final baseColor =
        color ?? widgetDec.color ?? studio.getCardFillColor(isDark);

    Widget content = child;
    if (padding != null) {
      content = Padding(padding: padding, child: content);
    }

    final isLiquidGlass = studio.isSystemWideLiquidGlass;
    final primaryColor = studio.resolvedPrimary;
    final tintColor = isDark ? Colors.white : primaryColor;
    final enableSpecular = studio.liquidGlassSpecularHighlight;
    final enableCaustics = studio.liquidGlassCausticRefraction;

    final List<BoxShadow> resolvedShadows = [
      ...effectiveShadows,
      if (isLiquidGlass)
        BoxShadow(
          color: primaryColor.withValues(alpha: isDark ? 0.05 : 0.02),
          blurRadius: 20,
          spreadRadius: -2,
          offset: const Offset(0, 6),
        ),
    ];

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(effectiveRadius),
        boxShadow: resolvedShadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            // Layer 0: Solid foundation backing to ensure cards are always crisp & legible
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(effectiveRadius),
                ),
              ),
            ),

            // Layer 1: Base background and border
            Container(
              decoration: BoxDecoration(
                color: (gradient != null || (isLiquidGlass && widgetDec.gradient != null))
                    ? null
                    : baseColor,
                gradient: gradient ?? (isLiquidGlass ? widgetDec.gradient : null),
                borderRadius: BorderRadius.circular(effectiveRadius),
                border: isLiquidGlass ? null : effectiveBorder,
              ),
            ),

            // Layer 2: Simulated Caustic Refraction Sheen & Subtle Rim
            if (isLiquidGlass && enableCaustics)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: LiquidRefractionPainter(
                      borderRadius: effectiveRadius,
                      tintColor: tintColor,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),

            // Layer 3: Content
            content,

            // Layer 4: Micro-Specular Rim & Directional Gradient Border
            if (isLiquidGlass && enableSpecular)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: LiquidSpecularBorderPainter(
                      borderRadius: effectiveRadius,
                      borderWidth: studio.widgetBorderWidth.clamp(0.8, 1.8),
                      borderGradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.22, 0.75, 1.0],
                        colors: isDark
                            ? const [
                                Color(0x35FFFFFF),
                                Color(0x0AFFFFFF),
                                Color(0x00FFFFFF),
                                Color(0x04FFFFFF),
                              ]
                            : const [
                                Color(0x40FFFFFF),
                                Color(0x0EFFFFFF),
                                Color(0x00FFFFFF),
                                Color(0x06FFFFFF),
                              ],
                      ),
                      enableSpecularHighlight: true,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
    final moduleGap = studio.pageVerticalGap;
    final topSafePadding = MediaQuery.paddingOf(context).top + 16.0;

    return GlassScaffold(
      extendBodyBehindAppBar: false,
      body: SafeArea(
        top: false,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            provider.load(widget.userId);
            context.read<MoreProvider>().load(widget.userId);
            context.read<BudgetProvider>().load(widget.userId);
          },
          child: SingleChildScrollView(
            controller: _mainScrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(
              16.0,
              topSafePadding,
              16.0,
              136,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _buildHeader(isDark, studio, totalBalance),
                ),
                const SizedBox(height: 10),
                _buildDashboardSubHeader(isDark, studio, provider),
                SizedBox(height: moduleGap),
                ...(() {
                  final List<Widget> moduleWidgets = [];
                  for (final modId in studio.dashboardOrder) {
                    final w = _buildDashboardModule(
                      modId,
                      provider,
                      d,
                      totalBalance,
                      income,
                      expense,
                      netFlow,
                      txList,
                      isDark,
                      studio,
                    );
                    if (w != null) {
                      if (moduleWidgets.isNotEmpty) {
                        moduleWidgets.add(SizedBox(height: moduleGap));
                      }
                      moduleWidgets.add(w);
                    }
                  }
                  return moduleWidgets;
                })(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarWithAura(ThemeStudioController studio, bool isDark) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? const Color(0xFF23322C) : const Color(0xFFE3EBE7),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: widget.userPhotoUrl != null
            ? Image.network(
                widget.userPhotoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildAvatarFallback(),
              )
            : _buildAvatarFallback(),
      ),
    );
  }

  Widget _buildHeader(
      bool isDark, ThemeStudioController studio, num totalBalance) {
    final displayName = widget.userName.trim().isNotEmpty
        ? widget.userName.trim()
        : 'Hoà Trần';

    return Row(
      children: [
        // Left: Avatar + User Name (with full room to breathe, never overlapped!)
        _buildAvatarWithAura(studio, isDark),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: isDark ? Colors.white : const Color(0xFF0D1F1A),
              fontFamily: studio.fontFamilyName,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Right: Search Icon Button
        GestureDetector(
          onTap: () {
            if (widget.onViewAllTransactions != null) {
              widget.onViewAllTransactions!();
            } else {
              _openTransactionHistory();
            }
          },
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121A17) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE3EBE7),
                width: 1.0,
              ),
            ),
            child: Icon(
              Icons.search_rounded,
              color: isDark ? Colors.white : const Color(0xFF0D1F1A),
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Right: Notification Bell Button
        GestureDetector(
          onTap: () => _push(NotificationScreen(userId: widget.userId)),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121A17) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE3EBE7),
                width: 1.0,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  color: isDark ? Colors.white : const Color(0xFF0D1F1A),
                  size: 18,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
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

  Widget _buildDashboardSubHeader(
    bool isDark,
    ThemeStudioController studio,
    DashboardProvider dProv,
  ) {
    final filterLabel = dProv.customDate != null
        ? DateFormat('dd/MM/yyyy').format(dProv.customDate!)
        : dProv.selectedDateFilter.label;
    final currentOwner = dProv.selectedOwner;
    final (memberLabel, memberIcon, memberColor) = switch (currentOwner) {
      OwnerFilter.husband => (
          'Chồng',
          Icons.man_rounded,
          const Color(0xFF0284C7),
        ),
      OwnerFilter.wife => (
          'Vợ',
          Icons.woman_rounded,
          const Color(0xFFDB2777),
        ),
      _ => (
          'Tất cả',
          Icons.group_rounded,
          const Color(0xFF0F6E56),
        ),
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: 'Tổng quan dòng tiền' label + member filter pill
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tổng quan dòng tiền',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: isDark
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF0D1F1A),
                    fontFamily: studio.fontFamilyName,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _openOwnerFilterModal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4.5,
                    ),
                    decoration: BoxDecoration(
                      color: memberColor.withValues(alpha: isDark ? 0.22 : 0.12),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: memberColor.withValues(alpha: 0.32),
                        width: 0.9,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(memberIcon, size: 13, color: memberColor),
                        const SizedBox(width: 4),
                        Text(
                          memberLabel,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : memberColor,
                            fontFamily: studio.fontFamilyName,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 13,
                          color: isDark ? Colors.white70 : memberColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Right: Solid stadium-pill Date Filter button (📅 Hôm nay / Tháng này ▾)
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 142),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _openDateFilter,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F6E56),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F6E56)
                          .withValues(alpha: isDark ? 0.35 : 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      filterLabel,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontFamily: studio.fontFamilyName,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarFallback() {
    return const FinoraMascotImage(
      pose: FinoraMascotPose.appIcon,
      size: 42,
      fit: BoxFit.cover,
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
    if (studio.heroCardStyle == AppHeroCardStyle.zenvestGlassDeck) {
      return ZenvestGlassDeckCard(
        userId: widget.userId,
        userName: widget.userName,
        userPhotoUrl: widget.userPhotoUrl,
        provider: provider,
        totalBalance: totalBalance,
        income: income,
        expense: expense,
        netFlow: netFlow,
        txList: provider.data.recentTransactions,
        isDark: isDark,
        studio: studio,
        masked: _obscureBalance,
        onToggleMask: () => setState(() => _obscureBalance = !_obscureBalance),
        onViewWallets: widget.onViewWallets,
        onViewLoans: _navigateToLoans,
        onViewPlanning: widget.onViewPlanning,
        onViewTransactions: widget.onViewAllTransactions ?? _openTransactionHistory,
        onDateFilterTap: _openDateFilter,
        onAiQuickLogTap: () => _showAiQuickLogModal(context),
        onAiAdvisorTap: () => _push(AiAdvisorScreen(
          userId: widget.userId,
          familyId: widget.familyId,
        )),
      );
    }

    if (studio.heroCardStyle == AppHeroCardStyle.netWorthModernDeck) {
      return NetWorthModernDeckCard(
        userId: widget.userId,
        userName: widget.userName,
        userPhotoUrl: widget.userPhotoUrl,
        provider: provider,
        totalBalance: totalBalance,
        income: income,
        expense: expense,
        netFlow: netFlow,
        isDark: isDark,
        studio: studio,
        masked: _obscureBalance,
        onToggleMask: () => setState(() => _obscureBalance = !_obscureBalance),
        onViewWallets: widget.onViewWallets,
        onViewAssets: _navigateToAssets,
        onViewLoans: _navigateToLoans,
        onViewPlanning: widget.onViewPlanning,
        onViewTransactions: widget.onViewAllTransactions ?? _openTransactionHistory,
        onDateFilterTap: _openDateFilter,
      );
    }

    if (studio.heroCardStyle == AppHeroCardStyle.bentoLuxuryDeck) {
      return BentoLuxuryDeckCard(
        userId: widget.userId,
        provider: provider,
        totalBalance: totalBalance,
        income: income,
        expense: expense,
        netFlow: netFlow,
        isDark: isDark,
        studio: studio,
        masked: _obscureBalance,
        userName: widget.userName,
        onViewWallets: widget.onViewWallets,
        onDateFilterTap: _openDateFilter,
        onOwnerFilterTap: _openOwnerFilterModal,
        onToggleMask: () => setState(() => _obscureBalance = !_obscureBalance),
      );
    }

    final styleCtrl = context.watch<WidgetStyleController>();
    final assetStyle = styleCtrl.assetStyle;

    final isExecutive =
        studio.heroCardStyle == AppHeroCardStyle.executiveBlackVip;
    final isLiquidSphere =
        studio.heroCardStyle == AppHeroCardStyle.liquidEnergySphere;
    final isPulse = studio.heroCardStyle == AppHeroCardStyle.minimalistPulse;
    final isSpatialPrism =
        studio.heroCardStyle == AppHeroCardStyle.spatialPrismOrbital;

    final preset = WidgetStyleController.assetPresets.firstWhere(
      (p) => p.id == assetStyle,
      orElse: () => WidgetStyleController.assetPresets[0],
    );
    final cardPrimary = isExecutive
        ? const Color(0xFFFFD700)
        : (isSpatialPrism
            ? const Color(0xFF007AFF)
            : preset.accentColor);

    // Diurnal ambient sky tones for real-time dynamic environmental light
    final nowHour = DateTime.now().hour;
    final List<Color> ambientSkyColors = (nowHour >= 5 && nowHour < 11)
        ? [
            const Color(0xFFFF9A3C).withValues(alpha: isDark ? 0.28 : 0.14),
            const Color(0xFF007AFF).withValues(alpha: isDark ? 0.20 : 0.08),
          ]
        : (nowHour >= 11 && nowHour < 17)
            ? [
                const Color(0xFF007AFF).withValues(alpha: isDark ? 0.28 : 0.14),
                const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.20 : 0.09),
              ]
            : (nowHour >= 17 && nowHour < 20)
                ? [
                    const Color(0xFFFA709A).withValues(alpha: isDark ? 0.30 : 0.15),
                    const Color(0xFF7B2CBF).withValues(alpha: isDark ? 0.24 : 0.10),
                  ]
                : [
                    const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.24 : 0.11),
                    const Color(0xFF818CF8).withValues(alpha: isDark ? 0.20 : 0.08),
                  ];

    final cardBgGradient = isExecutive
        ? [
            const Color(0xFF0F1218),
            const Color(0xFF161B26),
            const Color(0xFF1A1F2C)
          ]
        : preset.gradientColors;
    final bool isLightCard = !isDark &&
        (preset.id == 5 ||
            (cardBgGradient.isNotEmpty &&
                ThemeData.estimateBrightnessForColor(cardBgGradient.first) ==
                    Brightness.light));
    final cardPadding = studio.getCardPadding(studio.dashboardDensity);
    final cardRadius = studio.getCardRadius(studio.dashboardDensity);

    final bool isLiquid = studio.isSystemWideLiquidGlass || isLiquidSphere || isSpatialPrism;
    final enableSpecular = studio.liquidGlassSpecularHighlight;
    final enableCaustics = studio.liquidGlassCausticRefraction;

    final Gradient effectiveHeroGradient = isSpatialPrism
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.32, 0.68, 1.0],
            colors: isDark
                ? [
                    const Color(0xFF080D1A),
                    Color.alphaBlend(
                        const Color(0xFF007AFF).withValues(alpha: 0.30),
                        const Color(0xFF0C162E)),
                    const Color(0xFF060914),
                    Color.alphaBlend(
                        const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                        const Color(0xFF04060E)),
                  ]
                : [
                    Colors.white,
                    const Color(0xFFF0F7FF),
                    Color.alphaBlend(
                        const Color(0xFF007AFF).withValues(alpha: 0.09),
                        const Color(0xFFE2EAFD)),
                    Color.alphaBlend(
                        const Color(0xFF00E5FF).withValues(alpha: 0.07),
                        const Color(0xFFD8EEFD)),
                  ],
          )
        : (isLiquid
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.45, 1.0],
                colors: isDark
                    ? [
                        Color.alphaBlend(
                            cardPrimary.withValues(alpha: 0.28),
                            const Color(0xFF142036)),
                        const Color(0xFF0C1424),
                        const Color(0xFF070D18),
                      ]
                    : [
                        Colors.white,
                        const Color(0xFFF8FAFD),
                        Color.alphaBlend(
                            cardPrimary.withValues(alpha: 0.08),
                            const Color(0xFFE8F2FD)),
                      ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: cardBgGradient,
              ));

    final List<BoxShadow> effectiveHeroShadows = isSpatialPrism
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 28,
              spreadRadius: -2,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: const Color(0xFF007AFF).withValues(alpha: isDark ? 0.22 : 0.10),
              blurRadius: 36,
              spreadRadius: -4,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.16 : 0.06),
              blurRadius: 48,
              spreadRadius: -6,
              offset: const Offset(0, 20),
            ),
          ]
        : (isLiquid
            ? [
                // Soft natural ambient occlusion shadow beneath the glass slab (zero halo)
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
                  blurRadius: 24,
                  spreadRadius: -3,
                  offset: const Offset(0, 10),
                ),
                // Whisper-soft diffused chromatic under-glow (tucked under body, negative spread)
                BoxShadow(
                  color: cardPrimary.withValues(alpha: isDark ? 0.10 : 0.05),
                  blurRadius: 32,
                  spreadRadius: -4,
                  offset: const Offset(0, 12),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .06),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ]);

    final Border effectiveHeroBorder = isSpatialPrism
        ? Border.all(
            color: (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))
                .withValues(alpha: isDark ? 0.32 : 0.20),
            width: 1.1,
          )
        : (isLiquid
            ? Border.all(
                color: (isDark ? Colors.white : const Color(0xFF0F172A))
                    .withValues(alpha: isDark ? 0.12 : 0.08),
                width: 1.0,
              )
            : Border.all(
                color: isLightCard
                    ? const Color(0xFFDDE5EF)
                    : Colors.white.withValues(alpha: .14),
              ));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: effectiveHeroShadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius),
        child: Stack(
          children: [
            // Layer 0: Solid foundation backing to prevent see-through washout
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(cardRadius),
                  color: isDark ? const Color(0xFF070B14) : Colors.white,
                ),
              ),
            ),

            // Layer 1: Base Translucent Gradient
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(cardRadius),
                gradient: effectiveHeroGradient,
                border: effectiveHeroBorder,
              ),
            ),

              // Layer 2: Theme background graphic
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.04,
                    child: _buildThemeBackgroundGraphic(assetStyle, cardPrimary),
                  ),
                ),
              ),

              // Layer 3: Simulated Caustic Refraction Sheen & Curved Meniscus
              if (isLiquid && enableCaustics)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: LiquidRefractionPainter(
                        borderRadius: cardRadius,
                        tintColor: cardPrimary,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),

              // Layer 4: 3D Liquid Energy Sphere (Ambient refraction, only when selected)
              if (isLiquidSphere)
                Positioned(
                  top: -30,
                  right: -30,
                  child: IgnorePointer(
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            cardPrimary.withValues(alpha: isDark ? 0.22 : 0.12),
                            (studio.resolvedSecondary).withValues(alpha: isDark ? 0.10 : 0.05),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

              // Layer 4b: Spatial Prism 3D (VisionOS Quả Cầu Quỹ Đạo & Tilted Celestial Halo)
              if (isSpatialPrism) ...[
                // Diurnal Ambient Luminescence (Di chuyển theo thời gian thực trong ngày)
                Positioned(
                  top: -45,
                  right: -25,
                  child: IgnorePointer(
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            ambientSkyColors[0],
                            ambientSkyColors[1],
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.48, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                // Optical depth counter-luminescence on lower-left
                Positioned(
                  bottom: -35,
                  left: -20,
                  child: IgnorePointer(
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.16 : 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Tilted Celestial Halo / Elliptical Orbital Ring (Vành đai quỹ đạo nghiêng)
                Positioned(
                  top: 22,
                  right: 28,
                  child: IgnorePointer(
                    child: Transform.rotate(
                      angle: -0.32,
                      child: Container(
                        width: 115,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.elliptical(115, 48)),
                          border: Border.all(
                            color: (isDark ? const Color(0xFF38BDF8) : const Color(0xFF007AFF))
                                .withValues(alpha: isDark ? 0.45 : 0.35),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.35 : 0.20),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // 3D Luminous Sphere with specular reflection
                Positioned(
                  top: 16,
                  right: 48,
                  child: IgnorePointer(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.35, -0.4),
                          radius: 0.85,
                          colors: isDark
                              ? [
                                  const Color(0xFFFFFFFF),
                                  const Color(0xFF67E8F9),
                                  const Color(0xFF0284C7),
                                  const Color(0xFF0F172A),
                                ]
                              : [
                                  const Color(0xFFFFFFFF),
                                  const Color(0xFFBAE6FD),
                                  const Color(0xFF0284C7),
                                  const Color(0xFF0369A1),
                                ],
                          stops: const [0.0, 0.3, 0.75, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.55 : 0.35),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.40 : 0.25),
                            blurRadius: 28,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4.5),
                              decoration: BoxDecoration(
                                color: isExecutive
                                    ? const Color(0xFFFFD700)
                                        .withValues(alpha: 0.20)
                                    : (isSpatialPrism
                                        ? const Color(0xFF00E5FF).withValues(alpha: 0.22)
                                        : (isLightCard
                                            ? const Color(0xFF3B82F6)
                                                .withValues(alpha: 0.15)
                                            : Colors.white.withValues(alpha: 0.18))),
                                shape: BoxShape.circle,
                                boxShadow: isSpatialPrism ? [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  )
                                ] : null,
                              ),
                              child: Icon(
                                isExecutive
                                    ? Icons.stars_rounded
                                    : (isSpatialPrism
                                        ? Icons.auto_awesome
                                        : Icons.account_balance_wallet_rounded),
                                size: 12,
                                color: isExecutive
                                    ? const Color(0xFFFFD700)
                                    : (isSpatialPrism
                                        ? (isDark ? const Color(0xFF67E8F9) : const Color(0xFF0284C7))
                                        : (isLightCard
                                            ? const Color(0xFF2563EB)
                                            : Colors.white)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                isExecutive
                                    ? 'VIP PORTFOLIO'
                                    : (isSpatialPrism
                                        ? 'SPATIAL ORBITAL'
                                        : 'TỔNG TÀI SẢN'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isExecutive
                                      ? const Color(0xFFFFD700)
                                      : (isSpatialPrism
                                          ? (isDark ? const Color(0xFFE0F2FE) : const Color(0xFF0F172A))
                                          : (isLightCard
                                              ? const Color(0xFF334155)
                                              : Colors.white.withValues(alpha: 0.85))),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: isSpatialPrism ? 0.8 : 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Actions: Integrated Liquid Glass Dual Capsule (Ultra-compact & sleek)
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: _buildHeroFilterActions(provider, isLightCard),
                        ),
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
                          child: FinoraPrivacyMask(
                            isMasked: studio.isPrivacyShieldActive,
                            style: studio.privacyStyle,
                            obscureText: '•••••••• đ',
                            child: FinoraAnimatedAmount(
                              amount: totalBalance,
                              style: TextStyle(
                                color: isExecutive
                                    ? Colors.white
                                    : (isLightCard
                                        ? const Color(0xFF0F172A)
                                        : Colors.white),
                                fontSize: studio.getHeroBalanceFontSize(),
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                              ),
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
                          studio.togglePrivacyShield();
                          setState(() =>
                              _obscureBalance = studio.isPrivacyShieldActive);
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
                            icon: studio.isPrivacyShieldActive
                                ? LucideIcons.eye_off
                                : LucideIcons.eye,
                            color: isLightCard
                                ? const Color(0xFF475569)
                                : Colors.white.withValues(alpha: 0.92),
                            size: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isExecutive) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 26,
                          height: 18,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFFDF00),
                                Color(0xFFB8860B),
                                Color(0xFFFFE082)
                              ],
                            ),
                          ),
                          child: const Icon(Icons.memory,
                              size: 13, color: Color(0xFF422006)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '••••  ••••  ••••  8899',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            letterSpacing: 1.8,
                            fontWeight: FontWeight.bold,
                            color:
                                const Color(0xFFFFD700).withValues(alpha: 0.85),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFFD700).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: const Color(0xFFFFD700)
                                    .withValues(alpha: 0.45),
                                width: 0.8),
                          ),
                          child: const Text(
                            'VIP CENTURION',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (isPulse) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: cardPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                                color: cardPrimary.withValues(alpha: 0.35),
                                width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: cardPrimary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color: cardPrimary,
                                        blurRadius: 4,
                                        spreadRadius: 1),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Chỉ số sức khỏe tài chính: Rất tốt (94/100)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isLightCard
                                      ? const Color(0xFF1E293B)
                                      : Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else if (isSpatialPrism) ...[
                    const SizedBox(height: 10),
                    _buildSpatialSatelliteWallets(provider, isDark, cardPrimary),
                  ],
                  const SizedBox(height: 14),

                  // 3. 3-Stat Subbar (Thu vào | Chi ra | Dòng tiền)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSpatialPrism
                          ? (isDark
                              ? const Color(0xFF0B1324).withValues(alpha: 0.55)
                              : Colors.white.withValues(alpha: 0.70))
                          : (isLiquid
                              ? (isLightCard
                                  ? Colors.white.withValues(alpha: 0.35)
                                  : Colors.black.withValues(alpha: 0.20))
                              : (isLightCard
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : Colors.black.withValues(alpha: 0.22))),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSpatialPrism
                            ? (isDark
                                ? const Color(0xFF38BDF8).withValues(alpha: 0.25)
                                : const Color(0xFF007AFF).withValues(alpha: 0.20))
                            : (isLiquid
                                ? (isDark
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : Colors.white.withValues(alpha: 0.65))
                                : (isLightCard
                                    ? const Color(0xFFCBD5E1)
                                    : Colors.white.withValues(alpha: 0.10))),
                        width: 0.9,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildColumnStat(
                            'Thu vào',
                            Formatters.formatCurrency(income),
                            studio.getIncomeColor(isDark),
                            Icons.arrow_downward_rounded,
                            isLightCard,
                            numericValue: income,
                            prefix: '+',
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
                            studio.getExpenseColor(isDark),
                            Icons.arrow_upward_rounded,
                            isLightCard,
                            numericValue: expense,
                            prefix: '-',
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
                            netFlow >= 0
                                ? studio.getIncomeColor(isDark)
                                : studio.getExpenseColor(isDark),
                            Icons.swap_vert_rounded,
                            isLightCard,
                            numericValue: netFlow,
                            prefix: netFlow > 0 ? '+' : '',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Layer 6: Micro-Specular Rim & Crowning Fresnel Lip Highlight
            if (isLiquid && enableSpecular)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: LiquidSpecularBorderPainter(
                      borderRadius: cardRadius,
                      borderWidth: 1.35,
                      borderGradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.22, 0.75, 1.0],
                        colors: isDark
                            ? const [
                                Color(0x35FFFFFF),
                                Color(0x0AFFFFFF),
                                Color(0x00FFFFFF),
                                Color(0x04FFFFFF),
                              ]
                            : const [
                                Color(0x40FFFFFF),
                                Color(0x0EFFFFFF),
                                Color(0x00FFFFFF),
                                Color(0x06FFFFFF),
                              ],
                      ),
                      enableSpecularHighlight: true,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsRow(bool isDark) {
    return _buildTitaniumActionDeck(isDark);
  }

  Widget _buildTitaniumActionDeck(bool isDark) {
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final cardRadius = studio?.getCardRadius(studio.globalDensity) ?? 20.0;
    final deckFill = studio?.getCardFillColor(isDark) ??
        (isDark ? const Color(0xFF111C30) : Colors.white);
    final borderColor = studio?.getBorderColor(isDark) ??
        (isDark ? const Color(0xFF22324D) : const Color(0xFFE2E8F0));

    return Container(
      decoration: BoxDecoration(
        color: deckFill,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(
          color: borderColor,
          width: 0.8,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _buildTitaniumActionSlot(
                  label: 'Quét QR',
                  icon: Icons.qr_code_scanner_rounded,
                  iconColor: const Color(0xFF2563EB),
                  isDark: isDark,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QrScannerScreen(userId: widget.userId),
                    ),
                  ),
                ),
              ),
              _buildTitaniumSlotDivider(isDark),
              Expanded(
                child: _buildTitaniumActionSlot(
                  label: 'Ghi chép',
                  icon: Icons.edit_calendar_rounded,
                  iconColor: const Color(0xFF059669),
                  isDark: isDark,
                  onTap: () => _push(AddTransactionPage(userId: widget.userId)),
                ),
              ),
              _buildTitaniumSlotDivider(isDark),
              Expanded(
                child: _buildTitaniumActionSlot(
                  label: 'Lịch sử',
                  icon: Icons.receipt_long_rounded,
                  iconColor: const Color(0xFFD97706),
                  isDark: isDark,
                  onTap: _openTransactionHistory,
                ),
              ),
              _buildTitaniumSlotDivider(isDark),
              Expanded(
                child: _buildTitaniumActionSlot(
                  label: 'Tài sản',
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: const Color(0xFF7C3AED),
                  isDark: isDark,
                  onTap: () {
                    if (widget.onViewWallets != null) {
                      widget.onViewWallets!();
                    } else {
                      _push(WalletScreen(userId: widget.userId));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitaniumSlotDivider(bool isDark) {
    return Container(
      width: 0.8,
      margin: const EdgeInsets.symmetric(vertical: 14),
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
    );
  }

  Widget _buildTitaniumActionSlot({
    required String label,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? iconColor.withValues(alpha: 0.18)
                      : iconColor.withValues(alpha: 0.10),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 20,
                    color: iconColor,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTransactionHistory() {
    if (widget.onViewAllTransactions != null) {
      widget.onViewAllTransactions!();
    } else {
      _push(WealthHubScreen(
        userId: widget.userId,
        familyId: widget.familyId,
        initialTabIndex: 0,
        isRoot: false,
      ));
    }
  }

  Widget _buildAiQuickLogBar(bool isDark, ThemeStudioController studio) {
    final primary = studio.primaryColor;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: studio.getCardFillColor(isDark),
        borderRadius: BorderRadius.circular(studio.cardCornerRadius),
        border: studio.getCardBorder(isDark),
      ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showAiQuickLogModal(context),
              borderRadius: BorderRadius.circular(studio.cardCornerRadius),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: isDark ? 0.22 : 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primary.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Icon(Icons.auto_awesome_rounded,
                          color: primary, size: 15),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Nhập nhanh với AI ("Ăn trưa 45k", "Đổ xăng 70k Momo")...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF334155),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: isDark ? 0.20 : 0.10),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primary.withValues(alpha: 0.35),
                          width: 0.9,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.mic_rounded,
                          size: 16,
                          color: primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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

          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  16, 14, 16, MediaQuery.of(ctx).viewInsets.bottom + 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
                ),
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
                          color:
                              const Color(0xFF94A3B8).withValues(alpha: 0.45),
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
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
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
                      textCapitalization: TextCapitalization.sentences,
                      inputFormatters: [FirstLetterUpperCaseFormatter()],
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
                          border: Border.all(
                              color: primary.withValues(alpha: 0.25)),
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
                                  FinoraNlpEngine.normalize(
                                      draft.walletName ?? ''),
                              orElse: () =>
                                  txProvider.wallets
                                      .where((w) =>
                                          !w.isCreditCard && w.type == 'cash')
                                      .firstOrNull ??
                                  txProvider.wallets
                                      .where((w) => !w.isCreditCard)
                                      .firstOrNull ??
                                  txProvider.wallets.first,
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
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
      ),
    );
  }

  Widget _buildHeroFilterActions(DashboardProvider provider, bool isLightCard) {
    final currentOwner = provider.selectedOwner;
    final memberLabel = currentOwner == OwnerFilter.husband
        ? 'Chồng'
        : (currentOwner == OwnerFilter.wife ? 'Vợ' : 'Tất cả');
    final memberVal = currentOwner == OwnerFilter.husband
        ? 'husband'
        : (currentOwner == OwnerFilter.wife ? 'wife' : 'all');

    final rawLabel = provider.data.periodLabel.isNotEmpty
        ? provider.data.periodLabel
        : _dateLabel;

    final String dateLabel;
    if (rawLabel.startsWith('Hôm nay')) {
      dateLabel = 'Hôm nay';
    } else if (rawLabel.startsWith('Hôm qua')) {
      dateLabel = 'Hôm qua';
    } else if (rawLabel.startsWith('Toàn bộ')) {
      dateLabel = 'Tất cả';
    } else if (rawLabel.startsWith('Tháng ')) {
      dateLabel = rawLabel.replaceFirst('Tháng ', 'T');
    } else if (rawLabel.length > 10) {
      dateLabel = rawLabel.substring(0, 10);
    } else {
      dateLabel = rawLabel;
    }

    return FinoraHeroFilterCapsule(
      memberLabel: memberLabel,
      memberValue: memberVal,
      onMemberTap: _openOwnerFilterModal,
      dateLabel: dateLabel,
      onDateTap: _openDateFilter,
      isLightCard: isLightCard,
    );
  }

  Widget _buildSpatialSatelliteWallets(
      DashboardProvider provider, bool isDark, Color primary) {
    final wallets = provider.data.wallets;
    if (wallets.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayWallets = wallets.take(3).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < displayWallets.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            _buildSatellitePill(displayWallets[i], isDark, primary, i),
          ],
          if (wallets.length > 3) ...[
            const SizedBox(width: 6),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.lightImpact();
                if (widget.onViewWallets != null) {
                  widget.onViewWallets!();
                } else {
                  _push(WalletScreen(userId: widget.userId));
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.08),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '+${wallets.length - 3}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF334155),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        size: 13, color: Colors.white60),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSatellitePill(
      Wallet wallet, bool isDark, Color primary, int index) {
    final shortName = (wallet.bankCode != null && wallet.bankCode!.isNotEmpty)
        ? wallet.bankCode!
        : (wallet.name.length > 10
            ? '${wallet.name.substring(0, 9)}…'
            : wallet.name);

    final balanceFormatted = _formatCompactSatelliteMoney(wallet.balance);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        if (widget.onViewWallets != null) {
          widget.onViewWallets!();
        } else {
          _push(WalletScreen(userId: widget.userId));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0F172A).withValues(alpha: 0.65)
              : Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: (index == 0 ? const Color(0xFF00E5FF) : primary)
                .withValues(alpha: isDark ? 0.35 : 0.25),
            width: 0.9,
          ),
          boxShadow: [
            BoxShadow(
              color: (index == 0 ? const Color(0xFF00E5FF) : primary)
                  .withValues(alpha: isDark ? 0.15 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == 0
                    ? const Color(0xFF00E5FF)
                    : (index == 1
                        ? const Color(0xFF38BDF8)
                        : const Color(0xFF818CF8)),
                boxShadow: [
                  BoxShadow(
                    color: index == 0
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF38BDF8),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Text(
              shortName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.85)
                    : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              balanceFormatted,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: isDark
                    ? const Color(0xFF7DD3FC)
                    : const Color(0xFF0284C7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCompactSatelliteMoney(num val) {
    if (val.abs() >= 1000000000) {
      return '${(val / 1000000000).toStringAsFixed(1)}B';
    } else if (val.abs() >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}M';
    } else if (val.abs() >= 1000) {
      return '${(val / 1000).toStringAsFixed(0)}k';
    }
    return '${val.toInt()}đ';
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
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                  width: 1.0,
                ),
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
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
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
                                  ? Colors.white
                                  : const Color(0xFF0F172A)),
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
                    accentColor: const Color(0xFF005FEA),
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
                    accentColor: const Color(0xFF0284C7),
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
              ? accentColor.withValues(alpha: isDark ? 0.20 : 0.12)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.035)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? accentColor
                : (isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.07)),
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
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
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
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }


  Widget _buildColumnStat(
      String label, String value, Color color, IconData icon, bool isLightCard,
      {num? numericValue, String prefix = ''}) {
    final studio = context.watch<ThemeStudioController>();
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: FinoraPrivacyMask(
            isMasked: studio.isPrivacyShieldActive,
            style: studio.privacyStyle,
            obscureText: '••••••',
            child: numericValue != null
                ? FinoraAnimatedAmount(
                    amount: numericValue,
                    prefix: prefix,
                    style: TextStyle(
                      color: color,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                  ),
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
    final studio = context.watch<ThemeStudioController>();

    final cardRadius = studio.getCardRadius(studio.dashboardDensity);
    final cardPadding = studio.getCardPadding(studio.dashboardDensity);

    final budgetGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              const Color(0xFF0F262B).withValues(alpha: studio.glassOpacity),
              const Color(0xFF131D24).withValues(alpha: studio.glassOpacity)
            ]
          : [
              const Color(0xFFF0FDFA).withValues(alpha: studio.glassOpacity),
              Colors.white.withValues(alpha: studio.glassOpacity)
            ],
    );

    return _buildGlassCardContainer(
      studio: studio,
      isDark: isDark,
      radius: cardRadius,
      padding: EdgeInsets.all(cardPadding),
      gradient: budgetGradient,
      border: studio.borderGlowStyle == CardBorderGlowStyle.none
          ? null
          : (studio.getCardBorder(isDark) ??
              Border.all(
                color: accent.withValues(alpha: isDark ? 0.30 : 0.18),
                width: 1,
              )),
      shadows: [
        ...studio.getGlowShadows(isDark),
        BoxShadow(
          color: accent.withValues(alpha: isDark ? 0.12 : 0.05),
          blurRadius: 18,
          offset: const Offset(0, 5),
        ),
      ],
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
                onTap: _navigateToPlanning,
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
              Expanded(
                child: Text(
                  budgets.isEmpty
                      ? 'Bắt đầu từ một danh mục'
                      : (remaining < 0 ? 'Vượt ngân sách' : 'Còn lại'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildBudgetProgressIndicator(
            studio: studio,
            progress: progress,
            remaining: remaining,
            accent: accent,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Đã chi: ${formatVND(totalSpent)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Hạn mức: ${formatVND(totalLimit)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
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

  Widget _buildBudgetProgressIndicator({
    required ThemeStudioController studio,
    required double progress,
    required int remaining,
    required Color accent,
    required bool isDark,
  }) {
    final isOverBudget = remaining < 0;
    final primaryColor = isOverBudget ? const Color(0xFFE11D48) : accent;

    switch (studio.budgetStyle) {
      case AppBudgetStyle.liquidBar:
        return Container(
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: accent.withValues(alpha: 0.15),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final activeWidth = constraints.maxWidth * progress;
              return Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    width: activeWidth.clamp(0.0, constraints.maxWidth),
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: isOverBudget
                            ? [const Color(0xFFF43F5E), const Color(0xFFE11D48)]
                            : [
                                accent,
                                const Color(0xFF14B8A6),
                                const Color(0xFF2DD4BF)
                              ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.45),
                          blurRadius: 8,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );

      case AppBudgetStyle.speedometerGauge:
        return SizedBox(
          height: 52,
          child: CustomPaint(
            painter: SpeedometerGaugePainter(
              progress: progress,
              trackColor: accent.withValues(alpha: 0.15),
              progressColor: primaryColor,
              strokeWidth: 8.0,
            ),
          ),
        );

      case AppBudgetStyle.minimalCapsule:
        const totalSegments = 10;
        final activeSegments =
            (progress * totalSegments).round().clamp(0, totalSegments);
        return Row(
          children: List.generate(totalSegments, (index) {
            final isActive = index < activeSegments;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color:
                      isActive ? primaryColor : accent.withValues(alpha: 0.14),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.35),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        );
    }
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
      onTap: () => _push(AiAdvisorScreen(
        userId: widget.userId,
        familyId: widget.familyId,
      )),
      child: FloatingGlassCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        radius: 22,
        blur: 0,
        glow: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD1FAE5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield_outlined,
                            color: Color(0xFF059669), size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sức khỏe tài chính\nFinora AI',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Container(
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
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
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
          ),
        ),
      ],
    );
  }

  Widget _buildWalletsSection(DashboardData d, bool isDark) {
    final wallets = d.wallets;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
      ],
    );
  }

  Widget _buildInvestmentsSection(DashboardData d, bool isDark) {
    final more = context.watch<MoreProvider>();
    final realAssets = more.assets;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildWealthRowHeader(
          title: 'Đầu tư',
          count: realAssets.length,
          icon: Icons.trending_up_rounded,
          gradientColors: const [Color(0xFF059669), Color(0xFF10B981)],
          isDark: isDark,
          onViewAll: _navigateToAssets,
        ),
        const SizedBox(height: 10),
        _buildInvestmentSummaryWidget(realAssets, isDark),
      ],
    );
  }

  Widget _buildLoansSection(DashboardData d, bool isDark) {
    final more = context.watch<MoreProvider>();
    final realLoans = more.loans;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildWealthRowHeader(
          title: 'Cho vay & Sổ nợ',
          count: realLoans.length,
          icon: Icons.handshake_rounded,
          gradientColors: const [Color(0xFFD97706), Color(0xFFF59E0B)],
          isDark: isDark,
          onViewAll: _navigateToLoans,
        ),
        const SizedBox(height: 10),
        _buildLoansSummaryWidgets(realLoans, isDark),
      ],
    );
  }

  Widget? _buildDashboardModule(
    DashboardModuleId id,
    DashboardProvider provider,
    DashboardData d,
    num totalBalance,
    num income,
    num expense,
    num netFlow,
    List<TransactionModel> txList,
    bool isDark,
    ThemeStudioController studio,
  ) {
    if (!studio.isDashboardModuleEnabled(id)) return null;

    switch (id) {
      case DashboardModuleId.heroCard:
        return _buildHeroCard(
            provider, totalBalance, income, expense, netFlow, isDark, studio);
      case DashboardModuleId.quickActions:
        if (studio.heroCardStyle == AppHeroCardStyle.netWorthModernDeck ||
            studio.heroCardStyle == AppHeroCardStyle.zenvestGlassDeck) {
          return const SizedBox.shrink();
        }
        return _buildQuickActionsRow(isDark);
      case DashboardModuleId.aiQuickLog:
        if (studio.heroCardStyle == AppHeroCardStyle.zenvestGlassDeck) {
          return const SizedBox.shrink();
        }
        if (!studio.showQuickLog) return null;
        return _buildAiQuickLogBar(isDark, studio);
      case DashboardModuleId.aiHealthScore:
        if (studio.heroCardStyle == AppHeroCardStyle.netWorthModernDeck ||
            studio.heroCardStyle == AppHeroCardStyle.zenvestGlassDeck) {
          return const SizedBox.shrink();
        }
        if (!studio.showAiInsight) return null;
        return _buildHealthScoreCard(d, isDark);
      case DashboardModuleId.budgetProgress:
        return _buildBudgetSection(d, isDark);
      case DashboardModuleId.walletsAccounts:
        return _buildWalletsSection(d, isDark);
      case DashboardModuleId.investmentsAssets:
        return _buildInvestmentsSection(d, isDark);
      case DashboardModuleId.loansDebts:
        return _buildLoansSection(d, isDark);
      case DashboardModuleId.recentTransactions:
        if (studio.heroCardStyle == AppHeroCardStyle.zenvestGlassDeck) {
          return const SizedBox.shrink();
        }
        return _buildRecentTransactionsSection(txList, isDark);
    }
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
        Expanded(
          flex: 3,
          child: Row(
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
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
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
        ),
        const SizedBox(width: 8),
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
    final studio = context.watch<ThemeStudioController>();
    final cardBg = (isDark ? const Color(0xFF111C30) : Colors.white)
        .withValues(alpha: studio.glassOpacity);
    final cardBorder = studio.getCardBorder(isDark);
    const emeraldAccent = Color(0xFF0D9488); // Deep forest teal-emerald
    final emeraldBadgeBg = isDark
        ? const Color(0xFF0D9488).withValues(alpha: 0.18)
        : const Color(0xFF0D9488).withValues(alpha: 0.08);

    return GestureDetector(
      onTap: _navigateToAssets,
      child: _buildGlassCardContainer(
        studio: studio,
        isDark: isDark,
        radius: studio.cardCornerRadius,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        color: cardBg,
        border: cardBorder,
        shadows: [
          BoxShadow(
            color:
                const Color(0xFF0F172A).withValues(alpha: isDark ? 0.28 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: Icon + Title + Category Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
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
                      Expanded(
                        child: Text(
                          'Tổng giá trị đầu tư',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
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
                      FinoraPrivacyMask(
                        isMasked: studio.isPrivacyShieldActive,
                        style: studio.privacyStyle,
                        obscureText: '••••••••',
                        child: Text(
                          Formatters.formatCurrency(totalInvestment.toInt()),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
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
                // Apple-style Mini Sparkline Trend Chart
                Builder(
                  builder: (context) {
                    final chartColors = studio.getChartColors(isDark);
                    final lineColor = chartColors.first;
                    final double fillAlpha = studio.chartAreaFill ==
                            AppChartAreaFill.neonGlow
                        ? 0.35
                        : (studio.chartAreaFill == AppChartAreaFill.subtleGlass
                            ? 0.08
                            : 0.0);
                    return SizedBox(
                      width: 92,
                      height: 44,
                      child: CustomPaint(
                        painter: _InvestmentSparklinePainter(
                          lineColor: lineColor,
                          fillColor: lineColor.withValues(alpha: fillAlpha),
                          isGain: gainPercent >= 0,
                          curveStyle: studio.chartCurveStyle,
                          areaFill: studio.chartAreaFill,
                        ),
                      ),
                    );
                  },
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
    final studio = context.watch<ThemeStudioController>();
    final cardBg = (isDark ? const Color(0xFF111C30) : Colors.white)
        .withValues(alpha: studio.glassOpacity);
    final cardBorder = studio.getCardBorder(isDark);

    const lentColor = Color(0xFF0D9488); // Forest Emerald
    const borrowedColor = Color(0xFFE11D48); // Deep Ruby Crimson

    return Row(
      children: [
        // Card 2: Đã cho vay
        Expanded(
          child: GestureDetector(
            onTap: _navigateToLoans,
            child: _buildGlassCardContainer(
              studio: studio,
              isDark: isDark,
              radius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              color: cardBg,
              border: cardBorder,
              shadows: [
                BoxShadow(
                  color: const Color(0xFF0F172A)
                      .withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Icon + Title + Chevron
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
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
                            Expanded(
                              child: Text(
                                'Đã cho vay',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
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
                  FinoraPrivacyMask(
                    isMasked: studio.isPrivacyShieldActive,
                    style: studio.privacyStyle,
                    obscureText: '••••••••',
                    child: Text(
                      Formatters.formatCurrency(totalLent),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: isDark ? const Color(0xFF2DD4BF) : lentColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
            onTap: _navigateToLoans,
            child: _buildGlassCardContainer(
              studio: studio,
              isDark: isDark,
              radius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              color: cardBg,
              border: cardBorder,
              shadows: [
                BoxShadow(
                  color: const Color(0xFF0F172A)
                      .withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Icon + Title + Chevron
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
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
                            Expanded(
                              child: Text(
                                'Đang nợ',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
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
                  FinoraPrivacyMask(
                    isMasked: studio.isPrivacyShieldActive,
                    style: studio.privacyStyle,
                    obscureText: '••••••••',
                    child: Text(
                      Formatters.formatCurrency(totalBorrowed),
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
      return const GlassCard(
          child: Padding(
        padding: EdgeInsets.all(12),
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
            walletId: wallet.id,
          );
        },
      ),
    );
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
    String? walletId,
  }) {
    final studio = context.watch<ThemeStudioController>();
    final isWifeWallet = owner == 'wife' || name.toLowerCase().contains('vợ');
    final ownerLabel = isWifeWallet
        ? 'Vợ'
        : owner == 'husband'
            ? 'Chồng'
            : 'Chung';

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

    final gradient = studio.getBankCardGradient(
      walletId: walletId,
      bankCode: effectiveCode ?? bankCode,
      bankName: bankName,
      name: name,
      themeColor: themeColor,
    );

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
          border: studio.borderGlowStyle == CardBorderGlowStyle.none
              ? null
              : (studio.getCardBorder(isDark) ??
                  Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 1.1,
                  )),
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
                    child: FinoraPrivacyMask(
                      isMasked: studio.isPrivacyShieldActive,
                      style: studio.privacyStyle,
                      obscureText: '••••••••',
                      child: Text(
                        Formatters.formatCurrency(balance),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
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
    final studio = context.watch<ThemeStudioController>();
    final displayList = transactions.take(15).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0284C7).withValues(alpha: 0.18)
                          : const Color(0xFFE0F2FE),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.receipt_long_rounded,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        size: 16),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Giao dịch gần đây',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
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
            ),
            const SizedBox(width: 8),
            FinoraSectionActionPill(
              label: 'Xem tất cả',
              onTap: _openTransactionHistory,
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (transactions.isEmpty)
          _buildGlassCardContainer(
            studio: studio,
            isDark: isDark,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            color: (isDark ? const Color(0xFF1E293B) : Colors.white)
                .withValues(alpha: studio.glassOpacity),
            border: studio.borderGlowStyle == CardBorderGlowStyle.none
                ? null
                : (studio.getCardBorder(isDark) ??
                    Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                      width: 1.5,
                    )),
            shadows: [
              ...studio.getGlowShadows(isDark),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.035),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
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
        else if (studio.transactionListStyle ==
            AppTransactionListStyle.bentoCards)
          _buildBentoTransactionList(
              displayList, transactions.length, isDark, studio)
        else
          Column(
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
                FinoraStaggeredItem(
                  index: i,
                  child: _buildTimelineTransactionItem(
                    displayList[i],
                    isDark,
                    isLastOverall: i == displayList.length - 1,
                  ),
                ),
              ],
              if (transactions.length > 5) ...[
                const SizedBox(height: 6),
                Center(
                  child: FinoraIconAction(
                    icon: Icons.arrow_forward_rounded,
                    label: 'Xem tất cả ${transactions.length} giao dịch',
                    onPressed: _openTransactionHistory,
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildBentoTransactionList(
    List<TransactionModel> displayList,
    int totalCount,
    bool isDark,
    ThemeStudioController studio,
  ) {
    final Map<String, List<TransactionModel>> grouped = {};
    for (final tx in displayList) {
      final key = DateFormat('yyyy-MM-dd').format(_parseTxDate(tx.date));
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in grouped.entries) ...[
          Builder(builder: (context) {
            final txs = entry.value;
            final date = _parseTxDate(txs.first.date);
            final dayTotal = txs.fold<int>(0, (sum, tx) {
              if (TransactionVisuals.isInflow(tx.type)) {
                return sum + tx.amount;
              } else if (TransactionVisuals.isOutflow(tx.type) &&
                  !TransactionVisuals.isTransfer(tx.type)) {
                return sum - tx.amount;
              }
              return sum;
            });

            return _buildGlassCardContainer(
              studio: studio,
              isDark: isDark,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              color: (isDark ? const Color(0xFF131D33) : Colors.white)
                  .withValues(alpha: studio.glassOpacity),
              border: studio.borderGlowStyle == CardBorderGlowStyle.none
                  ? null
                  : (studio.getCardBorder(isDark) ??
                      Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      )),
              shadows: [
                ...studio.getGlowShadows(isDark),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month_rounded,
                                size: 14, color: studio.primaryColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _formatRecentDateLabel(date),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? const Color(0xFFE2E8F0)
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: (dayTotal >= 0
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFDC2626))
                              .withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          dayTotal >= 0
                              ? '+${formatVND(dayTotal)}'
                              : '-${formatVND(dayTotal.abs())}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: dayTotal >= 0
                                ? const Color(0xFF059669)
                                : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (int i = 0; i < txs.length; i++) ...[
                    _buildTransactionCard(txs[i], isDark),
                    if (i < txs.length - 1) const SizedBox(height: 8),
                  ],
                ],
              ),
            );
          }),
        ],
        if (totalCount > 5) ...[
          const SizedBox(height: 6),
          Center(
            child: FinoraIconAction(
              icon: Icons.arrow_forward_rounded,
              label: 'Xem tất cả $totalCount giao dịch',
              onPressed: _openTransactionHistory,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimelineDateHeader(
    DateTime date,
    bool isDark, {
    required bool isFirstDate,
  }) {
    final label = _formatRecentDateLabel(date);

    return Padding(
      padding: EdgeInsets.only(top: isFirstDate ? 4 : 18, bottom: 8),
      child: Row(
        children: [
          Flexible(
            flex: 4,
            fit: FlexFit.loose,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131D31) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? const Color(0xFF22324D) : const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Container(
              height: 0.8,
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTransactionItem(
    TransactionModel tx,
    bool isDark, {
    required bool isLastOverall,
  }) {
    final isExpense = TransactionVisuals.isOutflow(tx.type) &&
        !TransactionVisuals.isTransfer(tx.type);
    final isIncome = TransactionVisuals.isInflow(tx.type);
    final nodeColor = isIncome
        ? const Color(0xFF059669)
        : (isExpense ? const Color(0xFFE11D48) : const Color(0xFF2563EB));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left timeline rail: ultra-sleek hairline + metallic node
          SizedBox(
            width: 24,
            child: Stack(
              children: [
                // Continuous vertical line
                Positioned(
                  left: 11,
                  top: 0,
                  bottom: isLastOverall ? null : 0,
                  height: isLastOverall ? 28 : null,
                  width: 1.2,
                  child: Container(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                // Horizontal branch connector
                Positioned(
                  left: 12,
                  top: 27,
                  right: 0,
                  height: 1.2,
                  child: Container(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                // Timeline node dot
                Positioned(
                  left: 8,
                  top: 24,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: nodeColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: nodeColor.withValues(alpha: 0.35),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Right column: Separated individual transaction card
          Expanded(
            child: _buildTransactionCard(tx, isDark),
          ),
        ],
      ),
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

  Widget _buildTransactionCard(TransactionModel tx, bool isDark) {
    final moreCats = context.watch<MoreProvider?>()?.categories ?? [];
    final txCats = context.watch<TransactionProvider?>()?.categories ?? [];
    final allCats = [...moreCats, ...txCats];
    final matchingCategory = allCats.cast<dynamic>().firstWhere(
          (category) {
            final catId = category?.id?.toString().trim().toLowerCase();
            final catName = category?.name?.toString().trim().toLowerCase();
            final txCatId = tx.categoryId?.trim().toLowerCase();
            final txCatName = tx.categoryName?.trim().toLowerCase();
            return (txCatId != null && txCatId.isNotEmpty && txCatId == catId) ||
                (txCatName != null && txCatName.isNotEmpty && txCatName == catName);
          },
          orElse: () => null,
        );
    final resolvedCategoryIcon = matchingCategory?.icon ?? tx.categoryIcon;
    final resolvedCategoryName = matchingCategory?.name ?? tx.categoryName;
    final resolvedCategoryColor = matchingCategory?.color ?? tx.categoryColor;

    final wallets = context.watch<TransactionProvider>().wallets;
    final wId = tx.walletId ?? tx.fromWalletId;
    final wName = tx.walletName ?? tx.fromWalletName;
    final matchingWallet = wallets.cast<Wallet?>().firstWhere(
          (w) =>
              (wId?.isNotEmpty == true && w?.id == wId) ||
              (wName?.isNotEmpty == true && w?.name == wName),
          orElse: () => null,
        );
    final displayName = matchingWallet?.name ?? wName ?? 'Ví chính';
    var effectiveCode = matchingWallet?.bankCode ?? matchingWallet?.type;
    if (effectiveCode == null || effectiveCode.isEmpty) {
      final clean =
          displayName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (clean.contains('tietkiem') ||
          clean.contains('tiếtkiệm') ||
          clean.contains('mb')) {
        effectiveCode = 'mbbank';
      } else if (clean.contains('tcb') || clean.contains('techcom')) {
        effectiveCode = 'tcb';
      }
    }
    final brand = BankIconRegistry.resolve(
      effectiveCode ?? matchingWallet?.bankName,
      bankName: displayName,
    );

    final isExpense = TransactionVisuals.isOutflow(tx.type) &&
        !TransactionVisuals.isTransfer(tx.type);
    final isIncome = TransactionVisuals.isInflow(tx.type);
    final txDate = _parseTxDate(tx.date);
    final studio = context.watch<ThemeStudioController>();

    final effectiveRadius = studio.getCardRadius(studio.transactionDensity);
    final effectivePadding = switch (studio.transactionDensity) {
      CardDensity.compact =>
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      CardDensity.standard =>
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      CardDensity.spacious =>
        const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
    };
    final effectiveMargin = switch (studio.transactionDensity) {
      CardDensity.compact => const EdgeInsets.only(bottom: 6),
      CardDensity.standard => const EdgeInsets.only(bottom: 10),
      CardDensity.spacious => const EdgeInsets.only(bottom: 14),
    };

    return _buildGlassCardContainer(
      studio: studio,
      isDark: isDark,
      radius: effectiveRadius,
      margin: effectiveMargin,
      border: studio.getCardBorder(isDark),
      shadows: [
        ...studio.getGlowShadows(isDark),
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.025),
          blurRadius: 6,
          offset: const Offset(0, 1.5),
        ),
      ],
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showTransactionDetailSheet(
            context,
            userId: widget.userId,
            transaction: tx,
          ),
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: Padding(
            padding: effectivePadding,
            child: Row(
              children: [
                // 1. Category Icon (clean, no overlapped badge)
                TransactionIconWidget(
                  type: tx.type,
                  categoryIcon: resolvedCategoryIcon,
                  categoryName: resolvedCategoryName ?? tx.note,
                  categoryColor: resolvedCategoryColor,
                  merchantId: tx.merchantId,
                  merchantName: tx.merchantName,
                  bankBrand: brand,
                  showBankBadge: false,
                  size: 40,
                ),
                const SizedBox(width: 12),
                // 2. Note & Unified Member/Wallet Badge
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
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                          height: 1.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: _buildUnifiedMemberWalletBadge(tx, isDark),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 3. Amount & Time (Right corner — Always pinned flush right)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 112),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: FinoraPrivacyMask(
                          isMasked: studio.isPrivacyShieldActive,
                          style: studio.privacyStyle,
                          obscureText: '••••••',
                          child: Text(
                            '${isIncome ? '+' : (isExpense ? '-' : '')} ${Formatters.formatCurrency(tx.amount)}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                              fontFeatures: const [FontFeature.tabularFigures()],
                              color: isIncome
                                  ? (isDark
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFF059669))
                                  : (isExpense
                                      ? (isDark
                                          ? const Color(0xFFFB7185)
                                          : const Color(0xFFE11D48))
                                      : (isDark
                                          ? const Color(0xFF34D399)
                                          : const Color(0xFF0F6E56))),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        DateFormat('HH:mm').format(txDate),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
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
    );
  }

  Widget _buildUnifiedMemberWalletBadge(TransactionModel tx, bool isDark) {
    final wallets = context.watch<TransactionProvider>().wallets;
    final wId = tx.walletId ?? tx.fromWalletId;
    final wName = tx.walletName ?? tx.fromWalletName;
    final matchingWallet = wallets.cast<Wallet?>().firstWhere(
          (w) =>
              (wId?.isNotEmpty == true && w?.id == wId) ||
              (wName?.isNotEmpty == true && w?.name == wName),
          orElse: () => null,
        );
    final displayName = matchingWallet?.name ?? wName ?? 'Ví chính';
    final rawBankCode = matchingWallet?.bankCode ?? matchingWallet?.type;
    var effectiveCode = rawBankCode;
    if (effectiveCode == null || effectiveCode.isEmpty) {
      final clean =
          displayName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (clean.contains('tietkiem') ||
          clean.contains('tiếtkiệm') ||
          clean.contains('mb')) {
        effectiveCode = 'mbbank';
      } else if (clean.contains('tcb') || clean.contains('techcom')) {
        effectiveCode = 'tcb';
      }
    }
    final brand = BankIconRegistry.resolve(
      effectiveCode ?? matchingWallet?.bankName,
      bankName: displayName,
    );
    final isCash = brand.code == 'cash' ||
        displayName.toLowerCase().contains('tiền mặt') ||
        displayName.toLowerCase().contains('tien mat');

    final resolved = context.read<TransactionProvider>().memberFor(tx);
    final isWife = resolved == TransactionMember.wife;
    final isJoint = resolved == TransactionMember.joint;

    final String memberLabel;
    final Color memberAccent;
    final IconData memberIcon;
    if (isWife) {
      memberLabel = 'Vợ';
      memberAccent = const Color(0xFFE11D48);
      memberIcon = Icons.favorite_rounded;
    } else if (isJoint) {
      memberLabel = 'Chung';
      memberAccent = const Color(0xFFD97706);
      memberIcon = Icons.group_rounded;
    } else {
      memberLabel = 'Chồng';
      memberAccent = const Color(0xFF2563EB);
      memberIcon = Icons.person_rounded;
    }

    final isAi = tx.tags.contains('Finora AI') || tx.creatorTag == 'AI';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141F33) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: isDark ? const Color(0xFF22324D) : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Member Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
            decoration: BoxDecoration(
              color: memberAccent.withValues(alpha: isDark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(4.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(memberIcon, size: 9.5, color: memberAccent),
                const SizedBox(width: 3),
                Text(
                  memberLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: memberAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          // 2. Micro Dot
          Text(
            '·',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 5),
          // 3. Wallet Logo + Name
          if (isCash)
            const Text('💵', style: TextStyle(fontSize: 10))
          else if (brand.assetPath != null)
            ClipOval(
              child: Image.asset(
                brand.assetPath!,
                width: 12,
                height: 12,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 10.5,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
            )
          else
            Icon(
              Icons.account_balance_wallet_rounded,
              size: 10.5,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              ),
            ),
          ),
          // 4. Subtle AI badge
          if (isAi) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF005FEA).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'AI',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0284C7),
                ),
              ),
            ),
          ],
        ],
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
class FinoraSectionActionPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const FinoraSectionActionPill({
    super.key,
    this.label = 'Xem tất cả',
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (label.toLowerCase().contains('thêm')) {
      return FinoraPillButton(
        icon: Icons.add_rounded,
        label: label,
        onTap: onTap,
        compact: true,
        primary: true,
      );
    }
    return FinoraSeeAllButton(
      label: label,
      onTap: onTap,
    );
  }
}

/// Mini Sparkline Trend Painter for Investment Card
class _InvestmentSparklinePainter extends CustomPainter {
  final Color lineColor;
  final Color fillColor;
  final bool isGain;
  final AppChartCurveStyle curveStyle;
  final AppChartAreaFill areaFill;

  const _InvestmentSparklinePainter({
    required this.lineColor,
    required this.fillColor,
    this.isGain = true,
    this.curveStyle = AppChartCurveStyle.smoothSpline,
    this.areaFill = AppChartAreaFill.neonGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final width = size.width;
    final height = size.height;

    // Points
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
      if (curveStyle == AppChartCurveStyle.straightSharp) {
        path.lineTo(p1.dx, p1.dy);
      } else if (curveStyle == AppChartCurveStyle.steppedMatrix) {
        path.lineTo(p1.dx, p0.dy);
        path.lineTo(p1.dx, p1.dy);
      } else {
        final ctrl1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
        final ctrl2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
        path.cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, p1.dx, p1.dy);
      }
    }

    // Gradient Area Fill Under Curve
    if (areaFill != AppChartAreaFill.outlineOnly) {
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
    }

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
      oldDelegate.lineColor != lineColor ||
      oldDelegate.fillColor != fillColor ||
      oldDelegate.isGain != isGain ||
      oldDelegate.curveStyle != curveStyle ||
      oldDelegate.areaFill != areaFill;
}
