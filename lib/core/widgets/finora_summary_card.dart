import 'package:flutter/material.dart';
import '../utils/formatters.dart';

/// FINORA V8 Luxury Velvet Header Card for all main overview pages.
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

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : const Color(0xFF0F172A);
    final muted = dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    String money(int value) => masked ? '•••••• ₫' : formatVND(value);

    final bgGradient = gradientColors != null
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors!,
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? [
                    const Color(0xFF1E293B),
                    Color.alphaBlend(
                      accent.withValues(alpha: 0.12),
                      const Color(0xFF0F172A),
                    ),
                  ]
                : [
                    Color.alphaBlend(
                      accent.withValues(alpha: 0.08),
                      Colors.white,
                    ),
                    Colors.white,
                  ],
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: bgGradient,
        border: Border.all(
          color: accent.withValues(alpha: dark ? 0.26 : 0.16),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black.withValues(alpha: 0.28)
                : accent.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Top Bar: Icon + Title + Actions / Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: dark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accent.withValues(alpha: dark ? 0.35 : 0.20),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (badgeText != null && badgeText!.isNotEmpty) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? accent).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: (badgeColor ?? accent).withValues(alpha: 0.35),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    badgeText!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeColor ?? accent,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (actions != null) actions!,
            ],
          ),
          const SizedBox(height: 14),

          // 2. Primary Number
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              money(amount),
              style: TextStyle(
                color: ink,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),

          // 3. Subtitle
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          // 4. Progress bar if applicable
          if (progress != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: dark
                    ? Colors.white.withValues(alpha: 0.08)
                    : accent.withValues(alpha: 0.12),
                color: progress! >= 1.0
                    ? const Color(0xFFFF3B30)
                    : (progress! >= 0.85 ? const Color(0xFFFF9500) : accent),
              ),
            ),
          ],

          // 5. Split Metrics Section
          if (metrics.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF1F5F9).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E8F0),
                  width: 0.9,
                ),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < metrics.length; i++) ...[
                    if (i > 0)
                      Container(
                        width: 1,
                        height: 28,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        color: dark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 3,
                                backgroundColor: _resolveDotColor(
                                  metrics[i].$1,
                                  i,
                                  metricColors,
                                  accent,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  metrics[i].$1,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              money(metrics[i].$2),
                              style: TextStyle(
                                color: ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                fontFeatures: const [
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
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: footerChips!,
            ),
          ],
        ],
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
    if (lower.contains('chi') || lower.contains('nợ') || lower.contains('trả')) {
      return const Color(0xFFFF3B30); // Apple Red
    }
    if (lower.contains('còn lại') || lower.contains('chờ')) {
      return const Color(0xFFFF9500); // Apple Orange
    }
    return fallback;
  }
}
