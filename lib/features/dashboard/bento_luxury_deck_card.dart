import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/utils/date_filter.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/widgets/finora_member_filter.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/widgets/subject_filter_pill.dart';
import '../../data/models/wallet.dart';
import '../../domain/finance/transaction_member.dart';
import '../../state/dashboard_provider.dart';
import '../../state/theme_studio_controller.dart';
import '../wallet/add_wallet_page.dart';

/// Bento Luxury Fintech Deck (Concept 1: Copilot Money & Apple Card Dark Luxury).
///
/// Features:
/// 1. 3D Tactile Physical Bank Card Deck Carousel (Brushed metal gradients, EMV chip, contactless wave, bank squircle badge)
/// 2. Bento Pod 1: Today's Spend & Safe-to-Spend Daily Velocity Gauge
/// 3. Bento Pod 2: 30-Day Cashflow Sparkline & Inflow/Outflow Velocity
class BentoLuxuryDeckCard extends StatefulWidget {
  final String userId;
  final DashboardProvider provider;
  final num totalBalance;
  final num income;
  final num expense;
  final num netFlow;
  final bool isDark;
  final ThemeStudioController studio;
  final bool masked;
  final String userName;
  final VoidCallback? onViewWallets;
  final VoidCallback? onDateFilterTap;
  final VoidCallback? onOwnerFilterTap;
  final VoidCallback? onToggleMask;
  final VoidCallback? onAddTransaction;

  const BentoLuxuryDeckCard({
    super.key,
    required this.userId,
    required this.provider,
    required this.totalBalance,
    required this.income,
    required this.expense,
    required this.netFlow,
    required this.isDark,
    required this.studio,
    this.masked = false,
    required this.userName,
    this.onViewWallets,
    this.onDateFilterTap,
    this.onOwnerFilterTap,
    this.onToggleMask,
    this.onAddTransaction,
  });

  @override
  State<BentoLuxuryDeckCard> createState() => _BentoLuxuryDeckCardState();
}

class _BentoLuxuryDeckCardState extends State<BentoLuxuryDeckCard> {
  late final PageController _cardPageController;
  int _currentCardIndex = 0;

  @override
  void initState() {
    super.initState();
    _cardPageController = PageController(viewportFraction: 0.90);
  }

  @override
  void dispose() {
    _cardPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final d = widget.provider.data;
    final wallets = d.wallets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Top Section Header (Vault branding & quick actions)
        _buildVaultHeader(isDark, widget.provider),

        const SizedBox(height: 14),

        // 2. Physical 3D Card Deck Carousel
        _buildCardCarousel(wallets, isDark),

        // 2b. Card Page Indicator Dots
        if (wallets.length > 1) ...[
          const SizedBox(height: 12),
          _buildPageIndicator(wallets.length + 1, isDark),
        ],

        const SizedBox(height: 16),

        // 3. Bento Dual Pods: Today's Spend Velocity & 30-Day Cashflow Curve
        _buildBentoDualPods(d, isDark),
      ],
    );
  }

  /// Top Row Header with luxury badge and dual filter pills (Chồng/Vợ & Ngày tháng)
  Widget _buildVaultHeader(bool isDark, DashboardProvider provider) {
    final currentOwner = provider.selectedOwner;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left: Finora Platinum Vault Title & Net Worth
        Expanded(
          flex: 5,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.lightImpact();
              if (widget.onViewWallets != null) {
                widget.onViewWallets!();
              }
            },
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.16) : const Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.35) : const Color(0xFFD97706).withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    LucideIcons.credit_card,
                    color: isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KHO TÀI SẢN',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: isDark ? const Color(0xFFE5C378) : const Color(0xFF946200),
                        ),
                      ),
                      const SizedBox(height: 1),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.onToggleMask?.call();
                        },
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.masked
                                ? '•••••••• ₫'
                                : Formatters.formatCurrency(widget.totalBalance),
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontFeatures: const [FontFeature.tabularFigures()],
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
        ),

        const SizedBox(width: 8),

        // Right: Dual Filter Pills (Chồng/Vợ & Ngày tháng)
        Flexible(
          flex: 6,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMemberFilterPill(isDark, currentOwner, provider),
                const SizedBox(width: 6),
                _buildDateFilterPill(isDark, provider),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Luxury Member Filter Pill: [ 👨 Chồng | 👩 Vợ | 👥 Tất cả ]
  Widget _buildMemberFilterPill(
      bool isDark, OwnerFilter currentOwner, DashboardProvider provider) {
    final memberStr = currentOwner == OwnerFilter.husband
        ? 'husband'
        : (currentOwner == OwnerFilter.wife ? 'wife' : null);

    return FinoraUnifiedMemberPill(
      currentMember: memberStr,
      onSelected: (val) {
        if (val == 'husband') {
          provider.setOwnerFilter(OwnerFilter.husband);
        } else if (val == 'wife') {
          provider.setOwnerFilter(OwnerFilter.wife);
        } else {
          provider.setOwnerFilter(OwnerFilter.all);
        }
      },
      isDark: isDark,
    );
  }

  /// Luxury Date Filter Pill: [ 📅 Tháng này / Hôm nay / T10 ▾ ]
  Widget _buildDateFilterPill(bool isDark, DashboardProvider provider) {
    final rawPeriod = provider.data.periodLabel.isNotEmpty
        ? provider.data.periodLabel
        : 'Tháng này';

    final String cleanLabel;
    if (provider.selectedDateFilter == DateFilterOption.today) {
      cleanLabel = 'Hôm nay';
    } else if (provider.selectedDateFilter == DateFilterOption.yesterday) {
      cleanLabel = 'Hôm qua';
    } else if (provider.selectedDateFilter == DateFilterOption.thisWeek) {
      cleanLabel = 'Tuần này';
    } else if (provider.selectedDateFilter == DateFilterOption.lastWeek) {
      cleanLabel = 'Tuần trước';
    } else if (provider.selectedDateFilter == DateFilterOption.thisMonth) {
      cleanLabel = 'Tháng này';
    } else if (provider.selectedDateFilter == DateFilterOption.lastMonth) {
      cleanLabel = 'Tháng trước';
    } else if (provider.selectedDateFilter == DateFilterOption.thisYear) {
      cleanLabel = 'Năm nay';
    } else if (provider.selectedDateFilter == DateFilterOption.allTime) {
      cleanLabel = 'Tất cả';
    } else if (rawPeriod.startsWith('Tháng ')) {
      final parts = rawPeriod.replaceFirst('Tháng ', '').split('/');
      cleanLabel = parts.isNotEmpty ? 'T${parts[0]}' : rawPeriod;
    } else if (rawPeriod.startsWith('Năm ')) {
      cleanLabel = rawPeriod;
    } else if (rawPeriod.length > 9) {
      cleanLabel = rawPeriod.substring(0, 9);
    } else {
      cleanLabel = rawPeriod;
    }

    final accentGold = isDark ? const Color(0xFFE5C378) : const Color(0xFF946200);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onDateFilterTap?.call();
        },
        borderRadius: BorderRadius.circular(100),
        child: Container(
          height: 32,
          constraints: const BoxConstraints(minHeight: 32),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isDark
                  ? const Color(0xFFE5C378).withValues(alpha: 0.32)
                  : const Color(0xFFB4833E).withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.calendar,
                size: 12.5,
                color: accentGold,
              ),
              const SizedBox(width: 4.5),
              Text(
                cleanLabel,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 3D Physical Bank Card Carousel
  Widget _buildCardCarousel(List<Wallet> wallets, bool isDark) {
    final itemCount = wallets.isEmpty ? 1 : wallets.length + 1;

    return SizedBox(
      height: 196,
      child: PageView.builder(
        controller: _cardPageController,
        clipBehavior: Clip.none,
        itemCount: itemCount,
        onPageChanged: (idx) => setState(() => _currentCardIndex = idx),
        itemBuilder: (context, index) {
          // If empty, render hero total card
          if (wallets.isEmpty) {
            return _buildPhysicalCard(
              wallet: null,
              isDark: isDark,
              cardIndex: 0,
            );
          }

          // If last index, show "+ Thêm thẻ / ví mới"
          if (index == wallets.length) {
            return _buildAddNewCardItem(isDark);
          }

          return _buildPhysicalCard(
            wallet: wallets[index],
            isDark: isDark,
            cardIndex: index,
          );
        },
      ),
    );
  }

  /// Single Physical Luxury Bank Card (Brushed titanium texture, EMV Chip, Contactless)
  Widget _buildPhysicalCard({
    required Wallet? wallet,
    required bool isDark,
    required int cardIndex,
  }) {
    final w = wallet;
    final isCash = w != null && w.type == 'cash';
    final isCredit = w != null && w.isCreditCard;
    final brand = BankIconRegistry.resolve(w?.bankCode, bankName: w?.bankName ?? w?.name);

    // Pick luxury gradient palette based on card type / bank
    final List<Color> cardGradient = _resolveCardGradient(w, brand.code, isCash, isCredit);

    final cardName = (w != null && w.name.isNotEmpty)
        ? w.name
        : 'FINORA PLATINUM VAULT';
    final cardHolder = _resolveCardHolder(w);

    final accountNumber = w?.accountNumber?.trim() ?? '';
    final maskedNum = accountNumber.isNotEmpty
        ? '••••  ••••  ••••  ${accountNumber.substring(math.max(0, accountNumber.length - 4))}'
        : (isCash ? 'TIỀN MẶT CẦM TAY' : '••••  ••••  ••••  8899');

    final balanceVal = w?.balance ?? widget.totalBalance;
    final currencyText = widget.masked
        ? '•••••• ₫'
        : Formatters.formatCurrency(balanceVal);

    return AnimatedBuilder(
      animation: _cardPageController,
      builder: (context, child) {
        double scale = 1.0;
        if (_cardPageController.position.haveDimensions) {
          final page = _cardPageController.page ?? _cardPageController.initialPage.toDouble();
          final diff = (page - cardIndex).abs();
          scale = (1.0 - (diff * 0.06)).clamp(0.92, 1.0);
        }

        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: cardGradient.first,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.16),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [

              // Card Content Face (fitted to prevent overflow under extreme text scaling or narrow width)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 290,
                      height: 154,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Row 1: Bank/Wallet Avatar + Name on Left | Contactless Wave + Chip on Right
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Left: Logo & Title
                              Expanded(
                                child: Row(
                                  children: [
                                    BankIconAvatar(
                                      bankCode: brand.code,
                                      size: 30,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cardName.toUpperCase(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                          Text(
                                            isCredit
                                                ? 'CREDIT PLATINUM'
                                                : (isCash ? 'TIỀN MẶT' : 'DEBIT TÀI KHOẢN'),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.65),
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Right: EMV Chip + Contactless Wave
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Contactless Wave
                                  RotatedBox(
                                    quarterTurns: 1,
                                    child: Icon(
                                      Icons.wifi_rounded,
                                      color: Colors.white.withValues(alpha: 0.70),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Metallic EMV Chip
                                  _buildEmvChip(),
                                ],
                              ),
                            ],
                          ),

                          // Row 2: Masked Card Number
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                maskedNum,
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.2,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          ),

                          // Row 3: Cardholder Name on Left | Balance Figure on Right
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Left: Cardholder Name
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'CHỦ THẺ',
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.55),
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      cardHolder,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Right: Balance Amount
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isCredit ? 'HẠN MỨC DỤNG' : 'SỐ DƯ KHẢ DỤNG',
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.65),
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        currencyText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.4,
                                          fontFeatures: [FontFeature.tabularFigures()],
                                        ),
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
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Add New Card / Wallet item in carousel
  Widget _buildAddNewCardItem(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131826) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFFCBD5E1),
          width: 1.2,
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddWalletPage(userId: widget.userId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isDark ? Colors.white : const Color(0xFF0F172A))
                          .withValues(alpha: 0.08),
                      border: Border.all(
                        color: (isDark ? Colors.white : const Color(0xFF0F172A))
                            .withValues(alpha: 0.15),
                      ),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thêm Thẻ Hoặc Ví Mới',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Quản lý đa tài khoản & ngân hàng',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Realistic EMV Metallic Smart Chip
  Widget _buildEmvChip() {
    return Container(
      width: 28,
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: const Color(0xFFD4AF37),
      ),
      child: Center(
        child: Container(
          width: 14,
          height: 10,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF8A6B1A), width: 0.8),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  /// Animated indicator dots below card carousel
  Widget _buildPageIndicator(int count, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == _currentCardIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 22 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? const Color(0xFFE5C378) : const Color(0xFF946200))
                : (isDark
                    ? Colors.white.withValues(alpha: 0.20)
                    : Colors.black.withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  /// Bento Dual Pods:
  /// Left Pod: Today's Spend & Safe-to-Spend Daily Velocity Gauge
  /// Right Pod: 30-Day Cashflow Sparkline & Velocity
  Widget _buildBentoDualPods(DashboardData d, bool isDark) {
    // 1. Calculate Today's Expense
    final todayExpense = d.selectedDateFilter == DateFilterOption.today
        ? d.periodExpense
        : _computeTodayExpenseFromTransactions(d.allTransactions);

    // Estimate daily budget target based on month expense / 30, or default 500k
    final num dailyBudgetCap = (d.currentMonthExpenses > 0)
        ? math.max(300000, (d.currentMonthExpenses / DateTime.now().day * 1.1).round())
        : 500000;

    final double velocityRatio = dailyBudgetCap > 0
        ? (todayExpense / dailyBudgetCap).clamp(0.0, 1.5)
        : 0.0;
    final int velocityPercent = (velocityRatio * 100).round();
    final num dailyRemaining = math.max(0, dailyBudgetCap - todayExpense);

    final podBg = isDark ? const Color(0xFF131826) : Colors.white;
    final podBorder = Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFE2E8F0),
      width: 1.0,
    );

    final pod1 = _buildTodaySpendPod(
      todayExpense: todayExpense,
      dailyBudgetCap: dailyBudgetCap,
      velocityRatio: velocityRatio,
      velocityPercent: velocityPercent,
      dailyRemaining: dailyRemaining,
      podBg: podBg,
      podBorder: podBorder,
      isDark: isDark,
    );

    final pod2 = _buildCashflowCurvePod(
      income: d.currentMonthIncome > 0 ? d.currentMonthIncome : widget.income,
      expense: d.currentMonthExpenses > 0 ? d.currentMonthExpenses : widget.expense,
      podBg: podBg,
      podBorder: podBorder,
      isDark: isDark,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: pod1),
        const SizedBox(width: 10),
        Expanded(child: pod2),
      ],
    );
  }

  /// Bento Pod 1: Today's Spend & Daily Velocity Meter
  Widget _buildTodaySpendPod({
    required num todayExpense,
    required num dailyBudgetCap,
    required double velocityRatio,
    required int velocityPercent,
    required num dailyRemaining,
    required Color podBg,
    required BoxBorder podBorder,
    required bool isDark,
  }) {
    // Velocity color: Green (<70%), Amber (70-100%), Coral (>100%)
    final velocityColor = velocityRatio > 1.0
        ? const Color(0xFFFF4D6D)
        : (velocityRatio > 0.75
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981));

    return Container(
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(minHeight: 104),
      decoration: BoxDecoration(
        color: podBg,
        borderRadius: BorderRadius.circular(16),
        border: podBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'TIÊU HÔM NAY',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(3.5),
                decoration: BoxDecoration(
                  color: velocityColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.zap,
                  size: 11,
                  color: velocityColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Big Amount Spent
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              widget.masked ? '•••••• ₫' : Formatters.formatCurrency(todayExpense),
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.4,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),

          const SizedBox(height: 7),

          // Horizontal Progress Velocity Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 5,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: velocityRatio.clamp(0.05, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981),
                        velocityColor,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Velocity pill tag & Remaining
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '$velocityPercent% Nhịp độ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: velocityColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  widget.masked
                      ? '••••'
                      : 'Còn ${_formatCompact(dailyRemaining)}đ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bento Pod 2: 30-Day Cashflow Sparkline & Inflow/Outflow Breakdown
  Widget _buildCashflowCurvePod({
    required num income,
    required num expense,
    required Color podBg,
    required BoxBorder podBorder,
    required bool isDark,
  }) {
    final netMargin = income - expense;
    final isSurplus = netMargin >= 0;

    return Container(
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(minHeight: 104),
      decoration: BoxDecoration(
        color: podBg,
        borderRadius: BorderRadius.circular(16),
        border: podBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'DÒNG TIỀN THÁNG',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(3.5),
                decoration: BoxDecoration(
                  color: (isSurplus ? const Color(0xFF10B981) : const Color(0xFFFF4D6D))
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSurplus ? LucideIcons.trending_up : LucideIcons.trending_down,
                  size: 11,
                  color: isSurplus ? const Color(0xFF10B981) : const Color(0xFFFF4D6D),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Sparkline Wave Chart (Bezier Smooth Curve)
          SizedBox(
            height: 32,
            width: double.infinity,
            child: CustomPaint(
              painter: _BentoSparklinePainter(
                isSurplus: isSurplus,
                isDark: isDark,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Inflow / Outflow Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  widget.masked
                      ? 'Thu: ••••'
                      : '+${_formatCompact(income)}đ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  widget.masked
                      ? 'Chi: ••••'
                      : '-${_formatCompact(expense)}đ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF4D6D),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Resolves physical card gradient based on bank or skin
  List<Color> _resolveCardGradient(
      Wallet? w, String bankCode, bool isCash, bool isCredit) {
    if (isCash) {
      return const [
        Color(0xFF0F382A),
        Color(0xFF134E3A),
        Color(0xFF09261C),
      ];
    }

    if (isCredit) {
      return const [
        Color(0xFF1E2430),
        Color(0xFF2B3444),
        Color(0xFF11141B),
      ];
    }

    final code = bankCode.toLowerCase();
    if (code == 'vcb' || code == 'vpb') {
      return const [
        Color(0xFF0E3E28),
        Color(0xFF155C3C),
        Color(0xFF072115),
      ];
    } else if (code == 'tcb' || code == 'cake' || code == 'hdb') {
      return const [
        Color(0xFF5A121A),
        Color(0xFF821C27),
        Color(0xFF33090E),
      ];
    } else if (code == 'mbbank' || code == 'bidv' || code == 'acb') {
      return const [
        Color(0xFF0E2E5C),
        Color(0xFF16478E),
        Color(0xFF071833),
      ];
    } else if (code == 'tpb' || code == 'timo') {
      return const [
        Color(0xFF3A1854),
        Color(0xFF582480),
        Color(0xFF200B30),
      ];
    }

    // Default luxury obsidian brushed titanium
    return const [
      Color(0xFF1E222D),
      Color(0xFF2C3242),
      Color(0xFF12141A),
    ];
  }

  /// Resolves the card holder label as 'VỢ' or 'CHỒNG' based on wallet owner
  String _resolveCardHolder(Wallet? w) {
    if (w == null) return 'CHỒNG';
    final member = resolveWalletMember(w);
    if (member == TransactionMember.wife) {
      return 'VỢ';
    }
    if (member == TransactionMember.husband) {
      return 'CHỒNG';
    }
    if (member == TransactionMember.joint) {
      return 'CHUNG';
    }
    final rawOwner = w.owner.toLowerCase().trim();
    final rawOwnerName = w.ownerName.toLowerCase().trim();
    if (rawOwner == 'wife' || rawOwnerName.contains('vợ') || rawOwnerName == 'wife') {
      return 'VỢ';
    }
    if (rawOwner == 'husband' || rawOwnerName.contains('chồng') || rawOwnerName == 'husband') {
      return 'CHỒNG';
    }
    if (w.ownerName.trim().isNotEmpty) {
      return w.ownerName.trim().toUpperCase();
    }
    return 'CHỒNG';
  }

  String _formatCompact(num amount) {
    final abs = amount.abs();
    if (abs >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)} tỷ';
    } else if (abs >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} tr';
    } else if (abs >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return amount.toStringAsFixed(0);
  }

  num _computeTodayExpenseFromTransactions(List<dynamic> allTx) {
    final now = DateTime.now();
    num total = 0;
    for (final tx in allTx) {
      if (tx.type == 'expense') {
        final d = tx.date;
        DateTime? dt;
        if (d is DateTime) {
          dt = d;
        } else if (d is int) {
          dt = d > 100000000000
              ? DateTime.fromMillisecondsSinceEpoch(d)
              : DateTime.fromMillisecondsSinceEpoch(d * 1000);
        }
        if (dt != null &&
            dt.year == now.year &&
            dt.month == now.month &&
            dt.day == now.day) {
          total += (tx.amount ?? 0);
        }
      }
    }
    return total;
  }
}

/// Custom painter rendering a smooth cubic bezier sparkline wave for 30-day cashflow
class _BentoSparklinePainter extends CustomPainter {
  final bool isSurplus;
  final bool isDark;

  const _BentoSparklinePainter({
    required this.isSurplus,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeColor = isSurplus ? const Color(0xFF10B981) : const Color(0xFFFF4D6D);
    final w = size.width;
    final h = size.height;

    // Normalised points for smooth financial wave
    final points = isSurplus
        ? [
            Offset(0, h * 0.75),
            Offset(w * 0.20, h * 0.60),
            Offset(w * 0.45, h * 0.80),
            Offset(w * 0.70, h * 0.35),
            Offset(w * 0.90, h * 0.20),
            Offset(w, h * 0.15),
          ]
        : [
            Offset(0, h * 0.25),
            Offset(w * 0.25, h * 0.40),
            Offset(w * 0.50, h * 0.30),
            Offset(w * 0.75, h * 0.70),
            Offset(w, h * 0.85),
          ];

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // 1. Draw glowing area beneath wave
    final fillPath = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          strokeColor.withValues(alpha: isDark ? 0.30 : 0.15),
          strokeColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(fillPath, fillPaint);

    // 2. Draw crisp stroke line
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);

    // 3. Draw indicator dot at terminal end
    final endPoint = points.last;
    final dotPaint = Paint()..color = strokeColor;
    final dotRingPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(endPoint, 3.5, dotPaint);
    canvas.drawCircle(endPoint, 6.0, dotRingPaint);
  }

  @override
  bool shouldRepaint(covariant _BentoSparklinePainter oldDelegate) {
    return oldDelegate.isSurplus != isSurplus || oldDelegate.isDark != isDark;
  }
}
