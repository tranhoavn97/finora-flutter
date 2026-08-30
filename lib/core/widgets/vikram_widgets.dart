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
          bottom: -7,
          child: CustomPaint(
            size: const Size(18, 9),
            painter: _NotchTrianglePainter(
              color: isDark ? const Color(0xFF223157) : const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotchTrianglePainter extends CustomPainter {
  final Color color;
  _NotchTrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
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
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
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
