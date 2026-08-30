import 'package:flutter/material.dart';

class FinoraTheme {
  static const lime = Color(0xFFD9FF63);
  static const cobalt = Color(0xFF5C6CFF);
  static const coral = Color(0xFFFF7167);
  static const ink = Color(0xFF10120F);
  static const ivory = Color(0xFFF4F2EA);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: lime,
      onPrimary: ink,
      secondary: cobalt,
      onSecondary: Colors.white,
      error: coral,
      onError: ink,
      surface: dark ? const Color(0xFF171A16) : Colors.white,
      onSurface: dark ? const Color(0xFFF5F7EF) : ink,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? ink : ivory,
      textTheme: const TextTheme(
        displaySmall: TextStyle(
            fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1.8),
        headlineMedium: TextStyle(
            fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1),
        headlineSmall: TextStyle(
            fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -.4),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        bodyMedium: TextStyle(fontSize: 14, height: 1.35),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
      cardTheme: CardThemeData(
          elevation: 0,
          color: dark ? const Color(0xFF1A1D18) : Colors.white,
          margin: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF222620) : Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: cobalt, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              backgroundColor: lime,
              foregroundColor: ink,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              textStyle: const TextStyle(fontWeight: FontWeight.w900))),
    );
  }
}
