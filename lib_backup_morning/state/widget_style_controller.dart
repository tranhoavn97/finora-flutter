import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePresetMeta {
  final int id;
  final String title;
  final String subtitle;
  final bool isDark;
  final List<Color> gradientColors;
  final Color accentColor;

  const ThemePresetMeta({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.gradientColors,
    required this.accentColor,
  });
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
      title: 'Vũ trụ huyền bí',
      subtitle: 'Nền không gian vũ trụ Finora',
      isDark: true,
      gradientColors: [Color(0xFF020617), Color(0xFF1E1B4B)],
      accentColor: Color(0xFF818CF8),
    ),
    ThemePresetMeta(
      id: 1,
      title: 'Neon Cyan Pulse',
      subtitle: 'Sóng biểu đồ Neon phát sáng',
      isDark: true,
      gradientColors: [Color(0xFF04132B), Color(0xFF0A2540)],
      accentColor: Color(0xFF38BDF8),
    ),
    ThemePresetMeta(
      id: 2,
      title: 'Cyber Purple EQ',
      subtitle: 'Cột Equalizer tím Neon sống động',
      isDark: true,
      gradientColors: [Color(0xFF0F061E), Color(0xFF220D45)],
      accentColor: Color(0xFFC084FC),
    ),
    ThemePresetMeta(
      id: 3,
      title: 'Emerald Wave',
      subtitle: 'Sóng ngọc lục bảo & điểm chốt sáng',
      isDark: true,
      gradientColors: [Color(0xFF021B1D), Color(0xFF063335)],
      accentColor: Color(0xFF2DD4BF),
    ),
    ThemePresetMeta(
      id: 4,
      title: 'Starlight Meteors',
      subtitle: 'Dải sao băng hoàng kim sang trọng',
      isDark: true,
      gradientColors: [Color(0xFF0A0A0C), Color(0xFF1C1917)],
      accentColor: Color(0xFFFBBF24),
    ),
    ThemePresetMeta(
      id: 5,
      title: 'Pearl Pastel',
      subtitle: 'Trắng ngọc trai & đồi sóng pastel',
      isDark: false,
      gradientColors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
      accentColor: Color(0xFF3B82F6),
    ),
    ThemePresetMeta(
      id: 6,
      title: 'Sci-Fi Holo Radar',
      subtitle: 'Radar hologram & khung cyber vát góc',
      isDark: true,
      gradientColors: [Color(0xFF04131D), Color(0xFF082230)],
      accentColor: Color(0xFF06B6D4),
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
