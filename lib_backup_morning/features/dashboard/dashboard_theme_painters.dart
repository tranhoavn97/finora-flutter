import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Painter for Theme 1: Neon Cyan Pulse (smooth glowing wave line with glowing points)
class NeonWavePainter extends CustomPainter {
  final Color primaryColor;
  final Color glowColor;

  const NeonWavePainter({
    this.primaryColor = const Color(0xFF38BDF8),
    this.glowColor = const Color(0xFF0284C7),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final path = Path();
    final startX = size.width * 0.35;
    final endX = size.width * 0.96;
    final startY = size.height * 0.72;

    path.moveTo(startX, startY);
    path.cubicTo(
      size.width * 0.52,
      size.height * 0.45,
      size.width * 0.68,
      size.height * 0.88,
      size.width * 0.82,
      size.height * 0.50,
    );
    path.cubicTo(
      size.width * 0.88,
      size.height * 0.32,
      size.width * 0.92,
      size.height * 0.22,
      endX,
      size.height * 0.26,
    );

    // Background gradient glow under wave
    final fillPath = Path.from(path)
      ..lineTo(endX, size.height)
      ..lineTo(startX, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withValues(alpha: 0.18),
          primaryColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(startX, 0, endX - startX, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Wide outer blur glow
    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawPath(path, glowPaint);

    // Core crisp line
    final linePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // End glowing beacon point
    final endPoint = Offset(endX, size.height * 0.26);
    final beaconGlow = Paint()
      ..color = primaryColor.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(endPoint, 6, beaconGlow);

    final beaconCore = Paint()..color = Colors.white;
    canvas.drawCircle(endPoint, 3.5, beaconCore);
  }

  @override
  bool shouldRepaint(covariant NeonWavePainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.glowColor != glowColor;
}

/// Painter for Theme 2: Cyber Purple Equalizer (vertical glowing audio bars)
class EqualizerBarsPainter extends CustomPainter {
  final Color primaryColor;

  const EqualizerBarsPainter({
    this.primaryColor = const Color(0xFFC084FC),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    const barCount = 14;
    const barWidth = 3.0;
    const spacing = 5.5;
    const totalWidth = barCount * barWidth + (barCount - 1) * spacing;
    final startX = size.width - totalWidth - 14;
    final baseBottom = size.height * 0.76;

    final heights = [
      0.18, 0.35, 0.25, 0.45, 0.70, 0.52, 0.85,
      0.40, 0.95, 0.65, 0.80, 0.42, 0.60, 0.30
    ];

    for (int i = 0; i < barCount; i++) {
      final x = startX + i * (barWidth + spacing);
      final barHeight = heights[i % heights.length] * size.height * 0.48;
      final top = baseBottom - barHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, barHeight),
        const Radius.circular(2),
      );

      // Glow paint
      final glowPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(rect, glowPaint);

      // Core bar
      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            primaryColor.withValues(alpha: 0.5),
            primaryColor,
            Colors.white,
          ],
          stops: const [0.0, 0.75, 1.0],
        ).createShader(Rect.fromLTWH(x, top, barWidth, barHeight));

      canvas.drawRRect(rect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant EqualizerBarsPainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor;
}

/// Painter for Theme 3: Cyber Emerald Wave (dark teal background with undulating wave and nodes)
class EmeraldWavePainter extends CustomPainter {
  final Color primaryColor;

  const EmeraldWavePainter({
    this.primaryColor = const Color(0xFF2DD4BF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final path = Path();
    final startX = size.width * 0.20;
    final endX = size.width * 0.98;
    final startY = size.height * 0.68;

    path.moveTo(startX, startY);
    path.cubicTo(
      size.width * 0.42,
      size.height * 0.82,
      size.width * 0.55,
      size.height * 0.52,
      size.width * 0.68,
      size.height * 0.60,
    );
    path.cubicTo(
      size.width * 0.78,
      size.height * 0.68,
      size.width * 0.88,
      size.height * 0.38,
      endX,
      size.height * 0.56,
    );

    // Glow under wave
    final fillPath = Path.from(path)
      ..lineTo(endX, size.height)
      ..lineTo(startX, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withValues(alpha: 0.16),
          primaryColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(startX, 0, endX - startX, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Glow line
    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(path, glowPaint);

    // Crisp line
    final linePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, linePaint);

    // Multiple glowing node checkpoints
    final nodes = [
      Offset(size.width * 0.38, size.height * 0.77),
      Offset(size.width * 0.62, size.height * 0.56),
      Offset(size.width * 0.86, size.height * 0.42),
      Offset(endX, size.height * 0.56),
    ];

    for (final node in nodes) {
      final halo = Paint()
        ..color = primaryColor.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(node, 5, halo);

      final core = Paint()..color = Colors.white;
      canvas.drawCircle(node, 2.5, core);
    }
  }

  @override
  bool shouldRepaint(covariant EmeraldWavePainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor;
}

/// Painter for Theme 4: Starlight Gold Meteors (golden light rays and shooting streaks)
class GoldenMeteorsPainter extends CustomPainter {
  final Color primaryColor;

  const GoldenMeteorsPainter({
    this.primaryColor = const Color(0xFFFBBF24),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final meteors = [
      // (originX, originY, length, angleRad, thickness, alpha)
      (size.width * 0.72, size.height * 0.42, 38.0, 0.62, 2.2, 0.90),
      (size.width * 0.84, size.height * 0.36, 48.0, 0.60, 2.8, 0.95),
      (size.width * 0.92, size.height * 0.48, 36.0, 0.65, 2.0, 0.85),
      (size.width * 0.78, size.height * 0.56, 32.0, 0.58, 1.8, 0.75),
      (size.width * 0.65, size.height * 0.50, 26.0, 0.60, 1.6, 0.65),
      (size.width * 0.96, size.height * 0.40, 24.0, 0.63, 1.5, 0.60),
    ];

    for (final m in meteors) {
      final startX = m.$1;
      final startY = m.$2;
      final len = m.$3;
      final angle = m.$4;
      final width = m.$5;
      final alpha = m.$6;

      // Tail extends backwards towards top-right
      final endX = startX - len * math.cos(angle);
      final endY = startY - len * math.sin(angle);

      final p1 = Offset(startX, startY);
      final p2 = Offset(endX, endY);

      // Glow paint
      final glowPaint = Paint()
        ..color = primaryColor.withValues(alpha: alpha * 0.4)
        ..strokeWidth = width * 2.2
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawLine(p1, p2, glowPaint);

      // Gradient tail
      final linePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            primaryColor.withValues(alpha: alpha * 0.8),
            Colors.white,
          ],
          stops: const [0.0, 0.7, 1.0],
        ).createShader(Rect.fromPoints(p2, p1))
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p2, p1, linePaint);

      // Bright head point
      final headGlow = Paint()
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(p1, width * 0.9, headGlow);
    }
  }

  @override
  bool shouldRepaint(covariant GoldenMeteorsPainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor;
}

/// Painter for Theme 5: Pearl Pastel Horizon (soft lavender/cyan/blue pastel wavy hills)
class PastelHorizonPainter extends CustomPainter {
  const PastelHorizonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // First background wave (soft lavender/purple hill)
    final path1 = Path();
    path1.moveTo(size.width * 0.40, size.height);
    path1.cubicTo(
      size.width * 0.55,
      size.height * 0.65,
      size.width * 0.68,
      size.height * 0.75,
      size.width * 0.80,
      size.height * 0.58,
    );
    path1.cubicTo(
      size.width * 0.90,
      size.height * 0.45,
      size.width * 0.96,
      size.height * 0.50,
      size.width,
      size.height * 0.55,
    );
    path1.lineTo(size.width, size.height);
    path1.close();

    final paint1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFC4B5FD).withValues(alpha: 0.45),
          const Color(0xFFDDD6FE).withValues(alpha: 0.20),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path1, paint1);

    // Second foreground wave (soft cyan-blue mist)
    final path2 = Path();
    path2.moveTo(size.width * 0.50, size.height);
    path2.cubicTo(
      size.width * 0.62,
      size.height * 0.78,
      size.width * 0.76,
      size.height * 0.60,
      size.width * 0.88,
      size.height * 0.72,
    );
    path2.cubicTo(
      size.width * 0.94,
      size.height * 0.78,
      size.width * 0.98,
      size.height * 0.75,
      size.width,
      size.height * 0.70,
    );
    path2.lineTo(size.width, size.height);
    path2.close();

    final paint2 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFBAE6FD).withValues(alpha: 0.55),
          const Color(0xFFE0F2FE).withValues(alpha: 0.15),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path2, paint2);

    // Subtle sun/glow circle on horizon
    final sunCenter = Offset(size.width * 0.84, size.height * 0.48);
    final sunGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFDE68A).withValues(alpha: 0.5),
          const Color(0xFFDDD6FE).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: 28));
    canvas.drawCircle(sunCenter, 28, sunGlow);
  }

  @override
  bool shouldRepaint(covariant PastelHorizonPainter oldDelegate) => false;
}

/// Painter for Theme 6: Sci-Fi Holo Radar (futuristic cyan sonar circles & crosshair)
class HoloRadarPainter extends CustomPainter {
  final Color primaryColor;

  const HoloRadarPainter({
    this.primaryColor = const Color(0xFF06B6D4),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width * 0.82, size.height * 0.52);
    final maxRadius = size.height * 0.42;

    // Concentric radar rings
    final rings = [0.28, 0.55, 0.82, 1.0];
    for (final fraction in rings) {
      final r = maxRadius * fraction;
      final ringPaint = Paint()
        ..color = primaryColor.withValues(alpha: fraction == 1.0 ? 0.22 : 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(center, r, ringPaint);
    }

    // Crosshair axes (thin)
    final axisPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.15)
      ..strokeWidth = 0.8;
    canvas.drawLine(
      Offset(center.dx - maxRadius * 1.08, center.dy),
      Offset(center.dx + maxRadius * 1.08, center.dy),
      axisPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius * 1.08),
      Offset(center.dx, center.dy + maxRadius * 1.08),
      axisPaint,
    );

    // Glowing center radar pulse
    final pulseGlow = Paint()
      ..color = primaryColor.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, 9, pulseGlow);

    final pulseMid = Paint()
      ..color = primaryColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(center, 4.5, pulseMid);

    final pulseCore = Paint()..color = Colors.white;
    canvas.drawCircle(center, 2.2, pulseCore);
  }

  @override
  bool shouldRepaint(covariant HoloRadarPainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor;
}

/// Painter for Decorative Soft Leaves (Green Nature Theme)
class BotanicalLeavesPainter extends CustomPainter {
  final Color leafColor;

  const BotanicalLeavesPainter({
    this.leafColor = const Color(0xFF10B981),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..color = leafColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Draw 2 delicate botanical leaves in corner
    final leaf1 = Path();
    final p1 = Offset(size.width - 12, size.height - 36);
    leaf1.moveTo(p1.dx, p1.dy);
    leaf1.quadraticBezierTo(p1.dx - 22, p1.dy - 18, p1.dx - 32, p1.dy + 8);
    leaf1.quadraticBezierTo(p1.dx - 12, p1.dy + 14, p1.dx, p1.dy);
    canvas.drawPath(leaf1, paint);

    final leaf2 = Path();
    final p2 = Offset(size.width - 24, size.height - 14);
    leaf2.moveTo(p2.dx, p2.dy);
    leaf2.quadraticBezierTo(p2.dx - 18, p2.dy - 16, p2.dx - 28, p2.dy - 2);
    leaf2.quadraticBezierTo(p2.dx - 8, p2.dy + 8, p2.dx, p2.dy);
    canvas.drawPath(leaf2, paint);
  }

  @override
  bool shouldRepaint(covariant BotanicalLeavesPainter oldDelegate) =>
      oldDelegate.leafColor != leafColor;
}

/// Painter for Dotted Circular Progress Badge
class DottedCircleProgressPainter extends CustomPainter {
  final Color color;
  final double progress; // 0.0 - 1.0

  const DottedCircleProgressPainter({
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 4) / 2;
    const totalDots = 24;

    for (int i = 0; i < totalDots; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / totalDots);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      final isActive = (i / totalDots) <= progress;

      final dotPaint = Paint()
        ..color = isActive ? color : color.withValues(alpha: 0.22)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), isActive ? 1.6 : 1.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant DottedCircleProgressPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.progress != progress;
}

/// Painter for Cyber Hexagonal Border Shape
class HexagonBorderPainter extends CustomPainter {
  final Color strokeColor;
  final Color? fillColor;
  final double strokeWidth;

  const HexagonBorderPainter({
    required this.strokeColor,
    this.fillColor,
    this.strokeWidth = 1.4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cut = w * 0.25;

    final path = Path()
      ..moveTo(cut, 0)
      ..lineTo(w - cut, 0)
      ..lineTo(w, h / 2)
      ..lineTo(w - cut, h)
      ..lineTo(cut, h)
      ..lineTo(0, h / 2)
      ..close();

    if (fillColor != null) {
      final fPaint = Paint()
        ..color = fillColor!
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fPaint);
    }

    final sPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawPath(path, sPaint);
  }

  @override
  bool shouldRepaint(covariant HexagonBorderPainter oldDelegate) =>
      oldDelegate.strokeColor != strokeColor ||
      oldDelegate.fillColor != fillColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
