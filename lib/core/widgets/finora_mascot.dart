import 'fresh_design.dart';
import 'package:flutter/material.dart';

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

/// Widget hiển thị linh thú Rồng ngọc Finora 3D với hiệu ứng bóng đổ mềm tự nhiên
class FinoraMascotImage extends StatelessWidget {
  final FinoraMascotPose pose;
  final double size;
  final BoxFit fit;
  final bool showGlow;
  final bool? withGlow;

  const FinoraMascotImage({
    super.key,
    this.pose = FinoraMascotPose.hero,
    this.size = 64,
    this.fit = BoxFit.contain,
    this.showGlow = false,
    this.withGlow,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGlow = withGlow ?? showGlow;
    final img = Image.asset(
      pose.assetPath,
      width: size,
      height: size,
      fit: fit,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => FioMascot(
        size: size,
        celebrate: pose == FinoraMascotPose.celebrate ||
            pose == FinoraMascotPose.happy ||
            pose == FinoraMascotPose.excited,
      ),
    );

    if (!effectiveGlow) return img;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: FinoraBrandPalette.mintLight.withValues(alpha: 0.22),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121A17) : Colors.white,
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
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F6E56).withValues(alpha: 0.18)
                      : const Color(0xFFEFF7F4),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: FinoraMascotImage(
                  pose: pose,
                  size: 56,
                  showGlow: false,
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
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFFA7F3D0)
                            : FinoraBrandPalette.forestEmerald,
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
                              : FinoraBrandPalette.forestEmerald
                                  .withValues(alpha: 0.12),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF10B981),
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

/// Hình linh thú Rồng ngọc Finora chìm (Ambient Watermark) dùng để trang trí tinh tế
/// bên trong các Widget lớn (Hero Card Trang chủ, Tài sản, Kế hoạch, Gia đình, AI...).
class FinoraAmbientMascotWatermark extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final effectiveOffset = (right != null || bottom != null)
        ? Offset(-(right ?? -14), -(bottom ?? -12))
        : offset;
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Transform.translate(
          offset: effectiveOffset,
          child: Transform.rotate(
            angle: rotation,
            child: Opacity(
              opacity: opacity.clamp(0.03, 0.45),
              child: FinoraMascotImage(
                pose: pose,
                size: size,
                showGlow: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
