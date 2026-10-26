import 'dart:math' as math;
import 'package:flutter/material.dart';

/// An organic, animated chromatic fluid mesh background.
///
/// Features:
/// - Multi-orb chromatic mesh (Cobalt Sapphire, Ultraviolet, Solar Amber, Cyber Cyan).
/// - Non-linear Lissajous harmonic orbits simulating viscous buoyancy.
/// - Dynamic radial dissipation gradients for high-refraction glassmorphism cards.
class FluidMeshBackground extends StatefulWidget {
  final Widget child;
  final bool animate;
  final double speedMultiplier;
  final Color baseColor;

  const FluidMeshBackground({
    super.key,
    required this.child,
    this.animate = true,
    this.speedMultiplier = 1.0,
    this.baseColor = const Color(0xFF040714), // Deep interstellar obsidian
  });

  @override
  State<FluidMeshBackground> createState() => _FluidMeshBackgroundState();
}

class _FluidMeshBackgroundState extends State<FluidMeshBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant FluidMeshBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.baseColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Animated Fluid Chromatic Mesh Orbs
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value * 2 * math.pi * widget.speedMultiplier;
              return CustomPaint(
                painter: _FluidOrbsPainter(
                  time: t,
                ),
                size: Size.infinite,
              );
            },
          ),

          // High-frequency subtle vignette / dark rim for contrast
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.15,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    stops: const [0.4, 0.78, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Forefront Page Content (Liquid Cards)
          widget.child,
        ],
      ),
    );
  }
}

class _FluidOrbsPainter extends CustomPainter {
  final double time;

  _FluidOrbsPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;

    // Orb 1: Cobalt Royal Sapphire (Deep optical anchor)
    final orb1X = w * (0.32 + 0.18 * math.sin(time * 0.7));
    final orb1Y = h * (0.28 + 0.14 * math.cos(time * 0.9));
    final orb1Radius = w * 0.65;
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF005FEA).withValues(alpha: 0.55), // Vibrant electric cobalt
          const Color(0xFF1D4ED8).withValues(alpha: 0.32),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(orb1X, orb1Y), radius: orb1Radius));
    canvas.drawCircle(Offset(orb1X, orb1Y), orb1Radius, paint1);

    // Orb 2: Ultraviolet / Electric Magenta (Upper-right chromatic burst)
    final orb2X = w * (0.75 + 0.16 * math.cos(time * 0.8 + 1.2));
    final orb2Y = h * (0.22 + 0.15 * math.sin(time * 0.6));
    final orb2Radius = w * 0.58;
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF9333EA).withValues(alpha: 0.48), // Hyper violet
          const Color(0xFFC026D3).withValues(alpha: 0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(orb2X, orb2Y), radius: orb2Radius));
    canvas.drawCircle(Offset(orb2X, orb2Y), orb2Radius, paint2);

    // Orb 3: Solar Neon Amber (Dynamic caustics in the lower-left)
    final orb3X = w * (0.25 + 0.22 * math.cos(time * 0.5 + 2.5));
    final orb3Y = h * (0.68 + 0.16 * math.sin(time * 0.75 + 0.5));
    final orb3Radius = w * 0.55;
    final paint3 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFF59E0B).withValues(alpha: 0.38), // Neon Amber
          const Color(0xFFEA580C).withValues(alpha: 0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.48, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(orb3X, orb3Y), radius: orb3Radius));
    canvas.drawCircle(Offset(orb3X, orb3Y), orb3Radius, paint3);

    // Orb 4: Cyan Aurora / Liquidity Pool (Lower-right harmonic pulse)
    final orb4X = w * (0.80 + 0.14 * math.sin(time * 0.9 + 3.0));
    final orb4Y = h * (0.82 + 0.12 * math.cos(time * 0.65 + 1.0));
    final orb4Radius = w * 0.60;
    final paint4 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF06B6D4).withValues(alpha: 0.42), // Pure cyan luminescence
          const Color(0xFF0284C7).withValues(alpha: 0.20),
          Colors.transparent,
        ],
        stops: const [0.0, 0.44, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(orb4X, orb4Y), radius: orb4Radius));
    canvas.drawCircle(Offset(orb4X, orb4Y), orb4Radius, paint4);
  }

  @override
  bool shouldRepaint(covariant _FluidOrbsPainter oldDelegate) =>
      oldDelegate.time != time;
}
