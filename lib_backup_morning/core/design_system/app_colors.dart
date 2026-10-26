import 'package:flutter/material.dart';

class AppColors {
  // Light Mode Colors
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF); // Solid white cards
  static const Color lightSurfaceSolid = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9);

  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextTertiary = Color(0xFF94A3B8);
  static const Color lightBorder = Color(0xFFE2E8F0); // Subtle gray border
  static const Color lightDivider = Color(0xFFF1F5F9);

  // Dark Mode Colors
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceSolid = Color(0xFF1E293B);
  static const Color darkSurfaceElevated = Color(0xFF334155);

  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextTertiary = Color(0xFF64748B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkDivider = Color(0xFF1E293B);

  // Semantic Colors (Shared)
  static const Color primary = Color(0xFF2563EB); // Royal Blue
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color secondary = Color(0xFF3B82F6);
  static const Color accent = Color(0xFF2563EB);
  static const Color accentLight = Color(0xFF60A5FA);
  static const Color sirenDarkNavy = Color(0xFF0F172A);
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color warning = Color(0xFFF59E0B); // Amber Orange
  static const Color error = Color(0xFFEF4444); // Crimson Red
  static const Color info = Color(0xFF2563EB);

  static const LinearGradient heroBlueGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroPurpleGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroBalanceGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
