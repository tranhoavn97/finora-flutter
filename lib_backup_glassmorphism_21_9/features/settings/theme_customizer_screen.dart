import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/v8/finora_v8.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../state/theme_studio_controller.dart';
import '../../state/theme_controller.dart';

class ThemeCustomizerScreen extends StatelessWidget {
  const ThemeCustomizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<ThemeStudioController>();
    final themeCtrl = context.watch<ThemeController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPalette = studio.currentPaletteMeta;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0B1220) : const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            FinoraPageHeader(
              title: 'Cá nhân hóa giao diện',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                physics: const BouncingScrollPhysics(),
                children: [
                  // LIVE CARD & AMBIENT PREVIEW SECTION
                  _buildLivePreview(context, studio, isDark, currentPalette),
                  const SizedBox(height: 22),

                  // SECTION 1: CHẾ ĐỘ HIỂN THỊ
                  _buildSectionTitle(
                    icon: Icons.brightness_6_rounded,
                    title: 'CHẾ ĐỘ HIỂN THỊ',
                    subtitle:
                        'Chuyển đổi giao diện Sáng, Tối Sapphire hoặc AMOLED Đen',
                    color: currentPalette.primary,
                  ),
                  const SizedBox(height: 10),
                  _buildThemeModeCard(context, themeCtrl, currentPalette, isDark),
                  const SizedBox(height: 22),

                  // SECTION 2: BACKGROUND GRADIENT BLUR
                  _buildSectionTitle(
                    icon: Icons.blur_on_rounded,
                    title: 'MÀU SẮC BACKGROUND GRADIENT BLUR',
                    subtitle:
                        'Tùy biến dải màu nền mờ và luồng ánh sáng trôi nổi toàn ứng dụng',
                    color: currentPalette.primary,
                  ),
                  const SizedBox(height: 10),
                  ...ThemeStudioController.ambientBlurPresets.map(
                    (p) => _buildAmbientBlurTile(context, studio, p, isDark),
                  ),
                  const SizedBox(height: 22),

                  // SECTION 3: BẢNG MÀU CHỦ ĐẠO (ACCENT PALETTE)
                  _buildSectionTitle(
                    icon: Icons.palette_rounded,
                    title: 'BẢNG MÀU CHỦ ĐẠO (ACCENT PALETTE)',
                    subtitle:
                        'Màu nhấn thương hiệu trên nút bấm, biểu đồ & thẻ chính',
                    color: currentPalette.primary,
                  ),
                  const SizedBox(height: 10),
                  ...ThemeStudioController.palettes.map(
                    (p) => _buildPaletteTile(context, studio, p, isDark),
                  ),
                  const SizedBox(height: 26),

                  // RESET BUTTON
                  Center(
                    child: TextButton.icon(
                      onPressed: () async {
                        await studio.resetToDefault();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Đã khôi phục cài đặt giao diện mặc định'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Khôi phục thiết kế ban đầu'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildLivePreview(
    BuildContext context,
    ThemeStudioController studio,
    bool isDark,
    PaletteMeta palette,
  ) {
    final blurMeta = studio.currentAmbientBlurMeta;
    final bgColors = isDark ? blurMeta.bgColorsDark : blurMeta.bgColorsLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: palette.primary.withValues(alpha: isDark ? 0.35 : 0.20),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.remove_red_eye_rounded,
                      size: 15, color: Color(0xFF64748B)),
                  SizedBox(width: 6),
                  Text(
                    'XEM TRƯỚC TRỰC TIẾP (LIVE PREVIEW)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  palette.title,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: palette.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Mini Preview with dynamic Ambient Background & Glow
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: bgColors,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Stack(
                children: [
                  if (blurMeta.preset != AmbientBlurPreset.amoledPitch) ...[
                    Positioned(
                      top: -10,
                      left: -10,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: blurMeta.orb1.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -10,
                      right: -10,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: blurMeta.orb2.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ],
                  Column(
                    children: [
                      // Mini Hero Card Preview
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: palette.heroGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: palette.primary.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Tổng tài sản khả dụng',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.trending_up_rounded,
                                          color: Colors.white, size: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        '+12.5%',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '125.450.000 ₫',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Nền: ${blurMeta.title}',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 10.5),
                                ),
                                const Spacer(),
                                const Text(
                                  'Finora Luxury Glass',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 10.5),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Mini Transaction Item Preview
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? const Color(0xFF0F172A)
                                  : Colors.white)
                              .withValues(alpha: isDark ? 0.75 : 0.85),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: palette.primary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.coffee_rounded,
                                  color: palette.primary, size: 16),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cà phê sáng Highlands',
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    'Ví Techcombank · Hôm nay',
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            const Text(
                              '-39.000 ₫',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientBlurTile(
    BuildContext context,
    ThemeStudioController studio,
    AmbientBlurMeta meta,
    bool isDark,
  ) {
    final isSelected = studio.ambientBlur == meta.preset;
    final primary = studio.primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => studio.setAmbientBlur(meta.preset),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? primary
                  : (isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0)),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Visual Gradient Preview Capsule
              Container(
                width: 56,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark ? meta.bgColorsDark : meta.bgColorsLight,
                  ),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                    width: 0.8,
                  ),
                ),
                child: Stack(
                  children: [
                    if (meta.orb1.a > 0)
                      Positioned(
                        top: 3,
                        left: 3,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: meta.orb1.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    if (meta.orb2.a > 0)
                      Positioned(
                        bottom: 3,
                        right: 3,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: meta.orb2.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    if (isSelected)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check_rounded,
                              color: primary, size: 14),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta.title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? primary
                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta.subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),

              // Indicator Badge
              if (isSelected)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'Đang chọn',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaletteTile(
    BuildContext context,
    ThemeStudioController studio,
    PaletteMeta palette,
    bool isDark,
  ) {
    final isSelected = studio.palette == palette.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => studio.setPalette(palette.palette),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? palette.primary
                  : (isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0)),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: palette.heroGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: palette.primary.withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      palette.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? palette.primary
                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      palette.subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'Đang chọn',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: palette.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeModeCard(
    BuildContext context,
    ThemeController themeCtrl,
    PaletteMeta palette,
    bool isDark,
  ) {
    final modes = [
      ('light', Icons.wb_sunny_rounded, 'Sáng'),
      ('dark', Icons.nightlight_round, 'Tối Sapphire'),
      ('amoled', Icons.brightness_2_rounded, 'AMOLED Đen'),
      ('system', Icons.settings_brightness_rounded, 'Tự động'),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.style_rounded, size: 16, color: palette.primary),
              ),
              const SizedBox(width: 8),
              const Text(
                'Tone màu & Nền hiển thị',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 10,
                children: modes.map((m) {
                  final isSelected = themeCtrl.mode == m.$1;
                  return SizedBox(
                    width: itemWidth,
                    child: InkWell(
                      onTap: () => themeCtrl.setMode(m.$1),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? palette.primary
                                  .withValues(alpha: isDark ? 0.25 : 0.12)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? palette.primary
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.10)
                                    : const Color(0xFFE2E8F0)),
                            width: isSelected ? 1.8 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              m.$2,
                              size: 17,
                              color: isSelected
                                  ? palette.primary
                                  : (isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                m.$3,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? palette.primary
                                      : (isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A)),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
