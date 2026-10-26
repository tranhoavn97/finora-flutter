import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppColorPalette {
  oceanicSapphire,
  emeraldWealth,
  obsidianGold,
  sunsetCoral,
  slateMinimal,
}

enum AmbientBlurPreset {
  sapphireCyan,
  midnightAurora,
  sunsetAmber,
  cyberElectric,
  obsidianSlate,
  amoledPitch,
}

class AmbientBlurMeta {
  final AmbientBlurPreset preset;
  final String title;
  final String subtitle;
  final List<Color> bgColorsDark;
  final List<Color> bgColorsLight;
  final Color orb1;
  final Color orb2;
  final Color orb3;
  final Color orb4;

  const AmbientBlurMeta({
    required this.preset,
    required this.title,
    required this.subtitle,
    required this.bgColorsDark,
    required this.bgColorsLight,
    required this.orb1,
    required this.orb2,
    required this.orb3,
    required this.orb4,
  });
}

enum CardDensity {
  compact,
  standard,
  spacious,
}

enum CardSurfaceStyle {
  liquidGlass,
  solidModern,
  cyberGradient,
}

enum CardCornerStyle { subtle, rounded, extraRounded }

enum CardShadowIntensity { none, soft, elevated }

class PaletteMeta {
  final AppColorPalette palette;
  final String title;
  final String subtitle;
  final Color primary;
  final Color secondary;
  final Color lightBg;
  final Color darkBg;
  final List<Color> heroGradient;

  const PaletteMeta({
    required this.palette,
    required this.title,
    required this.subtitle,
    required this.primary,
    required this.secondary,
    required this.lightBg,
    required this.darkBg,
    required this.heroGradient,
  });
}

class ThemeStudioController extends ChangeNotifier {
  static const _paletteKey = 'finora_studio_palette';
  static const _ambientBlurKey = 'finora_studio_ambient_blur';
  static const _densityKey = 'finora_studio_density';
  static const _surfaceKey = 'finora_studio_surface';
  static const _cornerKey = 'finora_studio_corner';
  static const _shadowKey = 'finora_studio_shadow';
  static const _txDensityKey = 'finora_studio_tx_density';
  static const _dashDensityKey = 'finora_studio_dash_density';
  static const _showAiInsightKey = 'finora_studio_show_ai_insight';
  static const _showQuickLogKey = 'finora_studio_show_quick_log';

  AppColorPalette _palette = AppColorPalette.oceanicSapphire;
  AmbientBlurPreset _ambientBlur = AmbientBlurPreset.sapphireCyan;
  CardDensity _globalDensity = CardDensity.standard;
  CardDensity _dashboardDensity = CardDensity.standard;
  CardDensity _transactionDensity = CardDensity.compact;
  CardSurfaceStyle _surfaceStyle = CardSurfaceStyle.liquidGlass;
  CardCornerStyle _cornerStyle = CardCornerStyle.rounded;
  CardShadowIntensity _shadowIntensity = CardShadowIntensity.soft;
  bool _showAiInsight = true;
  bool _showQuickLog = true;

  AppColorPalette get palette => _palette;
  AmbientBlurPreset get ambientBlur => _ambientBlur;
  CardDensity get globalDensity => _globalDensity;
  CardDensity get dashboardDensity => _dashboardDensity;
  CardDensity get transactionDensity => _transactionDensity;
  CardSurfaceStyle get surfaceStyle => _surfaceStyle;
  CardCornerStyle get cornerStyle => _cornerStyle;
  CardShadowIntensity get shadowIntensity => _shadowIntensity;
  bool get showAiInsight => _showAiInsight;
  bool get showQuickLog => _showQuickLog;

  static const List<PaletteMeta> palettes = [
    PaletteMeta(
      palette: AppColorPalette.oceanicSapphire,
      title: 'Oceanic Sapphire',
      subtitle: 'Xanh hoàng gia chuẩn mực tài chính',
      primary: Color(0xFF005FEA),
      secondary: Color(0xFF0284C7),
      lightBg: Color(0xFFF8FAFC),
      darkBg: Color(0xFF0B1220),
      heroGradient: [Color(0xFF005FEA), Color(0xFF0284C7), Color(0xFF0369A1)],
    ),
    PaletteMeta(
      palette: AppColorPalette.emeraldWealth,
      title: 'Emerald Wealth',
      subtitle: 'Xanh ngọc lục bảo thịnh vượng & tiết kiệm',
      primary: Color(0xFF059669),
      secondary: Color(0xFF0D9488),
      lightBg: Color(0xFFF0FDF4),
      darkBg: Color(0xFF062118),
      heroGradient: [Color(0xFF065F46), Color(0xFF059669), Color(0xFF0D9488)],
    ),
    PaletteMeta(
      palette: AppColorPalette.obsidianGold,
      title: 'Obsidian Gold',
      subtitle: 'Hổ phách & Vàng Champagne sang trọng',
      primary: Color(0xFFD97706),
      secondary: Color(0xFFB45309),
      lightBg: Color(0xFFFFFBEB),
      darkBg: Color(0xFF1C1408),
      heroGradient: [Color(0xFF78350F), Color(0xFFB45309), Color(0xFFD97706)],
    ),
    PaletteMeta(
      palette: AppColorPalette.sunsetCoral,
      title: 'Sunset Coral',
      subtitle: 'San hô & Đỏ hoàng hôn hiện đại',
      primary: Color(0xFFE11D48),
      secondary: Color(0xFFBE123C),
      lightBg: Color(0xFFFFF1F2),
      darkBg: Color(0xFF200B10),
      heroGradient: [Color(0xFF881337), Color(0xFFBE123C), Color(0xFFE11D48)],
    ),
    PaletteMeta(
      palette: AppColorPalette.slateMinimal,
      title: 'Slate Minimal',
      subtitle: 'Xám than chì công nghệ & tối giản',
      primary: Color(0xFF475569),
      secondary: Color(0xFF334155),
      lightBg: Color(0xFFF1F5F9),
      darkBg: Color(0xFF0F172A),
      heroGradient: [Color(0xFF1E293B), Color(0xFF334155), Color(0xFF475569)],
    ),
  ];

  static const List<AmbientBlurMeta> ambientBlurPresets = [
    AmbientBlurMeta(
      preset: AmbientBlurPreset.sapphireCyan,
      title: 'Oceanic Sapphire & Sky',
      subtitle: 'Xanh hoàng gia và ánh trời thanh thoát',
      bgColorsDark: [Color(0xFF070B14), Color(0xFF0F172A), Color(0xFF0B1B36)],
      bgColorsLight: [Color(0xFFF1F5F9), Color(0xFFE0F2FE), Color(0xFFF8FAFC)],
      orb1: Color(0xFF005FEA),
      orb2: Color(0xFF0284C7),
      orb3: Color(0xFF0369A1),
      orb4: Color(0xFF059669),
    ),
    AmbientBlurMeta(
      preset: AmbientBlurPreset.midnightAurora,
      title: 'Midnight Aurora',
      subtitle: 'Cực quang xanh ngọc bích & lục bảo huyền bí',
      bgColorsDark: [Color(0xFF04130F), Color(0xFF062118), Color(0xFF0A2B20)],
      bgColorsLight: [Color(0xFFF0FDF4), Color(0xFFE6F4EA), Color(0xFFF8FAFC)],
      orb1: Color(0xFF059669),
      orb2: Color(0xFF0D9488),
      orb3: Color(0xFF10B981),
      orb4: Color(0xFF0284C7),
    ),
    AmbientBlurMeta(
      preset: AmbientBlurPreset.sunsetAmber,
      title: 'Sunset Amber Glow',
      subtitle: 'Hoàng hôn ấm áp, cam san hô & hổ phách',
      bgColorsDark: [Color(0xFF170C06), Color(0xFF261208), Color(0xFF381A0B)],
      bgColorsLight: [Color(0xFFFFFBEB), Color(0xFFFFEDD5), Color(0xFFFFF7ED)],
      orb1: Color(0xFFEA580C),
      orb2: Color(0xFFF59E0B),
      orb3: Color(0xFFE11D48),
      orb4: Color(0xFFD97706),
    ),
    AmbientBlurMeta(
      preset: AmbientBlurPreset.cyberElectric,
      title: 'Cyber Electric Neon',
      subtitle: 'Xanh điện quang rực rỡ & băng tuyết công nghệ',
      bgColorsDark: [Color(0xFF081226), Color(0xFF0E1E3D), Color(0xFF082247)],
      bgColorsLight: [Color(0xFFE0F2FE), Color(0xFFE8F0FE), Color(0xFFF0F9FF)],
      orb1: Color(0xFF2563EB),
      orb2: Color(0xFF38BDF8),
      orb3: Color(0xFF06B6D4),
      orb4: Color(0xFF005FEA),
    ),
    AmbientBlurMeta(
      preset: AmbientBlurPreset.obsidianSlate,
      title: 'Obsidian Minimal Slate',
      subtitle: 'Khói than chì & đá phiến tối giản tĩnh lặng',
      bgColorsDark: [Color(0xFF0B0F17), Color(0xFF111827), Color(0xFF1A2233)],
      bgColorsLight: [Color(0xFFF1F5F9), Color(0xFFE2E8F0), Color(0xFFF8FAFC)],
      orb1: Color(0xFF334155),
      orb2: Color(0xFF475569),
      orb3: Color(0xFF1E293B),
      orb4: Color(0xFF64748B),
    ),
    AmbientBlurMeta(
      preset: AmbientBlurPreset.amoledPitch,
      title: 'AMOLED True Black',
      subtitle: 'Đen tuyền tuyệt đối 100% tiết kiệm pin OLED',
      bgColorsDark: [Color(0xFF000000), Color(0xFF000000), Color(0xFF000000)],
      bgColorsLight: [Color(0xFFFAFAFA), Color(0xFFF5F5F5), Color(0xFFFFFFFF)],
      orb1: Color(0x00000000),
      orb2: Color(0x00000000),
      orb3: Color(0x00000000),
      orb4: Color(0x00000000),
    ),
  ];

  PaletteMeta get currentPaletteMeta {
    return palettes.firstWhere(
      (p) => p.palette == _palette,
      orElse: () => palettes[0],
    );
  }

  AmbientBlurMeta get currentAmbientBlurMeta {
    return ambientBlurPresets.firstWhere(
      (p) => p.preset == _ambientBlur,
      orElse: () => ambientBlurPresets[0],
    );
  }

  Color get primaryColor => currentPaletteMeta.primary;
  Color get secondaryColor => currentPaletteMeta.secondary;

  double getCardPadding(CardDensity density) {
    switch (density) {
      case CardDensity.compact:
        return 12.0;
      case CardDensity.standard:
        return 16.0;
      case CardDensity.spacious:
        return 20.0;
    }
  }

  double getCardRadius(CardDensity density) {
    final multiplier = switch (_cornerStyle) {
      CardCornerStyle.subtle => .72,
      CardCornerStyle.rounded => 1.0,
      CardCornerStyle.extraRounded => 1.28,
    };
    switch (density) {
      case CardDensity.compact:
        return 16.0 * multiplier;
      case CardDensity.standard:
        return 20.0 * multiplier;
      case CardDensity.spacious:
        return 24.0 * multiplier;
    }
  }

  List<BoxShadow> cardShadows(Color color) => switch (_shadowIntensity) {
        CardShadowIntensity.none => const [],
        CardShadowIntensity.soft => [
            BoxShadow(
              color: color.withValues(alpha: .10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        CardShadowIntensity.elevated => [
            BoxShadow(
              color: color.withValues(alpha: .18),
              blurRadius: 24,
              offset: const Offset(0, 9),
            ),
          ],
      };

  double getHeroCardHeight(CardDensity density) {
    switch (density) {
      case CardDensity.compact:
        return 168.0;
      case CardDensity.standard:
        return 196.0;
      case CardDensity.spacious:
        return 228.0;
    }
  }

  double getTxRowHeight(CardDensity density) {
    switch (density) {
      case CardDensity.compact:
        return 50.0;
      case CardDensity.standard:
        return 58.0;
      case CardDensity.spacious:
        return 66.0;
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final pIdx = prefs.getInt(_paletteKey);
    if (pIdx != null && pIdx >= 0 && pIdx < AppColorPalette.values.length) {
      _palette = AppColorPalette.values[pIdx];
    }
    final bIdx = prefs.getInt(_ambientBlurKey);
    if (bIdx != null && bIdx >= 0 && bIdx < AmbientBlurPreset.values.length) {
      _ambientBlur = AmbientBlurPreset.values[bIdx];
    }
    final dIdx = prefs.getInt(_densityKey);
    if (dIdx != null && dIdx >= 0 && dIdx < CardDensity.values.length) {
      _globalDensity = CardDensity.values[dIdx];
    }
    final dashIdx = prefs.getInt(_dashDensityKey);
    if (dashIdx != null &&
        dashIdx >= 0 &&
        dashIdx < CardDensity.values.length) {
      _dashboardDensity = CardDensity.values[dashIdx];
    }
    final txIdx = prefs.getInt(_txDensityKey);
    if (txIdx != null && txIdx >= 0 && txIdx < CardDensity.values.length) {
      _transactionDensity = CardDensity.values[txIdx];
    }
    final sIdx = prefs.getInt(_surfaceKey);
    if (sIdx != null && sIdx >= 0 && sIdx < CardSurfaceStyle.values.length) {
      _surfaceStyle = CardSurfaceStyle.values[sIdx];
    }
    final cornerIdx = prefs.getInt(_cornerKey);
    if (cornerIdx != null &&
        cornerIdx >= 0 &&
        cornerIdx < CardCornerStyle.values.length) {
      _cornerStyle = CardCornerStyle.values[cornerIdx];
    }
    final shadowIdx = prefs.getInt(_shadowKey);
    if (shadowIdx != null &&
        shadowIdx >= 0 &&
        shadowIdx < CardShadowIntensity.values.length) {
      _shadowIntensity = CardShadowIntensity.values[shadowIdx];
    }
    _showAiInsight = prefs.getBool(_showAiInsightKey) ?? true;
    _showQuickLog = prefs.getBool(_showQuickLogKey) ?? true;

    notifyListeners();
  }

  Future<void> setPalette(AppColorPalette val) async {
    _palette = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_paletteKey, val.index);
  }

  Future<void> setAmbientBlur(AmbientBlurPreset val) async {
    _ambientBlur = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_ambientBlurKey, val.index);
  }

  Future<void> setGlobalDensity(CardDensity val) async {
    _globalDensity = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_densityKey, val.index);
  }

  Future<void> setDashboardDensity(CardDensity val) async {
    _dashboardDensity = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dashDensityKey, val.index);
  }

  Future<void> setTransactionDensity(CardDensity val) async {
    _transactionDensity = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_txDensityKey, val.index);
  }

  Future<void> setSurfaceStyle(CardSurfaceStyle val) async {
    _surfaceStyle = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_surfaceKey, val.index);
  }

  Future<void> setCornerStyle(CardCornerStyle val) async {
    _cornerStyle = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_cornerKey, val.index);
  }

  Future<void> setShadowIntensity(CardShadowIntensity val) async {
    _shadowIntensity = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_shadowKey, val.index);
  }

  Future<void> setShowAiInsight(bool val) async {
    _showAiInsight = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showAiInsightKey, val);
  }

  Future<void> setShowQuickLog(bool val) async {
    _showQuickLog = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showQuickLogKey, val);
  }

  Future<void> resetToDefault() async {
    _palette = AppColorPalette.oceanicSapphire;
    _ambientBlur = AmbientBlurPreset.sapphireCyan;
    _globalDensity = CardDensity.standard;
    _dashboardDensity = CardDensity.standard;
    _transactionDensity = CardDensity.compact;
    _surfaceStyle = CardSurfaceStyle.liquidGlass;
    _cornerStyle = CardCornerStyle.rounded;
    _shadowIntensity = CardShadowIntensity.soft;
    _showAiInsight = true;
    _showQuickLog = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_paletteKey);
    await prefs.remove(_ambientBlurKey);
    await prefs.remove(_densityKey);
    await prefs.remove(_dashDensityKey);
    await prefs.remove(_txDensityKey);
    await prefs.remove(_surfaceKey);
    await prefs.remove(_cornerKey);
    await prefs.remove(_shadowKey);
    await prefs.remove(_showAiInsightKey);
    await prefs.remove(_showQuickLogKey);
  }
}
