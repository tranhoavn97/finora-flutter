import 'package:flutter/material.dart';

import '../theme/finora_tokens.dart';

/// Renders the custom flowing "F" logo in FINORA 2026 Solid Ink.
class FinoraLogo extends StatelessWidget {
  final double size;
  final Color? color;
  const FinoraLogo({super.key, this.size = 64, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = color ?? FinoraTokens.ink(isDark);
    return CustomPaint(
      size: Size(size, size),
      painter: _FinoraLogoPainter(color: effectiveColor),
    );
  }
}

class _FinoraLogoPainter extends CustomPainter {
  final Color color;
  _FinoraLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 100.0;
    final scaleY = size.height / 100.0;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final dx = (size.width - 100.0 * scale) / 2;
    final dy = (size.height - 100.0 * scale) / 2;
    canvas.save();
    canvas.translate(dx, dy);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    final path1 = Path()
      ..moveTo(32.0 * scale, 80.0 * scale)
      ..lineTo(32.0 * scale, 38.0 * scale)
      ..arcToPoint(
        Offset(50.0 * scale, 20.0 * scale),
        radius: Radius.circular(18.0 * scale),
        clockwise: true,
      )
      ..lineTo(72.0 * scale, 20.0 * scale);

    final path2 = Path()
      ..moveTo(32.0 * scale, 48.0 * scale)
      ..lineTo(54.0 * scale, 48.0 * scale);

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FinoraLogoPainter oldDelegate) => oldDelegate.color != color;
}

/// Renders the complete stylized horizontal brand logo (F + vector "inora") in Solid Ink.
class FinoraBrandLogo extends StatelessWidget {
  final double width;
  final double height;
  final Color? color;
  const FinoraBrandLogo({super.key, this.width = 192, this.height = 60, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = color ?? FinoraTokens.ink(isDark);
    return CustomPaint(
      size: Size(width, height),
      painter: _FinoraBrandLogoPainter(color: effectiveColor),
    );
  }
}

class _FinoraBrandLogoPainter extends CustomPainter {
  final Color color;
  _FinoraBrandLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 320.0;
    final scaleY = size.height / 100.0;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final dx = (size.width - 320.0 * scale) / 2;
    final dy = (size.height - 100.0 * scale) / 2;
    canvas.save();
    canvas.translate(dx, dy);

    // Flowing "F" Logo painter
    final fPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    final pathF1 = Path()
      ..moveTo(32.0 * scale, 80.0 * scale)
      ..lineTo(32.0 * scale, 38.0 * scale)
      ..arcToPoint(
        Offset(50.0 * scale, 20.0 * scale),
        radius: Radius.circular(18.0 * scale),
        clockwise: true,
      )
      ..lineTo(72.0 * scale, 20.0 * scale);

    final pathF2 = Path()
      ..moveTo(32.0 * scale, 48.0 * scale)
      ..lineTo(54.0 * scale, 48.0 * scale);

    canvas.drawPath(pathF1, fPaint);
    canvas.drawPath(pathF2, fPaint);

    // Vector text "inora" painter
    final textPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    // i
    final pathI = Path()
      ..moveTo(98.0 * scale, 44.0 * scale)
      ..lineTo(98.0 * scale, 80.0 * scale);
    canvas.drawPath(pathI, textPaint);
    canvas.drawCircle(Offset(98.0 * scale, 26.0 * scale), 5.0 * scale, fillPaint);

    // n
    final pathN = Path()
      ..moveTo(124.0 * scale, 80.0 * scale)
      ..lineTo(124.0 * scale, 44.0 * scale)
      ..moveTo(124.0 * scale, 54.0 * scale)
      ..arcToPoint(
        Offset(154.0 * scale, 54.0 * scale),
        radius: Radius.circular(15.0 * scale),
        clockwise: true,
      )
      ..lineTo(154.0 * scale, 80.0 * scale);
    canvas.drawPath(pathN, textPaint);

    // o
    canvas.drawCircle(Offset(186.0 * scale, 62.0 * scale), 18.0 * scale, textPaint);

    // r
    final pathR = Path()
      ..moveTo(224.0 * scale, 80.0 * scale)
      ..lineTo(224.0 * scale, 44.0 * scale)
      ..moveTo(224.0 * scale, 56.0 * scale)
      ..quadraticBezierTo(232.0 * scale, 44.0 * scale, 248.0 * scale, 44.0 * scale);
    canvas.drawPath(pathR, textPaint);

    // a
    canvas.drawCircle(Offset(274.0 * scale, 62.0 * scale), 18.0 * scale, textPaint);
    final pathA = Path()
      ..moveTo(292.0 * scale, 44.0 * scale)
      ..lineTo(292.0 * scale, 80.0 * scale);
    canvas.drawPath(pathA, textPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FinoraBrandLogoPainter oldDelegate) => oldDelegate.color != color;
}
