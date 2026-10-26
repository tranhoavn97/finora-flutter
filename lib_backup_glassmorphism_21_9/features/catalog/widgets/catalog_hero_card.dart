import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/glassmorphism_tokens.dart';

/// Hero Glass card with glowing gradient backdrops, balance visibility toggle,
/// and high-contrast fintech metrics.
class CatalogHeroCard extends StatefulWidget {
  final String title;
  final int amount;
  final String? subtitle;
  final List<Color> gradientColors;
  final List<HeroMetricItem> metrics;
  final Widget? trailing;
  final VoidCallback? onTap;

  const CatalogHeroCard({
    super.key,
    required this.title,
    required this.amount,
    this.subtitle,
    this.gradientColors = const [
      Color(0xFF0F172A),
      Color(0xFF1E293B),
    ],
    this.metrics = const [],
    this.trailing,
    this.onTap,
  });

  @override
  State<CatalogHeroCard> createState() => _CatalogHeroCardState();
}

class _CatalogHeroCardState extends State<CatalogHeroCard> {
  bool _obscure = false;
  static final NumberFormat _formatter = NumberFormat('#,##0', 'vi_VN');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(24);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.gradientColors.first.withValues(alpha: isDark ? 0.40 : 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassmorphismTokens.surfaceBlurHigh,
            sigmaY: GlassmorphismTokens.surfaceBlurHigh,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.35),
                width: GlassmorphismTokens.borderThin,
              ),
              color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Title + Eye toggle + Trailing
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.title.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _obscure = !_obscure);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                            child: Icon(
                              _obscure ? LucideIcons.eye_off : LucideIcons.eye,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.trailing != null) widget.trailing!,
                  ],
                ),
                const SizedBox(height: 12),

                // Main Amount
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _obscure ? '••••••••••••' : '${_formatter.format(widget.amount)} ₫',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),

                if (widget.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                // Metric ribbon if present
                if (widget.metrics.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: widget.metrics.map((metric) {
                        return Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                metric.label,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.70),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _obscure ? '••••' : metric.value,
                                  style: TextStyle(
                                    color: metric.color ?? Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HeroMetricItem {
  final String label;
  final String value;
  final Color? color;

  const HeroMetricItem({
    required this.label,
    required this.value,
    this.color,
  });
}
