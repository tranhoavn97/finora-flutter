import 'dart:ui';
import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_radius.dart';
import '../utils/formatters.dart';
import 'premium_widgets.dart';

/// Quiet edge-to-edge background. Decorative light is deliberately subtle so
/// financial content, not chrome, owns the visual hierarchy.
class PearlMeshBackground extends StatelessWidget {
  final Widget child;
  const PearlMeshBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.darkBg : AppColors.lightBg,
      child: Stack(
        children: [
          // Background Glow Blobs
          IgnorePointer(
            child: Stack(
              children: [
                // Top-Left Lavender / Indigo Blob
                Positioned(
                  top: -80,
                  left: -60,
                  child: _buildBlob(
                    size: 340,
                    color: isDark
                        ? AppColors.primary.withOpacity(0.08)
                        : AppColors.primaryLight.withOpacity(0.10),
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }

  Widget _buildBlob({required double size, required Color color}) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 110, sigmaY: 110),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

/// Default content surface. Glass is kept for navigation and transient
/// controls, not repeated through the content layer.
class FrostedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final bool hasNotch;
  final Color? customBgColor;

  const FrostedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28.0,
    this.onTap,
    this.hasNotch = false,
    this.customBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(radius);

    final cardBg = customBgColor ??
        (isDark ? AppColors.darkSurface : AppColors.lightSurface);

    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    Widget content = Padding(
      padding: padding,
      child: child,
    );

    Widget cardWidget = Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.035),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: borderRadius, child: content),
    );

    if (onTap != null) {
      cardWidget = Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: cardWidget,
        ),
      );
    }

    if (!hasNotch) return cardWidget;

    // Stack with Downward Triangle Notch
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        cardWidget,
        Positioned(
          bottom: -6,
          child: CustomPaint(
            size: const Size(18, 8),
            painter: _NotchTrianglePainter(
              fillColor: cardBg,
              borderColor: borderColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _NotchTrianglePainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  _NotchTrianglePainter({required this.fillColor, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. CapsuleBadge: High-contrast status pill chip (e.g. TODAY, 2 DAYS, +12%).
class CapsuleBadge extends StatelessWidget {
  final String text;
  final Color bgColor;
  final Color textColor;
  final IconData? icon;
  final VoidCallback? onTap;

  const CapsuleBadge({
    super.key,
    required this.text,
    required this.bgColor,
    required this.textColor,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: badge,
      );
    }
    return badge;
  }
}

/// 4. SquircleActionTile: 4 Rounded Squircle Buttons with soft pastel icons.
class SquircleActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const SquircleActionTile({
    super.key,
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF16213D) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? const Color(0xFF223157) : Colors.white,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.25)
                        : const Color(0xFF4F46E5).withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: primaryTextColor,
          ),
        ),
      ],
    );
  }
}

/// 5. LiquidListCard: Squircle logo + Title + Status capsule pill + Price.
class LiquidListCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final String amount;
  final bool isExpense;
  final String? badgeText;
  final Color? badgeBgColor;
  final Color? badgeTextColor;
  final VoidCallback? onTap;

  const LiquidListCard({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.isExpense = true,
    this.badgeText,
    this.badgeBgColor,
    this.badgeTextColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return FrostedCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: onTap,
      child: Row(
        children: [
          // Squircle Leading Logo Container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2644) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: leading,
          ),
          const SizedBox(width: 12),
          // Title & Subtitle + Optional Badge
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
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: primaryTextColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (badgeText != null) ...[
                      const SizedBox(width: 8),
                      CapsuleBadge(
                        text: badgeText!,
                        bgColor: badgeBgColor ?? const Color(0xFFFEF3C7),
                        textColor: badgeTextColor ?? const Color(0xFFD97706),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isExpense
                      ? (isDark
                          ? const Color(0xFFF87171)
                          : const Color(0xFFDC2626))
                      : (isDark
                          ? const Color(0xFF34D399)
                          : const Color(0xFF059669)),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isExpense ? 'đã chi' : 'thu nhập',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: secondaryTextColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 6. OverlapAvatarStack: Overlapping avatars for family members or active services.
class OverlapAvatarStack extends StatelessWidget {
  final List<Widget> avatars;
  final String label;

  const OverlapAvatarStack({
    super.key,
    required this.avatars,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24.0 + (avatars.length - 1) * 16.0,
          height: 28,
          child: Stack(
            children: List.generate(avatars.length, (index) {
              return Positioned(
                left: index * 16.0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF131C35) : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(child: avatars[index]),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}

/// 7. GlowPillButton: Vibrant gradient pill button with soft colored glow (Indigo, Coral, Amber).
enum GlowButtonStyle { indigo, coral, amber, outline }

class GlowPillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final GlowButtonStyle style;
  final double height;
  final double? width;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  const GlowPillButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.style = GlowButtonStyle.indigo,
    this.height = 44.0,
    this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    this.fontSize = 13.5,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    List<Color> gradientColors;
    List<BoxShadow> shadows;
    Color textColor = Colors.white;

    switch (style) {
      case GlowButtonStyle.indigo:
        gradientColors = [const Color(0xFF6366F1), const Color(0xFF4338CA)];
        shadows = [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.40),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ];
        break;
      case GlowButtonStyle.coral:
        gradientColors = [const Color(0xFFEF4444), const Color(0xFFDC2626)];
        shadows = [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.40),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ];
        break;
      case GlowButtonStyle.amber:
        gradientColors = [const Color(0xFFF97316), const Color(0xFFEA580C)];
        shadows = [
          BoxShadow(
            color: const Color(0xFFF97316).withValues(alpha: 0.40),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ];
        break;
      case GlowButtonStyle.outline:
        gradientColors = [Colors.transparent, Colors.transparent];
        shadows = [];
        textColor = isDark ? Colors.white : AppColors.sirenDarkNavy;
        break;
    }

    final shape = BorderRadius.circular(999);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: shape,
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: shape,
            gradient: style == GlowButtonStyle.outline
                ? null
                : LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            border: style == GlowButtonStyle.outline
                ? Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                    width: 1.2,
                  )
                : null,
            boxShadow: shadows,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 6),
                Icon(icon, color: textColor, size: fontSize + 2),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 8. VikramPillDropdown: Capsule Month/Filter pill (e.g. May, 2026 ˇ) with royal indigo background.
class VikramPillDropdown extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const VikramPillDropdown({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF4338CA),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4338CA).withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

/// 9. VikramToggleRow: Frosted card row with custom purple switch.
class VikramToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const VikramToggleRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return FrostedCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
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
                    fontWeight: FontWeight.w800,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF4338CA),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor:
                isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
        ],
      ),
    );
  }
}

/// 10. VikramTimelineNode: Timeline item connected with vertical line & colored ring node.
class VikramTimelineNode extends StatelessWidget {
  final Widget child;
  final Color nodeColor;
  final bool isFirst;
  final bool isLast;

  const VikramTimelineNode({
    super.key,
    required this.child,
    required this.nodeColor,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator column
          SizedBox(
            width: 24,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Top line
                if (!isFirst)
                  Positioned(
                    top: 0,
                    bottom: 12,
                    child: Container(
                      width: 2,
                      color: lineColor,
                    ),
                  ),
                // Bottom line
                if (!isLast)
                  Positioned(
                    top: 12,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: lineColor,
                    ),
                  ),
                // Center ring node
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: nodeColor,
                      width: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// 11. VikramInfoTile: Detail stat tile (e.g. Next Payment, Billing Cycle, Total Spent, Category).
class VikramInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String primaryValue;
  final String secondaryValue;

  const VikramInfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.primaryValue,
    required this.secondaryValue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return FrostedCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: secondaryTextColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            primaryValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: primaryTextColor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            secondaryValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
