import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/theme_studio_controller.dart';
import 'fresh_design.dart';
import 'finora_interactive_mascot.dart';

export 'finora_interactive_mascot.dart';

bool _isWatermarkTestEnv() {
  if (kIsWeb) return false;
  try {
    return Platform.environment.containsKey('FLUTTER_TEST');
  } catch (_) {
    return false;
  }
}

/// Các tư thế & biểu cảm của linh thú Rồng ngọc Finora 3D
enum FinoraMascotPose {
  /// Rồng ngọc dang cánh bay cùng đồng xu vàng (Hero / Flying)
  hero('assets/mascot/animation-keypose-01-flying.png'),

  /// Vui vẻ - ôm đồng xu vàng cười tít mắt
  happy('assets/mascot/expression-01-happy.png'),

  /// Tự tin - mỉm cười đĩnh đạc cầm đồng xu vàng nhỏ
  confident('assets/mascot/expression-02-confident.png'),

  /// Tập trung - cầm máy tính bảng phân tích chi tiêu
  focused('assets/mascot/expression-03-focused.png'),
  thinking('assets/mascot/expression-03-focused.png'),
  card('assets/mascot/expression-02-confident.png'),

  /// Ăn mừng / Phấn khích - giơ hai tay cùng pháo hoa confetti
  celebrate('assets/mascot/expression-04-excited.png'),
  excited('assets/mascot/expression-04-excited.png'),

  /// Yêu thương - ôm trái tim đỏ gắn kết gia đình
  loving('assets/mascot/expression-05-loving.png'),

  /// Thư giãn - xoa bụng bình yên, thảnh thơi không âu lo
  relaxed('assets/mascot/expression-06-relaxed.png'),

  /// Đang bay lượn trên bầu trời (Keypose 01)
  flying('assets/mascot/animation-keypose-01-flying.png'),

  /// Ôm heo đất tiết kiệm (Keypose 02)
  saving('assets/mascot/animation-keypose-02-saving.png'),

  /// Đứng vững cạnh đồng xu tài lộc (Keypose 03)
  goal('assets/mascot/animation-keypose-03-goal.png'),

  /// Toàn cảnh gia đình 3 chú rồng ngọc sum họp (Keypose 04)
  family('assets/mascot/animation-keypose-04-family.png'),

  /// Minh họa Onboarding 01: Chào mừng
  welcome('assets/mascot/onboarding-01-welcome.png'),

  /// Minh họa Onboarding 02: Ngân sách & Tiết kiệm
  budget('assets/mascot/onboarding-02-budget.png'),

  /// Minh họa Onboarding 03: Gia đình cùng quản lý
  onboardingFamily('assets/mascot/onboarding-03-family.png'),

  /// Icon ứng dụng rồng Finora 3D nền ngọc lục bảo
  appIcon('assets/mascot/app-icon.png'),

  /// Biểu tượng thương hiệu Finora
  leafLogo('assets/mascot/app-icon.png');

  final String assetPath;
  const FinoraMascotPose(this.assetPath);
}

/// Bộ sticker cảm xúc của linh thú Rồng ngọc Finora
enum FinoraMascotSticker {
  coLen('assets/mascot/sticker-01-encourage.png', 'Cố lên!'),
  tietKiem('assets/mascot/sticker-02-save.png', 'Tiết kiệm nhé!'),
  tuyetVoi('assets/mascot/sticker-03-great.png', 'Tuyệt vời!'),
  kiemTra('assets/mascot/sticker-04-check.png', 'Đang kiểm tra chi tiêu...'),
  caNha('assets/mascot/sticker-05-family.png', 'Cả nhà cùng quản lý!'),
  mucTieu('assets/mascot/sticker-06-goal.png', 'Mục tiêu gần rồi!'),
  giaoDichThanhCong('assets/mascot/sticker-07-transaction-success.png', 'Đã thêm giao dịch!');

  final String assetPath;
  final String label;
  const FinoraMascotSticker(this.assetPath, this.label);
}

/// Bảng màu thương hiệu chuẩn theo Brand Sheet của Finora (Pine, Emerald, Mint & Gold - tuyệt đối không tím)
class FinoraBrandPalette {
  FinoraBrandPalette._();

  /// Xanh ngọc mint tươi sáng
  static const Color mintLight = Color(0xFF34D399);
  static const Color mintSoft = Color(0xFFBDEDD6);

  /// Xanh lục bảo rừng sâu chủ đạo (Primary Brand Color)
  static const Color forestEmerald = Color(0xFF0F6E56);
  static const Color deepEmerald = Color(0xFF0B4F3E);
  static const Color pinePrimary = Color(0xFF003D35);
  static const Color darkWordmark = Color(0xFF083A2C);

  /// Vàng kim tài lộc (Gold Accent)
  static const Color goldAccent = Color(0xFFF59E0B);
  static const Color goldLight = Color(0xFFFDE68A);

  /// Nền kem trắng ngọc ấm áp
  static const Color warmCream = Color(0xFFF9FBFA);

  /// Dải màu chuyển sắc thương hiệu Finora (Emerald -> Mint)
  static const List<Color> primaryGradient = [
    Color(0xFF0F6E56),
    Color(0xFF10B981),
  ];

  /// Dải màu chuyển sắc thẻ tổng quan tài chính chuẩn mẫu
  static const List<Color> heroEmeraldGradient = [
    Color(0xFF0D5C48),
    Color(0xFF147A60),
    Color(0xFF094234),
  ];

  /// Dải màu chuyển sắc linh vật Rồng ngọc (Emerald -> Mint)
  static const List<Color> mascotSignatureGradient = [
    Color(0xFF00866A),
    Color(0xFF34D399),
  ];
}

/// Widget hiển thị linh thú Finora đồng bộ toàn hệ thống theo ThemeStudioController
class FinoraMascotImage extends StatelessWidget {
  final FinoraMascotPose pose;
  final double size;
  final BoxFit fit;
  final bool showGlow;
  final bool? withGlow;
  final AppMascotCharacter? characterOverride;
  final bool forceShow;

  const FinoraMascotImage({
    super.key,
    this.pose = FinoraMascotPose.hero,
    this.size = 64,
    this.fit = BoxFit.contain,
    this.showGlow = false,
    this.withGlow,
    this.characterOverride,
    this.forceShow = false,
  });

  static FinoraMascotPose resolvePoseByName(
    String? name, [
    FinoraMascotPose fallback = FinoraMascotPose.hero,
  ]) {
    if (name == null || name.isEmpty) return fallback;
    for (final p in FinoraMascotPose.values) {
      if (p.name == name) return p;
    }
    return fallback;
  }

  String _chibiAssetForPose(FinoraMascotPose p) {
    switch (p) {
      case FinoraMascotPose.happy:
      case FinoraMascotPose.loving:
        return 'assets/mascot/mascot_happy.png';
      case FinoraMascotPose.confident:
      case FinoraMascotPose.card:
      case FinoraMascotPose.goal:
        return 'assets/mascot/mascot_confident.png';
      case FinoraMascotPose.focused:
      case FinoraMascotPose.thinking:
      case FinoraMascotPose.budget:
      case FinoraMascotPose.saving:
        return 'assets/mascot/mascot_focused.png';
      case FinoraMascotPose.celebrate:
      case FinoraMascotPose.excited:
        return 'assets/mascot/mascot_celebrate.png';
      case FinoraMascotPose.relaxed:
        return 'assets/mascot/mascot_relaxed.png';
      default:
        return 'assets/mascot/mascot_hero.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeStudioController? studio;
    try {
      studio = Provider.of<ThemeStudioController?>(context);
    } catch (_) {
      studio = null;
    }
    final character =
        characterOverride ?? studio?.mascotCharacter ?? AppMascotCharacter.jadeDragon3D;
    if (character == AppMascotCharacter.hidden && !forceShow) {
      return const SizedBox.shrink();
    }

    final effectivePose = (pose == FinoraMascotPose.hero &&
            characterOverride == null &&
            studio?.mascotDefaultPose != null)
        ? resolvePoseByName(studio!.mascotDefaultPose, pose)
        : pose;

    final effectiveGlow = withGlow ?? showGlow;
    final brandColor = studio?.resolvedPrimary ?? FinoraBrandPalette.mintLight;

    Widget img;
    switch (character) {
      case AppMascotCharacter.chibiClassic:
        img = Image.asset(
          _chibiAssetForPose(effectivePose),
          width: size,
          height: size,
          fit: fit,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => FioMascot(size: size),
        );
        break;
      case AppMascotCharacter.fioMinimalOrb:
      case AppMascotCharacter.luckyCat:
      case AppMascotCharacter.finoraLeaf:
      case AppMascotCharacter.jadeDragon3D:
      case AppMascotCharacter.hidden:
        img = Image.asset(
          effectivePose.assetPath,
          width: size,
          height: size,
          fit: fit,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => FioMascot(
            size: size,
            celebrate: effectivePose == FinoraMascotPose.celebrate ||
                effectivePose == FinoraMascotPose.happy ||
                effectivePose == FinoraMascotPose.excited,
          ),
        );
        break;
    }

    if (!effectiveGlow) return img;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: brandColor.withValues(alpha: 0.24),
            blurRadius: size * 0.35,
            spreadRadius: -4,
          ),
        ],
      ),
      child: img,
    );
  }
}

/// Widget hiển thị Sticker cảm xúc của Rồng ngọc Finora
class FinoraStickerBadge extends StatelessWidget {
  final FinoraMascotSticker sticker;
  final double size;

  const FinoraStickerBadge({
    super.key,
    required this.sticker,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      sticker.assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => FinoraMascotImage(
        pose: FinoraMascotPose.happy,
        size: size,
      ),
    );
  }
}

/// Banner đồng hành cùng linh thú Finora chuẩn mẫu "Trong app"
class FinoraCompanionBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final FinoraMascotPose pose;
  final double? progress;
  final VoidCallback? onTap;

  const FinoraCompanionBanner({
    super.key,
    this.title = 'Cùng Finora xây dựng tương lai tài chính vững vàng!',
    this.subtitle = 'Thông minh – Đáng tin – Luôn bên bạn',
    this.pose = FinoraMascotPose.hero,
    this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ThemeStudioController? studio;
    try {
      studio = Provider.of<ThemeStudioController?>(context);
    } catch (_) {
      studio = null;
    }
    if (studio?.mascotCharacter == AppMascotCharacter.hidden) {
      return const SizedBox.shrink();
    }
    final brandPrimary =
        studio?.resolvedPrimary ?? FinoraBrandPalette.forestEmerald;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE3EBE7),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: brandPrimary.withValues(alpha: isDark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: FinoraInteractive3DMascot(
                  pose: pose,
                  size: 58,
                  enableFloatingAnimation: true,
                  enableTouch3DRotation: true,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        letterSpacing: -0.2,
                        color: isDark
                            ? Colors.white
                            : FinoraBrandPalette.darkWordmark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Color.lerp(brandPrimary, Colors.white, 0.45)
                            : brandPrimary,
                      ),
                    ),
                    if (progress != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: progress!.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : brandPrimary.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            brandPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hình linh thú Rồng ngọc Finora 3D chìm sống động (Ambient 3D Watermark)
/// Tự động lơ lửng và thở 3D nhẹ nhàng trên thiết bị thật, tự tắt lặp trong môi trường test.
class FinoraAmbientMascotWatermark extends StatefulWidget {
  final FinoraMascotPose pose;
  final double size;
  final double opacity;
  final double rotation;
  final Alignment alignment;
  final Offset offset;
  final double? right;
  final double? bottom;

  const FinoraAmbientMascotWatermark({
    super.key,
    this.pose = FinoraMascotPose.hero,
    this.size = 132,
    this.opacity = 0.14,
    this.rotation = -0.08,
    this.alignment = Alignment.bottomRight,
    this.offset = const Offset(14, 12),
    this.right,
    this.bottom,
  });

  @override
  State<FinoraAmbientMascotWatermark> createState() =>
      _FinoraAmbientMascotWatermarkState();
}

class _FinoraAmbientMascotWatermarkState
    extends State<FinoraAmbientMascotWatermark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    );
    _syncAnimation(disableAnimations: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disable = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncAnimation(disableAnimations: disable);
  }

  void _syncAnimation({required bool disableAnimations}) {
    final shouldAnimate = !disableAnimations && !_isWatermarkTestEnv();
    if (shouldAnimate && !_animating) {
      _animating = true;
      _controller.repeat(reverse: true);
    } else if (!shouldAnimate && _animating) {
      _animating = false;
      _controller.stop();
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeStudioController? studio;
    try {
      studio = Provider.of<ThemeStudioController?>(context);
    } catch (_) {
      studio = null;
    }
    if (studio?.mascotCharacter == AppMascotCharacter.hidden ||
        studio?.showMascotWatermark == false) {
      return const SizedBox.shrink();
    }

    final effectiveOffset = (widget.right != null || widget.bottom != null)
        ? Offset(-(widget.right ?? -14), -(widget.bottom ?? -12))
        : widget.offset;

    return IgnorePointer(
      child: Align(
        alignment: widget.alignment,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            final hoverY = _animating ? math.sin(t * math.pi) * 3.0 : 0.0;
            final rotY = _animating ? (t - 0.5) * 0.08 : 0.0;

            final matrix = Matrix4.identity()
              ..setEntry(3, 2, 0.0018)
              ..multiply(Matrix4.translationValues(
                effectiveOffset.dx,
                effectiveOffset.dy - hoverY,
                0.0,
              ))
              ..rotateY(rotY)
              ..rotateZ(widget.rotation);

            return Transform(
              alignment: Alignment.center,
              transform: matrix,
              child: Opacity(
                opacity: widget.opacity.clamp(0.03, 0.45),
                child: RepaintBoundary(child: child),
              ),
            );
          },
          child: FinoraMascotImage(
            pose: widget.pose,
            size: widget.size,
            showGlow: false,
          ),
        ),
      ),
    );
  }
}
