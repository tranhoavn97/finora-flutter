import 'package:flutter/material.dart';

/// Các tư thế biểu cảm của linh thú mèo Finora 3D
enum FinoraMascotPose {
  /// Chú mèo Finora ngồi cạnh ví xanh lục bảo và đồng xu vàng (Hero)
  hero('assets/mascot/mascot_hero.png'),

  /// Vui vẻ - ôm đồng xu vàng cười tít mắt
  happy('assets/mascot/mascot_happy.png'),

  /// Tự tin - nháy mắt giơ ngón cái
  confident('assets/mascot/mascot_confident.png'),

  /// Tập trung - cầm máy tính bảng phân tích chi tiêu
  focused('assets/mascot/mascot_focused.png'),

  /// Ăn mừng - nhảy lên giơ đồng xu vàng
  celebrate('assets/mascot/mascot_celebrate.png'),

  /// Thư giãn - ngồi nhắm mắt bình yên
  relaxed('assets/mascot/mascot_relaxed.png'),

  /// Icon ứng dụng mèo Finora nền ngọc lục bảo
  appIcon('assets/mascot/finora_cat_app_icon.png'),

  /// Biểu tượng chiếc lá kép Finora (Xanh mint & Tím hoàng gia)
  leafLogo('assets/mascot/finora_leaf_logo.png');

  final String assetPath;
  const FinoraMascotPose(this.assetPath);
}

/// Bộ sticker cảm xúc của linh thú mèo Finora
enum FinoraMascotSticker {
  coLen('assets/mascot/sticker_colen.png', 'Cố lên!'),
  tietKiem('assets/mascot/sticker_tietkiem.png', 'Tiết kiệm nhé!'),
  tuyetVoi('assets/mascot/sticker_tuyetvoi.png', 'Tuyệt vời!'),
  kiemTra('assets/mascot/sticker_kiemtra.png', 'Đang kiểm tra chi tiêu...'),
  caNha('assets/mascot/sticker_canha.png', 'Cả nhà cùng quản lý!'),
  mucTieu('assets/mascot/sticker_muctieu.png', 'Mục tiêu gần rồi!');

  final String assetPath;
  final String label;
  const FinoraMascotSticker(this.assetPath, this.label);
}

/// Bảng màu thương hiệu chuẩn theo Brand Sheet của Finora (Emerald Mint & Royal Violet)
class FinoraBrandPalette {
  FinoraBrandPalette._();

  /// Xanh ngọc mint tươi sáng (Circle 1)
  static const Color mintLight = Color(0xFF34D399);

  /// Xanh lục bảo rừng sâu chủ đạo (Circle 2 - Primary Brand Color)
  static const Color forestEmerald = Color(0xFF0F6E56);
  static const Color deepEmerald = Color(0xFF0B4F3E);
  static const Color darkWordmark = Color(0xFF083A2C);

  /// Tím thạch anh hoàng gia điểm xuyết (Circle 3 - Secondary Brand Color)
  static const Color royalViolet = Color(0xFF6D28D9);
  static const Color vibrantViolet = Color(0xFF7C3AED);

  /// Tím oải hương pastel dịu (Circle 4)
  static const Color softLavender = Color(0xFFC4B5FD);

  /// Nền kem trắng ngọc ấm áp (Circle 5)
  static const Color warmCream = Color(0xFFF6F9F7);

  /// Dải màu chuyển sắc thương hiệu Finora (Emerald -> Mint)
  static const List<Color> primaryGradient = [
    Color(0xFF0F6E56),
    Color(0xFF10B981),
  ];

  /// Dải màu chuyển sắc thẻ tổng quan tài chính chuẩn mẫu "Trong app"
  static const List<Color> heroEmeraldGradient = [
    Color(0xFF0D5C48),
    Color(0xFF147A60),
    Color(0xFF094234),
  ];

  /// Dải màu chuyển sắc kép Emerald - Violet đặc trưng của chỏm tóc & đuôi linh thú
  static const List<Color> mascotSignatureGradient = [
    Color(0xFF10B981),
    Color(0xFF7C3AED),
  ];
}

/// Widget hiển thị linh thú mèo Finora 3D với hiệu ứng bóng đổ mềm tự nhiên
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
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
      errorBuilder: (_, __, ___) => Icon(
        Icons.pets_rounded,
        size: size * 0.6,
        color: FinoraBrandPalette.forestEmerald,
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

/// Widget hiển thị Sticker cảm xúc của mèo Finora
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
