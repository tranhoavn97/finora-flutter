import 'dart:ui' as ui;
import 'package:flutter/material.dart';

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
    final cardBody = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          // Soft ambient floor shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 36,
            spreadRadius: -4,
            offset: const Offset(0, 18),
          ),
          // Chromatic diffused refraction glow
          if (glowColor != null)
            BoxShadow(
              color: glowColor!,
              blurRadius: glowRadius,
              spreadRadius: 2,
              offset: glowOffset,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: blurSigma,
            sigmaY: blurSigma,
            tileMode: TileMode.clamp,
          ),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              // Layer 1: Viscous liquid tint & optical depth
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0.0, 0.45, 1.0],
                    colors: [
                      tintColor.withValues(alpha: (tintOpacity * 1.8).clamp(0.0, 1.0)),
                      tintColor.withValues(alpha: (tintOpacity * 0.9).clamp(0.0, 1.0)),
                      tintColor.withValues(alpha: (tintOpacity * 0.4).clamp(0.0, 1.0)),
                    ],
                  ),
                ),
              ),

              // Layer 2: Simulated Caustic & Inner Refractive Sheen
              if (enableInnerRefraction)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _LiquidRefractionPainter(
                        borderRadius: borderRadius,
                        tintColor: tintColor,
                      ),
                    ),
                  ),
                ),

              // Layer 3: Content Body
              Padding(
                padding: padding,
                child: child,
              ),

              // Layer 4: Micro-Specular Rim & Directional Gradient Border
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _LiquidSpecularBorderPainter(
                      borderRadius: borderRadius,
                      borderWidth: borderWidth,
                      borderGradient: borderGradient ??
                          const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: [0.0, 0.28, 0.65, 1.0],
                            colors: [
                              Color(0x66FFFFFF), // Top-left crisp refraction
                              Color(0x28FFFFFF), // Soft lateral dissipation
                              Color(0x0EFFFFFF), // Low opacity body
                              Color(0x20FFFFFF), // Bottom-right ambient bounce
                            ],
                          ),
                      enableSpecularHighlight: enableSpecularHighlight,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: Colors.white.withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.04),
          child: cardBody,
        ),
      );
    }

    return cardBody;
  }
}

/// Custom painter for physical caustic curvature and viscous inner sheen.
class _LiquidRefractionPainter extends CustomPainter {
  final double borderRadius;
  final Color tintColor;

  _LiquidRefractionPainter({
    required this.borderRadius,
    required this.tintColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    canvas.save();
    canvas.clipRRect(rrect);

    // Caustic crest: subtle angled parabolic wash across the top-left quadrant
    final causticPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.85, 0)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.55,
        0,
        size.height * 0.75,
      )
      ..close();

    final causticPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width * 0.6, size.height * 0.6),
        [
          tintColor.withValues(alpha: 0.12),
          tintColor.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        [0.0, 0.4, 1.0],
      );

    canvas.drawPath(causticPath, causticPaint);

    // Inner bottom bounce rim
    final bouncePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.height * 0.8),
        Offset(0, size.height),
        [
          Colors.transparent,
          tintColor.withValues(alpha: 0.06),
        ],
      );

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.8, size.width, size.height * 0.2),
      bouncePaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LiquidRefractionPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius || oldDelegate.tintColor != tintColor;
}

/// Custom painter for directional Fresnel refraction borders and micro-specular highlights.
class _LiquidSpecularBorderPainter extends CustomPainter {
  final double borderRadius;
  final double borderWidth;
  final Gradient borderGradient;
  final bool enableSpecularHighlight;

  _LiquidSpecularBorderPainter({
    required this.borderRadius,
    required this.borderWidth,
    required this.borderGradient,
    required this.enableSpecularHighlight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final halfBorder = borderWidth / 2.0;
    final rect = Rect.fromLTWH(
      halfBorder,
      halfBorder,
      size.width - borderWidth,
      size.height - borderWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius - halfBorder));

    // Draw main directional refraction border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = borderGradient.createShader(rect);

    canvas.drawRRect(rrect, borderPaint);

    // Draw micro-specular highlight pin-stripe on top-left edge
    if (enableSpecularHighlight && size.width > 40 && size.height > 40) {
      final specularPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = borderWidth * 1.3
        ..shader = ui.Gradient.linear(
          Offset(halfBorder, halfBorder),
          Offset(size.width * 0.45, halfBorder + 8),
          const [
            Color(0xAAFFFFFF), // Intense micro-specular core
            Color(0x40FFFFFF), // Mid-falloff
            Color(0x00FFFFFF), // Dissolve
          ],
          [0.0, 0.5, 1.0],
        );

      final highlightPath = Path()
        ..moveTo(halfBorder + borderRadius * 0.35, halfBorder)
        ..lineTo(size.width * 0.4, halfBorder);

      canvas.drawPath(highlightPath, specularPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidSpecularBorderPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.enableSpecularHighlight != enableSpecularHighlight;
}
