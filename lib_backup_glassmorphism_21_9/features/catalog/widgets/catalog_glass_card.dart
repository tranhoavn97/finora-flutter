import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/design_system/glassmorphism_tokens.dart';

/// Reusable authentic Glassmorphism 2.0 card with multi-layer BackdropFilter blur,
/// directional specular hairline border, chromatic depth shadow, and tactile touch feedback.
class CatalogGlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color? glowColor;
  final double blurSigma;
  final double borderWidth;
  final Color? customFill;

  const CatalogGlassCard({
    super.key,
    required this.child,
    this.radius = 20.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.glowColor,
    this.blurSigma = GlassmorphismTokens.surfaceBlurMedium,
    this.borderWidth = GlassmorphismTokens.hairlineBorderWidth,
    this.customFill,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(radius);

    final cardContent = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: GlassmorphismTokens.cardShadow(isDark, glowColor: glowColor),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: CustomPaint(
            foregroundPainter: _SpecularBorderPainter(
              borderRadius: radius,
              borderWidth: borderWidth,
              gradient: GlassmorphismTokens.cardBorderGradient(isDark),
            ),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                color: customFill ??
                    (isDark
                        ? GlassmorphismTokens.surfaceBaseDark.withValues(alpha: GlassmorphismTokens.surfaceDarkAlpha)
                        : GlassmorphismTokens.surfaceBaseLight.withValues(alpha: GlassmorphismTokens.surfaceLightAlpha)),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: () {
            HapticFeedback.lightImpact();
            onTap!();
          },
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

/// Custom painter for directional specular hairline highlight
class _SpecularBorderPainter extends CustomPainter {
  final double borderRadius;
  final double borderWidth;
  final Gradient gradient;

  _SpecularBorderPainter({
    required this.borderRadius,
    required this.borderWidth,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset.zero & size;
    final half = borderWidth / 2;
    final adjustedRect = Rect.fromLTWH(
      half,
      half,
      size.width - borderWidth,
      size.height - borderWidth,
    );

    final effectiveRadius = (borderRadius - half).clamp(0.0, 100.0);
    final rrect = RRect.fromRectAndRadius(
      adjustedRect,
      Radius.circular(effectiveRadius),
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = gradient.createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _SpecularBorderPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.gradient != gradient;
  }
}
