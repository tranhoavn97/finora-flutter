import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'finora_mascot.dart';

/// Widget Linh Thú Mèo Finora 3D Tương Tác Sống Động
///
/// Tính năng chuẩn Designer & Micro-interactions:
/// 1. Xoay 3D theo cử chỉ ngón tay (Interactive 3D Perspective Matrix)
/// 2. Hiệu ứng thở / lơ lửng tự nhiên (Idle Floating Animation)
/// 3. Lực nảy lò xo đàn hồi khi buông tay (Spring-back Elastic Physics)
/// 4. Bóng đổ 3D chuyển động ngược hướng (Dynamic Depth Shadow)
/// 5. Phản ứng xúc giác haptic và chạm để mở bong bóng thoại AI tư vấn
class FinoraInteractive3DMascot extends StatefulWidget {
  final FinoraMascotPose pose;
  final double size;
  final bool enableFloatingAnimation;
  final bool enableTouch3DRotation;
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

  // Góc xoay 3D tương tác
  double _rotX = 0.0;
  double _rotY = 0.0;
  bool _showSpeechBubble = false;

  @override
  void initState() {
    super.initState();

    // 1. Hoạt ảnh lơ lửng thở nhẹ (Idle breathing floating)
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.enableFloatingAnimation) {
      _floatingController.repeat(reverse: true);
    }

    // 2. Hoạt ảnh lò xo nảy về khi thả tay (Spring bounce back)
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    // 3. Hoạt ảnh nhún khi nhấn chạm (Tap punch scale)
    _tapBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
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
      // Giới hạn góc nghiêng tối đa +/- 0.42 radian (~24 độ) tạo chiều sâu 3D vừa vặn
      _rotY = (_rotY + details.delta.dx * 0.008).clamp(-0.42, 0.42);
      _rotX = (_rotX - details.delta.dy * 0.008).clamp(-0.35, 0.35);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.enableTouch3DRotation) return;
    final beginX = _rotX;
    final beginY = _rotY;

    // Kích hoạt đường cong đàn hồi ElasticOut đưa linh thú lắc lư trở về trục chuẩn
    final springAnimation = CurvedAnimation(
      parent: _springController,
      curve: Curves.elasticOut,
    );

    _springController.reset();
    _springController.addListener(() {
      setState(() {
        _rotX = beginX * (1.0 - springAnimation.value);
        _rotY = beginY * (1.0 - springAnimation.value);
      });
    });
    _springController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    _tapBounceController.forward(from: 0.0).then((_) {
      _tapBounceController.reverse();
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
      return FinoraMascotPose.focused; // Soi chi tiêu cẩn thận
    }
    if (widget.netCashflow != null && widget.netCashflow! > 1000000) {
      return FinoraMascotPose.happy; // Tiết kiệm dòng tiền dương vui vẻ
    }
    return widget.pose;
  }

  String _resolveDefaultSpeech() {
    if (widget.customSpeechText != null && widget.customSpeechText!.isNotEmpty) {
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
    return 'Xin chào! Mình là Finora, bạn đồng hành tài chính của bạn!';
  }

  @override
  Widget build(BuildContext context) {
    final effectivePose = _resolveContextualPose();
    final speechText = _resolveDefaultSpeech();
    final boxWidth = widget.size;

    return SizedBox(
      width: boxWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Bong bóng thoại AI khi chạm vào hoặc khi bật
          if (_showSpeechBubble)
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF34D399).withValues(alpha: 0.40),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.20),
                    blurRadius: 10,
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

          // Khối tương tác cử chỉ & xoay 3D
          GestureDetector(
            onTap: _handleTap,
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            behavior: HitTestBehavior.opaque,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _floatingController,
                _tapBounceController,
              ]),
              builder: (context, child) {
                // Hoạt ảnh lơ lửng thở nhẹ (dao động sin 6px)
                final floatOffset = widget.enableFloatingAnimation
                    ? math.sin(_floatingController.value * math.pi) * 6.0
                    : 0.0;

                // Hoạt ảnh nảy khi chạm (tap punch scale)
                final tapScale = 1.0 + _tapBounceController.value * 0.12;

                // Ma trận xoay 3D Perspective
                final transformMatrix = Matrix4.identity()
                  ..setEntry(3, 2, 0.002) // Độ sâu phối cảnh (Perspective focal depth)
                  ..multiply(Matrix4.translationValues(0.0, -floatOffset, 0.0))
                  ..multiply(Matrix4.diagonal3Values(tapScale, tapScale, 1.0))
                  ..rotateX(_rotX)
                  ..rotateY(_rotY);

                return SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Bóng đổ 3D mềm phía dưới (di chuyển ngược hướng nghiêng)
                      Positioned(
                        bottom: 4 + floatOffset * 0.4,
                        child: Container(
                          width: widget.size * 0.65 - (_rotX.abs() * 15),
                          height: 12 + (_rotY.abs() * 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: (0.28 - floatOffset * 0.015).clamp(0.08, 0.35),
                                ),
                                blurRadius: 16 + floatOffset,
                                spreadRadius: 2,
                                offset: Offset(
                                  -_rotY * 25, // Bóng trôi ngược hướng xoay
                                  _rotX * 15,
                                ),
                              ),
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(
                                  alpha: (0.16 - floatOffset * 0.01).clamp(0.04, 0.22),
                                ),
                                blurRadius: 24,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Mô hình Linh Thú xoay 3D
                      Transform(
                        alignment: Alignment.center,
                        transform: transformMatrix,
                        child: FinoraMascotImage(
                          pose: effectivePose,
                          size: widget.size,
                          showGlow: true,
                          withGlow: true,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
