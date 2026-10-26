import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'liquid_tokens.dart';

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
    this.primaryColor = LiquidColors.cobaltElectric,
    this.isPrimary = true,
    this.height = LiquidButtonSizes.primaryHeight,
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
            borderRadius: BorderRadius.circular(LiquidButtonSizes.radiusPill),
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
                style: LiquidTypography.buttonPrimary.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A normalized 40px height secondary / glass button.
class LiquidSecondaryButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color textColor;
  final double height;
  final EdgeInsetsGeometry padding;

  const LiquidSecondaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.textColor = Colors.white,
    this.height = LiquidButtonSizes.secondaryHeight,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
  });

  @override
  State<LiquidSecondaryButton> createState() => _LiquidSecondaryButtonState();
}

class _LiquidSecondaryButtonState extends State<LiquidSecondaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
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
            borderRadius: BorderRadius.circular(LiquidButtonSizes.radiusPill),
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 16, color: widget.textColor),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A strictly normalized 36px height segmented filter pill container.
class LiquidSegmentedTabs extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const LiquidSegmentedTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: LiquidButtonSizes.filterPillHeight,
      padding: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LiquidButtonSizes.radiusPill),
        color: Colors.white.withValues(alpha: 0.07),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(tabs.length, (index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onTabSelected(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(LiquidButtonSizes.radiusPill),
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.transparent,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                tabs[index],
                style: LiquidTypography.filterPill.copyWith(
                  color: isSelected
                      ? const Color(0xFF0F172A)
                      : Colors.white.withValues(alpha: 0.75),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// A normalized 50x50px quick action vessel tile with label underneath.
class LiquidQuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color baseColor;

  const LiquidQuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.baseColor = LiquidColors.cobaltElectric,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: LiquidButtonSizes.quickActionVesselSize,
            height: LiquidButtonSizes.quickActionVesselSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.35, -0.35),
                radius: 1.1,
                colors: [
                  baseColor.withValues(alpha: 0.55),
                  baseColor,
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.45),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: baseColor.withValues(alpha: 0.40),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, size: 20, color: Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
    this.size = LiquidButtonSizes.quickActionVesselSize,
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
        shape: BoxShape.circle,
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

/// A chromatic pill badge indicating dynamic growth or state (normalized 26px height).
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
    final accentColor = isPositive ? LiquidColors.emeraldMint : LiquidColors.coralRose;

    return Container(
      height: LiquidButtonSizes.badgeHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LiquidButtonSizes.radiusPill),
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
              fontSize: 11.0,
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
    this.activeGlowColor = LiquidColors.cobaltElectric,
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
                    borderRadius: BorderRadius.circular(LiquidButtonSizes.radiusPill),
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
                    borderRadius: BorderRadius.circular(LiquidButtonSizes.radiusPill),
                    gradient: LinearGradient(
                      colors: [
                        activeGlowColor.withValues(alpha: 0.85),
                        LiquidColors.cyberCyan,
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
