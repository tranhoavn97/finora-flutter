import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/adaptive_glass_surface.dart';
import '../../core/widgets/finora_motion.dart';
import '../../core/widgets/finora_privacy_mask.dart';
import '../../core/widgets/morph_icon.dart';
import '../../state/theme_studio_controller.dart';

class FinoraHeroStyleMeta {
  final AppHeroCardStyle style;
  final String title;
  final String subtitle;
  final bool isNew;
  final List<Color> previewColors;
  final IconData icon;

  const FinoraHeroStyleMeta({
    required this.style,
    required this.title,
    required this.subtitle,
    this.isNew = false,
    required this.previewColors,
    required this.icon,
  });
}

const List<FinoraHeroStyleMeta> kFinoraHeroStyleCatalog = [
  FinoraHeroStyleMeta(
    style: AppHeroCardStyle.auroraVaultCard,
    title: 'Aurora Vault',
    subtitle: 'Kính cực quang 2 tầng & tỷ lệ giữ tiền',
    isNew: true,
    previewColors: [Color(0xFF0F766E), Color(0xFF0284C7)],
    icon: Icons.auto_awesome_rounded,
  ),
  FinoraHeroStyleMeta(
    style: AppHeroCardStyle.obsidianTitanium,
    title: 'Obsidian Titanium',
    subtitle: 'Thẻ kim loại đen chip EMV & viền ánh kim',
    isNew: true,
    previewColors: [Color(0xFF0F172A), Color(0xFF334155)],
    icon: Icons.credit_card_rounded,
  ),
  FinoraHeroStyleMeta(
    style: AppHeroCardStyle.porcelainMinimal,
    title: 'Porcelain Private',
    subtitle: 'Trắng sứ tinh giản chuẩn Private Banking',
    isNew: true,
    previewColors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
    icon: Icons.account_balance_rounded,
  ),
  FinoraHeroStyleMeta(
    style: AppHeroCardStyle.cyberMeshHorizon,
    title: 'Mesh Horizon',
    subtitle: 'Lưới chuyển sắc đa tầng & 3 thẻ chỉ số nổi',
    isNew: true,
    previewColors: [Color(0xFF4338CA), Color(0xFF0EA5E9)],
    icon: Icons.blur_on_rounded,
  ),
  FinoraHeroStyleMeta(
    style: AppHeroCardStyle.zenvestGlassDeck,
    title: 'Zenvest Glass',
    subtitle: 'Kính mờ lơ lửng & thanh phím tác vụ nhanh',
    previewColors: [Color(0xFF059669), Color(0xFF14B8A6)],
    icon: Icons.layers_rounded,
  ),
  FinoraHeroStyleMeta(
    style: AppHeroCardStyle.netWorthModernDeck,
    title: 'Net Worth Modern',
    subtitle: 'Phong cách hiện đại với 5 phím Pastel & Bento',
    previewColors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
    icon: Icons.dashboard_customize_rounded,
  ),
  FinoraHeroStyleMeta(
    style: AppHeroCardStyle.bentoLuxuryDeck,
    title: 'Bento Luxury',
    subtitle: 'Thớt thẻ 3D sang trọng & nhịp chi tiêu',
    previewColors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    icon: Icons.view_quilt_rounded,
  ),
  FinoraHeroStyleMeta(
    style: AppHeroCardStyle.spatialPrismOrbital,
    title: 'Spatial Orbital',
    subtitle: 'Quả cầu quỹ đạo 3D với hiệu ứng quang học',
    previewColors: [Color(0xFF0284C7), Color(0xFF8B5CF6)],
    icon: Icons.public_rounded,
  ),
  FinoraHeroStyleMeta(
    style: AppHeroCardStyle.classicFintech,
    title: 'Classic Fintech',
    subtitle: 'Finora chuẩn mực gọn gàng 3 chỉ số',
    previewColors: [Color(0xFF0D9488), Color(0xFF059669)],
    icon: Icons.account_balance_wallet_rounded,
  ),
  FinoraHeroStyleMeta(
    style: AppHeroCardStyle.executiveBlackVip,
    title: 'Black VIP Gold',
    subtitle: 'Thẻ đen quyền lực với điểm nhấn vàng 24K',
    previewColors: [Color(0xFF111827), Color(0xFFD97706)],
    icon: Icons.stars_rounded,
  ),
  FinoraHeroStyleMeta(
    style: AppHeroCardStyle.minimalistPulse,
    title: 'Minimal Pulse',
    subtitle: 'Số dư phóng đại tối giản tập trung dòng tiền',
    previewColors: [Color(0xFF334155), Color(0xFF475569)],
    icon: Icons.show_chart_rounded,
  ),
  FinoraHeroStyleMeta(
    style: AppHeroCardStyle.liquidEnergySphere,
    title: 'Liquid Sphere',
    subtitle: 'Kính lỏng khúc xạ với khối năng lượng nổi',
    previewColors: [Color(0xFF0891B2), Color(0xFF6366F1)],
    icon: Icons.water_drop_rounded,
  ),
];

bool isExtendedHeroCardStyle(AppHeroCardStyle style) {
  return style == AppHeroCardStyle.auroraVaultCard ||
      style == AppHeroCardStyle.obsidianTitanium ||
      style == AppHeroCardStyle.porcelainMinimal ||
      style == AppHeroCardStyle.cyberMeshHorizon;
}

class ExtendedNetWorthHeroCard extends StatelessWidget {
  final AppHeroCardStyle style;
  final num totalBalance;
  final num income;
  final num expense;
  final num netFlow;
  final bool isDark;
  final ThemeStudioController studio;
  final Widget filterActions;
  final VoidCallback onTogglePrivacy;

  const ExtendedNetWorthHeroCard({
    super.key,
    required this.style,
    required this.totalBalance,
    required this.income,
    required this.expense,
    required this.netFlow,
    required this.isDark,
    required this.studio,
    required this.filterActions,
    required this.onTogglePrivacy,
  });

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case AppHeroCardStyle.auroraVaultCard:
        return _buildAuroraVault(context);
      case AppHeroCardStyle.obsidianTitanium:
        return _buildObsidianTitanium(context);
      case AppHeroCardStyle.porcelainMinimal:
        return _buildPorcelainMinimal(context);
      case AppHeroCardStyle.cyberMeshHorizon:
        return _buildCyberMeshHorizon(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBalanceValue(Color color) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: FinoraPrivacyMask(
        isMasked: studio.isPrivacyShieldActive,
        style: studio.privacyStyle,
        obscureText: '•••••••• đ',
        textStyle: TextStyle(
          color: color,
          fontSize: studio.getHeroBalanceFontSize(),
          fontWeight: FontWeight.w900,
          letterSpacing: -0.6,
        ),
        child: FinoraAnimatedAmount(
          amount: totalBalance,
          style: TextStyle(
            color: color,
            fontSize: studio.getHeroBalanceFontSize(),
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
          ),
        ),
      ),
    );
  }

  Widget _buildEyeButton({
    required Color bgColor,
    required Color borderColor,
    required Color iconColor,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTogglePrivacy();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 0.9),
        ),
        child: MorphIcon(
          icon: studio.isPrivacyShieldActive
              ? LucideIcons.eye_off
              : LucideIcons.eye,
          color: iconColor,
          size: 15,
        ),
      ),
    );
  }

  Widget _buildStatValue(String formatted, Color color) {
    return FinoraPrivacyMask(
      isMasked: studio.isPrivacyShieldActive,
      style: studio.privacyStyle,
      obscureText: '••••',
      textStyle: TextStyle(
        color: color,
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
      ),
      child: Text(
        formatted,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  /// Style 1: Aurora Vault — luminous dual-hue aurora glass vault with savings ratio bar
  Widget _buildAuroraVault(BuildContext context) {
    final radius = studio.getCardRadius(studio.dashboardDensity);
    final pad = studio.getCardPadding(studio.dashboardDensity);
    final primary = studio.resolvedPrimary;
    final secondary = studio.resolvedSecondary;
    final opacity = studio.glassOpacity.clamp(0.45, 1.0);
    final baseBg = Color.alphaBlend(
      primary.withValues(alpha: isDark ? 0.20 : 0.08),
      (isDark ? const Color(0xFF0B1324) : const Color(0xFFF8FBFF))
          .withValues(alpha: opacity),
    );
    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
    final subText =
        isDark ? Colors.white.withValues(alpha: 0.72) : const Color(0xFF475569);
    final totalFlow = (income + expense).toDouble();
    final incomeRatio =
        totalFlow > 0 ? (income / totalFlow).clamp(0.08, 0.92).toDouble() : 0.5;
    final savingsPct = income > 0
        ? (((income - expense) / income) * 100).round().clamp(-99, 100)
        : 0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.24 : 0.12),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            Positioned.fill(
              child: AdaptiveGlassSurface(
                decoration: BoxDecoration(
                  color: baseBg,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: primary.withValues(alpha: isDark ? 0.35 : 0.22),
                    width: 1.1,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -42,
              right: -28,
              child: IgnorePointer(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        primary.withValues(alpha: isDark ? 0.34 : 0.20),
                        secondary.withValues(alpha: isDark ? 0.14 : 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: isDark ? 0.24 : 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: primary.withValues(alpha: 0.30),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded,
                                size: 13, color: primary),
                            const SizedBox(width: 5),
                            Text(
                              'AURORA VAULT',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.7,
                                color: primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: filterActions,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'TỔNG TÀI SẢN HIỆN CÓ',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: subText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(child: _buildBalanceValue(primaryText)),
                      const SizedBox(width: 10),
                      _buildEyeButton(
                        bgColor:
                            primary.withValues(alpha: isDark ? 0.22 : 0.10),
                        borderColor: primary.withValues(alpha: 0.28),
                        iconColor: primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: SizedBox(
                            height: 6,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: (incomeRatio * 100).round(),
                                  child: Container(
                                    color: studio.getIncomeColor(isDark),
                                  ),
                                ),
                                Expanded(
                                  flex: ((1 - incomeRatio) * 100).round(),
                                  child: Container(
                                    color: studio.getExpenseColor(isDark),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (netFlow >= 0
                                  ? studio.getIncomeColor(isDark)
                                  : studio.getExpenseColor(isDark))
                              .withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Tích luỹ $savingsPct%',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: netFlow >= 0
                                ? studio.getIncomeColor(isDark)
                                : studio.getExpenseColor(isDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _AuroraFlowPill(
                          label: 'Thu vào',
                          valueWidget: _buildStatValue(
                            '+${Formatters.formatCurrency(income)}',
                            studio.getIncomeColor(isDark),
                          ),
                          icon: Icons.south_west_rounded,
                          tint: studio.getIncomeColor(isDark),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _AuroraFlowPill(
                          label: 'Chi ra',
                          valueWidget: _buildStatValue(
                            '-${Formatters.formatCurrency(expense)}',
                            studio.getExpenseColor(isDark),
                          ),
                          icon: Icons.north_east_rounded,
                          tint: studio.getExpenseColor(isDark),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _AuroraFlowPill(
                          label: 'Ròng',
                          valueWidget: _buildStatValue(
                            '${netFlow >= 0 ? '+' : ''}${Formatters.formatCurrency(netFlow)}',
                            netFlow >= 0
                                ? studio.getIncomeColor(isDark)
                                : studio.getExpenseColor(isDark),
                          ),
                          icon: Icons.stacked_line_chart_rounded,
                          tint: primary,
                          isDark: isDark,
                        ),
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

  /// Style 2: Obsidian Titanium — Dark brushed metal wealth card with EMV chip & NFC waves
  Widget _buildObsidianTitanium(BuildContext context) {
    final radius = studio.getCardRadius(studio.dashboardDensity);
    final pad = studio.getCardPadding(studio.dashboardDensity);
    final primary = studio.resolvedPrimary;
    final secondary = studio.resolvedSecondary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A0F1A),
            Color.alphaBlend(
                primary.withValues(alpha: 0.16), const Color(0xFF141C2B)),
            const Color(0xFF090D16),
          ],
        ),
        border: Border.all(
          color: primary.withValues(alpha: 0.42),
          width: 1.15,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: primary.withValues(alpha: 0.18),
            blurRadius: 28,
            spreadRadius: -4,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _TitaniumSheenPainter(
                    accent: primary,
                    secondary: secondary,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Brushed metallic EMV chip
                      Container(
                        width: 34,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFE2E8F0),
                              Color(0xFF94A3B8),
                              Color(0xFFCBD5E1),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.45),
                            width: 0.8,
                          ),
                        ),
                        child: Icon(
                          Icons.memory_rounded,
                          size: 15,
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.wifi_rounded,
                        size: 15,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'TITANIUM',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: filterActions,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TỔNG TÀI SẢN RÒNG',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: primary.withValues(alpha: 0.92),
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildBalanceValue(Colors.white),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildEyeButton(
                        bgColor: Colors.white.withValues(alpha: 0.12),
                        borderColor: Colors.white.withValues(alpha: 0.22),
                        iconColor: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _MinimalStatCell(
                            label: 'Thu vào',
                            valueWidget: _buildStatValue(
                              '+${Formatters.formatCurrency(income)}',
                              const Color(0xFF34D399),
                            ),
                            labelColor: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: _MinimalStatCell(
                              label: 'Chi ra',
                              valueWidget: _buildStatValue(
                                '-${Formatters.formatCurrency(expense)}',
                                const Color(0xFFFB7185),
                              ),
                              labelColor: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: _MinimalStatCell(
                              label: 'Dòng tiền',
                              valueWidget: _buildStatValue(
                                '${netFlow >= 0 ? '+' : ''}${Formatters.formatCurrency(netFlow)}',
                                netFlow >= 0
                                    ? const Color(0xFF38BDF8)
                                    : const Color(0xFFFB7185),
                              ),
                              labelColor: Colors.white.withValues(alpha: 0.65),
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
    );
  }

  /// Style 3: Porcelain Minimal — Private Banking refined high-clarity card
  Widget _buildPorcelainMinimal(BuildContext context) {
    final radius = studio.getCardRadius(studio.dashboardDensity);
    final pad = studio.getCardPadding(studio.dashboardDensity);
    final primary = studio.resolvedPrimary;
    final opacity = studio.glassOpacity.clamp(0.55, 1.0);
    final bgColor = (isDark ? const Color(0xFF131B2E) : Colors.white)
        .withValues(alpha: opacity);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final strokeColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: strokeColor, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'TÀI SẢN RÒNG',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: filterActions,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _buildBalanceValue(textPrimary)),
                const SizedBox(width: 10),
                _buildEyeButton(
                  bgColor: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFF1F5F9),
                  borderColor: strokeColor,
                  iconColor: textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (netFlow >= 0
                            ? studio.getIncomeColor(isDark)
                            : studio.getExpenseColor(isDark))
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        netFlow >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 13,
                        color: netFlow >= 0
                            ? studio.getIncomeColor(isDark)
                            : studio.getExpenseColor(isDark),
                      ),
                      const SizedBox(width: 4),
                      _buildStatValue(
                        '${netFlow >= 0 ? '+' : ''}${Formatters.formatCurrency(netFlow)}',
                        netFlow >= 0
                            ? studio.getIncomeColor(isDark)
                            : studio.getExpenseColor(isDark),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'PRIVATE LEDGER',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                    color: textSecondary.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: strokeColor),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: studio
                              .getIncomeColor(isDark)
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_downward_rounded,
                          size: 14,
                          color: studio.getIncomeColor(isDark),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MinimalStatCell(
                          label: 'Thu nhập',
                          valueWidget: _buildStatValue(
                            Formatters.formatCurrency(income),
                            textPrimary,
                          ),
                          labelColor: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: studio
                              .getExpenseColor(isDark)
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          size: 14,
                          color: studio.getExpenseColor(isDark),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MinimalStatCell(
                          label: 'Chi tiêu',
                          valueWidget: _buildStatValue(
                            Formatters.formatCurrency(expense),
                            textPrimary,
                          ),
                          labelColor: textSecondary,
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

  /// Style 4: Cyber Mesh Horizon — Multi-stop vibrant gradient with floating geometric arcs & 3 metric tiles
  Widget _buildCyberMeshHorizon(BuildContext context) {
    final radius = studio.getCardRadius(studio.dashboardDensity);
    final pad = studio.getCardPadding(studio.dashboardDensity);
    final primary = studio.resolvedPrimary;
    final secondary = studio.resolvedSecondary;
    final cMid = Color.lerp(primary, secondary, 0.52) ?? secondary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
                Colors.black.withValues(alpha: 0.14), primary),
            cMid,
            Color.alphaBlend(
                const Color(0xFF0F172A).withValues(alpha: 0.35), secondary),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.24),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.32),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _HorizonArcsPainter(),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.blur_on_rounded,
                                size: 13, color: Colors.white),
                            SizedBox(width: 5),
                            Text(
                              'MESH HORIZON',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.7,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: filterActions,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _buildBalanceValue(Colors.white)),
                      const SizedBox(width: 10),
                      _buildEyeButton(
                        bgColor: Colors.white.withValues(alpha: 0.18),
                        borderColor: Colors.white.withValues(alpha: 0.32),
                        iconColor: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _HorizonTile(
                          label: 'Thu vào',
                          valueWidget: _buildStatValue(
                            '+${Formatters.formatCurrency(income)}',
                            const Color(0xFFA7F3D0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _HorizonTile(
                          label: 'Chi ra',
                          valueWidget: _buildStatValue(
                            '-${Formatters.formatCurrency(expense)}',
                            const Color(0xFFFECDD3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _HorizonTile(
                          label: 'Ròng',
                          valueWidget: _buildStatValue(
                            '${netFlow >= 0 ? '+' : ''}${Formatters.formatCurrency(netFlow)}',
                            Colors.white,
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
      ),
    );
  }
}

class _AuroraFlowPill extends StatelessWidget {
  final String label;
  final Widget valueWidget;
  final IconData icon;
  final Color tint;
  final bool isDark;

  const _AuroraFlowPill({
    required this.label,
    required this.valueWidget,
    required this.icon,
    required this.tint,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: tint.withValues(alpha: isDark ? 0.25 : 0.22),
          width: 0.9,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: tint),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.70)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          valueWidget,
        ],
      ),
    );
  }
}

class _MinimalStatCell extends StatelessWidget {
  final String label;
  final Widget valueWidget;
  final Color labelColor;

  const _MinimalStatCell({
    required this.label,
    required this.valueWidget,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 2),
        valueWidget,
      ],
    );
  }
}

class _HorizonTile extends StatelessWidget {
  final String label;
  final Widget valueWidget;

  const _HorizonTile({
    required this.label,
    required this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 0.9,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.76),
            ),
          ),
          const SizedBox(height: 3),
          valueWidget,
        ],
      ),
    );
  }
}

class _TitaniumSheenPainter extends CustomPainter {
  final Color accent;
  final Color secondary;

  const _TitaniumSheenPainter({
    required this.accent,
    required this.secondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sheenPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.08),
          Colors.transparent,
          accent.withValues(alpha: 0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.72, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), sheenPaint);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.06);
    canvas.drawCircle(
      Offset(size.width * 0.92, size.height * 0.12),
      size.width * 0.36,
      arcPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.92, size.height * 0.12),
      size.width * 0.24,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TitaniumSheenPainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.secondary != secondary;
}

class _HorizonArcsPainter extends CustomPainter {
  const _HorizonArcsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.10);

    final center = Offset(size.width * 0.88, size.height * 0.15);
    for (final r in [46.0, 76.0, 108.0]) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        math.pi * 0.4,
        math.pi * 1.1,
        false,
        p1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HorizonArcsPainter oldDelegate) => false;
}
