import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// An organic, pill-shaped fluid action button with directional light refraction.
class LiquidPillButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color primaryColor;
  final bool isPrimary;
  final double height;
  final EdgeInsetsGeometry padding;

  const LiquidPillButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.primaryColor = const Color(0xFF005FEA),
    this.isPrimary = true,
    this.height = 48.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20.0),
  });

  @override
  State<LiquidPillButton> createState() => _LiquidPillButtonState();
}

class _LiquidPillButtonState extends State<LiquidPillButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.primaryColor;

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
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Container(
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9999),
            gradient: widget.isPrimary
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0.0, 0.45, 1.0],
                    colors: [
                      effectiveColor,
                      effectiveColor.withValues(alpha: 0.85),
                      const Color(0xFF2563EB),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.white.withValues(alpha: 0.04),
                    ],
                  ),
            boxShadow: [
              if (widget.isPrimary)
                BoxShadow(
                  color: effectiveColor.withValues(alpha: 0.40),
                  blurRadius: 18,
                  spreadRadius: -2,
                  offset: const Offset(0, 6),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
            border: Border.all(
              color: widget.isPrimary
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.20),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 17,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An embossed icon container mimicking refractive dual-light curvature.
class LiquidEmbossedIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final Color iconColor;
  final Color baseColor;

  const LiquidEmbossedIcon({
    super.key,
    required this.icon,
    this.size = 46.0,
    this.iconSize = 20.0,
    this.iconColor = Colors.white,
    this.baseColor = const Color(0xFFFFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.38),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor.withValues(alpha: 0.18),
            baseColor.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: baseColor.withValues(alpha: 0.12),
            blurRadius: 12,
            spreadRadius: -1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          size: iconSize,
          color: iconColor,
        ),
      ),
    );
  }
}

/// A chromatic pill badge indicating dynamic growth or state.
class LiquidMetricBadge extends StatelessWidget {
  final String text;
  final bool isPositive;
  final IconData? icon;

  const LiquidMetricBadge({
    super.key,
    required this.text,
    this.isPositive = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9999),
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.22),
            accentColor.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.45),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.18),
            blurRadius: 10,
            spreadRadius: -1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: accentColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: accentColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// A viscous, tactile liquid slider with glowing thumb and refractive track.
class LiquidFluidSlider extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final ValueChanged<double> onChanged;
  final Color activeGlowColor;

  const LiquidFluidSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeGlowColor = const Color(0xFF005FEA),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final thumbX = (totalWidth - 32) * value.clamp(0.0, 1.0);

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            final delta = details.localPosition.dx / totalWidth;
            onChanged(delta.clamp(0.0, 1.0));
          },
          onTapDown: (details) {
            final tapPercent = (details.localPosition.dx / totalWidth).clamp(0.0, 1.0);
            onChanged(tapPercent);
            HapticFeedback.selectionClick();
          },
          child: Container(
            height: 44,
            alignment: Alignment.centerLeft,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Track Container
                Container(
                  height: 12,
                  width: totalWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9999),
                    color: Colors.white.withValues(alpha: 0.06),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1.0,
                    ),
                  ),
                ),

                // Active Gradient Fill
                Container(
                  height: 12,
                  width: thumbX + 16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9999),
                    gradient: LinearGradient(
                      colors: [
                        activeGlowColor.withValues(alpha: 0.85),
                        const Color(0xFF06B6D4),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: activeGlowColor.withValues(alpha: 0.5),
                        blurRadius: 12,
                        spreadRadius: -1,
                      ),
                    ],
                  ),
                ),

                // Fluid Viscous Thumb
                Positioned(
                  left: thumbX,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Colors.white,
                          Color(0xFFE2E8F0),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                        BoxShadow(
                          color: activeGlowColor.withValues(alpha: 0.65),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white,
                        width: 2.0,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: activeGlowColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
