import 'package:flutter/material.dart';

class AppColors {
  // Light Mode Colors
  static const Color lightBg = Color(0xFFF4F6FA);
  static const Color lightSurface = Color(0xFFFFFFFF); // Solid white cards
  static const Color lightSurfaceSolid = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF8F9FC);
  
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextTertiary = Color(0xFF94A3B8);
  static const Color lightBorder = Color(0xFFE2E8F0); // Subtle gray border
  static const Color lightDivider = Color(0xFFE2E8F0);

  // Dark Mode Colors
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkSurface = Color(0x13FFFFFF); // Translucent glass 7%
  static const Color darkSurfaceSolid = Color(0xFF1E293B);
  static const Color darkSurfaceElevated = Color(0x0CFFFFFF);

  static const Color darkTextPrimary = Color(0xFFF2F2F7);
  static const Color darkTextSecondary = Color(0xFFAEAEB2);
  static const Color darkTextTertiary = Color(0xFF7C7C80);
  static const Color darkBorder = Color(0x1AFFFFFF); // Low opacity white border
  static const Color darkDivider = Color(0x26FFFFFF);

  // Semantic Colors (Shared)
  static const Color accent = Color(0xFF1849A9); // Royal navy blue from screenshot
  static const Color accentLight = Color(0xFF3B71CA); // Soft navy blue helper
  static const Color success = Color(0xFF34C759); // iOS Green
  static const Color warning = Color(0xFFFF9500); // iOS Orange
  static const Color error = Color(0xFFFF3B30); // iOS Red
  static const Color info = Color(0xFF007AFF); // iOS Blue
}
