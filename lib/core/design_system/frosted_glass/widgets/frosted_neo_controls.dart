import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../frosted_glass_tokens.dart';

/// Interactive Frosted Neo-Glass Button (Primary, Glass, Icon Circle)
class FrostedNeoButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isCircle;
  final double height;
  final double? width;
  final Color? color;
  final double borderRadius;

  const FrostedNeoButton({
    super.key,
    this.label,
    this.icon,
    this.onPressed,
    this.isPrimary = true,
    this.isCircle = false,
    this.height = 48.0,
    this.width,
    this.color,
    this.borderRadius = FrostedGlassTokens.radiusControl,
  }) : assert(label != null || icon != null);

  const FrostedNeoButton.primary({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.height = 48.0,
    this.width,
    this.color,
  })  : isPrimary = true,
        isCircle = false,
        borderRadius = FrostedGlassTokens.radiusControl;

  const FrostedNeoButton.glass({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.height = 48.0,
    this.width,
    this.color,
  })  : isPrimary = false,
        isCircle = false,
        borderRadius = FrostedGlassTokens.radiusControl;

  const FrostedNeoButton.circle({
    super.key,
    required this.icon,
    this.onPressed,
    double size = 44.0,
    this.isPrimary = true,
    this.color,
  })  : label = null,
        isCircle = true,
        height = size,
        width = size,
        borderRadius = FrostedGlassTokens.radiusPill;

  @override
  State<FrostedNeoButton> createState() => _FrostedNeoButtonState();
}

class _FrostedNeoButtonState extends State<FrostedNeoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBase = widget.color ?? FrostedGlassTokens.brandRoyalBlue;

    Color bg;
    Border? border;
    List<BoxShadow> shadows = [];
    Color contentColor;

    if (widget.isPrimary) {
      bg = _isPressed ? primaryBase.withValues(alpha: 0.85) : primaryBase;
      contentColor = Colors.white;
      shadows = [
        BoxShadow(
          color: primaryBase.withValues(alpha: 0.28),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
    } else {
      bg = _isPressed
          ? (isDark
              ? FrostedGlassTokens.darkGlassSurfacePressed
              : FrostedGlassTokens.lightGlassSurfacePressed)
          : (isDark
              ? FrostedGlassTokens.darkGlassSurface
              : FrostedGlassTokens.lightGlassSurface);
      contentColor = isDark
          ? FrostedGlassTokens.darkTextPrimary
          : FrostedGlassTokens.lightTextPrimary;
      border = Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.16)
            : const Color(0xFFCBD5E1).withValues(alpha: 0.60),
        width: 1.0,
      );
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];
    }

    final double effectiveRadius = widget.isCircle
        ? widget.height / 2
        : widget.borderRadius;

    Widget childWidget;
    if (widget.isCircle) {
      childWidget = Center(
        child: Icon(widget.icon, size: widget.height * 0.46, color: contentColor),
      );
    } else {
      childWidget = Row(
        mainAxisSize: widget.width != null ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 18, color: contentColor),
            const SizedBox(width: 8),
          ],
          if (widget.label != null)
            Text(
              widget.label!,
              style: TextStyle(
                color: contentColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
        ],
      );
    }

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          width: widget.width ?? (widget.isCircle ? widget.height : null),
          height: widget.height,
          padding: widget.isCircle
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(effectiveRadius),
            border: border,
            boxShadow: shadows,
          ),
          child: childWidget,
        ),
      ),
    );
  }
}

/// Frosted Neo-Glass Segmented Pill Tabs
class FrostedNeoTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double height;

  const FrostedNeoTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.height = 44.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0x66162032)
            : const Color(0x66E2E8F0),
        borderRadius: BorderRadius.circular(FrostedGlassTokens.radiusPill),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.70),
          width: 1,
        ),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(FrostedGlassTokens.radiusPill),
                  color: isSelected
                      ? (isDark
                          ? const Color(0xFF1E293B)
                          : Colors.white)
                      : Colors.transparent,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? (isDark ? Colors.white : FrostedGlassTokens.brandRoyalBlue)
                          : (isDark
                              ? FrostedGlassTokens.darkTextSecondary
                              : FrostedGlassTokens.lightTextSecondary),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Frosted Neo-Glass Semantic Badge (Income, Expense, Status)
class FrostedNeoBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color color;

  const FrostedNeoBadge({
    super.key,
    required this.text,
    this.icon,
    required this.color,
  });

  const FrostedNeoBadge.income({
    super.key,
    required this.text,
    this.icon = Icons.arrow_downward_rounded,
  }) : color = FrostedGlassTokens.incomeEmerald;

  const FrostedNeoBadge.expense({
    super.key,
    required this.text,
    this.icon = Icons.arrow_upward_rounded,
  }) : color = FrostedGlassTokens.expenseCoral;

  const FrostedNeoBadge.brand({
    super.key,
    required this.text,
    this.icon,
  }) : color = FrostedGlassTokens.brandRoyalBlue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(FrostedGlassTokens.radiusPill),
        border: Border.all(
          color: color.withValues(alpha: 0.28),
          width: 0.75,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
