import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mirrors ThemeConfig.kt — persists Light / Dark / System, defaults to Dark
/// (the navy glass look).
class ThemeController extends ChangeNotifier {
  static const _key = 'theme_mode';
  String _mode = 'light'; // "system" | "light" | "dark" | "amoled"

  String get mode => _mode;
  bool get isAmoled => _mode == 'amoled';

  ThemeMode get themeMode {
    switch (_mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
      case 'amoled':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = prefs.getString(_key) ?? 'light';
    notifyListeners();
  }

  Future<void> setMode(String mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode);
  }
}
