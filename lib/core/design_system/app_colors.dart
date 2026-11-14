import 'package:flutter/material.dart';

class AppColors {
  // Light Mode Colors — Alabaster & Crisp White (Adaptive Quiet Luxury)
  static const Color lightBg = Color(0xFFF4F6F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSolid = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFEDF2F7);

  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextTertiary = Color(0xFF94A3B8);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightDivider = Color(0xFFEDF2F7);

  // Dark Mode Colors — Obsidian & Specular Slate (Adaptive Quiet Luxury)
  static const Color darkBg = Color(0xFF090D16);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkSurfaceSolid = Color(0xFF111827);
  static const Color darkSurfaceElevated = Color(0xFF1E293B);

  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextTertiary = Color(0xFF64748B);
  static const Color darkBorder = Color(0xFF1E293B);
  static const Color darkDivider = Color(0xFF1E293B);

  // Semantic & Brand Colors (Apple HIG & Finora Semantics)
  static const Color primary = Color(0xFF0F6E56);
  static const Color primaryLight = Color(0xFF38BDF8);
  static const Color primaryDark = Color(0xFF10B981);
  static const Color secondary = Color(0xFF10B981);
  static const Color accent = Color(0xFF0F6E56);
  static const Color accentLight = Color(0xFF34D399);
  static const Color sirenDarkNavy = Color(0xFF0B1014);
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFE11D48);
  static const Color info = Color(0xFF0284C7);

  // Couple & Family Member Semantics
  static const Color husbandBlue = Color(0xFF0066CC);
  static const Color wifePink = Color(0xFFDB2777);
  static const Color jointTeal = Color(0xFF0D9488);

  static const LinearGradient heroBlueGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroPurpleGradient = LinearGradient(
    colors: [Color(0xFF003D35), Color(0xFF00866A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroBalanceGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroEmeraldGradient = LinearGradient(
    colors: [Color(0xFF043927), Color(0xFF0B6645)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color mintSoftLight = Color(0xFFE6F7F0);
  static const Color mintSoftDark = Color(0xFF13382C);
  static const Color primaryActionGreen = Color(0xFF00875A);
}
