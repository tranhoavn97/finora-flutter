import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/premium_widgets.dart';
import '../../state/theme_controller.dart';
import '../../state/theme_studio_controller.dart';

class SettingsScreen extends StatelessWidget {
  final String userId;
  const SettingsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    final studio = context.watch<ThemeStudioController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const displayModes = [
      ('light', 'Sáng'),
      ('dark', 'Tối'),
      ('amoled', 'AMOLED'),
    ];

    const swatches = [
      ('#005FEA', AppColorPalette.oceanicSapphire, Color(0xFF005FEA)),
      ('#138875', AppColorPalette.emeraldWealth, Color(0xFF138875)),
      ('#BF8331', AppColorPalette.obsidianGold, Color(0xFFBF8331)),
      ('#C86359', AppColorPalette.sunsetCoral, Color(0xFFC86359)),
    ];

    const bgPresets = [
      ('Sương trắng', AmbientBlurPreset.sapphireCyan),
      ('Cát ấm', AmbientBlurPreset.sunsetAmber),
      ('Xanh nhạt', AmbientBlurPreset.midnightAurora),
    ];

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF14273A) : const Color(0xFFF1F6FA),
      body: AmbientFloatingBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Soft Header: head('Giao diện', 'Một Finora hợp với bạn')
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E3146) : Colors.white,
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2E455C) : const Color(0xFFDCE7F0),
                          ),
                        ),
                        child: Icon(
                          LucideIcons.chevron_left,
                          size: 20,
                          color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Giao diện',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Một Finora hợp với bạn',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFFABC0D3) : const Color(0xFF7A90A5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Settings Content
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  children: [
                    // Angled Live Preview Card matching app.js (#themePreview)
                    Center(
                      child: Transform.rotate(
                        angle: -0.04,
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                studio.primaryColor,
                                studio.secondaryColor,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: studio.primaryColor.withValues(alpha: 0.35),
                                blurRadius: 25,
                                offset: const Offset(0, 14),
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
                                    'FINORA / CỦA BẠN',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Icon(
                                    isDark ? LucideIcons.moon : LucideIcons.sun,
                                    size: 16,
                                    color: Colors.white70,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              const Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '42.850.000',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '₫',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Không gian tài chính mỗi ngày',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 1: Chế độ hiển thị
                    _buildSectionTitle('Chế độ hiển thị', isDark),
                    const SizedBox(height: 8),
                    Container(
                      height: 44,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E3146) : const Color(0xFFE4EDF4),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: displayModes.map((m) {
                          final selected = theme.mode == m.$1;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => theme.setMode(m.$1),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? (isDark ? const Color(0xFF2A4460) : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.06),
                                            blurRadius: 4,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    m.$2,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                      color: selected
                                          ? (isDark ? Colors.white : const Color(0xFF233D58))
                                          : (isDark ? const Color(0xFFABC0D3) : const Color(0xFF7A90A5)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Bản xem trước thay đổi theo chế độ bạn chọn.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFFABC0D3) : const Color(0xFF7A90A5),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Section 2: Màu chủ đạo
                    _buildSectionTitle('Màu chủ đạo', isDark),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: swatches.map((s) {
                        final isSelected = studio.palette == s.$2;
                        return GestureDetector(
                          onTap: () => studio.setPalette(s.$2),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: s.$3,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: s.$3.withValues(alpha: 0.5),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                              ],
                            ),
                            child: isSelected
                                ? const Center(
                                    child: Icon(LucideIcons.check, color: Colors.white, size: 22),
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Section 3: Màu nền
                    _buildSectionTitle('Màu nền', isDark),
                    const SizedBox(height: 8),
                    Container(
                      height: 44,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E3146) : const Color(0xFFE4EDF4),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: bgPresets.map((b) {
                          final selected = studio.ambientBlur == b.$2;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => studio.setAmbientBlur(b.$2),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? (isDark ? const Color(0xFF2A4460) : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.06),
                                            blurRadius: 4,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    b.$1,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                      color: selected
                                          ? (isDark ? Colors.white : const Color(0xFF233D58))
                                          : (isDark ? const Color(0xFFABC0D3) : const Color(0xFF7A90A5)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Live Status Card matching app.js
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1B2C3E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2B3F55) : const Color(0xFFE4EDF4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE4EFEA),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Center(
                              child: Icon(
                                LucideIcons.check,
                                color: Color(0xFF138875),
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Xem trước trực tiếp',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Lựa chọn được tự động lưu trên thiết bị',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? const Color(0xFFABC0D3) : const Color(0xFF7A90A5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
      ),
    );
  }
}
