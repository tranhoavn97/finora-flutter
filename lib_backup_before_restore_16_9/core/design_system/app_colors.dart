import 'package:flutter/material.dart';

class AppColors {
  // Light Mode Colors (FINORA Pure)
  static const Color lightBg = Color(0xFFF8FAFC); // Clean Slate Mist
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure White
  static const Color lightSurfaceSolid = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9);

  static const Color lightTextPrimary = Color(0xFF0F172A); // Deep Slate 900
  static const Color lightTextSecondary = Color(0xFF64748B); // Slate 500
  static const Color lightTextTertiary = Color(0xFF94A3B8); // Slate 400
  static const Color lightBorder = Color(0xFFE2E8F0); // Subtle Slate border
  static const Color lightDivider = Color(0xFFF1F5F9);

  // Dark Mode Colors (FINORA Pure Dark)
  static const Color darkBg = Color(0xFF0B0F17); // Obsidian Midnight
  static const Color darkSurface = Color(0xFF141C2B); // Slate Dark Card
  static const Color darkSurfaceSolid = Color(0xFF141C2B);
  static const Color darkSurfaceElevated = Color(0xFF1E293B);

  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextTertiary = Color(0xFF64748B);
  static const Color darkBorder = Color(0xFF243045);
  static const Color darkDivider = Color(0xFF1E293B);

  // Semantic Colors (Shared)
  static const Color primary = Color(0xFF2563EB); // Pure Cobalt
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color secondary = Color(0xFF0F172A);
  static const Color accent = Color(0xFF2563EB);
  static const Color accentLight = Color(0xFF93C5FD);
  static const Color sirenDarkNavy = Color(0xFF0B0F17);
  static const Color success = Color(0xFF10B981); // Emerald Green (Thu vào / Tiết kiệm)
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFF43F5E); // Rose Crimson (Chi ra)
  static const Color expense = Color(0xFFF43F5E);
  static const Color income = Color(0xFF10B981);
  static const Color info = Color(0xFF2563EB);

  static const LinearGradient heroBlueGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroPurpleGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroBalanceGradient = LinearGradient(
    colors: [Color(0xFF1E40AF), Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Apex Sunrise Mobile Banking Colors (Warm Amber & Silk Orange)
  static const Color orangePrimary = Color(0xFFFF6A00);
  static const Color orangeLight = Color(0xFFFF9500);
  static const Color orangeDeep = Color(0xFFFF4800);
  static const Color orangeDark = Color(0xFFD94400);

  static const LinearGradient heroOrangeGradient = LinearGradient(
    colors: [Color(0xFFFF9500), Color(0xFFFF5E36), Color(0xFFFF3B30)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroSilkAmberGradient = LinearGradient(
    colors: [Color(0xFFFFA033), Color(0xFFFF6F37), Color(0xFFF93F20)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Sheet & Pill Tokens
  static const Color sheetLight = Color(0xFFFFFFFF);
  static const Color sheetDark = Color(0xFF161B26);
  static const Color pillTrackLight = Color(0xFFF2F4F7);
  static const Color pillTrackDark = Color(0xFF232A38);
  static const Color pillActiveLight = Color(0xFFFFFFFF);
  static const Color pillActiveDark = Color(0xFF2E384D);
}
