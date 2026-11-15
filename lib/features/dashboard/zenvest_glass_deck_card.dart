import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/widgets/finora_mascot.dart';
import '../../core/widgets/finora_member_filter.dart';
import '../../core/theme/finora_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../../state/dashboard_provider.dart';
import '../../state/budget_provider.dart';
import '../../state/more_provider.dart';
import '../../state/theme_studio_controller.dart';
import '../transaction/add_transaction_page.dart';
import '../transaction/transaction_detail_sheet.dart';
import '../transaction/transaction_theme_sheet.dart';
import '../wallet/wealth_hub_screen.dart';

/// Zenvest Glass Deck Card
/// Thiết kế chuẩn giao diện quản lý tài chính quốc tế theo phong cách Zenvest:
/// 1. Lời chào tài chính cá nhân hóa & Thẻ Kính Mờ Lơ Lửng (Frosted Glass Floating Card Deck) kích thước lớn
///    với hoa văn hào quang cực quang pastel (Iridescent bloom), huy hiệu cờ 🇻🇳 VND, số dư lớn, số tài khoản & hạn thẻ.
/// 2. Dãy phím tác vụ nhanh chuẩn Zenvest (Chuyển tiền ↗, Nhận tiền ✓, Tùy chọn ⋮ và Nút tròn nổi đen + 1 chạm).
/// 3. Khối AI Thông Minh tích hợp: Nhập nhanh AI & Sức khoẻ tài chính Finora AI nằm ngay trên khối giao dịch.
/// 4. Khối Giao Dịch bo tròn đáy (Transactions Surface Sheet) với thanh kéo, bộ lọc ≡, tiêu đề & tìm kiếm 🔍,
///    phân nhóm giao dịch theo ngày, avatar tròn đồng nhất danh mục không viền và nhãn phân loại màu sắc.
class ZenvestGlassDeckCard extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final DashboardProvider provider;
  final num totalBalance;
  final num income;
  final num expense;
  final num netFlow;
  final List<TransactionModel> txList;
  final bool isDark;
  final ThemeStudioController studio;
  final bool masked;
  final VoidCallback onToggleMask;
  final VoidCallback? onViewWallets;
  final VoidCallback? onViewLoans;
  final VoidCallback? onViewPlanning;
  final VoidCallback? onViewTransactions;
  final VoidCallback? onDateFilterTap;
  final VoidCallback? onAiQuickLogTap;
  final VoidCallback? onAiAdvisorTap;
  final Widget? filterBar;

  const ZenvestGlassDeckCard({
    super.key,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.provider,
    required this.totalBalance,
    required this.income,
    required this.expense,
    required this.netFlow,
    required this.txList,
    required this.isDark,
    required this.studio,
    required this.masked,
    required this.onToggleMask,
    this.onViewWallets,
    this.onViewLoans,
    this.onViewPlanning,
    this.onViewTransactions,
    this.onDateFilterTap,
    this.onAiQuickLogTap,
    this.onAiAdvisorTap,
    this.filterBar,
  });

  @override
  State<ZenvestGlassDeckCard> createState() => _ZenvestGlassDeckCardState();
}

class _ZenvestGlassDeckCardState extends State<ZenvestGlassDeckCard> {
  late PageController _pageController;
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'vi_VN');

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatAmount(num val) {
    return _currencyFormat.format(val.toInt());
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDate = DateTime(date.year, date.month, date.day);
    final diff = today.difference(txDate).inDays;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Hôm qua';
    return '${date.day} Thg ${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final wallets = widget.provider.data.wallets;
    final totalCards =
        1 + wallets.length; // Card 0: Tổng tài sản; Card 1..N: Ví cụ thể

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Zenvest Floating Frosted Glass Card Deck
        _buildCardDeck(wallets, totalCards, isDark),

        const SizedBox(height: 12),

        // 2. 3 Mini Widgets: Thu nhập, Chi tiêu, Số dư (Tiền mặt)
        _buildExpenseIncomeBalanceStats(isDark),

        // 3. Filter Bar (Tất cả & Hôm nay - 35/65) - Placed directly below the 3 mini widgets!
        if (widget.filterBar != null) ...[
          const SizedBox(height: 10),
          widget.filterBar!,
        ],

        const SizedBox(height: 12),

        // 4. Khối Finora AI Copilot Hợp Nhất (3D Mascot + Nhập nhanh AI + Sức khoẻ tài chính + Sổ nợ)
        _buildZenvestAiSection(isDark),

        const SizedBox(height: 14),

        // 5. Zenvest Transactions Surface Container
        _buildTransactionsSurface(isDark),
      ],
    );
  }

  // 2. Zenvest Card Carousel
  // 2. Zenvest Net Worth Master Card (Gọn gàng, sang trọng, không xếp chồng ví đằng sau)
  Widget _buildCardDeck(List<Wallet> wallets, int totalCards, bool isDark) {
    return _buildMasterGlassCard(
      title: 'Tổng tài sản',
      currency: 'VND',
      balance: widget.totalBalance,
      accountNumber: '',
      validDate: '',
      tierBadge: 'TỔNG TÀI SẢN',
      isDark: isDark,
      isMaster: true,
    );
  }

  Widget _buildMasterGlassCard({
    required String title,
    required String currency,
    required num balance,
    required String accountNumber,
    required String validDate,
    required String tierBadge,
    required bool isDark,
    required bool isMaster,
  }) {
    final wallets = widget.provider.data.wallets;
    final walletCount = wallets.length;
    final net = widget.income - widget.expense;
    final isPositiveNet = net >= 0;
    final dateFilterLabel = widget.provider.customDate != null
        ? DateFormat('dd/MM/yyyy').format(widget.provider.customDate!)
        : widget.provider.selectedDateFilter.label;
    final primary = widget.studio.resolvedPrimary;
    final secondary = widget.studio.resolvedSecondary;
    final heroGrad = widget.studio.getHeroCardGradient(isDark);
    final deep1 = Color.lerp(primary, const Color(0xFF020617), 0.72)!;
    final deep2 = Color.lerp(primary, const Color(0xFF020617), 0.44)!;
    final midColor = heroGrad.isNotEmpty ? heroGrad.first : primary;
    final endColor = heroGrad.length > 1 ? heroGrad.last : secondary;
    final lightTint = Color.lerp(secondary, Colors.white, 0.45)!;

    return Container(
      key: const ValueKey('compact-total-assets'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.45 : 0.28),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                deep1,
                deep2,
                midColor,
                endColor,
              ],
              stops: const [0.0, 0.35, 0.72, 1.0],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.26 : 0.22),
              width: 1.2,
            ),
          ),
          child: Stack(
            children: [
              // Crystal Aurora Light Orbs
              Positioned(
                top: -35,
                right: -25,
                child: Container(
                  width: 165,
                  height: 165,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        lightTint.withValues(alpha: 0.36),
                        primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -45,
                left: -25,
                child: Container(
                  width: 145,
                  height: 145,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        secondary.withValues(alpha: 0.24),
                        deep2.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Subtle Specular Top Highlight
              Positioned(
                top: 0,
                left: 24,
                right: 24,
                child: Container(
                  height: 1.2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.45),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Ambient 3D Mascot Watermark
              const FinoraAmbientMascotWatermark(
                pose: FinoraMascotPose.hero,
                size: 138,
                opacity: 0.16,
                alignment: Alignment.bottomRight,
                offset: Offset(16, 16),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: [ 🇻🇳 VND ] <-------> [ 🏛️ Tổng tài sản ]
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28),
                                width: 0.9,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const VietnamCurrencyFlag(),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    currency,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5.5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: lightTint.withValues(alpha: 0.35),
                                width: 0.9,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.account_balance_rounded,
                                  size: 13.5,
                                  color: lightTint,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Tổng tài sản',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      color: Colors.white.withValues(alpha: 0.96),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Balance Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  widget.masked
                                      ? '••••••••'
                                      : _formatAmount(balance),
                                  style: const TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    color: Colors.white,
                                    fontSize: 35,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.9,
                                    fontFeatures: [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                                if (!widget.masked) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '₫',
                                      style: TextStyle(
                                        fontFamily: 'BeVietnamPro',
                                        color: Colors.white
                                            .withValues(alpha: 0.92),
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.onToggleMask();
                            },
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.28),
                                  width: 1.0,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  widget.masked
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: Colors.white.withValues(alpha: 0.95),
                                  size: 19,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Luxury Frosted Status Footer Bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7.5,
                                  height: 7.5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF34D399),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF34D399)
                                            .withValues(alpha: 0.6),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '$walletCount ví hoạt động',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      color: Colors.white.withValues(alpha: 0.90),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPositiveNet
                                        ? Icons.trending_up_rounded
                                        : Icons.trending_down_rounded,
                                    size: 14,
                                    color: isPositiveNet
                                        ? const Color(0xFF6EE7B7)
                                        : const Color(0xFFFDA4AF),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.masked
                                        ? '$dateFilterLabel • ••••••'
                                        : '$dateFilterLabel: ${isPositiveNet ? "+" : "−"}${_formatAmount(net.abs())} ₫',
                                    style: TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      color: isPositiveNet
                                          ? const Color(0xFF6EE7B7)
                                          : const Color(0xFFFDA4AF),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
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
      ),
    );
  }

  // 2. Widget Chi tiêu, Thu nhập, Số dư (Phong cách UI/UX Apple Glass Bento Mới, Bỏ "Tháng này")
  Widget _buildExpenseIncomeBalanceStats(bool isDark) {
    final wallets = widget.provider.data.wallets;
    final cashBalance = wallets
        .where((w) =>
            w.type == 'cash' || w.name.toLowerCase().contains('tiền mặt'))
        .fold<num>(0, (sum, w) => sum + w.balance);

    return Row(
      children: [
        Expanded(
          child: _buildMetricMiniCard(
            label: 'Thu nhập',
            amount: widget.income,
            prefix: '+',
            color: const Color(0xFF059669),
            icon: Icons.arrow_downward_rounded,
            isDark: isDark,
            onTap: widget.onViewTransactions,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricMiniCard(
            label: 'Chi tiêu',
            amount: widget.expense,
            prefix: '−',
            color: const Color(0xFFE11D48),
            icon: Icons.arrow_upward_rounded,
            isDark: isDark,
            onTap: widget.onViewTransactions,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricMiniCard(
            label: 'Số dư ví',
            amount: cashBalance,
            prefix: '',
            color: const Color(0xFF0284C7),
            icon: Icons.account_balance_wallet_rounded,
            isDark: isDark,
            onTap: widget.onViewWallets,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricMiniCard({
    required String label,
    required num amount,
    required String prefix,
    required Color color,
    required IconData icon,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    final String amountStr =
        NumberFormat('#,##0', 'vi_VN').format(amount.abs());
    final formattedValue = widget.masked
        ? '••••••'
        : (amount == 0 ? '0 ₫' : '$prefix$amountStr ₫');

    // Adaptive Quiet Luxury Surface: Neutral card surface + studio glass opacity
    final double cardAlpha = widget.studio.glassOpacity;
    final Color solidBg = (isDark ? const Color(0xFF111827) : Colors.white)
        .withValues(alpha: cardAlpha);
    final Color solidBorder;
    final Color solidIconBg;
    final Color solidIconColor;
    final Color labelColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final Color valueColor;

    if (label == 'Thu nhập') {
      solidBorder = isDark
          ? const Color(0xFF10B981).withValues(alpha: 0.28)
          : const Color(0xFFD1FAE5);
      solidIconBg = isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
      solidIconColor =
          isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
      valueColor = widget.masked
          ? (isDark ? Colors.white : const Color(0xFF0F172A))
          : (isDark ? const Color(0xFF34D399) : const Color(0xFF059669));
    } else if (label == 'Chi tiêu') {
      solidBorder = isDark
          ? const Color(0xFFF43F5E).withValues(alpha: 0.28)
          : const Color(0xFFFFE4E6);
      solidIconBg = isDark ? const Color(0xFF881337) : const Color(0xFFFFF1F2);
      solidIconColor =
          isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48);
      valueColor = widget.masked
          ? (isDark ? Colors.white : const Color(0xFF0F172A))
          : (isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48));
    } else {
      solidBorder = isDark
          ? const Color(0xFF0284C7).withValues(alpha: 0.28)
          : const Color(0xFFE0F2FE);
      solidIconBg = isDark ? const Color(0xFF0C4A6E) : const Color(0xFFF0F9FF);
      solidIconColor =
          isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
      valueColor = widget.masked
          ? (isDark ? Colors.white : const Color(0xFF0F172A))
          : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7));
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          if (onTap != null) onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 78),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
          decoration: BoxDecoration(
            color: solidBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: solidBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: solidIconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(icon, color: solidIconColor, size: 14),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: labelColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formattedValue,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 14.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: valueColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

    // 4. Khối AI Thông Minh Tích Hợp (Hợp nhất Companion + Nhập Nhanh AI, Sức Khỏe AI, Cho Vay / Vay Nợ)
  Widget _buildZenvestAiSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 4.1. Thẻ Hợp Nhất Trợ Lý Finora AI & Nhập Nhanh Giao Dịch (Unified Copilot Strip)
        _buildFinora3DCompanionLounge(isDark),

        const SizedBox(height: 12),

        // 4.2. Thẻ Bento Sức Khỏe Tài Chính Finora AI (Thiết kế Clean Minimal)
        _buildZenvestAiHealthCard(isDark),

        const SizedBox(height: 12),

        // 4.3. Widget Cho Vay và Vay Nợ
        _buildLendingAndDebtWidget(isDark),
      ],
    );
  }

  // 4.1. Thẻ Hợp Nhất Trợ Lý Finora AI & Nhập Nhanh Giao Dịch (Apple Intelligence + 1-Tap Quick Input)
  Widget _buildFinora3DCompanionLounge(bool isDark) {
    return Builder(
      builder: (context) {
        final budgetProv = context.watch<BudgetProvider?>();
        final budgets = budgetProv?.budgetsWithSpent ?? [];
        final totalBudgetLimit =
            budgets.fold<int>(0, (s, b) => s + b.budget.limitAmount);
        final totalBudgetSpent =
            budgets.fold<int>(0, (s, b) => s + b.spentAmount);
        final budgetProgress = totalBudgetLimit > 0
            ? (totalBudgetSpent / totalBudgetLimit).clamp(0.0, 1.0)
            : 0.0;
        final isOver = budgetProgress > 0.85;

        final String speechText;
        if (totalBudgetLimit > 0) {
          if (isOver) {
            speechText =
                'Cảnh báo! Đã dùng ${(budgetProgress * 100).toInt()}% hạn mức tháng.';
          } else {
            speechText =
                'Tiến độ an toàn! Đã dùng ${(budgetProgress * 100).toInt()}% hạn mức.';
          }
        } else {
          speechText = 'Mình giúp bạn ghi chép nhanh và hiểu rõ thu chi.';
        }

        final primary = widget.studio.resolvedPrimary;
        final secondary = widget.studio.resolvedSecondary;
        final statusColor = isOver ? FinoraTokens.appleCoral : primary;
        final fill = widget.studio.getCardFillColor(isDark);

        return Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primary.withValues(alpha: isDark ? 0.28 : 0.25),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: isDark ? 0.22 : 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: isOver
                    ? widget.onViewPlanning
                    : (widget.onAiAdvisorTap ?? widget.onViewPlanning),
                borderRadius: BorderRadius.circular(14),
                child: Row(
                  children: [
                    // 1. Linh thú Rồng ngọc Finora 3D sống động (Hô hấp, chớp mắt, lơ lửng & xoay 3D)
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: primary.withValues(alpha: isDark ? 0.20 : 0.12),
                      ),
                      alignment: Alignment.center,
                      child: FinoraInteractive3DMascot(
                        pose: isOver
                            ? FinoraMascotPose.focused
                            : FinoraMascotPose.hero,
                        size: 48,
                        enableFloatingAnimation: true,
                        enableTouch3DRotation: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 2. Cột thông tin Ambient AI
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  isOver
                                      ? 'CẢNH BÁO HẠN MỨC'
                                      : 'TRỢ LÝ FINORA AI',
                                  style: TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: statusColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 15,
                                color: statusColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            speechText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF11221E),
                              height: 1.3,
                            ),
                          ),
                          if (totalBudgetLimit > 0) ...[
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: budgetProgress.clamp(0.0, 1.0),
                                minHeight: 4.5,
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.10)
                                    : Colors.black.withValues(alpha: 0.06),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(statusColor),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Thanh Hành Động AI Cân Đối 2 Cột (50% Nhập nhanh giao dịch | 50% Phân tích AI - Chiều cao 40px)
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.onAiQuickLogTap?.call();
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1B2430)
                                : const Color(0xFFF6F8F7),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF25303E)
                                  : const Color(0xFFE2EAE6),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                color: primary,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Nhập nhanh AI',
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          (widget.onAiAdvisorTap ?? widget.onViewPlanning)?.call();
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primary, secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(
                                    alpha: isDark ? 0.28 : 0.18),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.insights_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Phân tích AI',
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      fontSize: 12.5,
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
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildZenvestAiHealthCard(bool isDark) {
    final d = widget.provider.data;
    final score = d.aiHealthScore > 0 ? d.aiHealthScore : 92;
    final runway = d.emergencyRunwayMonths > 0
        ? d.emergencyRunwayMonths.toStringAsFixed(1)
        : '4.8';
    final savings = d.savingsRatePercent > 0
        ? d.savingsRatePercent.toInt().toString()
        : '46';
    final debt =
        d.debtRatioPercent > 0 ? d.debtRatioPercent.toInt().toString() : '1';
    final tier = d.aiHealthTier.isNotEmpty ? d.aiHealthTier : 'Xuất sắc';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onAiAdvisorTap?.call();
        },
        borderRadius: BorderRadius.circular(22),
        child: Builder(
          builder: (ctx) {
            final fill = widget.studio
                .getCardFillColor(isDark)
                .withValues(alpha: widget.studio.glassOpacity);
            final card = Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: fill,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE3EBE7),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              FinoraAmbientMascotWatermark(
                pose: FinoraMascotPose.thinking,
                size: 96,
                opacity: isDark ? 0.08 : 0.06,
                alignment: Alignment.bottomRight,
                offset: const Offset(10, 12),
              ),
              Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header row: Clean Icon Badge + Title + Tier Badge
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: widget.studio.resolvedPrimary
                          .withValues(alpha: isDark ? 0.22 : 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 15,
                      color: widget.studio.resolvedPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sức khoẻ tài chính',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: isDark ? Colors.white : const Color(0xFF0D1F1A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.studio.resolvedPrimary
                            .withValues(alpha: isDark ? 0.22 : 0.12),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        tier,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: widget.studio.resolvedPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Gauge Score + 3 Financial Metrics
              Row(
                children: [
                  // Circular Score Ring
                  SizedBox(
                    width: 68,
                    height: 68,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 68,
                          height: 68,
                          child: CircularProgressIndicator(
                            value: (score / 100).clamp(0.0, 1.0),
                            strokeWidth: 5.5,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                widget.studio.resolvedPrimary),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$score',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: widget.studio.resolvedPrimary,
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

                  const SizedBox(width: 14),

                  // 3 Key Metrics
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 68),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildZenvestAiMetricRow(
                              'Quỹ khẩn cấp', '$runway tháng', isDark),
                          const SizedBox(height: 4),
                          _buildZenvestAiMetricRow(
                              'Tỷ lệ tích lũy', '$savings%', isDark),
                          const SizedBox(height: 4),
                          _buildZenvestAiMetricRow(
                              'Tỷ lệ nợ/tài sản', '$debt%', isDark),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          ],
          ),
        );
        return card;
      }),
    ),
  );
  }

  Widget _buildZenvestAiMetricRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 110),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              maxLines: 1,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 4.3. Widget Cho Vay và Vay Nợ (Ngay Dưới Sức Khoẻ AI)
  Widget _buildLendingAndDebtWidget(bool isDark) {
    final moreProv = context.watch<MoreProvider>();
    final loans = moreProv.loans;
    final lentLoans =
        loans.where((l) => l.type == 'lent' && l.status == 'active').toList();
    final borrowedLoans = loans
        .where((l) => l.type == 'borrowed' && l.status == 'active')
        .toList();

    final totalLent = lentLoans.fold<int>(
      0,
      (sum, l) =>
          sum +
          (l.remainingPrincipal > 0
              ? l.remainingPrincipal
              : (l.amount - l.paidAmount)),
    );
    final totalBorrowed = borrowedLoans.fold<int>(
      0,
      (sum, l) =>
          sum +
          (l.remainingPrincipal > 0
              ? l.remainingPrincipal
              : (l.amount - l.paidAmount)),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
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
        borderRadius: BorderRadius.circular(22),
        child: Builder(
          builder: (ctx) {
            final fill = widget.studio
                .getCardFillColor(isDark)
                .withValues(alpha: widget.studio.glassOpacity);
            final card = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE3EBE7),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F6E56).withValues(alpha: 0.24)
                          : const Color(0xFFE8F5F0),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.handshake_outlined,
                        color: isDark
                            ? const Color(0xFF34D399)
                            : const Color(0xFF0F6E56),
                        size: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cho vay & Vay nợ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: isDark ? Colors.white : const Color(0xFF0D1F1A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 105),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Quản lý sổ nợ',
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF0F6E56),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 11,
                            color: isDark
                                ? const Color(0xFF34D399)
                                : const Color(0xFF0F6E56),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Two Pods: Cho vay & Vay nợ
              Row(
                children: [
                  // Cho vay
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F6E56).withValues(alpha: 0.12)
                            : const Color(0xFFF6FAF8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF10B981).withValues(alpha: 0.20)
                              : const Color(0xFFE3EBE7),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0F6E56),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  'Cần thu về',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF52665E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.masked
                                  ? '••••••'
                                  : '${_formatAmount(totalLent)} đ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: isDark
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFF0F6E56),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${lentLoans.length} khoản đang mở',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF83968E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Vay nợ
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFFD97706).withValues(alpha: 0.10)
                            : const Color(0xFFFDFBF7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.20)
                              : const Color(0xFFEDE8DF),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD97706),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  'Cần phải trả',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF52665E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.masked
                                  ? '••••••'
                                  : '${_formatAmount(totalBorrowed)} đ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: isDark
                                    ? const Color(0xFFFBBF24)
                                    : const Color(0xFFD97706),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${borrowedLoans.length} khoản đang mở',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF83968E),
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
        );
        return card;
      }),
    ),
  );
  }

  // 5. Zenvest Transactions Surface Container
  Widget _buildTransactionsSurface(bool isDark) {
    final txList = widget.txList;

    final cardFill = widget.studio
        .getCardFillColor(isDark)
        .withValues(alpha: widget.studio.glassOpacity);

    final surfaceContainer = Container(
      decoration: BoxDecoration(
        color: cardFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE3EBE7),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tay nắm kéo nhỏ ở đỉnh (Zenvest top handle)
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF23322C) : const Color(0xFFDDE7E2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Header: Filter ≡ | Title Giao dịch | Search 🔍
          Row(
            children: [
              // Filter Icon
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onDateFilterTap?.call();
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.04),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.sliders_horizontal,
                    size: 16,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF52665E),
                  ),
                ),
              ),

              // Title
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Giao dịch',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : const Color(0xFF0D1F1A),
                      ),
                    ),
                  ),
                ),
              ),

              // Theme Style Button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  showTransactionThemeModal(context);
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F6E56).withValues(alpha: 0.22)
                        : const Color(0xFFE8F5F0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.palette_outlined,
                    size: 16,
                    color: isDark
                        ? const Color(0xFF34D399)
                        : const Color(0xFF0F6E56),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Search Icon
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onViewTransactions?.call();
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.04),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.search,
                    size: 16,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF52665E),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Danh sách giao dịch phong cách Zenvest
          if (txList.isEmpty)
            _buildEmptyTransactionsPlaceholder(isDark)
          else ...[
            // Nhãn ngày tháng phân nhóm
            Text(
              'Gần đây',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF52665E),
              ),
            ),
            const SizedBox(height: 8),

            // Lấy tối đa 5 giao dịch gần nhất
            ...txList
                .take(5)
                .map((tx) => _buildZenvestTransactionItem(tx, isDark)),

            const SizedBox(height: 8),

            // Nút "Xem tất cả giao dịch →"
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onViewTransactions?.call();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    'Xem tất cả giao dịch →',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFF34D399)
                          : const Color(0xFF0F6E56),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: surfaceContainer,
    );
  }

  Widget _buildEmptyTransactionsPlaceholder(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const FinoraInteractive3DMascot(
            pose: FinoraMascotPose.relaxed,
            size: 76,
            enableFloatingAnimation: true,
            enableTouch3DRotation: true,
          ),
          const SizedBox(height: 10),
          Text(
            'Chưa có giao dịch gần đây',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddTransactionPage(userId: widget.userId),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : const Color(0xFF0F172A))
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '+ Tạo giao dịch đầu tiên',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Từng mục giao dịch chuẩn Zenvest: Avatar tròn đồng nhất danh mục, KHÔNG viền bao quanh
  Widget _buildZenvestTransactionItem(TransactionModel tx, bool isDark) {
    final isFlowIn = TransactionVisuals.isInflow(tx.type);
    final isTransfer = TransactionVisuals.isTransfer(tx.type);
    final isMasked = widget.masked;

    // Đồng nhất hoàn toàn icon và màu sắc với danh mục của người dùng
    final categories =
        Provider.of<MoreProvider?>(context, listen: false)?.categories ?? [];
    final txCatId = tx.categoryId?.trim().toLowerCase();
    final txCatName = tx.categoryName?.trim().toLowerCase();
    final matchingCategory = categories.cast<dynamic>().firstWhere(
      (c) {
        if (c == null) return false;
        final cId = c.id?.toString().trim().toLowerCase();
        final cName = c.name?.toString().trim().toLowerCase();
        if (txCatId != null && txCatId.isNotEmpty && cId == txCatId) {
          return true;
        }
        if (txCatName != null && txCatName.isNotEmpty && cName == txCatName) {
          return true;
        }
        return false;
      },
      orElse: () => null,
    );

    final resolvedIconStr = TransactionVisuals.iconFor(
      tx.type,
      matchingCategory?.icon ?? tx.categoryIcon,
      categoryName: matchingCategory?.name ?? tx.categoryName ?? tx.note,
      merchantId: tx.merchantId,
      merchantName: tx.merchantName,
    );
    final catColor = TransactionVisuals.iconColorFor(
      tx.type,
      categoryColor: matchingCategory?.color ?? tx.categoryColor,
    );
    final effectiveIconColor =
        isDark ? catColor : Color.lerp(catColor, Colors.black, 0.15)!;

    final catDisplayName =
        matchingCategory?.name ?? tx.categoryName ?? 'Giao dịch';
    final title = (tx.note != null && tx.note!.trim().isNotEmpty)
        ? tx.note!.trim()
        : catDisplayName;
    final txDate = DateTime.fromMillisecondsSinceEpoch(tx.date);
    final fullWallet = (tx.walletName != null && tx.walletName!.trim().isNotEmpty)
        ? tx.walletName!.trim()
        : 'Ví chính';
    final ownerNorm = FinoraMemberAvatar.normalizeMember(
        tx.owner ?? tx.creatorTag ?? 'all');
    final ownerLabel = ownerNorm == 'husband'
        ? widget.studio.husbandDisplayLabel
        : (ownerNorm == 'wife' ? widget.studio.wifeDisplayLabel : null);
    final ownerColor = FinoraMemberAvatar.colorFor(ownerNorm);
    final relDate = _formatRelativeDate(txDate);
    final subtitle = '$catDisplayName • $fullWallet • $relDate';

    final statusColor = TransactionVisuals.colorFor(tx.type);
    final statusLabel = switch (tx.type.toLowerCase()) {
      'lending' || 'loan' || 'lent' => 'Cho vay',
      'borrowing' || 'borrow' || 'debt' => 'Đi vay',
      'debt_repayment' || 'repayment' || 'debt_repayment_paid' => 'Trả nợ',
      'loan_repayment_received' || 'debt_collection' => 'Thu nợ',
      'investment' || 'invest' => 'Đầu tư',
      'saving' || 'savings' => 'Tiết kiệm',
      'credit_card_payment' => 'Trả thẻ',
      'transfer' => 'Chuyển tiền',
      'income' => 'Thu nhập',
      _ => isFlowIn ? 'Thu nhập' : 'Chi tiêu',
    };

    final amountPrefix = isTransfer ? '' : (isFlowIn ? '+' : '-');
    final amountText =
        isMasked ? '••••••' : '$amountPrefix${_formatAmount(tx.amount)} ₫';
    final amountColor = isTransfer
        ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))
        : (isFlowIn
            ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
            : (isDark ? const Color(0xFFF87171) : const Color(0xFFE11D48)));

    final isPhoto = CategoryIconHelper.isPhoto(
            resolvedIconStr, catDisplayName) ||
        (BankIconRegistry.resolve(resolvedIconStr, bankName: catDisplayName)
                    .code !=
                'cash' &&
            BankIconRegistry.resolve(resolvedIconStr, bankName: catDisplayName)
                    .assetPath !=
                null);

    final listStyle = widget.studio.transactionListStyle;

    Widget buildIconPod({
      required double size,
      required double iconSize,
      BoxShape shape = BoxShape.circle,
      BorderRadius? borderRadius,
      bool outlined = false,
    }) {
      final effectiveRadius = shape == BoxShape.rectangle
          ? (borderRadius ?? BorderRadius.circular(size * 0.32))
          : null;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isPhoto
                  ? Color.alphaBlend(
                      catColor.withValues(alpha: isDark ? 0.22 : 0.14),
                      isDark ? const Color(0xFF1E293B) : Colors.white,
                    )
                  : (outlined
                      ? catColor.withValues(alpha: isDark ? 0.12 : 0.08)
                      : catColor.withValues(alpha: isDark ? 0.22 : 0.14)),
              shape: shape,
              borderRadius: effectiveRadius,
              border: Border.all(
                color: isPhoto
                    ? catColor.withValues(alpha: isDark ? 0.62 : 0.45)
                    : (outlined
                        ? catColor.withValues(alpha: isDark ? 0.48 : 0.36)
                        : catColor.withValues(alpha: isDark ? 0.28 : 0.20)),
                width: isPhoto ? 1.5 : (outlined ? 1.2 : 1.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: catColor.withValues(alpha: isDark ? 0.16 : 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: isPhoto
                  ? Container(
                      width: size * 0.76,
                      height: size * 0.76,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        shape: shape,
                        borderRadius: shape == BoxShape.rectangle
                            ? BorderRadius.circular(size * 0.22)
                            : null,
                      ),
                      child: CategoryIconWidget(
                        icon: resolvedIconStr,
                        categoryName: catDisplayName,
                        size: size * 0.76,
                        color: effectiveIconColor,
                      ),
                    )
                  : CategoryIconWidget(
                      icon: resolvedIconStr,
                      categoryName: catDisplayName,
                      size: iconSize,
                      color: effectiveIconColor,
                    ),
            ),
          ),
          if (ownerNorm != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                ),
                padding: const EdgeInsets.all(1.2),
                child: FinoraMemberAvatar(
                  member: ownerNorm,
                  size: 11.6,
                  isDark: isDark,
                ),
              ),
            ),
        ],
      );
    }

    Widget itemBody;
    BoxDecoration? itemDecoration;
    EdgeInsetsGeometry itemPadding;
    EdgeInsetsGeometry itemMargin;

    switch (listStyle) {
      case AppTransactionListStyle.bentoCards:
        // 2. BENTO CARDS: Khối thẻ Bento nổi 2 tầng (Header strip + Nội dung chính)
        itemMargin = const EdgeInsets.symmetric(vertical: 4.5);
        itemPadding = const EdgeInsets.fromLTRB(12, 9, 12, 10);
        itemDecoration = BoxDecoration(
          color: isDark ? const Color(0xFF1A2232) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: catColor.withValues(alpha: isDark ? 0.28 : 0.20),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        );
        itemBody = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: isDark ? 0.20 : 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: catColor.withValues(alpha: isDark ? 0.35 : 0.22),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    catDisplayName,
                    style: TextStyle(
                      fontSize: 9.8,
                      fontWeight: FontWeight.w800,
                      color: effectiveIconColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 1.8),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : const Color(0xFF0F172A))
                          .withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      fullWallet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.8,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
                if (ownerLabel != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: ownerColor.withValues(alpha: isDark ? 0.20 : 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      ownerLabel,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: ownerColor,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  relDate,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                buildIconPod(
                  size: 38,
                  iconSize: 20,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 122),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      amountText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: amountColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
        break;

      case AppTransactionListStyle.timelineRail:
        // 3. TIMELINE RAIL: Trục thời gian dọc với nút đèn báo dòng tiền
        itemMargin = const EdgeInsets.symmetric(vertical: 3);
        itemPadding = const EdgeInsets.symmetric(vertical: 8, horizontal: 4);
        itemDecoration = null;
        itemBody = IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 44,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: isDark ? 0.08 : 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        DateFormat('HH:mm').format(txDate),
                        style: TextStyle(
                          fontSize: 9.2,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 2.2,
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: isDark ? 0.30 : 0.22),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF131A26) : Colors.white,
                              border: Border.all(
                                color: statusColor,
                                width: 2.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withValues(alpha: 0.40),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A2232) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: isDark ? 0.08 : 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      buildIconPod(size: 38, iconSize: 19),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.8,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                      color: isDark
                                          ? const Color(0xFFF1F5F9)
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5.5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color:
                                          (isDark ? Colors.white : const Color(0xFF0F172A))
                                              .withValues(alpha: 0.07),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      fullWallet,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? const Color(0xFFCBD5E1)
                                            : const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2.5),
                            Text(
                              ownerLabel != null ? '$subtitle • $ownerLabel' : subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 96),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                amountText,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                  color: amountColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 8.8,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
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
            ],
          ),
        );
        break;

      case AppTransactionListStyle.magazineLedger:
        // 4. MAGAZINE LEDGER: Phong cách Tạp chí Tài chính với Lịch Ngày bên trái
        itemMargin = const EdgeInsets.symmetric(vertical: 4);
        itemPadding = const EdgeInsets.symmetric(vertical: 10, horizontal: 11);
        itemDecoration = BoxDecoration(
          gradient: LinearGradient(
            colors: [
              catColor.withValues(alpha: isDark ? 0.14 : 0.08),
              (isDark ? const Color(0xFF1A2232) : const Color(0xFFF8FAFC))
                  .withValues(alpha: 0.65),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: catColor.withValues(alpha: isDark ? 0.24 : 0.16),
          ),
        );
        itemBody = Row(
          children: [
            Container(
              width: 42,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.26)
                    : Colors.white.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: catColor.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    txDate.day.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'T${txDate.month}',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: effectiveIconColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            buildIconPod(size: 36, iconSize: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    ownerLabel != null
                        ? '$catDisplayName · $fullWallet · $ownerLabel'
                        : '$catDisplayName · $fullWallet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.8,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      amountText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: amountColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusLabel.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        break;

      case AppTransactionListStyle.compactTable:
        // 5. COMPACT TABLE: Bảng kế toán mật độ cao 1 dòng
        itemMargin = const EdgeInsets.symmetric(vertical: 1);
        itemPadding = const EdgeInsets.symmetric(vertical: 6.5, horizontal: 8);
        itemDecoration = BoxDecoration(
          color: (isDark ? Colors.white : const Color(0xFF0F172A))
              .withValues(alpha: 0.025),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black)
                .withValues(alpha: 0.05),
            width: 0.6,
          ),
        );
        itemBody = Row(
          children: [
            buildIconPod(
              size: 28,
              iconSize: 15,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : const Color(0xFF0F172A))
                      .withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  fullWallet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 96),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  amountText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: amountColor,
                  ),
                ),
              ),
            ),
          ],
        );
        break;

      case AppTransactionListStyle.minimalDivided:
        // 6. MINIMAL DIVIDED: Tối giản phân cách mảnh chuẩn Swiss Ledger
        itemMargin = EdgeInsets.zero;
        itemPadding = const EdgeInsets.symmetric(vertical: 9.5, horizontal: 4);
        itemDecoration = BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.07),
              width: 0.7,
            ),
          ),
        );
        itemBody = Row(
          children: [
            buildIconPod(size: 36, iconSize: 18, outlined: true),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.8,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ownerLabel != null ? '$subtitle • $ownerLabel' : subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 96),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  amountText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: amountColor,
                  ),
                ),
              ),
            ),
          ],
        );
        break;

      case AppTransactionListStyle.modernStreamlined:
        // 1. MODERN STREAMLINED: Viên thuốc hiện đại tinh gọn chuẩn Apple/Revolut
        itemMargin = const EdgeInsets.symmetric(vertical: 3);
        itemPadding = const EdgeInsets.symmetric(vertical: 8.5, horizontal: 10);
        itemDecoration = BoxDecoration(
          color: (isDark ? Colors.white : const Color(0xFF0F172A))
              .withValues(alpha: isDark ? 0.035 : 0.025),
          borderRadius: BorderRadius.circular(16),
        );
        itemBody = Row(
          children: [
            buildIconPod(size: 40, iconSize: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: isDark
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color:
                                (isDark ? Colors.white : const Color(0xFF0F172A))
                                    .withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            fullWallet,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2.5),
                  Text(
                    ownerLabel != null ? '$subtitle • $ownerLabel' : subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      amountText,
                      style: TextStyle(
                        fontSize: 14.2,
                        fontWeight: FontWeight.w900,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: amountColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1.2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        break;
    }

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        showTransactionDetailSheet(
          context,
          transaction: tx,
          userId: widget.userId,
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: itemMargin,
        padding: itemPadding,
        decoration: itemDecoration,
        child: itemBody,
      ),
    );
  }
}

class VietnamCurrencyFlag extends StatelessWidget {
  const VietnamCurrencyFlag({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 12,
      decoration: BoxDecoration(
        color: const Color(0xFFDA251D),
        borderRadius: BorderRadius.circular(3),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.star_rounded,
        size: 8.5,
        color: Color(0xFFFFCD00),
      ),
    );
  }
}
