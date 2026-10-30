import 'dart:math' as math;
import 'package:flutter/material.dart';

enum FinoraQuickAction { send, receive, scan, goal }

/// Small native symbols with a shared dragon silhouette, readable without PNG crops.
class FinoraMascotActionIcon extends StatelessWidget {
  final FinoraQuickAction action;
  final Color color;
  const FinoraMascotActionIcon(
      {super.key, required this.action, required this.color});

  @override
  Widget build(BuildContext context) => CustomPaint(
      size: const Size.square(58),
      painter: _DragonActionPainter(action, color));
}

class _DragonActionPainter extends CustomPainter {
  final FinoraQuickAction action;
  final Color color;
  _DragonActionPainter(this.action, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 58, size.height / 58);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    switch (action) {
      case FinoraQuickAction.send:
        path.moveTo(14, 37);
        path.lineTo(35, 16);
        path.moveTo(19, 16);
        path.lineTo(35, 16);
        path.lineTo(35, 32);
      case FinoraQuickAction.receive:
        path.moveTo(16, 16);
        path.lineTo(35, 35);
        path.moveTo(19, 35);
        path.lineTo(35, 35);
        path.lineTo(35, 19);
      case FinoraQuickAction.scan:
        for (final offset in [
          const Offset(13, 13),
          const Offset(29, 13),
          const Offset(13, 29)
        ]) {
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  offset & const Size(10, 10), const Radius.circular(2)),
              stroke);
        }
        path.moveTo(30, 30);
        path.lineTo(34, 30);
        path.lineTo(34, 38);
        path.lineTo(39, 38);
      case FinoraQuickAction.goal:
        canvas.drawCircle(const Offset(26, 26), 14, stroke);
        canvas.drawCircle(const Offset(26, 26), 7, stroke);
        path.moveTo(26, 26);
        path.lineTo(39, 13);
        path.moveTo(32, 13);
        path.lineTo(39, 13);
        path.lineTo(39, 20);
    }
    canvas.drawPath(path, stroke);
    // A cream dragon face and mint horns peeking over the symbol's lower corner.
    final fill = Paint()..color = const Color(0xFF79CDA9);
    canvas.drawOval(const Rect.fromLTWH(36, 31, 6, 10), fill);
    canvas.drawOval(const Rect.fromLTWH(47, 31, 6, 10), fill);
    fill.color = const Color(0xFFFFF3D7);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(35, 36, 20, 17), const Radius.circular(8)),
        fill);
    final edge = Paint()
      ..color = color.withValues(alpha: .35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(35, 36, 20, 17), const Radius.circular(8)),
        edge);
    fill.color = const Color(0xFF0D5140);
    canvas.drawCircle(const Offset(41, 43), 1.4, fill);
    canvas.drawCircle(const Offset(49, 43), 1.4, fill);
    canvas.drawArc(
        const Rect.fromLTWH(42, 44, 6, 4),
        0,
        math.pi,
        false,
        Paint()
          ..color = fill.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DragonActionPainter old) =>
      old.action != action || old.color != color;
}

class VietnamCurrencyFlag extends StatelessWidget {
  const VietnamCurrencyFlag({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
      label: 'Việt Nam',
      child: CustomPaint(
          size: const Size(22, 15), painter: _VietnamFlagPainter()));
}

class _VietnamFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(3)),
        Paint()..color = const Color(0xFFDA251D));
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final radius = i.isEven ? size.height * .31 : size.height * .125;
      final point =
          center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path..close(), Paint()..color = const Color(0xFFFFE000));
  }

  @override
  bool shouldRepaint(_VietnamFlagPainter old) => false;
}
