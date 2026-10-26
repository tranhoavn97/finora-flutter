import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppColorPalette {
  goldStardust,
  earthOrbit,
  alpineLake,
  sunsetSea,
  twilightMoon,
  goldenWave,
  sakuraSpring,
  tropicalOcean,
  pastelSpheres,
  winterCabin,
  greenFoliage,
  rainyWindow,
  milkyWay,
  andromeda,
  blackHole,
  butterflyNebula,
  supernova,
  horsehead,
  triangulum,
  sombrero,
  cartwheel,
  sunflower,
  deepSpace,
  solarFlare,
  diamond,
  ruby,
  emerald,
  sapphire,
  gold,
  platinum,
  jade,
  amethyst,
  amber,
  tigerEye,
  blackPearl,
  sunstone,
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
  final String? gemSymbol;
  final String? imagePath;
  final List<Color>? ambientOrbs;

  const PaletteMeta({
    required this.palette,
    required this.title,
    required this.subtitle,
    required this.primary,
    required this.secondary,
    required this.lightBg,
    required this.darkBg,
    required this.heroGradient,
    this.gemSymbol,
    this.imagePath,
    this.ambientOrbs,
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

  AppColorPalette _palette = AppColorPalette.goldStardust;
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
      palette: AppColorPalette.goldStardust,
      title: 'Hoàng Kim Tinh Tú (Golden Stardust) ✨',
      subtitle: 'Bụi vàng lấp lánh • Tinh tú phương đông',
      primary: Color(0xFFD97706),
      secondary: Color(0xFFFBBF24),
      lightBg: Color(0xFFFFFBEB),
      darkBg: Color(0xFF130E04),
      heroGradient: [Color(0xFF1E1405), Color(0xFF382307), Color(0xFF5E3A0B)],
      gemSymbol: '✨',
      imagePath: 'assets/nature12/gold_stardust.png',
      ambientOrbs: [Color(0xFFD97706), Color(0xFFFBBF24), Color(0xFF78350F), Color(0xFFB45309)],
    ),
    PaletteMeta(
      palette: AppColorPalette.earthOrbit,
      title: 'Lam Cầu Vũ Trụ (Earth Horizon) 🌍',
      subtitle: 'Trái Đất đêm huyền ảo • Ánh đèn thành phố',
      primary: Color(0xFF0284C7),
      secondary: Color(0xFF38BDF8),
      lightBg: Color(0xFFF0F9FF),
      darkBg: Color(0xFF040D1A),
      heroGradient: [Color(0xFF020914), Color(0xFF0A1E3F), Color(0xFF163E78)],
      gemSymbol: '🌍',
      imagePath: 'assets/nature12/earth_orbit.png',
      ambientOrbs: [Color(0xFF0284C7), Color(0xFF38BDF8), Color(0xFF0369A1), Color(0xFF1D4ED8)],
    ),
    PaletteMeta(
      palette: AppColorPalette.alpineLake,
      title: 'Sơn Thủy Ngọc Bích (Alpine Lake) 🌲',
      subtitle: 'Rừng thông núi tuyết • Hồ ngọc lam thanh khiết',
      primary: Color(0xFF0D9488),
      secondary: Color(0xFF2DD4BF),
      lightBg: Color(0xFFF0FDFA),
      darkBg: Color(0xFF041410),
      heroGradient: [Color(0xFF03140E), Color(0xFF083325), Color(0xFF0F5744)],
      gemSymbol: '🌲',
      imagePath: 'assets/nature12/alpine_lake.png',
      ambientOrbs: [Color(0xFF0D9488), Color(0xFF2DD4BF), Color(0xFF047857), Color(0xFF115E59)],
    ),
    PaletteMeta(
      palette: AppColorPalette.sunsetSea,
      title: 'Nhật Lạc San Hô (Ocean Sunset) 🌅',
      subtitle: 'Hoàng hôn biển cả • Ánh dương rực rỡ chân trời',
      primary: Color(0xFFEA580C),
      secondary: Color(0xFFFB923C),
      lightBg: Color(0xFFFFF7ED),
      darkBg: Color(0xFF1A0A05),
      heroGradient: [Color(0xFF1E0904), Color(0xFF4A180B), Color(0xFF832A15)],
      gemSymbol: '🌅',
      imagePath: 'assets/nature12/sunset_sea.png',
      ambientOrbs: [Color(0xFFEA580C), Color(0xFFFB923C), Color(0xFFC2410C), Color(0xFF9A3412)],
    ),
    PaletteMeta(
      palette: AppColorPalette.twilightMoon,
      title: 'Tử Vân Nguyệt Dạ (Twilight Moon) 🌙',
      subtitle: 'Trăng non hoàng hôn • Biển mây tím hồng mộng mơ',
      primary: Color(0xFF9333EA),
      secondary: Color(0xFFC084FC),
      lightBg: Color(0xFFFAF5FF),
      darkBg: Color(0xFF13061F),
      heroGradient: [Color(0xFF150424), Color(0xFF330D54), Color(0xFF5B168A)],
      gemSymbol: '🌙',
      imagePath: 'assets/nature12/twilight_moon.png',
      ambientOrbs: [Color(0xFF9333EA), Color(0xFFC084FC), Color(0xFF7E22CE), Color(0xFFA855F7)],
    ),
    PaletteMeta(
      palette: AppColorPalette.goldenWave,
      title: 'Lụa Vàng Đẳng Cấp (Golden Wave) 💫',
      subtitle: 'Dải sóng hoàng kim • Tinh tế & quý phái',
      primary: Color(0xFFCA8A04),
      secondary: Color(0xFFFACC15),
      lightBg: Color(0xFFFEFCE8),
      darkBg: Color(0xFF121008),
      heroGradient: [Color(0xFF0F0D07), Color(0xFF28210F), Color(0xFF4C3E1A)],
      gemSymbol: '💫',
      imagePath: 'assets/nature12/golden_wave.png',
      ambientOrbs: [Color(0xFFCA8A04), Color(0xFFFACC15), Color(0xFFA16207), Color(0xFF854D0E)],
    ),
    PaletteMeta(
      palette: AppColorPalette.sakuraSpring,
      title: 'Hồng Phấn Sakura (Cherry Blossom) 🌸',
      subtitle: 'Hoa anh đào mùa xuân • Tươi mới & ngọt ngào',
      primary: Color(0xFFDB2777),
      secondary: Color(0xFFF472B6),
      lightBg: Color(0xFFFDF2F8),
      darkBg: Color(0xFF1A0713),
      heroGradient: [Color(0xFF210816), Color(0xFF4A1032), Color(0xFF7D1B53)],
      gemSymbol: '🌸',
      imagePath: 'assets/nature12/sakura_spring.png',
      ambientOrbs: [Color(0xFFDB2777), Color(0xFFF472B6), Color(0xFFBE185D), Color(0xFF9D174D)],
    ),
    PaletteMeta(
      palette: AppColorPalette.tropicalOcean,
      title: 'Hải Lam Nhiệt Đới (Tropical Surf) 🌊',
      subtitle: 'Sóng biển lam ngọc • Bờ cát trắng êm đềm',
      primary: Color(0xFF0891B2),
      secondary: Color(0xFF22D3EE),
      lightBg: Color(0xFFECFEFF),
      darkBg: Color(0xFF03141C),
      heroGradient: [Color(0xFF02121B), Color(0xFF072D3D), Color(0xFF0D4F66)],
      gemSymbol: '🌊',
      imagePath: 'assets/nature12/tropical_ocean.png',
      ambientOrbs: [Color(0xFF0891B2), Color(0xFF22D3EE), Color(0xFF0E7490), Color(0xFF155E75)],
    ),
    PaletteMeta(
      palette: AppColorPalette.pastelSpheres,
      title: 'Hologram Pastel 3D (Pastel Spheres) 🔮',
      subtitle: 'Khối cầu đa sắc • Hiện đại & trừu tượng',
      primary: Color(0xFF7C3AED),
      secondary: Color(0xFFA78BFA),
      lightBg: Color(0xFFF5F3FF),
      darkBg: Color(0xFF100B21),
      heroGradient: [Color(0xFF120C24), Color(0xFF271A4D), Color(0xFF452D82)],
      gemSymbol: '🔮',
      imagePath: 'assets/nature12/pastel_spheres.png',
      ambientOrbs: [Color(0xFF7C3AED), Color(0xFFA78BFA), Color(0xFF6D28D9), Color(0xFF8B5CF6)],
    ),
    PaletteMeta(
      palette: AppColorPalette.winterCabin,
      title: 'Bạch Tuyết Dạ Khúc (Winter Cabin) ❄️',
      subtitle: 'Mái nhà gỗ mùa đông • Tuyết trắng an yên',
      primary: Color(0xFF2563EB),
      secondary: Color(0xFF60A5FA),
      lightBg: Color(0xFFEFF6FF),
      darkBg: Color(0xFF060E21),
      heroGradient: [Color(0xFF050E22), Color(0xFF0F224E), Color(0xFF1A3B83)],
      gemSymbol: '❄️',
      imagePath: 'assets/nature12/winter_cabin.png',
      ambientOrbs: [Color(0xFF2563EB), Color(0xFF60A5FA), Color(0xFF1D4ED8), Color(0xFF1E40AF)],
    ),
    PaletteMeta(
      palette: AppColorPalette.greenFoliage,
      title: 'Thanh Diệp Thư Thái (Sunlit Leaves) 🍃',
      subtitle: 'Nắng mai rọi bóng lá • Bình yên & tự nhiên',
      primary: Color(0xFF16A34A),
      secondary: Color(0xFF4ADE80),
      lightBg: Color(0xFFF0FDF4),
      darkBg: Color(0xFF06140A),
      heroGradient: [Color(0xFF06140A), Color(0xFF0E2C17), Color(0xFF184E29)],
      gemSymbol: '🍃',
      imagePath: 'assets/nature12/green_foliage.png',
      ambientOrbs: [Color(0xFF16A34A), Color(0xFF4ADE80), Color(0xFF15803D), Color(0xFF166534)],
    ),
    PaletteMeta(
      palette: AppColorPalette.rainyWindow,
      title: 'Giọt Mưa Phố Thị (Rainy Window) 🌧️',
      subtitle: 'Mưa chiều qua khung kính • Ánh đèn vàng ấm áp',
      primary: Color(0xFF0284C7),
      secondary: Color(0xFF38BDF8),
      lightBg: Color(0xFFF0F9FF),
      darkBg: Color(0xFF07121C),
      heroGradient: [Color(0xFF07131D), Color(0xFF11293B), Color(0xFF1E445E)],
      gemSymbol: '🌧️',
      imagePath: 'assets/nature12/rainy_window.png',
      ambientOrbs: [Color(0xFF0284C7), Color(0xFF38BDF8), Color(0xFF0369A1), Color(0xFF075985)],
    ),
    // Backward-compatible entries:
    PaletteMeta(
      palette: AppColorPalette.diamond,
      title: 'Kim Cương 💎',
      subtitle: 'Pha lê vĩnh cửu',
      primary: Color(0xFF0284C7),
      secondary: Color(0xFF38BDF8),
      lightBg: Color(0xFFF0F9FF),
      darkBg: Color(0xFF071324),
      heroGradient: [Color(0xFF0A1E38), Color(0xFF14345E), Color(0xFF1E4C87)],
    ),
    PaletteMeta(
      palette: AppColorPalette.ruby,
      title: 'Hồng Ngọc 🔴',
      subtitle: 'Đỏ hoàng gia',
      primary: Color(0xFFE11D48),
      secondary: Color(0xFFF43F5E),
      lightBg: Color(0xFFFFF1F2),
      darkBg: Color(0xFF22060E),
      heroGradient: [Color(0xFF4C0B1B), Color(0xFF7A102C), Color(0xFFA8153C)],
    ),
    PaletteMeta(
      palette: AppColorPalette.emerald,
      title: 'Ngọc Lục Bảo 🟢',
      subtitle: 'Xanh lục bảo',
      primary: Color(0xFF059669),
      secondary: Color(0xFF10B981),
      lightBg: Color(0xFFF0FDF4),
      darkBg: Color(0xFF041C13),
      heroGradient: [Color(0xFF053B29), Color(0xFF0A5E42), Color(0xFF10855E)],
    ),
    PaletteMeta(
      palette: AppColorPalette.oceanicSapphire,
      title: 'Soft Edition',
      subtitle: 'Xanh dịu, bề mặt trắng và đường nét mềm mại',
      primary: Color(0xFF0969F2),
      secondary: Color(0xFF0284C7),
      lightBg: Color(0xFFF1F6FA),
      darkBg: Color(0xFF0B1220),
      heroGradient: [Color(0xFF187AF8), Color(0xFF0969F2), Color(0xFF0656DB)],
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

  Future<void> setGemTheme(int index) async {
    final safeIndex = index.clamp(0, 11);
    _palette = palettes[safeIndex].palette;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_paletteKey, _palette.index);
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
