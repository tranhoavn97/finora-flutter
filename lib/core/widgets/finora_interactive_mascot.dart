import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../state/theme_studio_controller.dart';
import 'finora_mascot.dart';

bool _isFlutterTestEnvironment() {
  if (kIsWeb) return false;
  try {
    return Platform.environment.containsKey('FLUTTER_TEST');
  } catch (_) {
    return false;
  }
}

/// Alias cho Widget Linh Vật Rồng Ngọc 3D Sống Động
typedef FinoraLiving3DMascot = FinoraInteractive3DMascot;

/// Widget Linh Thú Rồng Ngọc Finora 3D Tương Tác Sống Động (60fps)
///
/// Tính năng chuẩn 3D Living Mascot & Micro-interactions:
/// 1. Chuyển động 3D tự nhiên liên tục: Lơ lửng (hover), nhịp thở ngực (squash & stretch),
///    nghiêng 3D đa trục (idle gyroscope sway) với phối cảnh Matrix4 focal depth.
/// 2. Chớp mắt tự nhiên định kỳ (Periodic Eye-Blink crossfade) và phản ứng tung hoa khi chạm.
/// 3. Ánh kim lấp lánh quét qua đồng xu vàng & vảy ngọc (_Mascot3DSpecularGlintPainter)
///    cùng các hạt tinh thể ngọc lục bảo / vàng kim bay quanh quỹ đạo 3D.
/// 4. Xoay 3D theo cử chỉ ngón tay (Interactive 3D Perspective Matrix) + đàn hồi lò xo
///    (Curves.elasticOut) khi thả tay + bóng đổ 3D dịch chuyển ngược hướng nghiêng.
/// 5. Tự động tôn trọng Reduce Motion / môi trường Flutter Test để không bao giờ gây treo pumpAndSettle.
class FinoraInteractive3DMascot extends StatefulWidget {
  final FinoraMascotPose pose;
  final double size;
  final bool enableFloatingAnimation;
  final bool enableTouch3DRotation;
  final bool enableSparkles;
  final String? customSpeechText;
  final VoidCallback? onTap;
  final double? budgetSpentRatio;
  final double? netCashflow;
  final bool showSpeechBubbleOnTap;

  const FinoraInteractive3DMascot({
    super.key,
    this.pose = FinoraMascotPose.hero,
    this.size = 110.0,
    this.enableFloatingAnimation = true,
    this.enableTouch3DRotation = true,
    this.enableSparkles = true,
    this.customSpeechText,
    this.onTap,
    this.budgetSpentRatio,
    this.netCashflow,
    this.showSpeechBubbleOnTap = false,
  });

  @override
  State<FinoraInteractive3DMascot> createState() =>
      _FinoraInteractive3DMascotState();
}

class _FinoraInteractive3DMascotState extends State<FinoraInteractive3DMascot>
    with TickerProviderStateMixin {
  late final AnimationController _floatingController;
  late final AnimationController _springController;
  late final AnimationController _tapBounceController;

  // Góc xoay 3D tương tác khi người dùng vuốt
  double _rotX = 0.0;
  double _rotY = 0.0;
  bool _showSpeechBubble = false;
  bool _isRunningContinuous = false;

  @override
  void initState() {
    super.initState();

    // 1. Chu kỳ lơ lửng 3D êm dịu, không giật nhấp nháy: 5600ms
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5600),
    );

    // 2. Hoạt ảnh lò xo nảy về khi thả tay (Spring bounce back)
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    // 3. Hoạt ảnh nhún nhảy ăn mừng khi nhấn chạm (Tap punch scale & jump)
    _tapBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _syncAnimationState(disableAnimations: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncAnimationState(disableAnimations: disableAnimations);
  }

  @override
  void didUpdateWidget(covariant FinoraInteractive3DMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enableFloatingAnimation != widget.enableFloatingAnimation) {
      final disableAnimations =
          MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      _syncAnimationState(disableAnimations: disableAnimations);
    }
  }

  void _syncAnimationState({required bool disableAnimations}) {
    final shouldAnimate = widget.enableFloatingAnimation &&
        !disableAnimations &&
        !_isFlutterTestEnvironment();
    if (shouldAnimate && !_isRunningContinuous) {
      _isRunningContinuous = true;
      _floatingController.repeat();
    } else if (!shouldAnimate && _isRunningContinuous) {
      _isRunningContinuous = false;
      _floatingController.stop();
      _floatingController.value = 0.25;
    }
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _springController.dispose();
    _tapBounceController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.enableTouch3DRotation) return;
    _springController.stop();
    HapticFeedback.selectionClick();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enableTouch3DRotation) return;
    setState(() {
      // Giới hạn góc nghiêng tối đa +/- 0.44 radian (~25 độ) tạo chiều sâu 3D rõ nét
      _rotY = (_rotY + details.delta.dx * 0.0085).clamp(-0.44, 0.44);
      _rotX = (_rotX - details.delta.dy * 0.0085).clamp(-0.36, 0.36);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.enableTouch3DRotation) return;
    final beginX = _rotX;
    final beginY = _rotY;

    final springAnimation = CurvedAnimation(
      parent: _springController,
      curve: Curves.elasticOut,
    );

    _springController.reset();
    void updateSpring() {
      if (!mounted) return;
      setState(() {
        _rotX = beginX * (1.0 - springAnimation.value);
        _rotY = beginY * (1.0 - springAnimation.value);
      });
    }

    _springController.addListener(updateSpring);
    _springController.forward().whenComplete(() {
      _springController.removeListener(updateSpring);
    });
    HapticFeedback.lightImpact();
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    _tapBounceController.forward(from: 0.0).then((_) {
      if (mounted) {
        _tapBounceController.reverse();
      }
    });

    if (widget.showSpeechBubbleOnTap) {
      setState(() {
        _showSpeechBubble = !_showSpeechBubble;
      });
    }

    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  FinoraMascotPose _resolveContextualPose() {
    if (widget.budgetSpentRatio != null && widget.budgetSpentRatio! > 0.85) {
      return FinoraMascotPose.focused;
    }
    if (widget.netCashflow != null && widget.netCashflow! > 1000000) {
      return FinoraMascotPose.confident;
    }
    return widget.pose;
  }

  String _resolveDefaultSpeech() {
    if (widget.customSpeechText != null &&
        widget.customSpeechText!.isNotEmpty) {
      return widget.customSpeechText!;
    }
    if (widget.budgetSpentRatio != null && widget.budgetSpentRatio! > 0.90) {
      return 'Cẩn thận nhé! Đã dùng hơn 90% ngân sách tháng!';
    }
    if (widget.budgetSpentRatio != null && widget.budgetSpentRatio! > 0.75) {
      return 'Chi tiêu đang tăng, cân nhắc trước khi mua sắm nhé!';
    }
    if (widget.netCashflow != null && widget.netCashflow! > 0) {
      return 'Dòng tiền tháng này đang dương rất tốt, cố lên!';
    }
    return 'Xin chào! Mình là Rồng Ngọc Finora 3D, chạm hoặc xoay mình nhé!';
  }

  @override
  Widget build(BuildContext context) {
    ThemeStudioController? studio;
    try {
      studio = Provider.of<ThemeStudioController?>(context);
    } catch (_) {
      studio = null;
    }
    final activeCharacter =
        studio?.mascotCharacter ?? AppMascotCharacter.jadeDragon3D;
    if (activeCharacter == AppMascotCharacter.hidden) {
      return const SizedBox.shrink();
    }
    final brandPrimary = studio?.resolvedPrimary ?? const Color(0xFF10B981);
    final effectivePose = _resolveContextualPose();
    final speechText = _resolveDefaultSpeech();
    final boxWidth = widget.size;

    final mascotInteractiveBox = GestureDetector(
            onTap: _handleTap,
            onPanStart: widget.enableTouch3DRotation ? _onPanStart : null,
            onPanUpdate: widget.enableTouch3DRotation ? _onPanUpdate : null,
            onPanEnd: widget.enableTouch3DRotation ? _onPanEnd : null,
            behavior: HitTestBehavior.opaque,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _floatingController,
                _tapBounceController,
              ]),
              builder: (context, child) {
                final t = _floatingController.value;
                final theta = t * 2.0 * math.pi;

                // 1. Chuyển động lơ lửng 3D đơn tần số êm ái + nhảy nhẹ khi chạm
                final floatOffset = _isRunningContinuous
                    ? math.sin(theta) * (widget.size * 0.032).clamp(2.0, 4.5)
                    : 0.0;
                final tapJumpOffset =
                    _tapBounceController.value * (widget.size * 0.09);

                // 2. Co giãn thống nhất rất nhẹ để tránh giật khung hình khi render
                final breathScale = _isRunningContinuous
                    ? 1.0 + math.sin(theta) * 0.008
                    : 1.0;
                final tapScale = 1.0 + _tapBounceController.value * 0.12;

                // 3. Góc nghiêng 3D tự nhiên êm dịu kết hợp góc vuốt tay
                final idleRotY =
                    _isRunningContinuous ? math.sin(theta) * 0.08 : 0.0;
                final idleRotX =
                    _isRunningContinuous ? math.cos(theta) * 0.03 : 0.0;

                final totalRotX = (_rotX + idleRotX).clamp(-0.42, 0.42);
                final totalRotY = (_rotY + idleRotY).clamp(-0.46, 0.46);

                // Ma trận phối cảnh 3D mượt (Perspective focal depth)
                final transformMatrix = Matrix4.identity()
                  ..setEntry(3, 2, 0.0020)
                  ..multiply(Matrix4.translationValues(
                    0.0,
                    -(floatOffset + tapJumpOffset),
                    0.0,
                  ))
                  ..multiply(Matrix4.diagonal3Values(
                    breathScale * tapScale,
                    breathScale * tapScale,
                    1.0,
                  ))
                  ..rotateX(totalRotX)
                  ..rotateY(totalRotY);

                return SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Lớp 1: Hào quang dịu đồng bộ màu chủ đạo hệ thống
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Transform.translate(
                            offset: Offset(
                              totalRotY * 8,
                              -floatOffset * 0.35,
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    brandPrimary.withValues(alpha: 0.16),
                                    brandPrimary.withValues(alpha: 0.04),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.58, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Lớp 2: Bóng đổ 3D mặt đất nhẹ nhàng, ổn định
                      Positioned(
                        bottom: 2 + floatOffset * 0.28,
                        child: IgnorePointer(
                          child: Container(
                            width: (widget.size * 0.58 - (totalRotX.abs() * 10))
                                .clamp(widget.size * 0.3, widget.size * 0.78),
                            height: (widget.size * 0.10 + (totalRotY.abs() * 3))
                                .clamp(6.0, 16.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.22),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                  offset: Offset(
                                    -totalRotY * 16,
                                    totalRotX * 8,
                                  ),
                                ),
                                BoxShadow(
                                  color: brandPrimary.withValues(alpha: 0.14),
                                  blurRadius: 18,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Lớp 3: Mô hình Linh Vật 3D ổn định không đổi ảnh nhấp nháy
                      Transform(
                        alignment: Alignment.center,
                        transform: transformMatrix,
                        child: RepaintBoundary(
                          child: FinoraMascotImage(
                            pose: effectivePose,
                            size: widget.size,
                            showGlow: false,
                          ),
                        ),
                      ),

                      // Lớp 4: Hạt tinh thể ánh sáng lơ lửng dịu (không chớp nháy)
                      if (widget.enableSparkles &&
                          (_isRunningContinuous ||
                              _tapBounceController.value > 0.01))
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _Mascot3DSparkleOrbitPainter(
                                phase: t,
                                tapProgress: _tapBounceController.value,
                                tiltX: totalRotX,
                                tiltY: totalRotY,
                                accentColor: brandPrimary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          );

    if (!_showSpeechBubble) {
      return mascotInteractiveBox;
    }

    return SizedBox(
      width: boxWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: brandPrimary.withValues(alpha: 0.45),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: brandPrimary.withValues(alpha: 0.24),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 12,
                  color: Color(0xFF34D399),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    speechText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          mascotInteractiveBox,
        ],
      ),
    );
  }
}

/// Painter vẽ các hạt tinh thể ánh sáng lơ lửng dịu quanh linh thú 3D
class _Mascot3DSparkleOrbitPainter extends CustomPainter {
  final double phase;
  final double tapProgress;
  final double tiltX;
  final double tiltY;
  final Color accentColor;

  const _Mascot3DSparkleOrbitPainter({
    required this.phase,
    required this.tapProgress,
    required this.tiltX,
    required this.tiltY,
    required this.accentColor,
  });

  static const List<({double angle0, double radiusFactor, double yFactor, bool isGold, double size})>
      _orbits = [
    (angle0: 0.4, radiusFactor: 0.44, yFactor: -0.22, isGold: true, size: 2.5),
    (angle0: 2.1, radiusFactor: 0.46, yFactor: 0.14, isGold: false, size: 2.2),
    (angle0: 4.0, radiusFactor: 0.43, yFactor: -0.24, isGold: true, size: 2.3),
    (angle0: 5.3, radiusFactor: 0.43, yFactor: -0.05, isGold: false, size: 2.1),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final theta = phase * 2.0 * math.pi;
    final minSide = size.shortestSide;

    for (var i = 0; i < _orbits.length; i++) {
      final orb = _orbits[i];
      final angle = orb.angle0 + theta * (i.isEven ? 1.0 : -1.0);
      final burstBoost = 1.0 + tapProgress * 0.22;
      final rx = minSide * orb.radiusFactor * burstBoost;
      final ry = minSide * 0.16 * burstBoost;

      final x = center.dx + math.cos(angle) * rx - tiltY * 8;
      final y = center.dy +
          orb.yFactor * minSide +
          math.sin(angle) * ry +
          tiltX * 6;

      final twinkle =
          0.55 + 0.30 * (0.5 + 0.5 * math.sin(theta + orb.angle0));
      final baseColor = orb.isGold ? const Color(0xFFFBBF24) : accentColor;

      final glowPaint = Paint()
        ..color = baseColor.withValues(alpha: (0.20 * twinkle).clamp(0.05, 0.30));
      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: (0.68 * twinkle).clamp(0.20, 0.85));

      final r = orb.size * (minSide / 100.0).clamp(0.75, 1.35);
      final pos = Offset(x, y);
      canvas.drawCircle(pos, r * 2.0, glowPaint);
      canvas.drawCircle(pos, r * 0.80, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _Mascot3DSparkleOrbitPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.tapProgress != tapProgress ||
        oldDelegate.tiltY != tiltY ||
        oldDelegate.accentColor != accentColor;
  }
}
