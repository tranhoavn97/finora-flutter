import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/finora_mascot.dart';
import '../../core/widgets/finora_member_filter.dart';
import '../../core/widgets/finora_notice.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../state/theme_controller.dart';
import '../../state/theme_studio_controller.dart';
import '../dashboard/extended_hero_cards.dart';

class SettingsScreen extends StatefulWidget {
  final String userId;
  final bool advanced;
  const SettingsScreen(
      {super.key, required this.userId, this.advanced = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedZoneIndex =
      0; // 0: Vùng 1 (Trên), 1: Vùng 2 (Phải), 2: Vùng 3 (Dưới)
  late final TextEditingController _husbandNameCtrl;
  late final TextEditingController _wifeNameCtrl;
  final FocusNode _husbandNameFocus = FocusNode();
  final FocusNode _wifeNameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final studio = context.read<ThemeStudioController>();
    _husbandNameCtrl = TextEditingController(text: studio.husbandName);
    _wifeNameCtrl = TextEditingController(text: studio.wifeName);
    _husbandNameFocus.addListener(_onMemberNameFocusChange);
    _wifeNameFocus.addListener(_onMemberNameFocusChange);
  }

  void _onMemberNameFocusChange() {
    if (!_husbandNameFocus.hasFocus && !_wifeNameFocus.hasFocus && mounted) {
      context.read<ThemeStudioController>().notifyMemberNamesChanged();
    }
  }

  @override
  void dispose() {
    _husbandNameFocus.removeListener(_onMemberNameFocusChange);
    _wifeNameFocus.removeListener(_onMemberNameFocusChange);
    _husbandNameFocus.dispose();
    _wifeNameFocus.dispose();
    _husbandNameCtrl.dispose();
    _wifeNameCtrl.dispose();
    super.dispose();
  }

  static const _modes = [
    (
      'system',
      'Theo thiết bị',
      Icons.phone_android_rounded,
      'Tự động theo máy'
    ),
    ('light', 'Sáng', Icons.light_mode_rounded, 'Trắng pha ngọc/biển'),
    ('dark', 'Tối', Icons.dark_mode_rounded, 'Titanium OLED'),
  ];

  static const List<_RgbPresetItem> _presets = [
    _RgbPresetItem(
      name: 'Thạch Anh Hồng (Rose Quartz)',
      c1: Color(0xFFF472B6),
      c2: Color(0xFF0EA5E9),
      c3: Color(0xFF38BDF8),
      intensity: 0.22,
    ),
    _RgbPresetItem(
      name: 'Thạch Anh Lam Ngọc (Sapphire)',
      c1: Color(0xFF0284C7),
      c2: Color(0xFF0EA5E9),
      c3: Color(0xFF10B981),
      intensity: 0.22,
    ),
    _RgbPresetItem(
      name: 'Thạch Anh Ngọc Lục (Jade Quartz)',
      c1: Color(0xFF34D399),
      c2: Color(0xFF2DD4BF),
      c3: Color(0xFF38BDF8),
      intensity: 0.22,
    ),
    _RgbPresetItem(
      name: 'Thạch Anh Hoàng Kim (Citrine)',
      c1: Color(0xFFFBBF24),
      c2: Color(0xFFF472B6),
      c3: Color(0xFF60A5FA),
      intensity: 0.20,
    ),
    _RgbPresetItem(
      name: 'Thạch Anh Khói (Smoky Quartz)',
      c1: Color(0xFF94A3B8),
      c2: Color(0xFF0EA5E9),
      c3: Color(0xFF2DD4BF),
      intensity: 0.18,
    ),
    _RgbPresetItem(
      name: 'Trắng pha Xanh Ngọc',
      c1: Color(0xFF10B981),
      c2: Color(0xFF00C2FA),
      c3: Color(0xFF059669),
      intensity: 0.20,
    ),
    _RgbPresetItem(
      name: 'Trắng pha Xanh Biển',
      c1: Color(0xFF005FEA),
      c2: Color(0xFF0284C7),
      c3: Color(0xFF38BDF8),
      intensity: 0.18,
    ),
    _RgbPresetItem(
      name: 'Tối Giản Bạch Kim',
      c1: Color(0xFF64748B),
      c2: Color(0xFF94A3B8),
      c3: Color(0xFFCBD5E1),
      intensity: 0.14,
    ),
    _RgbPresetItem(
      name: 'Hoàng Hôn Ruby',
      c1: Color(0xFFF43F5E),
      c2: Color(0xFFF59E0B),
      c3: Color(0xFFFB7185),
      intensity: 0.20,
    ),
    _RgbPresetItem(
      name: 'Bắc Cực Quang',
      c1: Color(0xFF0D9488),
      c2: Color(0xFF0EA5E9),
      c3: Color(0xFF34D399),
      intensity: 0.20,
    ),
    _RgbPresetItem(
      name: 'Hổ Phách Ấm',
      c1: Color(0xFFF59E0B),
      c2: Color(0xFFEA580C),
      c3: Color(0xFFEF4444),
      intensity: 0.18,
    ),
    _RgbPresetItem(
      name: 'Bắc Cực Băng',
      c1: Color(0xFF38BDF8),
      c2: Color(0xFF0284C7),
      c3: Color(0xFF2DD4BF),
      intensity: 0.18,
    ),
    _RgbPresetItem(
      name: 'Cyberpunk Neon',
      c1: Color(0xFF06B6D4),
      c2: Color(0xFF10B981),
      c3: Color(0xFF84CC16),
      intensity: 0.22,
    ),
    _RgbPresetItem(
      name: 'Hoa Anh Đào',
      c1: Color(0xFFFB7185),
      c2: Color(0xFFF472B6),
      c3: Color(0xFFFDA4AF),
      intensity: 0.20,
    ),
    _RgbPresetItem(
      name: 'Rừng Thông',
      c1: Color(0xFF059669),
      c2: Color(0xFF0D9488),
      c3: Color(0xFF047857),
      intensity: 0.18,
    ),
    _RgbPresetItem(
      name: 'Trà Đào Vàng',
      c1: Color(0xFFFB923C),
      c2: Color(0xFFF43F5E),
      c3: Color(0xFFFBBF24),
      intensity: 0.18,
    ),
    _RgbPresetItem(
      name: 'Midnight Sapphire',
      c1: Color(0xFF0F172A),
      c2: Color(0xFF0C4A6E),
      c3: Color(0xFF134E4A),
      intensity: 0.25,
    ),
    _RgbPresetItem(
      name: 'Tối Giản Slate',
      c1: Color(0xFF64748B),
      c2: Color(0xFF94A3B8),
      c3: Color(0xFF0EA5E9),
      intensity: 0.12,
    ),
  ];

  static const List<Color> _swatches = [
    Color(0xFF10B981), // Emerald
    Color(0xFF34D399), // Mint
    Color(0xFF059669), // Dark Emerald
    Color(0xFF0D9488), // Teal
    Color(0xFF0EA5E9), // Sky Blue
    Color(0xFF0284C7), // Sapphire
    Color(0xFF2563EB), // Cobalt Blue
    Color(0xFF06B6D4), // Cyan
    Color(0xFF0F6E56), // Deep Emerald
    Color(0xFF14B8A6), // Sea Green
    Color(0xFF0891B2), // Ocean Cyan
    Color(0xFF0369A1), // Deep Sky
    Color(0xFFEC4899), // Pink
    Color(0xFFF43F5E), // Rose
    Color(0xFFE11D48), // Crimson
    Color(0xFFEA580C), // Deep Orange
    Color(0xFFF59E0B), // Amber
    Color(0xFFEAB308), // Gold Yellow
    Color(0xFF84CC16), // Lime Green
    Color(0xFF2DD4BF), // Bright Teal
    Color(0xFF475569), // Slate
    Color(0xFF64748B), // Slate Muted
    Color(0xFF94A3B8), // Slate Light
    Color(0xFF1E293B), // Obsidian
  ];

  Color _activeColor(ThemeStudioController studio) {
    switch (_selectedZoneIndex) {
      case 0:
        return studio.customBgColor1;
      case 1:
        return studio.customBgColor2;
      default:
        return studio.customBgColor3;
    }
  }

  void _updateActiveColor(ThemeStudioController studio, Color color) {
    if (_selectedZoneIndex == 0) {
      studio.setCustomBgColor1(color);
    } else if (_selectedZoneIndex == 1) {
      studio.setCustomBgColor2(color);
    } else {
      studio.setCustomBgColor3(color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    final studio = context.watch<ThemeStudioController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = (isDark ? const Color(0xFF121A17) : Colors.white)
        .withValues(alpha: studio.glassOpacity);
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0);

    final activeColor = _activeColor(studio);
    final rVal = (activeColor.r * 255.0).round().clamp(0, 255);
    final gVal = (activeColor.g * 255.0).round().clamp(0, 255);
    final bVal = (activeColor.b * 255.0).round().clamp(0, 255);
    final hexString =
        '#${activeColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    if (!_husbandNameFocus.hasFocus &&
        _husbandNameCtrl.text != studio.husbandName) {
      _husbandNameCtrl.text = studio.husbandName;
    }
    if (!_wifeNameFocus.hasFocus && _wifeNameCtrl.text != studio.wifeName) {
      _wifeNameCtrl.text = studio.wifeName;
    }

    return GlassScaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassTopBar(
        title: 'Giao diện',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          studio.pageHorizontalMargin,
          GlassScaffold.topInset(context, 10),
          studio.pageHorizontalMargin,
          32,
        ),
        children: [
          // ==========================================
          // PHÂN HỆ 1: CHẾ ĐỘ HIỂN THỊ & CỠ CHỮ (THEME & TYPOGRAPHY)
          // ==========================================
          _buildSectionHeader(
            title: 'Chế độ hiển thị & Giao diện',
            subtitle: 'Sáng trong & Đồng bộ toàn hệ thống',
            icon: Icons.palette_rounded,
            color: studio.resolvedPrimary,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
          ),
          const SizedBox(height: 12),
          Row(
            children: _modes.map((item) {
              final isSelected = theme.mode == item.$1;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        theme.setMode(item.$1);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? studio.resolvedPrimary
                                  .withValues(alpha: isDark ? 0.22 : 0.12)
                              : cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? studio.resolvedPrimary
                                : borderColor,
                            width: isSelected ? 1.6 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: studio.resolvedPrimary
                                        .withValues(alpha: 0.20),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? studio.resolvedPrimary
                                    : (isDark
                                        ? Colors.white10
                                        : const Color(0xFFF1F5F9)),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item.$3,
                                size: 18,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white70
                                        : const Color(0xFF475569)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? studio.resolvedPrimary
                                    : primaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cỡ chữ hiển thị',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                    Text(
                      '${(studio.fontScale * 100).round()}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: studio.resolvedPrimary,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: studio.resolvedPrimary,
                    inactiveTrackColor:
                        isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    thumbColor: Colors.white,
                    trackHeight: 5,
                  ),
                  child: Slider(
                    value: studio.fontScale.clamp(0.9, 1.25),
                    min: 0.9,
                    max: 1.25,
                    divisions: 7,
                    label: '${(studio.fontScale * 100).round()}%',
                    onChanged: studio.setFontScale,
                  ),
                ),
                  const Divider(height: 12),
                  Material(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            'Hiệu ứng chuyển trang mượt',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: primaryTextColor,
                            ),
                          ),
                          subtitle: Text(
                            'Giảm chuyển động',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: secondaryTextColor,
                            ),
                          ),
                          value: studio.motionDynamics !=
                              AppMotionDynamics.reducedMotion,
                          onChanged: (value) => studio.setMotionDynamics(value
                              ? AppMotionDynamics.smoothGentle
                              : AppMotionDynamics.reducedMotion),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            'Dùng giao diện cá nhân hóa',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: primaryTextColor,
                            ),
                          ),
                          subtitle: Text(
                            'Tùy chỉnh nâng cao',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: secondaryTextColor,
                            ),
                          ),
                          value: studio.useCustomRgbMeshBg,
                          onChanged: studio.setUseCustomRgbMeshBg,
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            'Phản hồi rung xúc giác (Haptic)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: primaryTextColor,
                            ),
                          ),
                          value: studio.hapticEnabled,
                          onChanged: studio.setHapticEnabled,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==========================================
            // PHÂN HỆ 1.2: MÀU SẮC CHỦ ĐẠO TOÀN HỆ THỐNG (SYSTEM PRIMARY COLOR)
            // ==========================================
            _buildSectionHeader(
              title: 'MÀU SẮC CHỦ ĐẠO TOÀN HỆ THỐNG',
              subtitle:
                  'Đồng bộ tức thì màu nút bấm, thẻ Hero, biểu đồ, viền sáng và hào quang nền',
              icon: Icons.color_lens_rounded,
              color: studio.resolvedPrimary,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: studio.currentPaletteMeta.heroGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: studio.resolvedPrimary
                                  .withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studio.currentPaletteMeta.title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              studio.currentPaletteMeta.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (studio.customPrimaryAccentColor != null)
                        TextButton(
                          onPressed: () =>
                              studio.setCustomPrimaryAccentColor(null),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Mặc định',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: studio.resolvedPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 68,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: ThemeStudioController.palettes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final p = ThemeStudioController.palettes[idx];
                        final selected =
                            studio.customPrimaryAccentColor == null &&
                                studio.palette == p.palette;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            studio.setPalette(p.palette);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 124,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? p.primary
                                      .withValues(alpha: isDark ? 0.22 : 0.10)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected ? p.primary : borderColor,
                                width: selected ? 1.8 : 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: p.heroGradient,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (selected)
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 16,
                                        color: p.primary,
                                      ),
                                  ],
                                ),
                                Text(
                                  p.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: selected
                                        ? FontWeight.w800
                                        : FontWeight.w700,
                                    color: selected
                                        ? p.primary
                                        : primaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'CHỌN NHANH MÀU CHỦ ĐẠO TUỲ BIẾN',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _swatches.map((swatch) {
                      final isSelected = studio.resolvedPrimary.toARGB32() ==
                          swatch.toARGB32();
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          studio.setCustomPrimaryAccentColor(swatch);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: swatch,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? (isDark ? Colors.white : Colors.black87)
                                  : Colors.white.withValues(alpha: 0.25),
                              width: isSelected ? 2.5 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: swatch.withValues(alpha: 0.45),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==========================================
            // PHÂN HỆ 1.3: KIỂU THẺ TỔNG TÀI SẢN TRANG CHỦ
            // ==========================================
            _buildSectionHeader(
              title: 'KIỂU THẺ TỔNG TÀI SẢN TRANG CHỦ',
              subtitle:
                  'Chọn 12 phong cách thẻ số dư (gồm 4 kiểu mới Aurora, Titanium, Porcelain & Horizon)',
              icon: Icons.style_rounded,
              color: studio.resolvedPrimary,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Builder(
                builder: (context) {
                  final newStyles =
                      kFinoraHeroStyleCatalog.where((e) => e.isNew).toList();
                  final classicStyles =
                      kFinoraHeroStyleCatalog.where((e) => !e.isNew).toList();
                  final activeMeta = kFinoraHeroStyleCatalog.firstWhere(
                    (e) => e.style == studio.heroCardStyle,
                    orElse: () => kFinoraHeroStyleCatalog.first,
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active Hero Card banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: studio.resolvedPrimary
                              .withValues(alpha: isDark ? 0.14 : 0.07),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                studio.resolvedPrimary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: LinearGradient(
                                  colors: activeMeta.previewColors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Icon(
                                activeMeta.icon,
                                size: 15,
                                color: activeMeta.style ==
                                        AppHeroCardStyle.porcelainMinimal
                                    ? const Color(0xFF0F172A)
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activeMeta.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                  Text(
                                    activeMeta.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: studio.resolvedPrimary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'ĐANG DÙNG',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '4 KIỂU THẺ MỚI ĐẶC BIỆT',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          mainAxisExtent: 106,
                        ),
                        itemCount: newStyles.length,
                        itemBuilder: (context, idx) {
                          final item = newStyles[idx];
                          final selected = studio.heroCardStyle == item.style;
                          final isPorcelain =
                              item.style == AppHeroCardStyle.porcelainMinimal;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              studio.setHeroCardStyle(item.style);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? studio.resolvedPrimary
                                        .withValues(alpha: isDark ? 0.18 : 0.08)
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.04)
                                        : const Color(0xFFF8FAFC)),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selected
                                      ? studio.resolvedPrimary
                                      : borderColor,
                                  width: selected ? 1.8 : 1.0,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          gradient: LinearGradient(
                                            colors: item.previewColors,
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          border: Border.all(
                                            color: isPorcelain
                                                ? const Color(0xFFCBD5E1)
                                                : Colors.white
                                                    .withValues(alpha: 0.30),
                                          ),
                                        ),
                                        child: Icon(
                                          item.icon,
                                          size: 12,
                                          color: isPorcelain
                                              ? const Color(0xFF0F172A)
                                              : Colors.white,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? studio.resolvedPrimary
                                              : studio.resolvedPrimary
                                                  .withValues(alpha: 0.14),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          selected ? 'ĐÃ CHỌN' : 'MỚI',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: selected
                                                ? Colors.white
                                                : studio.resolvedPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: selected
                                          ? studio.resolvedPrimary
                                          : primaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      height: 1.2,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'CÁC PHONG CÁCH CỔ ĐIỂN & SIGNATURE',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 76,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: classicStyles.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final item = classicStyles[idx];
                            final selected = studio.heroCardStyle == item.style;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                studio.setHeroCardStyle(item.style);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                width: 132,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? studio.resolvedPrimary.withValues(
                                          alpha: isDark ? 0.18 : 0.10)
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.04)
                                          : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: selected
                                        ? studio.resolvedPrimary
                                        : borderColor,
                                    width: selected ? 1.6 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            gradient: LinearGradient(
                                              colors: item.previewColors,
                                            ),
                                          ),
                                          child: Icon(
                                            item.icon,
                                            size: 10,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (selected)
                                          Icon(
                                            Icons.check_circle_rounded,
                                            size: 15,
                                            color: studio.resolvedPrimary,
                                          ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: selected
                                            ? studio.resolvedPrimary
                                            : primaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ==========================================
            // PHÂN HỆ 1.4: LINH VẬT ĐỒNG HÀNH TOÀN HỆ THỐNG (MASCOT STUDIO)
            // ==========================================
            _buildSectionHeader(
              title: 'LINH VẬT ĐỒNG HÀNH TOÀN HỆ THỐNG',
              subtitle:
                  'Tuỳ biến nhân vật linh thú, tư thế biểu cảm & hiệu ứng xuất hiện trên toàn ứng dụng',
              icon: Icons.pets_rounded,
              color: studio.resolvedPrimary,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Builder(
                builder: (context) {
                  const poseList = [
                    ('hero', 'Bay lượn (Hero)'),
                    ('happy', 'Vui vẻ'),
                    ('confident', 'Tự tin'),
                    ('focused', 'Tập trung'),
                    ('celebrate', 'Ăn mừng'),
                    ('saving', 'Tiết kiệm'),
                    ('goal', 'Mục tiêu'),
                    ('family', 'Gia đình'),
                    ('relaxed', 'Thảnh thơi'),
                  ];
                  final activePoseLabel = poseList
                      .firstWhere(
                        (e) => e.$1 == studio.mascotDefaultPose,
                        orElse: () => poseList.first,
                      )
                      .$2;
                  final activeCharacterTitle = switch (studio.mascotCharacter) {
                    AppMascotCharacter.jadeDragon3D => 'Rồng Ngọc 3D',
                    AppMascotCharacter.chibiClassic => 'Tiểu Rồng Chibi',
                    AppMascotCharacter.hidden => 'Đã ẩn Linh Vật',
                    _ => 'Rồng Ngọc 3D',
                  };
                  final isHidden =
                      studio.mascotCharacter == AppMascotCharacter.hidden;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Live companion preview showcase banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              studio.resolvedPrimary
                                  .withValues(alpha: isDark ? 0.20 : 0.10),
                              studio.resolvedSecondary
                                  .withValues(alpha: isDark ? 0.10 : 0.04),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                studio.resolvedPrimary.withValues(alpha: 0.24),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.white,
                                border: Border.all(
                                  color: studio.resolvedPrimary
                                      .withValues(alpha: 0.35),
                                  width: 1.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: isHidden
                                  ? Icon(
                                      Icons.visibility_off_rounded,
                                      size: 26,
                                      color: secondaryTextColor,
                                    )
                                  : FinoraMascotImage(
                                      pose: FinoraMascotImage.resolvePoseByName(
                                          studio.mascotDefaultPose),
                                      size: 48,
                                      forceShow: true,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          activeCharacterTitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                            color: primaryTextColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isHidden
                                              ? secondaryTextColor
                                                  .withValues(alpha: 0.14)
                                              : studio.resolvedPrimary,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          isHidden ? 'ĐANG ẨN' : 'ĐANG BẬT',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w900,
                                            color: isHidden
                                                ? secondaryTextColor
                                                : Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isHidden
                                        ? 'Chế độ tối giản — không hiển thị linh vật ở màn hình'
                                        : 'Biểu cảm mặc định: $activePoseLabel',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Spacious 3-column selector row
                      Row(
                        children: [
                          for (final (idx, item) in const [
                            (
                              AppMascotCharacter.jadeDragon3D,
                              'Rồng Ngọc 3D',
                              'Chính thức'
                            ),
                            (
                              AppMascotCharacter.chibiClassic,
                              'Tiểu Rồng Chibi',
                              'Đáng yêu'
                            ),
                            (
                              AppMascotCharacter.hidden,
                              'Ẩn Linh Vật',
                              'Tối giản'
                            ),
                          ].indexed) ...[
                            if (idx > 0) const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  studio.setMascotCharacter(item.$1);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: studio.mascotCharacter == item.$1
                                        ? studio.resolvedPrimary.withValues(
                                            alpha: isDark ? 0.20 : 0.10)
                                        : (isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.04)
                                            : const Color(0xFFF8FAFC)),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: studio.mascotCharacter == item.$1
                                          ? studio.resolvedPrimary
                                          : borderColor,
                                      width: studio.mascotCharacter == item.$1
                                          ? 1.8
                                          : 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: studio.mascotCharacter ==
                                                  item.$1
                                              ? studio.resolvedPrimary
                                                  .withValues(alpha: 0.12)
                                              : (isDark
                                                  ? Colors.white
                                                      .withValues(alpha: 0.05)
                                                  : Colors.white),
                                        ),
                                        alignment: Alignment.center,
                                        child: item.$1 ==
                                                AppMascotCharacter.hidden
                                            ? Icon(
                                                Icons.visibility_off_rounded,
                                                size: 24,
                                                color:
                                                    studio.mascotCharacter ==
                                                            item.$1
                                                        ? studio.resolvedPrimary
                                                        : secondaryTextColor,
                                              )
                                            : FinoraMascotImage(
                                                pose: FinoraMascotImage
                                                    .resolvePoseByName(
                                                        studio
                                                            .mascotDefaultPose),
                                                size: 40,
                                                characterOverride: item.$1,
                                                forceShow: true,
                                              ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        item.$2,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: studio.mascotCharacter ==
                                                  item.$1
                                              ? studio.resolvedPrimary
                                              : primaryTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.$3,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (!isHidden) ...[
                        const SizedBox(height: 14),
                        Text(
                          'TƯ THẾ & BIỂU CẢM MẶC ĐỊNH',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final poseItem in poseList)
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  studio.setMascotDefaultPose(poseItem.$1);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: studio.mascotDefaultPose ==
                                            poseItem.$1
                                        ? studio.resolvedPrimary
                                        : (isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.06)
                                            : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: studio.mascotDefaultPose ==
                                              poseItem.$1
                                          ? studio.resolvedPrimary
                                          : borderColor,
                                    ),
                                  ),
                                  child: Text(
                                    poseItem.$2,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: studio.mascotDefaultPose ==
                                              poseItem.$1
                                          ? Colors.white
                                          : primaryTextColor,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                          ),
                          child: Material(
                            type: MaterialType.transparency,
                            child: SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              activeTrackColor: studio.resolvedPrimary,
                              title: Text(
                                'Hiển thị hình chìm linh vật (Watermark 3D)',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: primaryTextColor,
                                ),
                              ),
                              subtitle: Text(
                                'Trang trí nhẹ nhàng ở góc các thẻ tổng quan & màn hình',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: secondaryTextColor,
                                ),
                              ),
                              value: studio.showMascotWatermark,
                              onChanged: studio.setShowMascotWatermark,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ==========================================
            // PHÂN HỆ 1.5: ĐẶT TÊN HIỂN THỊ THÀNH VIÊN (CHỒNG / VỢ)
            // ==========================================
            _buildSectionHeader(
              title: 'ĐẶT TÊN THÀNH VIÊN GIA ĐÌNH',
              subtitle:
                  'Hiển thị rút gọn ở mọi nút lọc: Tất cả · ${studio.husbandDisplayLabel} · ${studio.wifeDisplayLabel}',
              icon: Icons.people_alt_rounded,
              color: const Color(0xFF0284C7),
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _husbandNameCtrl,
                          focusNode: _husbandNameFocus,
                          textInputAction: TextInputAction.next,
                          onChanged: (v) {
                            studio.setHusbandName(v, notify: false);
                            setState(() {});
                          },
                          onSubmitted: (v) {
                            studio.setHusbandName(v, notify: true);
                          },
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Tên Chồng',
                            hintText: 'VD: Minh',
                            isDense: true,
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(8),
                              child: FinoraMemberAvatar(
                                member: 'husband',
                                size: 22,
                                isDark: isDark,
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 38,
                              minHeight: 38,
                            ),
                            suffixIcon: _husbandNameCtrl.text.isNotEmpty
                                ? IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 28,
                                      minHeight: 28,
                                    ),
                                    icon: Icon(
                                      Icons.close_rounded,
                                      size: 15,
                                      color: secondaryTextColor,
                                    ),
                                    onPressed: () {
                                      _husbandNameCtrl.clear();
                                      studio.setHusbandName('', notify: true);
                                      setState(() {});
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF0284C7),
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _wifeNameCtrl,
                          focusNode: _wifeNameFocus,
                          textInputAction: TextInputAction.done,
                          onChanged: (v) {
                            studio.setWifeName(v, notify: false);
                            setState(() {});
                          },
                          onSubmitted: (v) {
                            studio.setWifeName(v, notify: true);
                          },
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Tên Vợ',
                            hintText: 'VD: Lan',
                            isDense: true,
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(8),
                              child: FinoraMemberAvatar(
                                member: 'wife',
                                size: 22,
                                isDark: isDark,
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 38,
                              minHeight: 38,
                            ),
                            suffixIcon: _wifeNameCtrl.text.isNotEmpty
                                ? IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 28,
                                      minHeight: 28,
                                    ),
                                    icon: Icon(
                                      Icons.close_rounded,
                                      size: 15,
                                      color: secondaryTextColor,
                                    ),
                                    onPressed: () {
                                      _wifeNameCtrl.clear();
                                      studio.setWifeName('', notify: true);
                                      setState(() {});
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFEC4899),
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildColorBadge('Tất cả', const Color(0xFF10B981)),
                            _buildColorBadge(
                              studio.husbandDisplayLabel,
                              const Color(0xFF0284C7),
                            ),
                            _buildColorBadge(
                              studio.wifeDisplayLabel,
                              const Color(0xFFEC4899),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          FocusScope.of(context).unfocus();
                          studio.setHusbandName(
                            _husbandNameCtrl.text,
                            notify: false,
                          );
                          studio.setWifeName(
                            _wifeNameCtrl.text,
                            notify: true,
                          );
                          FinoraNotice.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Đã lưu tên: ${studio.husbandDisplayLabel} · ${studio.wifeDisplayLabel}',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: studio.resolvedPrimary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Lưu tên',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ==========================================
            // PHÂN HỆ 2: TUỲ BIẾN NỀN PHA MÀU ĐÁ THẠCH ANH (QUARTZ MESH)
            // ==========================================
            _buildSectionHeader(
              title: 'NỀN PHA MÀU ĐÁ THẠCH ANH & GRADIENT BLUR',
              subtitle:
                  'Bảng màu pha tinh thể Thạch Anh & Mesh Gradient 3 vùng',
              icon: Icons.auto_awesome_rounded,
              color: studio.resolvedPrimary,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            const SizedBox(height: 12),

            // 1. Live Preview Card
            Container(
              height: 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor, width: 1.2),
                color:
                    isDark ? const Color(0xFF090D16) : const Color(0xFFF6F8FA),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Live Backdrop Blur Mesh
                  if (studio.useCustomRgbMeshBg)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _SettingsMeshPreviewPainter(
                          c1: studio.customBgColor1,
                          c2: studio.customBgColor2,
                          c3: studio.customBgColor3,
                          intensity: studio.customBgIntensity,
                          blurSigma: studio.customBgBlur,
                          blendStyle: studio.meshBlendStyle,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  // Glass content overlay
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: studio.useCustomRgbMeshBg
                                          ? const Color(0xFF10B981)
                                          : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    studio.useCustomRgbMeshBg
                                        ? 'Bản xem trước trực tiếp'
                                        : 'Đang tắt hiệu ứng nền',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                studio.useCustomRgbMeshBg
                                    ? 'Nền RGB Mesh Gradient Blur đang áp dụng'
                                    : 'Bật công tắc bên dưới để áp dụng hiệu ứng',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: primaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildColorBadge(
                                      'Vùng 1', studio.customBgColor1),
                                  const SizedBox(width: 6),
                                  _buildColorBadge(
                                      'Vùng 2', studio.customBgColor2),
                                  const SizedBox(width: 6),
                                  _buildColorBadge(
                                      'Vùng 3', studio.customBgColor3),
                                ],
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

            const SizedBox(height: 14),

            // 2. Master Toggle Switch Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bật nền pha màu Gradient Blur',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: primaryTextColor,
                          ),
                        ),
                        Text(
                          'Hiển thị dải màu lan tỏa mềm mại toàn ứng dụng',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: studio.useCustomRgbMeshBg,
                    activeTrackColor: const Color(0xFF10B981),
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      studio.setUseCustomRgbMeshBg(val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 3. Quick Presets (12 Bảng Màu Mẫu)
            Text(
              '12 BẢNG MÀU MẪU ĐỘC ĐÁO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _presets.map((preset) {
                  final isSelected = studio.customBgColor1.toARGB32() ==
                          preset.c1.toARGB32() &&
                      studio.customBgColor2.toARGB32() ==
                          preset.c2.toARGB32() &&
                      studio.customBgColor3.toARGB32() == preset.c3.toARGB32();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        studio.applyRgbMeshPreset(
                          preset.c1,
                          preset.c2,
                          preset.c3,
                          intensity: preset.intensity,
                        );
                      },
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? studio.resolvedPrimary.withValues(
                                  alpha: isDark ? 0.22 : 0.12)
                              : cardBg,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: isSelected
                                ? studio.resolvedPrimary
                                : borderColor,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [preset.c1, preset.c2, preset.c3],
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              preset.name,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? studio.resolvedPrimary
                                    : primaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 18),

            // 3.5. Mesh Blend Style Selector
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'KIỂU PHA TRỘN GRADIENT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                        color: secondaryTextColor,
                      ),
                    ),
                    Text(
                      switch (studio.meshBlendStyle) {
                        MeshBlendStyle.radialMesh => 'Tản sắc Đa điểm',
                        MeshBlendStyle.auroraWave => 'Dải Cực quang',
                        MeshBlendStyle.linearFlow => 'Dòng chảy Chéo',
                        MeshBlendStyle.centerAura => 'Hào quang Trọng tâm',
                        MeshBlendStyle.prismaticFusion => 'Lăng kính Giao thoa',
                      },
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      (
                        MeshBlendStyle.radialMesh,
                        'Đa điểm',
                        Icons.blur_on_rounded
                      ),
                      (
                        MeshBlendStyle.auroraWave,
                        'Cực quang',
                        Icons.waves_rounded
                      ),
                      (
                        MeshBlendStyle.linearFlow,
                        'Dòng chảy',
                        Icons.trending_flat_rounded
                      ),
                      (
                        MeshBlendStyle.centerAura,
                        'Hào quang',
                        Icons.flare_rounded
                      ),
                      (
                        MeshBlendStyle.prismaticFusion,
                        'Lăng kính',
                        Icons.diamond_rounded
                      ),
                    ].map((item) {
                      final style = item.$1;
                      final title = item.$2;
                      final icon = item.$3;
                      final isSelected = studio.meshBlendStyle == style;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              studio.setMeshBlendStyle(style);
                            },
                            borderRadius: BorderRadius.circular(100),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 13, vertical: 7.5),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark
                                        ? const Color(0xFF1E2D27)
                                        : const Color(0xFFEAF5EF))
                                    : cardBg,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF10B981)
                                      : borderColor,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    icon,
                                    size: 14,
                                    color: isSelected
                                        ? const Color(0xFF10B981)
                                        : secondaryTextColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? const Color(0xFF10B981)
                                          : primaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // 4. Zone Selector & Color Tuning
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CHỌN VÙNG PHA MÀU',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                          color: secondaryTextColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: activeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: activeColor.withValues(alpha: 0.40),
                          ),
                        ),
                        child: Text(
                          hexString,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: activeColor,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  FinoraSegmentedTabs(
                    labels: const ['Vùng trên', 'Vùng phải', 'Vùng dưới'],
                    selectedIndex: _selectedZoneIndex,
                    height: 38,
                    onChanged: (index) =>
                        setState(() => _selectedZoneIndex = index),
                  ),

                  const SizedBox(height: 16),

                  // 24 Quick Swatches Palette
                  Text(
                    'BẢNG MÀU CHỌN NHANH',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _swatches.map((color) {
                      final isSelected =
                          activeColor.toARGB32() == color.toARGB32();
                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _updateActiveColor(studio, color);
                        },
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.35),
                                blurRadius: isSelected ? 8 : 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isSelected
                              ? const Center(
                                  child: Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // RGB Sliders for precise tuning
                  Text(
                    'TINH CHỈNH HỆ MÀU RGB',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildRgbSlider(
                    label: 'Đỏ (Red)',
                    value: rVal,
                    activeColor: const Color(0xFFEF4444),
                    onChanged: (newR) => _updateActiveColor(
                      studio,
                      Color.fromARGB(255, newR, gVal, bVal),
                    ),
                  ),
                  _buildRgbSlider(
                    label: 'Lục (Green)',
                    value: gVal,
                    activeColor: const Color(0xFF10B981),
                    onChanged: (newG) => _updateActiveColor(
                      studio,
                      Color.fromARGB(255, rVal, newG, bVal),
                    ),
                  ),
                  _buildRgbSlider(
                    label: 'Lam (Blue)',
                    value: bVal,
                    activeColor: const Color(0xFF3B82F6),
                    onChanged: (newB) => _updateActiveColor(
                      studio,
                      Color.fromARGB(255, rVal, gVal, newB),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 5. Intensity & Blur Sliders Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ĐỘ ĐẬM MÀU NỀN (INTENSITY)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                          color: secondaryTextColor,
                        ),
                      ),
                      Text(
                        '${(studio.customBgIntensity * 100).round()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF10B981),
                      inactiveTrackColor:
                          isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      thumbColor: Colors.white,
                      trackHeight: 5,
                    ),
                    child: Slider(
                      value: studio.customBgIntensity.clamp(0.05, 0.45),
                      min: 0.05,
                      max: 0.45,
                      onChanged: (val) => studio.setCustomBgIntensity(val),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ĐỘ MỜ GAUSSIAN BLUR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                          color: secondaryTextColor,
                        ),
                      ),
                      Text(
                        '${studio.customBgBlur.round()}px',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF0284C7),
                      inactiveTrackColor:
                          isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      thumbColor: Colors.white,
                      trackHeight: 5,
                    ),
                    child: Slider(
                      value: studio.customBgBlur.clamp(20.0, 100.0),
                      min: 20.0,
                      max: 100.0,
                      onChanged: (val) => studio.setCustomBgBlur(val),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ==========================================
            // PHÂN HỆ 3: ĐỘ TRONG SUỐT VÀ MỜ CHO HEADER, DOCK & THẺ
            // ==========================================
            _buildSectionHeader(
              title: 'ĐỘ MỜ & TUỲ BIẾN HEADER, DOCK & THẺ',
              subtitle:
                  'Tuỳ chỉnh độ mờ (opacity), độ blur và màu sắc cho thanh đầu trang, thanh dock và các thẻ',
              icon: Icons.tune_rounded,
              color: const Color(0xFF6366F1),
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. HEADER (THANH ĐẦU TRANG) ---
                  Row(
                    children: [
                      const Icon(Icons.view_headline_rounded,
                          size: 16, color: Color(0xFF005FEA)),
                      const SizedBox(width: 6),
                      Text(
                        'THANH ĐẦU TRANG (HEADER)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Độ mờ Header (Opacity)',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: secondaryTextColor),
                      ),
                      Text(
                        '${(studio.appBarOpacity * 100).round()}%',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: primaryTextColor),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF005FEA),
                      inactiveTrackColor:
                          isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      thumbColor: Colors.white,
                      trackHeight: 5,
                    ),
                    child: Slider(
                      value: studio.appBarOpacity.clamp(0.20, 1.0),
                      min: 0.20,
                      max: 1.0,
                      onChanged: (val) => studio.setAppBarOpacity(val),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Độ blur Header',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: secondaryTextColor),
                      ),
                      Text(
                        '${studio.appBarBlur.round()}px',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: primaryTextColor),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF005FEA),
                      inactiveTrackColor:
                          isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      thumbColor: Colors.white,
                      trackHeight: 5,
                    ),
                    child: Slider(
                      value: studio.appBarBlur.clamp(0.0, 30.0),
                      min: 0.0,
                      max: 30.0,
                      onChanged: (val) => studio.setAppBarBlur(val),
                    ),
                  ),

                  const Divider(height: 24),

                  // --- 2. DOCK NAVIGATION (THANH ĐIỀU HƯỚNG) ---
                  Row(
                    children: [
                      const Icon(Icons.navigation_rounded,
                          size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      Text(
                        'THANH DOCK ĐIỀU HƯỚNG',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Màu nút chọn thanh Dock',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: secondaryTextColor),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildDockColorPill(
                          null, 'Mặc định', const Color(0xFF005FEA), studio),
                      const SizedBox(width: 6),
                      _buildDockColorPill(const Color(0xFF10B981), 'Ngọc',
                          const Color(0xFF10B981), studio),
                      const SizedBox(width: 6),
                      _buildDockColorPill(const Color(0xFF0284C7), 'Biển',
                          const Color(0xFF0284C7), studio),
                      const SizedBox(width: 6),
                      _buildDockColorPill(const Color(0xFF8B5CF6), 'Tím',
                          const Color(0xFF8B5CF6), studio),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Màu nút dấu (+) ở thanh Dock',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: secondaryTextColor),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildDockPlusColorPill(null, 'Ngọc (Chuẩn)',
                            const Color(0xFF10B981), studio),
                        const SizedBox(width: 6),
                        _buildDockPlusColorPill(const Color(0xFF0284C7),
                            'Xanh Biển', const Color(0xFF0284C7), studio),
                        const SizedBox(width: 6),
                        _buildDockPlusColorPill(const Color(0xFFE11D48),
                            'San Hô', const Color(0xFFE11D48), studio),
                        const SizedBox(width: 6),
                        _buildDockPlusColorPill(const Color(0xFFF59E0B),
                            'Vàng Kim', const Color(0xFFF59E0B), studio),
                        const SizedBox(width: 6),
                        _buildDockPlusColorPill(const Color(0xFF8B5CF6),
                            'Tím Royal', const Color(0xFF8B5CF6), studio),
                        const SizedBox(width: 6),
                        _buildDockPlusColorPill(const Color(0xFFEC4899),
                            'Hồng Neon', const Color(0xFFEC4899), studio),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Độ mờ Dock (Opacity)',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: secondaryTextColor),
                      ),
                      Text(
                        '${(studio.dockOpacity * 100).round()}%',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: primaryTextColor),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF10B981),
                      inactiveTrackColor:
                          isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      thumbColor: Colors.white,
                      trackHeight: 5,
                    ),
                    child: Slider(
                      value: studio.dockOpacity.clamp(0.20, 1.0),
                      min: 0.20,
                      max: 1.0,
                      onChanged: (val) => studio.setDockOpacity(val),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Độ blur Dock',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: secondaryTextColor),
                      ),
                      Text(
                        '${studio.dockBlur.round()}px',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: primaryTextColor),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF10B981),
                      inactiveTrackColor:
                          isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      thumbColor: Colors.white,
                      trackHeight: 5,
                    ),
                    child: Slider(
                      value: studio.dockBlur.clamp(0.0, 30.0),
                      min: 0.0,
                      max: 30.0,
                      onChanged: (val) => studio.setDockBlur(val),
                    ),
                  ),

                  const Divider(height: 24),

                  // --- 3. THẺ & WIDGET (CARD BACKGROUND) ---
                  Row(
                    children: [
                      const Icon(Icons.dashboard_rounded,
                          size: 16, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 6),
                      Text(
                        'NỀN CÁC THẺ & WIDGET',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Độ mờ nền thẻ (Opacity)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: secondaryTextColor,
                        ),
                      ),
                      Text(
                        '${(studio.glassOpacity * 100).round()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFFF59E0B),
                      inactiveTrackColor:
                          isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      thumbColor: Colors.white,
                      trackHeight: 5,
                    ),
                    child: Slider(
                      value: studio.glassOpacity.clamp(0.0, 1.0),
                      min: 0.0,
                      max: 1.0,
                      onChanged: (val) => studio.setGlassOpacity(val),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Độ mờ kính thẻ (Blur Sigma)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: secondaryTextColor,
                        ),
                      ),
                      Text(
                        '${studio.glassBlur.round()}px',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFFF59E0B),
                      inactiveTrackColor:
                          isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      thumbColor: Colors.white,
                      trackHeight: 5,
                    ),
                    child: Slider(
                      value: studio.glassBlur.clamp(0.0, 30.0),
                      min: 0.0,
                      max: 30.0,
                      onChanged: (val) => studio.setGlassBlur(val),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDockColorPill(Color? color, String label, Color previewColor,
      ThemeStudioController studio) {
    final isSelected = (color == null && studio.dockActiveColor == null) ||
        (color != null &&
            studio.dockActiveColor?.toARGB32() == color.toARGB32());
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          studio.setDockActiveColor(color);
        },
        child: Container(
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? previewColor.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isSelected
                  ? previewColor
                  : (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0)),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: previewColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? previewColor
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : const Color(0xFF475569)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDockPlusColorPill(Color? color, String label, Color previewColor,
      ThemeStudioController studio) {
    final isSelected = (color == null && studio.dockPlusColor == null) ||
        (color != null && studio.dockPlusColor?.toARGB32() == color.toARGB32());
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        studio.setDockPlusColor(color);
      },
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? previewColor.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? previewColor
                : (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: previewColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 10,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? previewColor
                    : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRgbSlider({
    required String label,
    required int value,
    required Color activeColor,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: activeColor,
              inactiveTrackColor: activeColor.withValues(alpha: 0.18),
              thumbColor: activeColor,
              trackHeight: 4,
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 255,
              onChanged: (val) => onChanged(val.round()),
            ),
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RgbPresetItem {
  final String name;
  final Color c1;
  final Color c2;
  final Color c3;
  final double intensity;

  const _RgbPresetItem({
    required this.name,
    required this.c1,
    required this.c2,
    required this.c3,
    this.intensity = 0.18,
  });
}

class _SettingsMeshPreviewPainter extends CustomPainter {
  final Color c1;
  final Color c2;
  final Color c3;
  final double intensity;
  final double blurSigma;
  final MeshBlendStyle blendStyle;
  final bool isDark;

  const _SettingsMeshPreviewPainter({
    required this.c1,
    required this.c2,
    required this.c3,
    required this.intensity,
    required this.blurSigma,
    required this.blendStyle,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    CustomRgbMeshBlurPainter(
      color1: c1,
      color2: c2,
      color3: c3,
      intensity: intensity,
      blurSigma: blurSigma,
      blendStyle: blendStyle,
      isDark: isDark,
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _SettingsMeshPreviewPainter oldDelegate) =>
      oldDelegate.c1 != c1 ||
      oldDelegate.c2 != c2 ||
      oldDelegate.c3 != c3 ||
      oldDelegate.intensity != intensity ||
      oldDelegate.blurSigma != blurSigma ||
      oldDelegate.blendStyle != blendStyle ||
      oldDelegate.isDark != isDark;
}
