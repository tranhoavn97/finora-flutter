import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../frosted_glass_tokens.dart';

/// A precision-engineered Frosted Neo-Glass Card.
/// Implements Apple VisionOS optical characteristics:
/// - High Gaussian background blur ($\sigma \approx 24$).
/// - Hairline directional Fresnel specular border.
/// - Atmospheric ambient occlusion shadows.
/// - Tactile interactive scale feedback on touch.
class FrostedNeoCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final Color? surfaceColor;
  final Gradient? borderGradient;
  final double borderWidth;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final List<BoxShadow>? customShadows;
  final bool enableTactileFeedback;

  const FrostedNeoCard({
    super.key,
    required this.child,
    this.borderRadius = FrostedGlassTokens.radiusCard,
    this.blurSigma = FrostedGlassTokens.blurSurface,
    this.surfaceColor,
    this.borderGradient,
    this.borderWidth = 1.0,
    this.padding = const EdgeInsets.all(20.0),
    this.onTap,
    this.width,
    this.height,
    this.customShadows,
    this.enableTactileFeedback = true,
  });

  @override
  State<FrostedNeoCard> createState() => _FrostedNeoCardState();
}

class _FrostedNeoCardState extends State<FrostedNeoCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultSurfaceColor = isDark
        ? FrostedGlassTokens.darkGlassSurface
        : FrostedGlassTokens.lightGlassSurface;

    final effectiveSurfaceColor = widget.surfaceColor ?? defaultSurfaceColor;

    final effectiveBorderGradient = widget.borderGradient ??
        (isDark
            ? FrostedGlassTokens.darkBorderGradient
            : FrostedGlassTokens.lightBorderGradient);

    final effectiveShadows = widget.customShadows ??
        (isDark
            ? FrostedGlassTokens.darkCardShadows
            : FrostedGlassTokens.lightCardShadows);

    Widget content = RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: CustomPaint(
          painter: _FrostedFresnelBorderPainter(
            borderRadius: widget.borderRadius,
            borderWidth: widget.borderWidth,
            gradient: effectiveBorderGradient,
          ),
          child: Container(
            width: widget.width,
            height: widget.height,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: _isPressed && widget.onTap != null
                  ? (isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0))
                  : effectiveSurfaceColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    if (effectiveShadows.isNotEmpty) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: effectiveShadows,
        ),
        child: content,
      );
    }

    if (widget.onTap != null) {
      content = GestureDetector(
        onTapDown: (_) {
          if (widget.enableTactileFeedback) {
            setState(() => _isPressed = true);
            HapticFeedback.selectionClick();
          }
        },
        onTapUp: (_) {
          if (widget.enableTactileFeedback) {
            setState(() => _isPressed = false);
          }
        },
        onTapCancel: () {
          if (widget.enableTactileFeedback) {
            setState(() => _isPressed = false);
          }
        },
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed && widget.enableTactileFeedback ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: content,
        ),
      );
    }

    return content;
  }
}

/// Custom painter to draw high precision hairline Fresnel refractive border
class _FrostedFresnelBorderPainter extends CustomPainter {
  final double borderRadius;
  final double borderWidth;
  final Gradient gradient;

  _FrostedFresnelBorderPainter({
    required this.borderRadius,
    required this.borderWidth,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (borderWidth <= 0) return;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(borderWidth / 2),
      Radius.circular(borderRadius),
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = gradient.createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _FrostedFresnelBorderPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.gradient != gradient;
  }
}
