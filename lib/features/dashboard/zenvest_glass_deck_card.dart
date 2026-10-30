import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/widgets/finora_mascot.dart';
import '../../core/widgets/finora_member_filter.dart';
import '../../core/widgets/finora_quick_action_icon.dart';
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
import '../qr_pay/qr_scanner_screen.dart';

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

        // 3. Filter Bar (Tất cả & Hôm nay) - Placed directly below the 3 mini widgets!
        if (widget.filterBar != null) ...[
          const SizedBox(height: 12),
          widget.filterBar!,
        ],

        const SizedBox(height: 14),
        _buildFinora3DCompanionLounge(isDark),
        const SizedBox(height: 16),

        // 5. Khối AI Thông Minh (Nhập nhanh AI, Sức khoẻ tài chính, Cho vay & Vay nợ)
        _buildZenvestAiSection(isDark),

        const SizedBox(height: 20),

        // 6. Zenvest Transactions Surface Container
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

    return Container(
      key: const ValueKey('compact-total-assets'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF047857)
                .withValues(alpha: isDark ? 0.45 : 0.28),
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
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF022C22),
                Color(0xFF064E3B),
                Color(0xFF047857),
                Color(0xFF0D9488),
              ],
              stops: [0.0, 0.35, 0.72, 1.0],
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
                        const Color(0xFF34D399).withValues(alpha: 0.36),
                        const Color(0xFF10B981).withValues(alpha: 0.0),
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
                        const Color(0xFF2DD4BF).withValues(alpha: 0.22),
                        const Color(0xFF064E3B).withValues(alpha: 0.0),
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
              // Ambient Mascot Watermark
              const FinoraAmbientMascotWatermark(
                pose: FinoraMascotPose.happy,
                size: 132,
                opacity: 0.10,
                alignment: Alignment.bottomRight,
                offset: Offset(18, 18),
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
                                color: const Color(0xFF6EE7B7)
                                    .withValues(alpha: 0.35),
                                width: 0.9,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.account_balance_rounded,
                                  size: 13.5,
                                  color: Color(0xFF6EE7B7),
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

  // 3. Zenvest Action Row: 4 nút tác vụ tròn chuẩn Emerald Fintech (Chuyển tiền ↗, Nhận tiền ✓, Quét QR, Thêm)
  // 3. Zenvest Action Row: 4 nút tác vụ tròn chuẩn Emerald Fintech (Chuyển tiền, Nhận tiền, Quét QR, Mục tiêu)
  Widget _buildActionRow(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: FinoraTokens.calmCardDecoration(
        isDark: isDark,
        radius: 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCircularActionItem(
            label: 'Chuyển tiền',
            icon: LucideIcons.arrow_up_right,
            themeColor: const Color(0xFF0284C7),
            isDark: isDark,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddTransactionPage(
                    userId: widget.userId,
                    initialType: 'transfer',
                  ),
                ),
              );
            },
          ),
          _buildCircularActionItem(
            label: 'Nhận tiền',
            icon: LucideIcons.arrow_down_left,
            themeColor: const Color(0xFF00875A),
            isDark: isDark,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddTransactionPage(
                    userId: widget.userId,
                    initialType: 'income',
                  ),
                ),
              );
            },
          ),
          _buildCircularActionItem(
            label: 'Quét QR',
            icon: LucideIcons.qr_code,
            themeColor: const Color(0xFFD97706),
            isDark: isDark,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QrScannerScreen(
                    userId: widget.userId,
                  ),
                ),
              );
            },
          ),
          _buildCircularActionItem(
            label: 'Mục tiêu',
            icon: LucideIcons.target,
            themeColor: const Color(0xFF0D9488),
            isDark: isDark,
            onTap: () {
              HapticFeedback.lightImpact();
              if (widget.onViewPlanning != null) {
                widget.onViewPlanning!();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCircularActionItem({
    required String label,
    required IconData icon,
    required Color themeColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final podBg = themeColor.withValues(alpha: isDark ? 0.20 : 0.12);
    final borderColor = themeColor.withValues(alpha: isDark ? 0.40 : 0.25);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: podBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withValues(alpha: isDark ? 0.22 : 0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: FinoraMascotActionIcon(
                  action: switch (label) {
                    'Chuyển tiền' => FinoraQuickAction.send,
                    'Nhận tiền' => FinoraQuickAction.receive,
                    'Quét QR' => FinoraQuickAction.scan,
                    _ => FinoraQuickAction.goal,
                  },
                  color: themeColor,
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'BeVietnamPro',
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Widget Chi tiêu, Thu nhập, Số dư (Tiền mặt)
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
            subtitle: 'Tháng này',
            amount: widget.income,
            prefix: '+',
            color: const Color(0xFF059669),
            icon: Icons.south_west_rounded,
            isDark: isDark,
            onTap: widget.onViewTransactions,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricMiniCard(
            label: 'Chi tiêu',
            subtitle: 'Tháng này',
            amount: widget.expense,
            prefix: '−',
            color: const Color(0xFFE11D48),
            icon: Icons.north_east_rounded,
            isDark: isDark,
            onTap: widget.onViewTransactions,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricMiniCard(
            label: 'Số dư',
            subtitle: 'Tiền mặt',
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
    required String subtitle,
    required num amount,
    required String prefix,
    required Color color,
    required IconData icon,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    final formattedValue =
        widget.masked ? '••••••' : '$prefix${_formatAmount(amount)} ₫';

    final valueColor = widget.masked
        ? (isDark ? Colors.white : const Color(0xFF0F172A))
        : (label == 'Thu nhập'
            ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
            : (label == 'Chi tiêu'
                ? (isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48))
                : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))));

    final cardAlpha = widget.studio.glassOpacity.clamp(0.25, 1.0);
    final baseSurface = isDark
        ? Color.alphaBlend(
            color.withValues(alpha: 0.08), const Color(0xFF1E293B))
        : Color.alphaBlend(color.withValues(alpha: 0.04), Colors.white);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          if (onTap != null) onTap();
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(11, 11, 11, 11),
          decoration: BoxDecoration(
            color: baseSurface.withValues(alpha: cardAlpha),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.36 : 0.24),
              width: 1.15,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.16 : 0.07),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top: Circular Jewel Icon Badge + Label
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withValues(alpha: isDark ? 0.30 : 0.18),
                          color.withValues(alpha: isDark ? 0.14 : 0.08),
                        ],
                      ),
                      border: Border.all(
                        color: color.withValues(alpha: isDark ? 0.45 : 0.28),
                        width: 1.0,
                      ),
                    ),
                    child: Center(
                      child: Icon(icon, color: color, size: 15),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: isDark
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Value
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formattedValue,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: valueColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Bottom Accent Bar + Subtitle
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 3,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. Khối AI Thông Minh Tích Hợp (Nhập Nhanh AI + Sức Khỏe AI + Cho Vay / Vay Nợ + Companion Banner)
  Widget _buildZenvestAiSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 4.1. Thanh Nhập Nhanh Với AI (Thiết kế Clean Minimal Finora Emerald)
        _buildZenvestAiQuickInputBar(isDark),

        const SizedBox(height: 12),

        // 4.2. Thẻ Bento Sức Khỏe Tài Chính Finora AI (Thiết kế Clean Minimal)
        _buildZenvestAiHealthCard(isDark),

        const SizedBox(height: 12),

        // 4.3. Widget Cho Vay và Vay Nợ
        _buildLendingAndDebtWidget(isDark),
      ],
    );
  }

  // 2. Finora AI Smart Ambient Island (Apple Intelligence Inspired Companion)
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

        final statusColor =
            isOver ? FinoraTokens.appleCoral : const Color(0xFF00866A);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isOver
                ? widget.onViewPlanning
                : (widget.onAiAdvisorTap ?? widget.onViewPlanning),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF13221E) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF34D399).withValues(alpha: 0.24)
                      : const Color(0xFF34D399).withValues(alpha: 0.35),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF003D35)
                        .withValues(alpha: isDark ? 0.32 : 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 1. Linh thú Rồng ngọc Finora 3D chính thức (Đồng hành tài chính)
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: isDark
                          ? const Color(0xFF1D332B)
                          : const Color(0xFFE8F7F0),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF34D399).withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Image.asset(
                      isOver
                          ? 'assets/mascot/expression-03-focused.png'
                          : 'assets/mascot/expression-01-happy.png',
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
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
                                boxShadow: [
                                  BoxShadow(
                                    color: statusColor.withValues(alpha: 0.6),
                                    blurRadius: 4,
                                  ),
                                ],
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
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 15,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          speechText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                            height: 1.3,
                          ),
                        ),
                        if (totalBudgetLimit > 0) ...[
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: budgetProgress.clamp(0.0, 1.0),
                              minHeight: 5.0,
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
          ),
        );
      },
    );
  }

  Widget _buildZenvestAiQuickInputBar(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onAiQuickLogTap?.call();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121A17) : Colors.white,
            borderRadius: BorderRadius.circular(20),
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
          child: Row(
            children: [
              // 3D Finora Cat AI Mascot Badge
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F6E56).withValues(alpha: 0.20)
                      : const Color(0xFFEFF7F4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.auto_awesome_rounded,
                    color: isDark
                        ? const Color(0xFF6EE7B7)
                        : const Color(0xFF00866A),
                    size: 24),
              ),
              const SizedBox(width: 12),

              // Placeholder Hint
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Finora AI',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isDark
                            ? const Color(0xFF34D399)
                            : const Color(0xFF00866A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Nhập nhanh giao dịch',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0D1F1A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Mic / Record action pill (Pure icon only)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F6E56).withValues(alpha: 0.24)
                      : const Color(0xFFE8F5F0),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.mic_none_rounded,
                    size: 16,
                    color: isDark
                        ? const Color(0xFF34D399)
                        : const Color(0xFF0F6E56),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121A17) : Colors.white,
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
                      color: isDark
                          ? const Color(0xFF0F6E56).withValues(alpha: 0.24)
                          : const Color(0xFFE8F5F0),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 15,
                      color: isDark
                          ? const Color(0xFF34D399)
                          : const Color(0xFF0F6E56),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F6E56).withValues(alpha: 0.22)
                          : const Color(0xFFE8F5F0),
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
                        color: isDark
                            ? const Color(0xFF34D399)
                            : const Color(0xFF0F6E56),
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
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF10B981)),
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
                                letterSpacing: -0.5,
                                color: Color(0xFF10B981),
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
        ),
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
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121A17) : Colors.white,
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
        ),
      ),
    );
  }

  // 5. Zenvest Transactions Surface Container
  Widget _buildTransactionsSurface(bool isDark) {
    final txList = widget.txList;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121A17) : Colors.white,
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
  }

  Widget _buildEmptyTransactionsPlaceholder(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const FinoraMascotImage(
            pose: FinoraMascotPose.relaxed,
            size: 68,
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
    final shortWallet = formatShortWalletName(tx.walletName);
    final ownerRole = (tx.owner ?? tx.creatorTag ?? 'all').trim();
    final bankCode = tx.bankTransactionCode?.trim();
    final subtitle = '$catDisplayName • $shortWallet • ${_formatRelativeDate(txDate)}';

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

    final isPhoto = CategoryIconHelper.isPhoto(
            resolvedIconStr, catDisplayName) ||
        (BankIconRegistry.resolve(resolvedIconStr, bankName: catDisplayName)
                    .code !=
                'cash' &&
            BankIconRegistry.resolve(resolvedIconStr, bankName: catDisplayName)
                    .assetPath !=
                null);

    final listStyle = widget.studio.transactionListStyle;
    final isCompact = listStyle == AppTransactionListStyle.compactTable;
    final isBento = listStyle == AppTransactionListStyle.bentoCards;
    final isTimeline = listStyle == AppTransactionListStyle.timelineRail;
    final isMagazine = listStyle == AppTransactionListStyle.magazineLedger;
    final isMinimal = listStyle == AppTransactionListStyle.minimalDivided;

    final rowContent = Row(
      children: [
        if (isTimeline) ...[
          Container(
            width: 3.5,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 8),
        ],
        // Circular Avatar Icon + Member Avatar Badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: isCompact ? 34 : (isMagazine ? 46 : 42),
              height: isCompact ? 34 : (isMagazine ? 46 : 42),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: isPhoto
                    ? Colors.transparent
                    : catColor.withValues(alpha: isDark ? 0.22 : 0.14),
                shape: isBento ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: isBento ? BorderRadius.circular(14) : null,
              ),
              child: Center(
                child: CategoryIconWidget(
                  icon: resolvedIconStr,
                  categoryName: catDisplayName,
                  size: isPhoto
                      ? (isCompact ? 34 : (isMagazine ? 46 : 42))
                      : (isCompact ? 18 : 22),
                  color: effectiveIconColor,
                ),
              ),
            ),
            Positioned(
              right: -3,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF121A17) : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: FinoraMemberAvatar(
                  role: ownerRole,
                  size: isCompact ? 13 : 15,
                  studio: widget.studio,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(width: 12),

        // Title & Subtitle + Short Wallet + Bank Code
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
                        fontSize: isCompact ? 13.5 : (isMagazine ? 15 : 14.5),
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
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : const Color(0xFF0F172A))
                            .withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        shortWallet,
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
              if (!isCompact) ...[
                const SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.2,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    if (bankCode != null && bankCode.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '#$bankCode',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(width: 10),

        // Amount & Status Badge (Always pinned flush right)
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 116),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  amountText,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: isCompact ? 13.5 : (isMagazine ? 15.5 : 14.5),
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: isTransfer
                        ? (isDark
                            ? const Color(0xFF38BDF8)
                            : const Color(0xFF0284C7))
                        : (isFlowIn
                            ? (isDark
                                ? const Color(0xFF34D399)
                                : const Color(0xFF059669))
                            : (isDark
                                ? const Color(0xFFF87171)
                                : const Color(0xFFE11D48))),
                  ),
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

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
        margin: EdgeInsets.symmetric(vertical: (isBento || isMagazine) ? 4 : 1.5),
        padding: EdgeInsets.symmetric(
          vertical: isCompact ? 6 : (isMagazine ? 11 : 9),
          horizontal: (isBento || isMagazine) ? 12 : 4,
        ),
        decoration: isBento
            ? BoxDecoration(
                color: (isDark ? Colors.white : const Color(0xFF0F172A))
                    .withValues(alpha: 0.045),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: catColor.withValues(alpha: 0.22),
                ),
              )
            : isMagazine
                ? BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        catColor.withValues(alpha: isDark ? 0.14 : 0.08),
                        (isDark ? Colors.white : const Color(0xFF0F172A))
                            .withValues(alpha: 0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: catColor.withValues(alpha: 0.18),
                    ),
                  )
                : isMinimal
                    ? BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.06),
                            width: 0.7,
                          ),
                        ),
                      )
                    : null,
        child: rowContent,
      ),
    );
  }
}
