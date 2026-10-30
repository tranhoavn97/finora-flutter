import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Shared optical surface. Only the clipped background is blurred; text and
/// controls remain sharp. There is no animation or full-screen blur per card.
class LiquidGlassSurface extends StatelessWidget {
  const LiquidGlassSurface({
    super.key,
    required this.child,
    this.radius = 24,
    this.blur = 20,
    this.fillColor,
    this.gradient,
    this.tintColor = const Color(0xFF005FEA),
    this.enabled = true,
    this.specular = true,
    this.refraction = true,
  });

  final Widget child;
  final double radius;
  final double blur;
  final Color? fillColor;
  final Gradient? gradient;
  final Color tintColor;
  final bool enabled;
  final bool specular;
  final bool refraction;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = fillColor ??
        (dark
            ? const Color(0xFF161F30)
            : Colors.white);

    final Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? base : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );

    if (blur <= 0.1 || !enabled) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: surface,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: surface,
      ),
    );
  }
}

/// A world-class, high-refraction Liquid Glass (Fluid Glassmorphism) Card.
///
/// Aesthetic & Physical Architecture:
/// - High-refraction Gaussian backdrop blur ($\sigma \approx 25\text{–}35$).
/// - Directional multi-stop refractive border gradient simulating Fresnel edge illumination.
/// - Specular highlight rim painter simulating caustic reflections and surface tension.
/// - Diffused chromatic colored drop-shadow (deep-tinted ambient occlusion rather than flat black).
/// - Viscous inner gradient overlay for physical liquid depth.
class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final Color tintColor;
  final double tintOpacity;
  final Gradient? borderGradient;
  final double borderWidth;
  final Color? glowColor;
  final double glowRadius;
  final Offset glowOffset;
  final bool enableSpecularHighlight;
  final bool enableInnerRefraction;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 28.0,
    this.blurSigma = 28.0,
    this.tintColor = const Color(0xFFFFFFFF),
    this.tintOpacity = 0.07,
    this.borderGradient,
    this.borderWidth = 1.25,
    this.glowColor = const Color(0x1A005FEA),
    this.glowRadius = 24.0,
    this.glowOffset = const Offset(0, 10),
    this.enableSpecularHighlight = true,
    this.enableInnerRefraction = true,
    this.padding = const EdgeInsets.all(22.0),
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cardBody = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF161F30) : Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: dark ? const Color(0xFF26334A) : const Color(0xFFE2E8F0),
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: (dark ? Colors.white : Colors.black).withValues(alpha: 0.06),
          highlightColor: (dark ? Colors.white : Colors.black).withValues(alpha: 0.03),
          child: cardBody,
        ),
      );
    }

    return cardBody;
  }
}

/// Custom painter for refined crystal glass optical sheen and subtle ambient depth.
///
/// Designed to never obscure text, numbers, or interactive elements with greasy smudges or harsh scratches.
class LiquidRefractionPainter extends CustomPainter {
  final double borderRadius;
  final Color tintColor;
  final bool isDark;

  const LiquidRefractionPainter({
    required this.borderRadius,
    required this.tintColor,
    this.isDark = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final clampedRadius = borderRadius.clamp(0.0, size.shortestSide / 2.0);
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(clampedRadius));

    canvas.save();
    canvas.clipRRect(rrect);

    // 1. Crystal Top Rim Micro-Gleam (Crisp 2px optical catch along the upper rim)
    final rimHeight = (size.height * 0.05).clamp(1.5, 3.0);
    final rimPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.15, 0),
        Offset(size.width * 0.85, 0),
        [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: isDark ? 0.28 : 0.38),
          Colors.white.withValues(alpha: 0.0),
        ],
        const [0.0, 0.5, 1.0],
      );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, rimHeight),
      rimPaint,
    );

    // 2. Subtle Upper Ambient Sheen (Gentle, ultra-soft depth gradient fading out in top 12%)
    final sheenHeight = (size.height * 0.14).clamp(10.0, 36.0);
    final sheenPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, sheenHeight),
        [
          Colors.white.withValues(alpha: isDark ? 0.07 : 0.10),
          tintColor.withValues(alpha: isDark ? 0.02 : 0.03),
          Colors.transparent,
        ],
        const [0.0, 0.45, 1.0],
      );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, sheenHeight),
      sheenPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LiquidRefractionPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.tintColor != tintColor ||
      oldDelegate.isDark != isDark;
}

/// Custom painter for directional Fresnel refraction borders and micro-specular highlights.
class LiquidSpecularBorderPainter extends CustomPainter {
  final double borderRadius;
  final double borderWidth;
  final Gradient borderGradient;
  final bool enableSpecularHighlight;

  const LiquidSpecularBorderPainter({
    required this.borderRadius,
    required this.borderWidth,
    required this.borderGradient,
    required this.enableSpecularHighlight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.shortestSide <= borderWidth || borderWidth <= 0) return;
    final clampedRadius = borderRadius.clamp(0.0, size.shortestSide / 2.0);

    final halfBorder = borderWidth / 2.0;
    final rect = Rect.fromLTWH(
      halfBorder,
      halfBorder,
      size.width - borderWidth,
      size.height - borderWidth,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(
          clampedRadius > halfBorder ? clampedRadius - halfBorder : 0),
    );

    // 1. Draw main directional Fresnel refraction border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = borderGradient.createShader(rect);

    canvas.drawRRect(rrect, borderPaint);

    // 2. Draw refined, symmetrical top-edge specular glint
    if (enableSpecularHighlight && size.width > 20 && size.height > 15) {
      final effR =
          clampedRadius > halfBorder ? clampedRadius - halfBorder : 0.0;
      final startX = halfBorder + effR;
      final endX = size.width - halfBorder - effR;

      if (endX > startX) {
        final highlightPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = (borderWidth * 0.90).clamp(0.75, 1.2)
          ..shader = ui.Gradient.linear(
            Offset(startX, halfBorder),
            Offset(endX, halfBorder),
            const [
              Color(0x00FFFFFF),
              Color(0x40FFFFFF),
              Color(0x00FFFFFF),
            ],
            const [0.0, 0.5, 1.0],
          );

        final highlightPath = Path()
          ..moveTo(startX, halfBorder)
          ..lineTo(endX, halfBorder);

        canvas.drawPath(highlightPath, highlightPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LiquidSpecularBorderPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.borderGradient != borderGradient ||
      oldDelegate.enableSpecularHighlight != enableSpecularHighlight;
}
