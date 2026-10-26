import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePresetMeta {
  final int id;
  final String title;
  final String subtitle;
  final bool isDark;
  final List<Color> gradientColors;
  final Color accentColor;
  final String? gemSymbol;
  final String? imagePath;

  /// Backward-compatible alias
  String? get zodiacSymbol => gemSymbol;

  const ThemePresetMeta({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.gradientColors,
    required this.accentColor,
    String? gemSymbol,
    String? zodiacSymbol,
    this.imagePath,
  }) : gemSymbol = gemSymbol ?? zodiacSymbol;

}

class WidgetStyleController extends ChangeNotifier {
  static const _assetKey = 'widget_asset_style';
  static const _budgetKey = 'widget_budget_style';
  static const _assistantKey = 'widget_assistant_style';
  static const _historyKey = 'widget_history_style';

  int assetStyle = 0;
  int budgetStyle = 0;
  int assistantStyle = 0;
  int historyStyle = 0;

  static const List<ThemePresetMeta> assetPresets = [
    ThemePresetMeta(
      id: 0,
      title: 'Hoàng Kim Tinh Tú (Golden Stardust) ✨',
      subtitle: 'Bụi vàng lấp lánh • Tinh tú phương đông',
      isDark: true,
      gradientColors: [Color(0xFF1E1405), Color(0xFF382307), Color(0xFF5E3A0B)],
      accentColor: Color(0xFFFBBF24),
      gemSymbol: '✨',
      imagePath: 'assets/nature12/gold_stardust.png',
    ),
    ThemePresetMeta(
      id: 1,
      title: 'Lam Cầu Vũ Trụ (Earth Horizon) 🌍',
      subtitle: 'Trái Đất đêm huyền ảo • Ánh đèn thành phố',
      isDark: true,
      gradientColors: [Color(0xFF020914), Color(0xFF0A1E3F), Color(0xFF163E78)],
      accentColor: Color(0xFF38BDF8),
      gemSymbol: '🌍',
      imagePath: 'assets/nature12/earth_orbit.png',
    ),
    ThemePresetMeta(
      id: 2,
      title: 'Sơn Thủy Ngọc Bích (Alpine Lake) 🌲',
      subtitle: 'Rừng thông núi tuyết • Hồ ngọc lam thanh khiết',
      isDark: true,
      gradientColors: [Color(0xFF03140E), Color(0xFF083325), Color(0xFF0F5744)],
      accentColor: Color(0xFF2DD4BF),
      gemSymbol: '🌲',
      imagePath: 'assets/nature12/alpine_lake.png',
    ),
    ThemePresetMeta(
      id: 3,
      title: 'Nhật Lạc San Hô (Ocean Sunset) 🌅',
      subtitle: 'Hoàng hôn biển cả • Ánh dương rực rỡ chân trời',
      isDark: true,
      gradientColors: [Color(0xFF1E0904), Color(0xFF4A180B), Color(0xFF832A15)],
      accentColor: Color(0xFFFB923C),
      gemSymbol: '🌅',
      imagePath: 'assets/nature12/sunset_sea.png',
    ),
    ThemePresetMeta(
      id: 4,
      title: 'Tử Vân Nguyệt Dạ (Twilight Moon) 🌙',
      subtitle: 'Trăng non hoàng hôn • Biển mây tím hồng mộng mơ',
      isDark: true,
      gradientColors: [Color(0xFF150424), Color(0xFF330D54), Color(0xFF5B168A)],
      accentColor: Color(0xFFC084FC),
      gemSymbol: '🌙',
      imagePath: 'assets/nature12/twilight_moon.png',
    ),
    ThemePresetMeta(
      id: 5,
      title: 'Lụa Vàng Đẳng Cấp (Golden Wave) 💫',
      subtitle: 'Dải sóng hoàng kim • Tinh tế & quý phái',
      isDark: true,
      gradientColors: [Color(0xFF0F0D07), Color(0xFF28210F), Color(0xFF4C3E1A)],
      accentColor: Color(0xFFFACC15),
      gemSymbol: '💫',
      imagePath: 'assets/nature12/golden_wave.png',
    ),
    ThemePresetMeta(
      id: 6,
      title: 'Hồng Phấn Sakura (Cherry Blossom) 🌸',
      subtitle: 'Hoa anh đào mùa xuân • Tươi mới & ngọt ngào',
      isDark: true,
      gradientColors: [Color(0xFF210816), Color(0xFF4A1032), Color(0xFF7D1B53)],
      accentColor: Color(0xFFF472B6),
      gemSymbol: '🌸',
      imagePath: 'assets/nature12/sakura_spring.png',
    ),
    ThemePresetMeta(
      id: 7,
      title: 'Hải Lam Nhiệt Đới (Tropical Surf) 🌊',
      subtitle: 'Sóng biển lam ngọc • Bờ cát trắng êm đềm',
      isDark: true,
      gradientColors: [Color(0xFF02121B), Color(0xFF072D3D), Color(0xFF0D4F66)],
      accentColor: Color(0xFF22D3EE),
      gemSymbol: '🌊',
      imagePath: 'assets/nature12/tropical_ocean.png',
    ),
    ThemePresetMeta(
      id: 8,
      title: 'Hologram Pastel 3D (Pastel Spheres) 🔮',
      subtitle: 'Khối cầu đa sắc • Hiện đại & trừu tượng',
      isDark: true,
      gradientColors: [Color(0xFF120C24), Color(0xFF271A4D), Color(0xFF452D82)],
      accentColor: Color(0xFFA78BFA),
      gemSymbol: '🔮',
      imagePath: 'assets/nature12/pastel_spheres.png',
    ),
    ThemePresetMeta(
      id: 9,
      title: 'Bạch Tuyết Dạ Khúc (Winter Cabin) ❄️',
      subtitle: 'Mái nhà gỗ mùa đông • Tuyết trắng an yên',
      isDark: true,
      gradientColors: [Color(0xFF050E22), Color(0xFF0F224E), Color(0xFF1A3B83)],
      accentColor: Color(0xFF60A5FA),
      gemSymbol: '❄️',
      imagePath: 'assets/nature12/winter_cabin.png',
    ),
    ThemePresetMeta(
      id: 10,
      title: 'Thanh Diệp Thư Thái (Sunlit Leaves) 🍃',
      subtitle: 'Nắng mai rọi bóng lá • Bình yên & tự nhiên',
      isDark: true,
      gradientColors: [Color(0xFF06140A), Color(0xFF0E2C17), Color(0xFF184E29)],
      accentColor: Color(0xFF4ADE80),
      gemSymbol: '🍃',
      imagePath: 'assets/nature12/green_foliage.png',
    ),
    ThemePresetMeta(
      id: 11,
      title: 'Giọt Mưa Phố Thị (Rainy Window) 🌧️',
      subtitle: 'Mưa chiều qua khung kính • Ánh đèn vàng ấm áp',
      isDark: true,
      gradientColors: [Color(0xFF07131D), Color(0xFF11293B), Color(0xFF1E445E)],
      accentColor: Color(0xFF38BDF8),
      gemSymbol: '🌧️',
      imagePath: 'assets/nature12/rainy_window.png',
    ),
  ];



  static const List<ThemePresetMeta> budgetPresets = [
    ThemePresetMeta(
      id: 0,
      title: 'Glass Blue',
      subtitle: 'Thẻ kính xanh thanh lịch (Light)',
      isDark: false,
      gradientColors: [Color(0xFFFFFFFF), Color(0xFFF0F9FF)],
      accentColor: Color(0xFF0284C7),
    ),
    ThemePresetMeta(
      id: 1,
      title: 'Gradient Purple',
      subtitle: 'Tím gradient phát quang (Dark)',
      isDark: true,
      gradientColors: [Color(0xFF170F26), Color(0xFF2A1545)],
      accentColor: Color(0xFFA855F7),
    ),
    ThemePresetMeta(
      id: 2,
      title: 'Green Nature',
      subtitle: 'Họa tiết lá xanh thiên nhiên (Light)',
      isDark: false,
      gradientColors: [Color(0xFFF0FBF5), Color(0xFFE6F7ED)],
      accentColor: Color(0xFF10B981),
    ),
    ThemePresetMeta(
      id: 3,
      title: 'Warm Orange',
      subtitle: 'Cam hổ phách ấm áp (Dark)',
      isDark: true,
      gradientColors: [Color(0xFF141210), Color(0xFF241B10)],
      accentColor: Color(0xFFF59E0B),
    ),
  ];

  static const List<ThemePresetMeta> assistantPresets = [
    ThemePresetMeta(
      id: 0,
      title: 'Light Coral Red',
      subtitle: 'Đỏ san hô cảnh báo nổi bật (Light)',
      isDark: false,
      gradientColors: [Color(0xFFFFFFFF), Color(0xFFFFF5F5)],
      accentColor: Color(0xFFEF4444),
    ),
    ThemePresetMeta(
      id: 1,
      title: 'Dark Neon Purple',
      subtitle: 'Vòng sáng tím huyền ảo (Dark)',
      isDark: true,
      gradientColors: [Color(0xFF100D24), Color(0xFF221742)],
      accentColor: Color(0xFFA855F7),
    ),
    ThemePresetMeta(
      id: 2,
      title: 'Green Nature Mint',
      subtitle: 'Xanh bạc hà dịu nhẹ (Light)',
      isDark: false,
      gradientColors: [Color(0xFFF2FAF7), Color(0xFFE4F7EF)],
      accentColor: Color(0xFF10B981),
    ),
    ThemePresetMeta(
      id: 3,
      title: 'Dark Cyber Cyan',
      subtitle: 'Hologram công nghệ tương lai (Dark)',
      isDark: true,
      gradientColors: [Color(0xFF031E24), Color(0xFF07333B)],
      accentColor: Color(0xFF06B6D4),
    ),
  ];

  static const List<ThemePresetMeta> historyPresets = [
    ThemePresetMeta(
      id: 0,
      title: 'Clean Blue',
      subtitle: 'Trắng xanh tối giản thanh thoát (Light)',
      isDark: false,
      gradientColors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
      accentColor: Color(0xFF2563EB),
    ),
    ThemePresetMeta(
      id: 1,
      title: 'Deep Purple Glow',
      subtitle: 'Viền sáng neon xanh tím (Dark)',
      isDark: true,
      gradientColors: [Color(0xFF0C1033), Color(0xFF161F58)],
      accentColor: Color(0xFF38BDF8),
    ),
    ThemePresetMeta(
      id: 2,
      title: 'Green Nature',
      subtitle: 'Xanh lá thư thái thiên nhiên (Light)',
      isDark: false,
      gradientColors: [Color(0xFFF0FDF4), Color(0xFFE8FAF0)],
      accentColor: Color(0xFF10B981),
    ),
    ThemePresetMeta(
      id: 3,
      title: 'Purple Wave',
      subtitle: 'Pastel tím uốn lượn mềm (Light)',
      isDark: false,
      gradientColors: [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
      accentColor: Color(0xFF9333EA),
    ),
    ThemePresetMeta(
      id: 4,
      title: 'Cyber Neon Teal',
      subtitle: 'Khung lục giác Cyber phát sáng (Dark)',
      isDark: true,
      gradientColors: [Color(0xFF04151B), Color(0xFF0B252E)],
      accentColor: Color(0xFF14B8A6),
    ),
    ThemePresetMeta(
      id: 5,
      title: 'Warm Amber',
      subtitle: 'Cam hổ phách ấm cúng (Light)',
      isDark: false,
      gradientColors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
      accentColor: Color(0xFFF59E0B),
    ),
    ThemePresetMeta(
      id: 6,
      title: 'Soft Blue Frost',
      subtitle: 'Băng giá mờ sương Glass (Light)',
      isDark: false,
      gradientColors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
      accentColor: Color(0xFF0284C7),
    ),
    ThemePresetMeta(
      id: 7,
      title: 'Pink Pastel Star',
      subtitle: 'Hồng phấn timeline ngôi sao (Light)',
      isDark: false,
      gradientColors: [Color(0xFFFDF2F8), Color(0xFFFCE7F3)],
      accentColor: Color(0xFFEC4899),
    ),
    ThemePresetMeta(
      id: 8,
      title: 'Pitch Charcoal Dark',
      subtitle: 'Đen than chì tối giản sang trọng (Dark)',
      isDark: true,
      gradientColors: [Color(0xFF121214), Color(0xFF1E1E22)],
      accentColor: Color(0xFFEF4444),
    ),
  ];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    assetStyle = (prefs.getInt(_assetKey) ?? 0).clamp(0, 6);
    budgetStyle = (prefs.getInt(_budgetKey) ?? 0).clamp(0, 3);
    assistantStyle = (prefs.getInt(_assistantKey) ?? 0).clamp(0, 3);
    historyStyle = (prefs.getInt(_historyKey) ?? 0).clamp(0, 8);
    notifyListeners();
  }

  Future<void> setAssetStyle(int value) =>
      _set(_assetKey, value.clamp(0, 6), () => assetStyle = value.clamp(0, 6));

  Future<void> setBudgetStyle(int value) => _set(
      _budgetKey, value.clamp(0, 3), () => budgetStyle = value.clamp(0, 3));

  Future<void> setAssistantStyle(int value) => _set(_assistantKey,
      value.clamp(0, 3), () => assistantStyle = value.clamp(0, 3));

  Future<void> setHistoryStyle(int value) => _set(
      _historyKey, value.clamp(0, 8), () => historyStyle = value.clamp(0, 8));

  Future<void> _set(String key, int value, VoidCallback apply) async {
    apply();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }
}
