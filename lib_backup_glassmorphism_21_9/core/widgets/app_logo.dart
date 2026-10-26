import 'package:flutter/material.dart';

import '../design_system/app_colors.dart';

/// Renders the custom flowing "F" logo from the web app using a custom painter.
class FinoraLogo extends StatelessWidget {
  final double size;
  const FinoraLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _FinoraLogoPainter(),
    );
  }
}

class _FinoraLogoPainter extends CustomPainter {
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
      ..strokeJoin = StrokeJoin.round;

    paint.shader = const LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [
        Color(0xFF1877F2),
        Color(0xFF4DA3FF),
        Color(0xFF55C7FF),
      ],
      stops: [0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, 100.0 * scale, 100.0 * scale));

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Renders the complete stylized horizontal brand logo (F + vector "inora") matching the web app.
class FinoraBrandLogo extends StatelessWidget {
  final double width;
  final double height;
  const FinoraBrandLogo({super.key, this.width = 192, this.height = 60});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      size: Size(width, height),
      painter: _FinoraBrandLogoPainter(isDark: isDark),
    );
  }
}

class _FinoraBrandLogoPainter extends CustomPainter {
  final bool isDark;
  _FinoraBrandLogoPainter({required this.isDark});

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
      ..strokeJoin = StrokeJoin.round;

    fPaint.shader = const LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [
        Color(0xFF1877F2),
        Color(0xFF4DA3FF),
        Color(0xFF55C7FF),
      ],
      stops: [0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTWH(32.0 * scale, 20.0 * scale, 40.0 * scale, 60.0 * scale));

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
      ..color = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
