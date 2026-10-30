// ignore_for_file: unused_element, unused_element_parameter, duplicate_ignore
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/finora_mascot.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/finora_privacy_mask.dart';
import '../../core/theme/finora_tokens.dart';
// ignore: unused_import
import '../../core/widgets/ai_context_button.dart';
import '../../state/budget_provider.dart';
import '../../state/more_provider.dart';
import '../../state/dashboard_provider.dart';
import '../../state/transaction_provider.dart';
import '../../state/theme_studio_controller.dart';
import '../budget/budget_screen.dart';
import '../goal/goal_screen.dart';
import '../report/report_screen.dart';

/// Siêu Trung Tâm Quản Lý Kế Hoạch & Báo Cáo Tài Chính (PlanningHubScreen)
/// Hợp nhất 3 phân hệ cốt lõi: Ngân sách chi tiêu, Mục tiêu tích luỹ & Báo cáo dòng tiền.
class PlanningHubScreen extends StatefulWidget {
  final String userId;
  final String? familyId;
  final bool isRoot;
  final int initialTabIndex;

  const PlanningHubScreen({
    super.key,
    required this.userId,
    this.familyId,
    this.isRoot = false,
    this.initialTabIndex = 0,
  });

  @override
  State<PlanningHubScreen> createState() => _PlanningHubScreenState();
}

class _PlanningHubScreenState extends State<PlanningHubScreen> {
  late int _selectedTab; // 0: Ngân sách, 1: Mục tiêu, 2: Báo cáo
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex.clamp(0, 2);
    _pageController = PageController(initialPage: _selectedTab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        context
            .read<BudgetProvider>()
            .load(widget.userId, familyId: widget.familyId);
      } catch (_) {}
      try {
        context
            .read<MoreProvider>()
            .load(widget.userId, familyId: widget.familyId);
      } catch (_) {}
      try {
        context
            .read<DashboardProvider>()
            .load(widget.userId, familyId: widget.familyId);
      } catch (_) {}
      try {
        context.read<TransactionProvider>().load(widget.userId);
      } catch (_) {}
    });
  }

  @override
  void didUpdateWidget(covariant PlanningHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.familyId != widget.familyId) {
      try {
        context
            .read<BudgetProvider>()
            .load(widget.userId, familyId: widget.familyId);
      } catch (_) {}
      try {
        context
            .read<MoreProvider>()
            .load(widget.userId, familyId: widget.familyId);
      } catch (_) {}
      try {
        context
            .read<DashboardProvider>()
            .load(widget.userId, familyId: widget.familyId);
      } catch (_) {}
      try {
        context.read<TransactionProvider>().load(widget.userId);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (_selectedTab != index) {
      HapticFeedback.selectionClick();
      setState(() => _selectedTab = index);
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  // ignore: unused_element
  void _openQuickAdd() {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showFinoraGlassModalBottomSheet(
      context: context,
      title: 'Tạo kế hoạch mới',
      subtitle: 'Chọn loại kế hoạch tài chính muốn khởi tạo',
      icon: Icons.add_circle_outline_rounded,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(ctx).padding.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionItem(
              context: ctx,
              title: 'Thêm định mức ngân sách',
              subtitle:
                  'Thiết lập hạn mức chi tiêu cho nhóm (Ăn uống, Mua sắm...)',
              icon: Icons.pie_chart_rounded,
              gradient: const [Color(0xFFF97316), Color(0xFFFBBF24)],
              isDark: isDark,
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _selectedTab = 0);
              },
            ),
            const SizedBox(height: 10),
            _buildActionItem(
              context: ctx,
              title: 'Thêm mục tiêu tiết kiệm',
              subtitle:
                  'Tạo quỹ tích lũy mua nhà, mua xe, du lịch, dự phòng...',
              icon: Icons.savings_rounded,
              gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
              isDark: isDark,
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _selectedTab = 1);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildActionItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: gradient.first.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studio = context.watch<ThemeStudioController?>();
    final bp = context.watch<BudgetProvider>();
    final mp = context.watch<MoreProvider>();

    final budgets = bp.budgetsWithSpent;
    final goals = mp.goals;

    final canPop = !widget.isRoot && Navigator.of(context).canPop();
    final blurSigma = (studio?.appBarBlur ?? 22.0).clamp(0.0, 48.0);
    final barOpacity = (studio?.appBarOpacity ?? 0.85).clamp(0.0, 1.0);
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: Container(
                  padding: EdgeInsets.fromLTRB(16, topPad + 6, 16, 10),
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF0B1120) : Colors.white)
                        .withValues(alpha: barOpacity * (isDark ? 0.72 : 0.78)),
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08 * barOpacity)
                            : Colors.black.withValues(alpha: 0.05 * barOpacity),
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (canPop) ...[
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: _buildSegmentSelector(
                          budgetsCount: budgets.length,
                          goalsCount: goals.length,
                          isDark: isDark,
                          studio: studio,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const ClampingScrollPhysics(),
                  onPageChanged: (idx) {
                    if (_selectedTab != idx) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTab = idx);
                    }
                  },
                  children: [
                    BudgetScreen(userId: widget.userId, isTab: true),
                    GoalScreen(userId: widget.userId, isTab: true),
                    ReportScreen(
                        userId: widget.userId, isRoot: true, isTab: true),
                  ],
                ),
              ),
            ],
          )),
    );
  }

  String _formatCompactStat(int amount) {
    final absVal = amount.abs();
    if (absVal >= 1000000000) {
      final v = (absVal / 1000000000).toStringAsFixed(1).replaceAll('.0', '');
      return '${amount < 0 ? '-' : ''}$v tỷ';
    } else if (absVal >= 1000000) {
      final v = (absVal / 1000000).toStringAsFixed(1).replaceAll('.0', '');
      return '${amount < 0 ? '-' : ''}$v tr';
    } else if (absVal >= 1000) {
      final v = (absVal / 1000).toStringAsFixed(0);
      return '${amount < 0 ? '-' : ''}${v}k';
    }
    return formatVND(amount);
  }

  Widget _buildCompactPlanningBar({
    required int selectedTab,
    required bool isDark,
    required int totalBudgetLimit,
    required int totalBudgetSpent,
    required double budgetProgress,
    required int totalGoalTarget,
    required int totalGoalSaved,
    required double goalProgress,
    required int goalsCount,
    required int monthIncome,
    required int monthExpense,
    required int netCashflow,
  }) {
    final Color barAccent;
    final String label;
    final String mainStat;
    final String badgeText;
    final Color badgeColor;

    if (selectedTab == 0) {
      barAccent = const Color(0xFF0F6E56);
      label = 'NGÂN SÁCH:';
      mainStat =
          '${_formatCompactStat(totalBudgetSpent)} / ${_formatCompactStat(totalBudgetLimit)}';
      final pct = (budgetProgress * 100).toStringAsFixed(0);
      badgeText = '$pct% đã dùng';
      badgeColor = budgetProgress > 1.0
          ? const Color(0xFFEF4444)
          : (budgetProgress > 0.8
              ? const Color(0xFFF59E0B)
              : const Color(0xFF10B981));
    } else if (selectedTab == 1) {
      barAccent = const Color(0xFFD97706);
      label = 'MỤC TIÊU:';
      mainStat =
          '${_formatCompactStat(totalGoalSaved)} / ${_formatCompactStat(totalGoalTarget)}';
      final pct = (goalProgress * 100).toStringAsFixed(0);
      badgeText = '$pct% · $goalsCount mục tiêu';
      badgeColor = const Color(0xFFD97706);
    } else {
      barAccent = const Color(0xFF2563EB);
      label = 'DÒNG TIỀN:';
      mainStat = '${netCashflow >= 0 ? '+' : ''}${formatVND(netCashflow)}';
      badgeText =
          'Thu +${_formatCompactStat(monthIncome)} · Chi -${_formatCompactStat(monthExpense)}';
      badgeColor =
          netCashflow >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    }

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? Color.alphaBlend(
                barAccent.withValues(alpha: 0.14), const Color(0xFF1E293B))
            : Color.alphaBlend(barAccent.withValues(alpha: 0.08), Colors.white),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: barAccent.withValues(alpha: isDark ? 0.40 : 0.28),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: barAccent.withValues(alpha: isDark ? 0.16 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: barAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: barAccent.withValues(alpha: 0.65),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: barAccent,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            mainStat,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? badgeColor
                        : badgeColor.withValues(alpha: 0.95),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicPlanningMasterCard({
    required int selectedTab,
    required int totalBudgetLimit,
    required int totalBudgetSpent,
    required double budgetProgress,
    required int totalGoalTarget,
    required int totalGoalSaved,
    required double goalProgress,
    required int goalsCount,
    required int monthIncome,
    required int monthExpense,
    required int netCashflow,
    required bool isDark,
    required ThemeStudioController? studio,
  }) {
    final (List<Color> heroGradient, Color accentShadowColor) =
        switch (selectedTab) {
      1 => (
          const [Color(0xFF2E1906), Color(0xFF451A03), Color(0xFF5A2508)],
          FinoraTokens.appleAmber,
        ),
      2 => (
          const [Color(0xFF0A1224), Color(0xFF101B36), Color(0xFF16254A)],
          FinoraTokens.appleCobalt,
        ),
      _ => (
          const [Color(0xFF062319), Color(0xFF093627), Color(0xFF0D4532)],
          FinoraTokens.appleMint,
        ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      height: 128,
      decoration: BoxDecoration(
        color: heroGradient.first,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: accentShadowColor.withValues(alpha: isDark ? 0.28 : 0.20),
            blurRadius: 18,
            offset: const Offset(0, 5),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Layer 1: Tab-matched Hero Gradient (Emerald Teal / Royal Indigo / Apple Cobalt Blue)
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: heroGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            // Layer 2: Hào quang Luminous Bloom nhẹ nhàng theo màu tab
            Positioned.fill(
              child: CustomPaint(
                painter: _PlanningBloomPainter(
                  themeColor: heroGradient.last,
                  isDark: isDark,
                ),
              ),
            ),

            // Layer 3: Specular Sheen Overlay: Phản quang bóng kính tinh tế
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: const Alignment(-0.8, -1.0),
                      end: const Alignment(0.8, 1.0),
                      colors: [
                        Colors.white.withValues(alpha: 0.14),
                        Colors.white.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.22),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Layer 4: Viền pha lê cao cấp
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1.1,
                  ),
                ),
              ),
            ),
            const FinoraAmbientMascotWatermark(
              pose: FinoraMascotPose.thinking,
              size: 108,
              opacity: 0.11,
              right: -12,
              bottom: -14,
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.03),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(selectedTab),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 360,
                      child: () {
                        switch (selectedTab) {
                          case 1:
                            return _buildGoalHeroContent(
                              totalGoalTarget: totalGoalTarget,
                              totalGoalSaved: totalGoalSaved,
                              goalProgress: goalProgress,
                              goalsCount: goalsCount,
                              isDark: isDark,
                              studio: studio,
                            );
                          case 2:
                            return _buildReportHeroContent(
                              monthIncome: monthIncome,
                              monthExpense: monthExpense,
                              netCashflow: netCashflow,
                              isDark: isDark,
                              studio: studio,
                            );
                          case 0:
                          default:
                            return _buildBudgetHeroContent(
                              totalBudgetLimit: totalBudgetLimit,
                              totalBudgetSpent: totalBudgetSpent,
                              budgetProgress: budgetProgress,
                              isDark: isDark,
                              studio: studio,
                            );
                        }
                      }(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildBudgetHeroContent({
    required int totalBudgetLimit,
    required int totalBudgetSpent,
    required double budgetProgress,
    required bool isDark,
    required ThemeStudioController? studio,
  }) {
    final remaining =
        (totalBudgetLimit - totalBudgetSpent).clamp(0, double.infinity).toInt();
    final isOver = totalBudgetSpent > totalBudgetLimit && totalBudgetLimit > 0;
    final percent = (budgetProgress * 100).clamp(0, 999).toInt();
    final now = DateTime.now();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Đồng Hồ Bán Nguyệt Đo Tốc Độ Chi Tiêu (Speedometer Arc Gauge)
        Container(
          width: 82,
          height: 82,
          margin: const EdgeInsets.only(right: 12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(82, 82),
                painter: _BudgetSpeedometerPainter(
                  progress: budgetProgress,
                  isOver: isOver,
                  isDark: isDark,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$percent%',
                    style: TextStyle(
                      fontSize: percent >= 100 ? 15 : 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: isOver
                          ? const Color(0xFFFCA5A5)
                          : (percent > 85
                              ? const Color(0xFFFDE68A)
                              : Colors.white),
                    ),
                  ),
                  Text(
                    isOver ? 'QUÁ MỨC' : 'ĐÃ DÙNG',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Colors.white.withValues(alpha: 0.70),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 2. Cột Số Liệu Trọng Tâm Ngân Sách
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hàng tiêu đề & Trạng thái
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'NGÂN SÁCH THÁNG ${now.month}/${now.year}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7.5, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: (isOver
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF10B981))
                          .withValues(alpha: isDark ? 0.22 : 0.15),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: (isOver
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981))
                            .withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      isOver ? 'Bội chi' : 'An toàn',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: isOver
                            ? (isDark
                                ? const Color(0xFFFCA5A5)
                                : const Color(0xFFF87171))
                            : (isDark
                                ? const Color(0xFF6EE7B7)
                                : const Color(0xFF34D399)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),

              // Số tiền còn lại
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Còn: ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: FinoraPrivacyMask(
                        child: Text(
                          Formatters.formatCurrency(remaining),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color:
                                isOver ? const Color(0xFFEF4444) : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),

              // 2 Chip Đã chi & Hạn mức
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ĐÃ CHI',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: FinoraPrivacyMask(
                              child: Text(
                                Formatters.formatCurrency(totalBudgetSpent),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HẠN MỨC',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: FinoraPrivacyMask(
                              child: Text(
                                Formatters.formatCurrency(totalBudgetLimit),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoalHeroContent({
    required int totalGoalTarget,
    required int totalGoalSaved,
    required double goalProgress,
    required int goalsCount,
    required bool isDark,
    required ThemeStudioController? studio,
  }) {
    final remainingGoal =
        (totalGoalTarget - totalGoalSaved).clamp(0, double.infinity).toInt();
    final percent = (goalProgress * 100).clamp(0, 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'TỔNG TÍCH LŨY MỤC TIÊU',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7.5, vertical: 2.5),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                  width: 0.8,
                ),
              ),
              child: Text(
                'Đạt $percent%',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFDE68A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Đã góp: ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: FinoraPrivacyMask(
                  child: Text(
                    Formatters.formatCurrency(totalGoalSaved),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),

        // Bản đồ cột mốc Quest Waypoints (0% -> 50% -> 100%)
        _buildMilestoneQuestBar(
          progress: goalProgress,
          percent: percent,
        ),
        const SizedBox(height: 6),

        // 2 Chip Mục tiêu & Cần tích lũy
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MỤC TIÊU',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: FinoraPrivacyMask(
                        child: Text(
                          Formatters.formatCurrency(totalGoalTarget),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CẦN TÍCH LŨY',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: FinoraPrivacyMask(
                        child: Text(
                          Formatters.formatCurrency(remainingGoal),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFDE68A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMilestoneQuestBar({
    required double progress,
    required int percent,
  }) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Stack(
            children: [
              Container(
                height: 7,
                color: Colors.black.withValues(alpha: 0.25),
              ),
              FractionallySizedBox(
                widthFactor: clampedProgress,
                child: Container(
                  height: 7,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFF59E0B),
                        Color(0xFFFBBF24),
                        Color(0xFF34D399)
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0%',
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
            Text(
              '50%',
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flag_rounded,
                    size: 9, color: Color(0xFFFDE68A)),
                const SizedBox(width: 2),
                Text(
                  '100%',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportHeroContent({
    required int monthIncome,
    required int monthExpense,
    required int netCashflow,
    required bool isDark,
    required ThemeStudioController? studio,
  }) {
    final isPositive = netCashflow >= 0;
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 7.5,
                    height: 7.5,
                    decoration: BoxDecoration(
                      color: isPositive
                          ? const Color(0xFF0284C7)
                          : const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isPositive
                                  ? const Color(0xFF0284C7)
                                  : const Color(0xFFEF4444))
                              .withValues(alpha: 0.50),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'DÒNG TIỀN THÁNG ${now.month}/${now.year}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.white.withValues(alpha: 0.90),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
              decoration: BoxDecoration(
                color: (isPositive
                        ? const Color(0xFF0284C7)
                        : const Color(0xFFEF4444))
                    .withValues(alpha: isDark ? 0.20 : 0.10),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: (isPositive
                          ? const Color(0xFF0284C7)
                          : const Color(0xFFEF4444))
                      .withValues(alpha: 0.30),
                  width: 0.8,
                ),
              ),
              child: Text(
                isPositive ? 'Dương dòng tiền' : 'Bội chi trong kỳ',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: isPositive
                      ? (isDark
                          ? const Color(0xFF7DD3FC)
                          : const Color(0xFF0284C7))
                      : (isDark
                          ? const Color(0xFFFCA5A5)
                          : const Color(0xFFDC2626)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Thu ròng: ',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: FinoraPrivacyMask(
                  child: Text(
                    '${netCashflow >= 0 ? '+' : ''}${Formatters.formatCurrency(netCashflow)}',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: isPositive
                          ? const Color(0xFF34D399)
                          : const Color(0xFFFB7185),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        _buildCashflowRatioBar(
          income: monthIncome,
          expense: monthExpense,
          isDark: isDark,
        ),
        const SizedBox(height: 6),
        // Dual metrics frosted glass chips matching Tab 0 and Tab 1
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TỔNG THU',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: FinoraPrivacyMask(
                        child: Text(
                          '+${Formatters.formatCurrency(monthIncome)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TỔNG CHI',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: FinoraPrivacyMask(
                        child: Text(
                          '-${Formatters.formatCurrency(monthExpense)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFB7185),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Custom gradient progress bar với LayoutBuilder an toàn, bo tròn 100
  // ignore: unused_element
  Widget _buildGradientProgressBar({
    required double progress,
    required List<Color> gradientColors,
    required Color backgroundColor,
    double height = 7,
  }) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth * clampedProgress;
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: barWidth,
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Thanh tiến độ tỷ lệ Thu ròng vs Bội chi hai dải màu gradient
  Widget _buildCashflowRatioBar({
    required int income,
    required int expense,
    required bool isDark,
    double height = 4.5,
  }) {
    final total = income + expense;
    final incomeRatio = total > 0 ? (income / total).clamp(0.05, 0.95) : 0.5;
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: Row(
          children: [
            Expanded(
              flex: (incomeRatio * 1000).toInt(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 1.5),
            Expanded(
              flex: ((1 - incomeRatio) * 1000).toInt(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFB7185), Color(0xFFE11D48)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentSelector({
    required int budgetsCount,
    required int goalsCount,
    required bool isDark,
    required ThemeStudioController? studio,
  }) {
    return FinoraSegmentedTabs(
      labels: const ['Ngân sách', 'Mục tiêu', 'Báo cáo'],
      icons: const [
        Icons.pie_chart_rounded,
        Icons.savings_rounded,
        Icons.auto_graph_rounded,
      ],
      selectedIndex: _selectedTab,
      colors: const [
        Color(0xFF0D9488), // Teal for Budget
        Color(0xFFD97706), // Warm Amber for Goals (NO PURPLE)
        Color(0xFF2563EB), // Cobalt Blue for Reports
      ],
      height: 42,
      fontSize: 12.5,
      onChanged: (idx) => _switchTab(idx),
    );
  }

  // ignore: unused_element
  Widget _buildSegmentButton({
    required int index,
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activePillColor,
    required bool isDark,
  }) {
    final inactiveColor =
        isDark ? const Color(0xFF83968E) : const Color(0xFF52665E);

    return GestureDetector(
      onTap: () => _switchTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? activePillColor : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        activePillColor.withValues(alpha: isDark ? 0.35 : 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14.5,
                color: isSelected ? Colors.white : inactiveColor,
              ),
              const SizedBox(width: 4.5),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                  color: isSelected ? Colors.white : inactiveColor,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Planning Bloom Painter
/// Vẽ dải hào quang theo màu tab trên Master Card Kế hoạch & Báo cáo
class _PlanningBloomPainter extends CustomPainter {
  final Color themeColor;
  final bool isDark;

  const _PlanningBloomPainter({
    required this.themeColor,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.85, size.height * 0.40);

    // 1. Vầng sáng theo màu tab mềm mại
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          themeColor.withValues(alpha: isDark ? 0.26 : 0.32),
          themeColor.withValues(alpha: isDark ? 0.10 : 0.14),
          Colors.transparent,
        ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(Rect.fromCircle(
        center: center,
        radius: size.height * 0.85,
      ));
    canvas.drawCircle(center, size.height * 0.85, paint1);

    // 2. Vầng phản quang trắng ngọc nhẹ ở góc trên phải
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.08 : 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.80],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.92, size.height * 0.18),
        radius: size.height * 0.55,
      ));
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.18),
        size.height * 0.55, paint2);
  }

  @override
  bool shouldRepaint(covariant _PlanningBloomPainter oldDelegate) {
    return oldDelegate.themeColor != themeColor || oldDelegate.isDark != isDark;
  }
}

class _PlanningHubCollapsiblePinnedHeaderDelegate
    extends SliverPersistentHeaderDelegate {
  final double maxHeight;
  final double minHeight;
  final double heroFullHeight;
  final bool isDark;
  final Widget fullHeroWidget;
  final Widget compactHeroWidget;
  final Widget tabSegmentBar;

  _PlanningHubCollapsiblePinnedHeaderDelegate({
    required this.maxHeight,
    required this.minHeight,
    this.heroFullHeight = 128.0,
    required this.isDark,
    required this.fullHeroWidget,
    required this.compactHeroWidget,
    required this.tabSegmentBar,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double collapseRange = maxHeight - minHeight;
    final double progress = collapseRange > 0
        ? (shrinkOffset / collapseRange).clamp(0.0, 1.0)
        : 0.0;
    final double currentHeight =
        (maxHeight - shrinkOffset).clamp(minHeight, maxHeight);

    // Dynamic height of master card as it shrinks from heroFullHeight down to 36.0
    final double currentHeroHeight =
        (heroFullHeight - progress * (heroFullHeight - 36.0))
            .clamp(36.0, heroFullHeight);

    // Cross-fade opacities
    final double fullHeroOpacity = (1.0 - progress * 2.2).clamp(0.0, 1.0);
    final double compactHeroOpacity =
        ((progress - 0.35) * 1.54).clamp(0.0, 1.0);

    return SizedBox(
      height: currentHeight,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF0F172A) : Colors.white)
                  .withValues(alpha: isDark ? 0.88 : 0.88),
              border: Border(
                bottom: BorderSide(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: isDark ? 0.08 : 0.05),
                  width: 0.8,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: OverflowBox(
              minHeight: 0.0,
              maxHeight: double.infinity,
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 4),

                    // 1. PINNED 3-Pill Segment Selector (Directly beneath top header!)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: tabSegmentBar,
                    ),

                    if (heroFullHeight > 0.0) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: SizedBox(
                          height: currentHeroHeight,
                          child: Stack(
                            children: [
                              if (fullHeroOpacity > 0.0)
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: fullHeroOpacity,
                                    child: fullHeroWidget,
                                  ),
                                ),
                              if (compactHeroOpacity > 0.0)
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: compactHeroOpacity,
                                    child: Center(child: compactHeroWidget),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(
      covariant _PlanningHubCollapsiblePinnedHeaderDelegate oldDelegate) {
    return oldDelegate.maxHeight != maxHeight ||
        oldDelegate.minHeight != minHeight ||
        oldDelegate.heroFullHeight != heroFullHeight ||
        oldDelegate.isDark != isDark ||
        oldDelegate.fullHeroWidget != fullHeroWidget ||
        oldDelegate.compactHeroWidget != compactHeroWidget ||
        oldDelegate.tabSegmentBar != tabSegmentBar;
  }
}

/// CustomPainter vẽ vòng bán nguyệt đo tốc độ chi tiêu (Speedometer Arc Gauge)
class _BudgetSpeedometerPainter extends CustomPainter {
  final double progress;
  final bool isOver;
  final bool isDark;

  _BudgetSpeedometerPainter({
    required this.progress,
    required this.isOver,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 5.0;
    const startAngle = 135 * (math.pi / 180);
    const sweepTotalAngle = 270 * (math.pi / 180);

    // Track nền
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotalAngle,
      false,
      trackPaint,
    );

    // Vạch tiến độ
    final effectiveSweep = sweepTotalAngle * progress.clamp(0.0, 1.0);
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: isOver
            ? const [Color(0xFFFB7185), Color(0xFFEF4444)]
            : (progress > 0.85
                ? const [Color(0xFFFBBF24), Color(0xFFF59E0B)]
                : const [Color(0xFF34D399), Color(0xFF10B981)]),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round;

    if (effectiveSweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        effectiveSweep,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BudgetSpeedometerPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isOver != isOver;
}
