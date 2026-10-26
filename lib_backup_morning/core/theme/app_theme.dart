import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_typography.dart';
import '../design_system/app_theme.dart' as ds;

/// Brand / semantic accent colors (constant across light & dark).
class Brand {
  static const primaryBlue = AppColors.accent;
  static const accentBlue = AppColors.accentLight;
  static const glowCyan = AppColors.accentLight;
  static const glowIndigo = Color(0xFF6366F1);
  static const primaryGreen = AppColors.success;
  static const errorRed = AppColors.error;
  static const warningOrange = AppColors.warning;
}

/// Theme-aware glassmorphism palette (mirrors FinoraColors in the Kotlin app).
@immutable
class FinoraColors {
  final List<Color> bgGradient;
  final Color glowA;
  final Color glowB;
  final Color surface; // glass card fill (translucent)
  final Color surfaceElevated; // recessed glass (tracks, chips)
  final Color highlight; // tinted glass (highlighted summary card)
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color hairline; // glass edge / dividers
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
    bgGradient: [AppColors.darkBg, AppColors.darkBg],
    glowA: AppColors.accent,
    glowB: Color(0xFF6366F1),
    surface: AppColors.darkSurface,
    surfaceElevated: AppColors.darkSurfaceElevated,
    highlight: AppColors.accent,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textTertiary: AppColors.darkTextTertiary,
    hairline: AppColors.darkBorder,
    isDark: true,
  );

  static const light = FinoraColors(
    bgGradient: [AppColors.lightBg, AppColors.lightBg],
    glowA: AppColors.accent,
    glowB: AppColors.accentLight,
    surface: AppColors.lightSurface,
    surfaceElevated: AppColors.lightSurfaceElevated,
    highlight: AppColors.accent,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textTertiary: AppColors.lightTextTertiary,
    hairline: AppColors.lightBorder,
    isDark: false,
  );
}

/// Convenience accessor: `context.fc` returns the active glass palette.
extension FinoraColorsContext on BuildContext {
  FinoraColors get fc {
    return Theme.of(this).brightness == Brightness.dark
        ? FinoraColors.dark
        : FinoraColors.light;
  }
}

/// App-wide text styles (mirrors Type.kt).
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
