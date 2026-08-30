import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppShadows {
  // Soft, diffuse light card shadow
  static List<BoxShadow> get lightCardShadow => [
        BoxShadow(
          color: const Color(0xFF101828).withValues(alpha: 0.05),
          blurRadius: 24,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: const Color(0xFF5B6FD4).withValues(alpha: 0.03),
          blurRadius: 12,
          spreadRadius: -2,
          offset: const Offset(0, 4),
        ),
      ];

  // Elevated floating surface shadow
  static List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: const Color(0xFF101828).withValues(alpha: 0.08),
          blurRadius: 32,
          spreadRadius: 0,
          offset: const Offset(0, 12),
        ),
      ];

  // Dark mode diffuse shadow
  static List<BoxShadow> get darkCardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.40),
          blurRadius: 24,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  // Primary color glow for active buttons and FAB
  static List<BoxShadow> primaryGlow([Color color = AppColors.primary]) => [
        BoxShadow(
          color: color.withValues(alpha: 0.28),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  // Accent color glow
  static List<BoxShadow> get accentGlow => [
        BoxShadow(
          color: AppColors.accent.withValues(alpha: 0.32),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];
}
