import 'package:flutter/material.dart';

/// Shared roles for FINORA's bright, rounded visual language.
abstract final class FreshColors {
  static const blue = Color(0xFF0066CC);
  static const sky = Color(0xFF007AFF);
  static const background = Color(0xFFF5F8FF);
  static const ink = Color(0xFF182536);
  static const mint = Color(0xFFC5F2E5);
  static const butter = Color(0xFFFFF1BA);
  static Color surface(BuildContext c) => Theme.of(c).colorScheme.surface;
  static Color text(BuildContext c) => Theme.of(c).colorScheme.onSurface;
  static Color muted(BuildContext c) =>
      Theme.of(c).colorScheme.onSurfaceVariant;
  static Color tint(BuildContext c) => Theme.of(c).brightness == Brightness.dark
      ? const Color(0xFF243B56)
      : const Color(0xFFE8F2FF);
}

class FreshPanel extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  const FreshPanel(
      {super.key,
      required this.child,
      this.color,
      this.padding = const EdgeInsets.all(20)});
  @override
  Widget build(BuildContext context) => Material(
        color: color ?? FreshColors.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withValues(alpha: 0.45)),
        ),
        child: Padding(padding: padding, child: child),
      );
}

class FreshPageIntro extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const FreshPageIntro(
      {super.key,
      required this.eyebrow,
      required this.title,
      this.subtitle,
      this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 20),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(eyebrow,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 7),
                Text(title,
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        height: 1.18,
                        letterSpacing: -0.7,
                        color: FreshColors.text(context))),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(subtitle!,
                      style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: FreshColors.muted(context))),
                ],
              ])),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ]),
      );
}

/// Linh thú Rồng ngọc Fio đồng hành cùng Finora 3D
class FioMascot extends StatelessWidget {
  final double size;
  final bool celebrate;
  const FioMascot({super.key, this.size = 72, this.celebrate = false});
  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Fio, rồng ngọc đồng hành cùng Finora',
        image: true,
        child: SizedBox.square(
          dimension: size,
          child: Image.asset(
            celebrate
                ? 'assets/mascot/expression-04-excited.png'
                : 'assets/mascot/expression-01-happy.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => CustomPaint(
              painter: _FioPainter(celebrate),
            ),
          ),
        ),
      );
}

class _FioPainter extends CustomPainter {
  final bool celebrate;
  _FioPainter(this.celebrate);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final paint = Paint()..isAntiAlias = true;

    // Soft emerald shadow base
    canvas.drawOval(
      const Rect.fromLTWH(20, 84, 60, 8),
      paint..color = const Color(0xFF003D35).withValues(alpha: 0.14),
    );

    // Cute Emerald Dragon Body
    final body = Path()
      ..moveTo(50, 20)
      ..cubicTo(74, 18, 86, 42, 82, 68)
      ..cubicTo(78, 86, 64, 90, 50, 90)
      ..cubicTo(36, 90, 22, 86, 18, 68)
      ..cubicTo(14, 42, 26, 18, 50, 20)
      ..close();
    paint.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF34D399), Color(0xFF00866A), Color(0xFF003D35)],
    ).createShader(const Rect.fromLTWH(18, 18, 64, 72));
    canvas.drawPath(body, paint);
    paint.shader = null;

    // Cute Dragon Horns (Gold Accent)
    final leftHorn = Path()
      ..moveTo(34, 24)
      ..cubicTo(26, 12, 28, 4, 32, 2)
      ..cubicTo(37, 4, 38, 14, 40, 22)
      ..close();
    final rightHorn = Path()
      ..moveTo(66, 24)
      ..cubicTo(74, 12, 72, 4, 68, 2)
      ..cubicTo(63, 4, 62, 14, 60, 22)
      ..close();
    paint.color = const Color(0xFFF59E0B);
    canvas.drawPath(leftHorn, paint);
    canvas.drawPath(rightHorn, paint);

    // Cream/Mint Belly
    final belly = Path()
      ..moveTo(50, 48)
      ..cubicTo(65, 48, 70, 72, 64, 86)
      ..cubicTo(56, 89, 44, 89, 36, 86)
      ..cubicTo(30, 72, 35, 48, 50, 48)
      ..close();
    paint.color = const Color(0xFFE8F8F2);
    canvas.drawPath(belly, paint);

    // Eyes
    paint.color = const Color(0xFF003D35);
    if (celebrate) {
      // Happy curving eyes ^ ^
      final eyeLeft = Path()
        ..moveTo(35, 40)
        ..quadraticBezierTo(40, 34, 45, 40);
      final eyeRight = Path()
        ..moveTo(55, 40)
        ..quadraticBezierTo(60, 34, 65, 40);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 3.0;
      paint.strokeCap = StrokeCap.round;
      canvas.drawPath(eyeLeft, paint);
      canvas.drawPath(eyeRight, paint);
      paint.style = PaintingStyle.fill;
    } else {
      canvas.drawCircle(const Offset(40, 38), 4.0, paint);
      canvas.drawCircle(const Offset(60, 38), 4.0, paint);
      paint.color = Colors.white;
      canvas.drawCircle(const Offset(41, 37), 1.4, paint);
      canvas.drawCircle(const Offset(61, 37), 1.4, paint);
    }

    // Rosy dragon cheeks
    paint.color = const Color(0xFFFF9B9B).withValues(alpha: 0.6);
    canvas.drawOval(const Rect.fromLTWH(30, 43, 8, 4), paint);
    canvas.drawOval(const Rect.fromLTWH(62, 43, 8, 4), paint);

    // Golden Coin held by dragon
    paint.color = const Color(0xFFF59E0B);
    canvas.drawCircle(const Offset(50, 68), 10, paint);
    paint.color = const Color(0xFFFEF3C7);
    canvas.drawCircle(const Offset(50, 68), 7, paint);
    paint.color = const Color(0xFFD97706);
    canvas.drawRect(const Rect.fromLTWH(47, 65, 6, 6), paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_FioPainter old) => old.celebrate != celebrate;
}

/// Launcher-safe mark: a white wing forming an F on a blue field.
class FioAppIcon extends StatelessWidget {
  final double size;
  final bool rounded;
  const FioAppIcon({super.key, this.size = 64, this.rounded = true});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(rounded ? size * 0.23 : 0),
        child: Image.asset(
          'assets/mascot/app-icon.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => CustomPaint(
            size: Size.square(size),
            painter: FioAppIconPainter(),
          ),
        ),
      );
}

class FioAppIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    canvas.drawRect(
        Offset.zero & size,
        p
          ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF39ABFF),
                Color(0xFF007AFF),
                Color(0xFF005FD6)
              ]).createShader(Offset.zero & size));
    p.shader = null;
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final wing = Path()
      ..moveTo(29, 76)
      ..lineTo(29, 41)
      ..quadraticBezierTo(29, 25, 46, 25)
      ..lineTo(78, 25)
      ..quadraticBezierTo(68, 42, 47, 42)
      ..lineTo(45, 51)
      ..lineTo(66, 51)
      ..quadraticBezierTo(60, 65, 43, 65)
      ..lineTo(42, 76)
      ..close();
    canvas.drawPath(wing, p..color = Colors.white);
    canvas.drawCircle(const Offset(75, 69), 5, p..color = FreshColors.mint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(FioAppIconPainter old) => false;
}

class FreshPinnedHeader extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  FreshPinnedHeader({required this.child, required this.height});
  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: child));
  @override
  bool shouldRebuild(FreshPinnedHeader old) =>
      old.child != child || old.height != height;
}
