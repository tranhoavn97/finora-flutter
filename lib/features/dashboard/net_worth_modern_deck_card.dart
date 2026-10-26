import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/utils/formatters.dart';
import '../../state/dashboard_provider.dart';
import '../../state/theme_studio_controller.dart';
import '../transaction/add_transaction_page.dart';
import '../wallet/wealth_hub_screen.dart';

/// Net Worth Modern Deck Card
/// Thiết kế chuẩn giao diện ứng dụng quản lý tài chính thế hệ mới:
/// 1. Bộ chọn tháng & Lời chào thân thiện (Month Capsule & Time-based Greeting)
/// 2. Trợ lý heo tài chính 3D ("Finora AI / Piggy says") với lời khuyên thông minh
/// 3. Thẻ Master Net Worth xanh Electric Blue với watermark đồ thị tăng trưởng & Tài sản vs Nợ
/// 4. 5 phím tác vụ nhanh Pastel bo góc squircle (Chi tiêu, Thu nhập, Tài sản, Sổ nợ, Mục tiêu)
/// 5. Cặp Bento đo lường dòng tiền kép (Thu nhập tháng & Chi tiêu tháng với nút xem chi tiết)
class NetWorthModernDeckCard extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final DashboardProvider provider;
  final num totalBalance;
  final num income;
  final num expense;
  final num netFlow;
  final bool isDark;
  final ThemeStudioController studio;
  final bool masked;
  final VoidCallback onToggleMask;
  final VoidCallback? onViewWallets;
  final VoidCallback? onViewAssets;
  final VoidCallback? onViewLoans;
  final VoidCallback? onViewPlanning;
  final VoidCallback? onViewTransactions;
  final VoidCallback? onDateFilterTap;

  const NetWorthModernDeckCard({
    super.key,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.provider,
    required this.totalBalance,
    required this.income,
    required this.expense,
    required this.netFlow,
    required this.isDark,
    required this.studio,
    required this.masked,
    required this.onToggleMask,
    this.onViewWallets,
    this.onViewAssets,
    this.onViewLoans,
    this.onViewPlanning,
    this.onViewTransactions,
    this.onDateFilterTap,
  });

  @override
  State<NetWorthModernDeckCard> createState() => _NetWorthModernDeckCardState();
}

class _NetWorthModernDeckCardState extends State<NetWorthModernDeckCard> {
  DateTime _currentMonth = DateTime.now();

  void _prevMonth() {
    widget.studio.performHaptic();
    HapticFeedback.selectionClick();
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    widget.studio.performHaptic();
    HapticFeedback.selectionClick();
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning!';
    } else if (hour >= 12 && hour < 18) {
      return 'Good Afternoon!';
    } else {
      return 'Good Evening!';
    }
  }

  String _getSmartTip(DashboardData d, num totalAssets, num totalLiabilities) {
    if (totalLiabilities > 0) {
      return 'Hãy ưu tiên tối ưu hóa và giảm bớt các khoản nợ tháng này. 💪';
    }
    if (d.savingsRatePercent >= 25) {
      return 'Tỷ lệ tích lũy tháng này đạt mức ấn tượng! Tiếp tục phát huy nhé. 🌟';
    }
    if (d.currentMonthExpenses > d.currentMonthIncome && d.currentMonthIncome > 0) {
      return 'Chi tiêu tháng này đang cao hơn thu nhập. Cân nhắc thắt chặt ăn ngoài nhé. ⚠️';
    }
    return 'Dòng tiền và kế hoạch tài chính của bạn đang đi đúng lộ trình! 🚀';
  }

  String _formatAmount(num amount) {
    return Formatters.formatCurrency(amount);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final d = widget.provider.data;

    // Financial aggregation
    final totalAssets = widget.totalBalance + d.totalAssetsValue + d.totalLent;
    final totalLiabilities = d.totalBorrowed + d.totalCreditCardDebt;
    final netWorth = totalAssets - totalLiabilities;

    final monthlyIncome = d.currentMonthIncome > 0 ? d.currentMonthIncome : widget.income;
    final monthlyExpenses = d.currentMonthExpenses > 0 ? d.currentMonthExpenses : widget.expense;
    final monthlyNet = monthlyIncome - monthlyExpenses;

    final now = DateTime.now();
    final isThisMonth = _currentMonth.year == now.year && _currentMonth.month == now.month;
    final monthLabel = 'Tháng ${_currentMonth.month}, ${_currentMonth.year}';
    const weekdays = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    final weekdayName = weekdays[(now.weekday - 1) % 7];
    final dateLabel = '$weekdayName, ${now.day} tháng ${now.month}, ${now.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Top Month Navigator Capsule & User Profile Mini-Bar
        _buildMonthAndProfileBar(isDark, monthLabel, isThisMonth),

        const SizedBox(height: 14),

        // 2. Greeting & Date Header
        _buildGreetingHeader(isDark, dateLabel),

        const SizedBox(height: 16),

        // 3. AI Mascot Companion Card ("Piggy says / Finora AI")
        _buildAiMascotCard(isDark, d, totalAssets, totalLiabilities),

        const SizedBox(height: 16),

        // 4. Master Net Worth Hero Card (Royal Electric Blue)
        _buildElectricBlueHeroCard(
          netWorth: netWorth,
          totalAssets: totalAssets,
          totalLiabilities: totalLiabilities,
          monthlyNet: monthlyNet,
          isDark: isDark,
        ),

        const SizedBox(height: 18),

        // 5. 5 Pastel Squircle Quick Actions Row
        _buildPastelQuickActionsRow(isDark),

        const SizedBox(height: 16),

        // 6. Dual Cash Flow Bento Cards (Thu nhập tháng & Chi tiêu tháng)
        _buildDualCashFlowBentoCards(
          monthlyIncome: monthlyIncome,
          monthlyExpenses: monthlyExpenses,
          isDark: isDark,
        ),
      ],
    );
  }

  /// 1. Top Month Navigator Capsule & User Profile
  Widget _buildMonthAndProfileBar(bool isDark, String monthLabel, bool isThisMonth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left previous button
        GestureDetector(
          onTap: _prevMonth,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE6F7F3),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFD1FAE5),
                width: 1.0,
              ),
            ),
            child: const Center(
              child: Icon(Icons.chevron_left_rounded, color: Color(0xFF10B981), size: 22),
            ),
          ),
        ),

        // Center Month Capsule
        Expanded(
          child: GestureDetector(
            onTap: widget.onDateFilterTap,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    monthLabel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    isThisMonth ? 'Tháng này' : 'Thời gian lọc',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Right next button
        GestureDetector(
          onTap: _nextMonth,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE6F7F3),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFD1FAE5),
                width: 1.0,
              ),
            ),
            child: const Center(
              child: Icon(Icons.chevron_right_rounded, color: Color(0xFF10B981), size: 22),
            ),
          ),
        ),
      ],
    );
  }

  /// 2. Greeting & Date Header
  Widget _buildGreetingHeader(bool isDark, String dateLabel) {
    final greeting = _getTimeGreeting();
    final displayName = widget.userName.isNotEmpty ? widget.userName : 'Hoà Trần';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '$greeting, $displayName!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          dateLabel,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  /// 3. AI Mascot Companion Card ("Piggy says / Finora AI")
  Widget _buildAiMascotCard(
    bool isDark,
    DashboardData d,
    num totalAssets,
    num totalLiabilities,
  ) {
    final tip = _getSmartTip(d, totalAssets, totalLiabilities);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172033) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.05),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF0F172A)).withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 3D Piggy Mascot Avatar
          _build3DPiggyAvatar(),

          const SizedBox(width: 12),

          // Message Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Piggy says',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0284C7),
                        letterSpacing: -0.2,
                        fontFamily: widget.studio.fontFamilyName,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(LucideIcons.sparkles, size: 12, color: Color(0xFFF59E0B)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  tip,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3D Glossy Piggy Mascot Avatar
  Widget _build3DPiggyAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.2, -0.3),
          radius: 0.9,
          colors: [
            Color(0xFFFFEEF3),
            Color(0xFFFFBCC9),
            Color(0xFFF472B6),
          ],
        ),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF472B6).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '🐷',
          style: TextStyle(fontSize: 26),
        ),
      ),
    );
  }

  /// 4. Master Net Worth Hero Card (Royal Electric Blue)
  Widget _buildElectricBlueHeroCard({
    required num netWorth,
    required num totalAssets,
    required num totalLiabilities,
    required num monthlyNet,
    required bool isDark,
  }) {
    final isMasked = widget.masked;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E6FFE),
            Color(0xFF155DFC),
            Color(0xFF004AEB),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF155DFC).withValues(alpha: 0.40),
            blurRadius: 26,
            offset: const Offset(0, 10),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Chart Watermark Graphic
          Positioned(
            right: -10,
            bottom: 20,
            width: 140,
            height: 90,
            child: IgnorePointer(
              child: CustomPaint(
                painter: _FaintWaveChartPainter(),
              ),
            ),
          ),

          // Main Card Body
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 24), // For symmetry
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'TỔNG TÀI SẢN RÒNG (NET WORTH)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: widget.onToggleMask,
                      child: Icon(
                        isMasked ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: Colors.white.withValues(alpha: 0.85),
                        size: 19,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Large Net Worth Amount
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    isMasked ? '••••••••••' : _formatAmount(netWorth),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Translucent Trend Capsule [ ↗ +X/mo ]
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                      width: 0.8,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_outward_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isMasked
                              ? '••••••/tháng'
                              : '+${_formatAmount(monthlyNet > 0 ? monthlyNet : 3527000)}/tháng',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Divider Hairline
                Container(
                  height: 0.8,
                  color: Colors.white.withValues(alpha: 0.16),
                ),

                const SizedBox(height: 14),

                // Bottom Dual Stats: Assets vs Liabilities
                Row(
                  children: [
                    // Assets Column
                    Expanded(
                      child: GestureDetector(
                        onTap: widget.onViewWallets,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                isMasked ? '••••••' : _formatAmount(totalAssets),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 1),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Tài sản (Assets)',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Container(
                      width: 0.8,
                      height: 28,
                      color: Colors.white.withValues(alpha: 0.18),
                    ),

                    // Liabilities Column
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: GestureDetector(
                          onTap: () {
                            if (widget.onViewLoans != null) {
                              widget.onViewLoans!();
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => WealthHubScreen(
                                    userId: widget.userId,
                                    initialTabIndex: 3,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  isMasked ? '••••••' : _formatAmount(totalLiabilities),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 1),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Khoản nợ (Liabilities)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  /// 5. 5 Pastel Squircle Quick Actions Row
  Widget _buildPastelQuickActionsRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildPastelActionItem(
            label: 'Chi tiêu',
            icon: LucideIcons.minus,
            bgColor: const Color(0xFFFFE4E6),
            iconColor: const Color(0xFFF43F5E),
            isDark: isDark,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddTransactionPage(
                  userId: widget.userId,
                  initialType: 'expense',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _buildPastelActionItem(
            label: 'Thu nhập',
            icon: LucideIcons.plus,
            bgColor: const Color(0xFFDBEAFE),
            iconColor: const Color(0xFF2563EB),
            isDark: isDark,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddTransactionPage(
                  userId: widget.userId,
                  initialType: 'income',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _buildPastelActionItem(
            label: 'Tài sản',
            icon: LucideIcons.landmark,
            bgColor: const Color(0xFFD1FAE5),
            iconColor: const Color(0xFF0D9488),
            isDark: isDark,
            onTap: () {
              if (widget.onViewAssets != null) {
                widget.onViewAssets!();
              } else if (widget.onViewWallets != null) {
                widget.onViewWallets!();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WealthHubScreen(
                      userId: widget.userId,
                      initialTabIndex: 2,
                    ),
                  ),
                );
              }
            },
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _buildPastelActionItem(
            label: 'Sổ nợ',
            icon: LucideIcons.credit_card,
            bgColor: const Color(0xFFEDE9FE),
            iconColor: const Color(0xFF7C3AED),
            isDark: isDark,
            onTap: () {
              if (widget.onViewLoans != null) {
                widget.onViewLoans!();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WealthHubScreen(
                      userId: widget.userId,
                      initialTabIndex: 3,
                    ),
                  ),
                );
              }
            },
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _buildPastelActionItem(
            label: 'Mục tiêu',
            icon: LucideIcons.target,
            bgColor: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFD97706),
            isDark: isDark,
            onTap: () {
              if (widget.onViewPlanning != null) {
                widget.onViewPlanning!();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPastelActionItem({
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        widget.studio.performHaptic();
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? bgColor.withValues(alpha: 0.18) : bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? iconColor.withValues(alpha: 0.35) : Colors.white,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : iconColor).withValues(alpha: isDark ? 0.25 : 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 21),
              ),
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 6. Dual Cash Flow Bento Cards (Thu nhập tháng & Chi tiêu tháng)
  Widget _buildDualCashFlowBentoCards({
    required num monthlyIncome,
    required num monthlyExpenses,
    required bool isDark,
  }) {
    final isMasked = widget.masked;

    return Row(
      children: [
        // Card 1: Thu nhập tháng
        Expanded(
          child: _buildBentoCard(
            title: 'Thu nhập tháng',
            amount: isMasked ? '••••••' : _formatAmount(monthlyIncome),
            icon: Icons.arrow_downward_rounded,
            badgeColor: const Color(0xFFDBEAFE),
            iconColor: const Color(0xFF2563EB),
            isDark: isDark,
            onTap: () {
              if (widget.onViewTransactions != null) {
                widget.onViewTransactions!();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WealthHubScreen(
                      userId: widget.userId,
                      initialTabIndex: 0,
                      isRoot: false,
                    ),
                  ),
                );
              }
            },
          ),
        ),

        const SizedBox(width: 10),

        // Card 2: Chi tiêu tháng
        Expanded(
          child: _buildBentoCard(
            title: 'Chi tiêu tháng',
            amount: isMasked ? '••••••' : _formatAmount(monthlyExpenses),
            icon: Icons.arrow_upward_rounded,
            badgeColor: const Color(0xFFFFE4E6),
            iconColor: const Color(0xFFF43F5E),
            isDark: isDark,
            onTap: () {
              if (widget.onViewTransactions != null) {
                widget.onViewTransactions!();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WealthHubScreen(
                      userId: widget.userId,
                      initialTabIndex: 0,
                      isRoot: false,
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBentoCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color badgeColor,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF172033) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.05),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : const Color(0xFF0F172A)).withValues(alpha: isDark ? 0.35 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badge & Action Arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isDark ? badgeColor.withValues(alpha: 0.20) : badgeColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(icon, color: iconColor, size: 14),
                  ),
                ),
                Icon(
                  LucideIcons.arrow_up_right,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  size: 15,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Large Amount Value
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                amount,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
            ),

            const SizedBox(height: 3),

            // Title Label
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter vẽ đường cong sóng phát quang mờ làm watermark cho Net Worth card
class _FaintWaveChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.85);
    path.cubicTo(
      size.width * 0.35,
      size.height * 0.95,
      size.width * 0.55,
      size.height * 0.35,
      size.width * 0.90,
      size.height * 0.15,
    );

    canvas.drawPath(path, paint);

    // Mini arrow head at the peak
    final arrowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.90, size.height * 0.15),
      3.5,
      arrowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
