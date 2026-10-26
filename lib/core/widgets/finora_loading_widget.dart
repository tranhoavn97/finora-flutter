import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/theme_studio_controller.dart';

/// [FinoraPulseLoading]: Hệ thống hiệu ứng tải dữ liệu cao cấp FINORA
/// Hỗ trợ 5 phong cách chuyển động 120fps siêu mượt:
/// 1. Liquid Energy Ripple (Sóng ngọc lỏng Aquamorphic)
/// 2. Cyber Hologram Orbit (Quỹ đạo vòng xoay Hologram neon sci-fi)
/// 3. Golden Coin Flip 3D (Đồng xu FINORA xoay 3D lấp lánh)
/// 4. Glass Shimmer Wave (Dải sáng kính quang học phủ sương)
/// 5. Infinity Quantum Dots (Hạt lượng tử lượn vô cực)
class FinoraPulseLoading extends StatefulWidget {
  final double size;
  final Color? color;
  final String? message;
  final AppLoadingIndicatorStyle? overrideStyle;

  const FinoraPulseLoading({
    super.key,
    this.size = 56.0,
    this.color,
    this.message,
    this.overrideStyle,
  });

  @override
  State<FinoraPulseLoading> createState() => _FinoraPulseLoadingState();
}

class _FinoraPulseLoadingState extends State<FinoraPulseLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studio = Provider.of<ThemeStudioController?>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = widget.color ?? (studio?.primaryColor ?? const Color(0xFF007AFF));
    final style = widget.overrideStyle ??
        (studio?.loadingStyle ?? AppLoadingIndicatorStyle.liquidRipple);

    Widget animationWidget;
    switch (style) {
      case AppLoadingIndicatorStyle.liquidRipple:
        animationWidget = _buildLiquidRipple(primary, isDark);
        break;
      case AppLoadingIndicatorStyle.cyberOrbit:
        animationWidget = _buildCyberOrbit(primary, isDark);
        break;
      case AppLoadingIndicatorStyle.goldenCoin3D:
        animationWidget = _buildGoldenCoin3D(primary, isDark);
        break;
      case AppLoadingIndicatorStyle.glassShimmer:
        animationWidget = _buildGlassShimmer(primary, isDark);
        break;
      case AppLoadingIndicatorStyle.infinityDots:
        animationWidget = _buildInfinityDots(primary, isDark);
        break;
    }

    if (widget.message == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: animationWidget,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: animationWidget,
        ),
        const SizedBox(height: 12),
        Text(
          widget.message!,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // 1. LIQUID ENERGY RIPPLE (SÓNG NGỌC LỎNG AQUAMORPHIC)
  Widget _buildLiquidRipple(Color primary, bool isDark) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _LiquidRipplePainter(
            progress: _controller.value,
            color: primary,
            isDark: isDark,
          ),
        );
      },
    );
  }

  // 2. CYBER HOLOGRAM ORBIT (QUỸ ĐẠO VÒNG XOAY HOLOGRAM)
  Widget _buildCyberOrbit(Color primary, bool isDark) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _CyberOrbitPainter(
            progress: _controller.value,
            color: primary,
            isDark: isDark,
          ),
        );
      },
    );
  }

  // 3. GOLDEN COIN FLIP 3D (ĐỒNG XU FINORA XOAY 3D)
  Widget _buildGoldenCoin3D(Color primary, bool isDark) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = _controller.value * 2 * math.pi;
        final scaleX = math.cos(angle);
        final isFront = scaleX >= 0;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateY(angle),
          alignment: Alignment.center,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isFront
                    ? [const Color(0xFFFFD700), const Color(0xFFF59E0B), const Color(0xFFB45309)]
                    : [const Color(0xFFF59E0B), const Color(0xFFD97706), const Color(0xFF92400E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.7),
                width: 1.5,
              ),
            ),
            child: Center(
              child: isFront
                  ? const Text(
                      '₫',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        shadows: [Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 1))],
                      ),
                    )
                  : const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        );
      },
    );
  }

  // 4. GLASS SHIMMER WAVE (DẢI SÁNG KÍNH QUANG HỌC)
  Widget _buildGlassShimmer(Color primary, bool isDark) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            border: Border.all(
              color: primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: ClipOval(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment(
                      -2.0 + (_controller.value * 4.0),
                      0.0,
                    ),
                    child: Container(
                      width: widget.size * 0.7,
                      height: widget.size,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            primary.withValues(alpha: 0.6),
                            Colors.white.withValues(alpha: 0.85),
                            primary.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: primary,
                    size: widget.size * 0.45,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 5. INFINITY QUANTUM DOTS (HẠT LƯỢNG TỬ ĐỘNG)
  Widget _buildInfinityDots(Color primary, bool isDark) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _InfinityDotsPainter(
            progress: _controller.value,
            color: primary,
          ),
        );
      },
    );
  }
}

// ====================================================================
// CUSTOM PAINTERS ĐỈNH CAO CHO TỪNG PHONG CÁCH
// ====================================================================

class _LiquidRipplePainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isDark;

  _LiquidRipplePainter({
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Vòng sóng 1
    final r1 = (progress * maxRadius).clamp(0.0, maxRadius);
    final alpha1 = (1.0 - progress).clamp(0.0, 1.0);
    final paint1 = Paint()
      ..color = color.withValues(alpha: alpha1 * 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawCircle(center, r1, paint1);

    // Vòng sóng 2 (trễ pha 0.5)
    final prog2 = (progress + 0.5) % 1.0;
    final r2 = (prog2 * maxRadius).clamp(0.0, maxRadius);
    final alpha2 = (1.0 - prog2).clamp(0.0, 1.0);
    final paint2 = Paint()
      ..color = color.withValues(alpha: alpha2 * 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(center, r2, paint2);

    // Lõi ngọc phát sáng ở giữa
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white, color, color.withValues(alpha: 0.8)],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius * 0.35));
    canvas.drawCircle(center, maxRadius * 0.32, corePaint);

    // Vòng viền hào quang quanh lõi
    final haloPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, maxRadius * 0.36, haloPaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidRipplePainter oldDelegate) => true;
}

class _CyberOrbitPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isDark;

  _CyberOrbitPainter({
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    // Vòng ngoài quay xuôi kim đồng hồ
    final outerAngle = progress * 2 * math.pi;
    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [Colors.transparent, color.withValues(alpha: 0.2), color, Colors.white],
        stops: const [0.0, 0.5, 0.85, 1.0],
        transform: GradientRotation(outerAngle),
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), outerAngle, math.pi * 1.4, false, outerPaint);

    // Vòng trong quay ngược kim đồng hồ
    final innerRadius = radius * 0.62;
    final innerAngle = -progress * 2 * math.pi;
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [Colors.transparent, const Color(0xFF00E5FF).withValues(alpha: 0.3), const Color(0xFF00E5FF), Colors.white],
        stops: const [0.0, 0.5, 0.85, 1.0],
        transform: GradientRotation(innerAngle),
      ).createShader(Rect.fromCircle(center: center, radius: innerRadius));
    canvas.drawArc(Rect.fromCircle(center: center, radius: innerRadius), innerAngle, math.pi * 1.2, false, innerPaint);

    // Chấm sáng laser ở tâm
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 3.2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _CyberOrbitPainter oldDelegate) => true;
}

class _InfinityDotsPainter extends CustomPainter {
  final double progress;
  final Color color;

  _InfinityDotsPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const count = 8;

    for (int i = 0; i < count; i++) {
      final t = (progress + (i / count)) % 1.0;
      final angle = t * 2 * math.pi;
      // Đường cong Lemniscate of Bernoulli (Hình số 8)
      final scale = w * 0.38;
      final denom = 1 + math.sin(angle) * math.sin(angle);
      final x = (w / 2) + (scale * math.cos(angle) / denom);
      final y = (h / 2) + (scale * math.sin(angle) * math.cos(angle) / denom);

      final dotRadius = (2.2 + (i * 0.4)).clamp(1.5, 4.5);
      final alpha = (i / count).clamp(0.2, 1.0);
      final dotPaint = Paint()..color = color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _InfinityDotsPainter oldDelegate) => true;
}
