import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/formatters.dart';
import '../../state/theme_studio_controller.dart';
import 'liquid_glass/liquid_glass_card.dart';

/// FINORA V8 Luxury Velvet Header Card with rich gradient styling (like Asset Screen).
/// Compact height, vivid depth, specular frosted borders and high-contrast typography.
class FinoraSummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int amount;
  final IconData icon;
  final Color accent;
  final List<(String, int)> metrics;
  final bool masked;
  final double? progress;
  final Widget? actions;
  final String? badgeText;
  final Color? badgeColor;
  final List<Color>? gradientColors;
  final List<Widget>? footerChips;
  final List<Color?>? metricColors;

  const FinoraSummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.accent,
    required this.metrics,
    this.subtitle = '',
    this.masked = false,
    this.progress,
    this.actions,
    this.badgeText,
    this.badgeColor,
    this.gradientColors,
    this.footerChips,
    this.metricColors,
  });

  List<Color> _buildDefaultGradient(Color acc, bool dark, bool isLiquid) {
    final hsl = HSLColor.fromColor(acc);
    final c1 =
        hsl.withLightness((hsl.lightness * 0.45).clamp(0.12, 0.35)).toColor();
    final c2 =
        hsl.withLightness((hsl.lightness * 0.82).clamp(0.28, 0.55)).toColor();
    final c3 =
        hsl.withLightness((hsl.lightness * 1.18).clamp(0.48, 0.75)).toColor();
    if (isLiquid) {
      if (dark) {
        return [
          c1.withValues(alpha: 0.35),
          c2.withValues(alpha: 0.45),
          c3.withValues(alpha: 0.55),
        ];
      }
      return [
        Colors.white.withValues(alpha: 0.58),
        c2.withValues(alpha: 0.20),
        const Color(0xFFE2F0FD).withValues(alpha: 0.42),
      ];
    }
    if (dark) {
      return [
        c1.withValues(alpha: 0.85),
        c2.withValues(alpha: 0.88),
        c3.withValues(alpha: 0.90),
      ];
    }
    return [c1, c2, c3];
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final studio = Provider.of<ThemeStudioController?>(context);
    final isLiquid = studio?.isSystemWideLiquidGlass ?? false;
    final enableSpecular = studio?.liquidGlassSpecularHighlight ?? false;
    final enableCaustics = studio?.liquidGlassCausticRefraction ?? false;

    String money(int value) => masked ? '•••••• ₫' : formatVND(value);

    final activeColors = gradientColors ?? _buildDefaultGradient(accent, dark, isLiquid);
    final glowColor = activeColors.length > 1 ? activeColors[1] : accent;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.26 : 0.05),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
          if (isLiquid)
            BoxShadow(
              color: glowColor.withValues(alpha: dark ? 0.08 : 0.03),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
              // Layer 1: Base Liquid Tint
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: activeColors,
                  ),
                  border: isLiquid ? null : Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 1.0,
                  ),
                ),
              ),

              // Layer 2: Caustic Refraction Lens
              if (isLiquid && enableCaustics)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: LiquidRefractionPainter(
                        borderRadius: 22,
                        tintColor: accent,
                        isDark: dark,
                      ),
                    ),
                  ),
                ),

              // Layer 3: Content Body
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Top Bar: Icon + Title + Actions / Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(icon, color: Colors.white, size: 15),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  if (badgeText != null && badgeText!.isNotEmpty) ...[
                    Flexible(
                        child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (badgeColor != null && badgeColor != accent)
                            ? badgeColor!.withValues(alpha: 0.28)
                            : Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: (badgeColor != null && badgeColor != accent)
                              ? badgeColor!.withValues(alpha: 0.45)
                              : Colors.white.withValues(alpha: 0.30),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        badgeText!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    )),
                    const SizedBox(width: 4),
                  ],
                  if (actions != null) actions!,
                ],
              ),
              const SizedBox(height: 7),

              // 2. Primary Number
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  money(amount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),

              // 3. Subtitle
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.76),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              // 4. Progress bar if applicable
              if (progress != null) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress!.clamp(0.0, 1.0),
                    minHeight: 4.5,
                    backgroundColor: Colors.white.withValues(alpha: 0.20),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],

              // 5. Split Metrics Section
              if (metrics.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < metrics.length; i++) ...[
                        if (i > 0)
                          Container(
                            width: 1,
                            height: 24,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 5.5,
                                    height: 5.5,
                                    decoration: BoxDecoration(
                                      color: _resolveDotColor(
                                        metrics[i].$1,
                                        i,
                                        metricColors,
                                        accent,
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _resolveDotColor(
                                            metrics[i].$1,
                                            i,
                                            metricColors,
                                            accent,
                                          ).withValues(alpha: 0.6),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      metrics[i].$1,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.78),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  money(metrics[i].$2),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    fontFeatures: [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // 6. Footer Chips if provided
              if (footerChips != null && footerChips!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: footerChips!,
                ),
              ],
            ],
          ),
        ),

        // Layer 4: Micro-Specular Rim & Crowning Fresnel Lip Highlight
        if (isLiquid && enableSpecular)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: LiquidSpecularBorderPainter(
                  borderRadius: 22,
                  borderWidth: 1.15,
                  borderGradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.22, 0.75, 1.0],
                    colors: dark
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

  Color _resolveDotColor(
    String label,
    int index,
    List<Color?>? explicitColors,
    Color fallback,
  ) {
    if (explicitColors != null &&
        index < explicitColors.length &&
        explicitColors[index] != null) {
      return explicitColors[index]!;
    }
    final lower = label.toLowerCase();
    if (lower.contains('thu') ||
        lower.contains('khả dụng') ||
        lower.contains('tích lũy')) {
      return const Color(0xFF34C759); // Apple Green
    }
    if (lower.contains('chi') ||
        lower.contains('nợ') ||
        lower.contains('trả')) {
      return const Color(0xFFFF453A); // Apple Red
    }
    if (lower.contains('còn lại') || lower.contains('chờ')) {
      return const Color(0xFFFF9F0A); // Apple Orange
    }
    return fallback;
  }
}
