import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_typography.dart';
import '../design_system/app_theme.dart' as ds;

/// Brand / semantic accent colors.
class Brand {
  static const primaryBlue = AppColors.primary;
  static const secondaryBlue = AppColors.secondary;
  static const accentBlue = AppColors.secondary;
  static const glowCyan = AppColors.cyan;
  static const glowIndigo = AppColors.primary;
  static const primaryGreen = AppColors.success;
  static const errorRed = AppColors.error;
  static const warningOrange = AppColors.warning;
  static const accentWarm = AppColors.accent;
}

/// Theme-aware luxury fintech palette.
@immutable
class FinoraColors {
  final List<Color> bgGradient;
  final Color glowA;
  final Color glowB;
  final Color surface;
  final Color surfaceElevated;
  final Color highlight;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color hairline;
  final bool isDark;

  const FinoraColors({
    required this.bgGradient,
    required this.glowA,
    required this.glowB,
    required this.surface,
    required this.surfaceElevated,
    required this.highlight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.hairline,
    required this.isDark,
  });

  static const dark = FinoraColors(
    bgGradient: [AppColors.darkBg, AppColors.darkBg, Color(0xFF111217)],
    glowA: AppColors.primary,
    glowB: AppColors.secondary,
    surface: AppColors.darkSurface,
    surfaceElevated: AppColors.darkSurfaceElevated,
    highlight: AppColors.primary,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textTertiary: AppColors.darkTextTertiary,
    hairline: AppColors.darkBorder,
    isDark: true,
  );

  static const light = FinoraColors(
    bgGradient: [AppColors.lightBg, AppColors.lightBg, AppColors.lightBgWarm],
    glowA: AppColors.primaryLight,
    glowB: Color(0xFFFFEEDB),
    surface: AppColors.lightSurface,
    surfaceElevated: AppColors.lightSurfaceElevated,
    highlight: AppColors.primary,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textTertiary: AppColors.lightTextTertiary,
    hairline: AppColors.lightBorder,
    isDark: false,
  );
}

extension FinoraColorsContext on BuildContext {
  FinoraColors get fc {
    return Theme.of(this).brightness == Brightness.dark
        ? FinoraColors.dark
        : FinoraColors.light;
  }
}

class AppText {
  static TextStyle get mainBalance => AppTypography.numericValue;
  static TextStyle get pageTitle => AppTypography.title2;
  static TextStyle get sectionTitle => AppTypography.title3;
  static TextStyle get cardTitle => AppTypography.headline;
  static TextStyle get body => AppTypography.body;
  static TextStyle get caption => AppTypography.caption1;
  static TextStyle get overline => AppTypography.caption2;
}

ThemeData buildFinoraTheme(Brightness brightness) {
  return ds.buildAppleTheme(brightness);
}
