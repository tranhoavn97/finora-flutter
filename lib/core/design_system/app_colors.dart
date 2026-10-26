import 'package:flutter/material.dart';

class AppColors {
  // Light Mode Colors — Clean Warm Paper & Ink ("Sổ tay tối giản")
  static const Color lightBg = Color(0xFFF6F5F2);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSolid = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFEFEDE8);

  static const Color lightTextPrimary = Color(0xFF141518);
  static const Color lightTextSecondary = Color(0xFF5E6168);
  static const Color lightTextTertiary = Color(0xFF9A9CA1);
  static const Color lightBorder = Color(0xFFE6E3DC);
  static const Color lightDivider = Color(0xFFE6E3DC);

  // Dark Mode Colors — Warm Charcoal & Soft Ink
  static const Color darkBg = Color(0xFF0E0F10);
  static const Color darkSurface = Color(0xFF17181A);
  static const Color darkSurfaceSolid = Color(0xFF17181A);
  static const Color darkSurfaceElevated = Color(0xFF1F2023);

  static const Color darkTextPrimary = Color(0xFFECEBE7);
  static const Color darkTextSecondary = Color(0xFFA3A5AA);
  static const Color darkTextTertiary = Color(0xFF6D6F74);
  static const Color darkBorder = Color(0xFF25272A);
  static const Color darkDivider = Color(0xFF25272A);

  // Semantic & Brand Colors (Warm Minimalist Ink)
  static const Color primary = Color(0xFF141518);
  static const Color primaryLight = Color(0xFF2E7D55);
  static const Color primaryDark = Color(0xFF0E0F10);
  static const Color secondary = Color(0xFF5E6168);
  static const Color accent = Color(0xFF141518);
  static const Color accentLight = Color(0xFF2E7D55);
  static const Color sirenDarkNavy = Color(0xFF141518);
  static const Color success = Color(0xFF2E7D55);
  static const Color warning = Color(0xFFB07A1E);
  static const Color error = Color(0xFFB5452F);
  static const Color info = Color(0xFF141518);

  static const LinearGradient heroBlueGradient = LinearGradient(
    colors: [Color(0xFF0F6E56), Color(0xFF147A60)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroPurpleGradient = LinearGradient(
    colors: [Color(0xFF0F6E56), Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroBalanceGradient = LinearGradient(
    colors: [Color(0xFF0D5C48), Color(0xFF147A60)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
