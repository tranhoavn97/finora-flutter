import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Liquid aurora orbs — the "liquid" in Liquid Glass.
///
/// One full-screen painter drawing radial-gradient orbs (the radial alpha
/// falloff is the blur, so no per-frame blur filter). Static by default;
/// with `animate: true` the orbs drift on slow sinusoidal paths and the
/// painter freezes when the OS asks to disable animations.
class LiquidAuroraLayer extends StatefulWidget {
  final List<Color> colors;
  final bool isDark;
  final Duration period;

  /// When false (default) the aurora is painted once and never re-paints.
  /// Animating this layer under full-app BackdropFilters forces the GPU to
  /// re-blur every frame and janks low/mid-end devices, so motion is opt-in.
  final bool animate;

  const LiquidAuroraLayer({
    super.key,
    required this.colors,
    this.isDark = false,
    this.period = const Duration(seconds: 32),
    this.animate = false,
  });

  @override
  State<LiquidAuroraLayer> createState() => _LiquidAuroraLayerState();
}

class _LiquidAuroraLayerState extends State<LiquidAuroraLayer>
    with SingleTickerProviderStateMixin {
  static const _frameInterval = Duration(milliseconds: 66);
  static const bool _kTestEnv = bool.fromEnvironment('FLUTTER_TEST');
  late final Ticker _ticker;
  final ValueNotifier<double> _phase = ValueNotifier(0);
  DateTime _lastPaint = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    if (_kTestEnv || !widget.animate) return;
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final now = DateTime.now();
    if (now.difference(_lastPaint) < _frameInterval) return;
    _lastPaint = now;
    if (MediaQuery.disableAnimationsOf(context)) return;
    _phase.value =
        elapsed.inMicroseconds / widget.period.inMicroseconds;
  }

  @override
  void dispose() {
    if (!_kTestEnv && widget.animate) {
      _ticker.dispose();
    }
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.colors.every((c) => c.a == 0)) {
      return const SizedBox.shrink();
    }
    return RepaintBoundary(
      child: IgnorePointer(
        child: SizedBox.expand(
          child: ValueListenableBuilder<double>(
            valueListenable: _phase,
            builder: (context, phase, _) => CustomPaint(
              painter: LiquidAuroraPainter(
                colors: widget.colors,
                phase: phase,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LiquidAuroraPainter extends CustomPainter {
  final List<Color> colors;
  final double phase;

  const LiquidAuroraPainter({required this.colors, required this.phase});

  // (centerX, centerY, radiusFactor, driftX, driftY, phaseOffset)
  static const List<(double, double, double, double, double, double)>
      _orbConfigs = [
    (0.86, 0.08, 0.78, 0.04, 0.04, 0.00),
    (0.12, 0.16, 0.68, 0.04, 0.05, 0.45),
    (0.84, 0.78, 0.74, 0.04, 0.04, 1.10),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || colors.isEmpty) return;
    final shortest = size.shortestSide;

    for (var i = 0; i < _orbConfigs.length; i++) {
      final config = _orbConfigs[i];
      final color = colors[i % colors.length];
      if (color.a == 0) continue;

      final t = phase * 2 * math.pi + config.$6;
      final center = Offset(
        size.width * config.$1 + math.sin(t) * config.$4 * size.width,
        size.height * config.$2 + math.cos(t * 0.9) * config.$5 * size.height,
      );
      final radius = shortest * config.$3;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color,
            color.withValues(alpha: color.a * 0.35),
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.52, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant LiquidAuroraPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.colors != colors;
}
