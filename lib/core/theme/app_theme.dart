import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/theme_studio_controller.dart' show PaletteMeta, ThemeStudioController;
import '../design_system/app_colors.dart';
import '../design_system/app_typography.dart';
import '../design_system/app_theme.dart' as ds;

/// Brand / semantic accent colors (constant across light & dark).
class Brand {
  static const primaryBlue = AppColors.accent;
  static const accentBlue = AppColors.accentLight;
  static const glowCyan = AppColors.accentLight;
  static const glowOcean = Color(0xFF0284C7);
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
    glowB: Color(0xFF0284C7),
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
    final dark = Theme.of(this).brightness == Brightness.dark;
    final base = dark ? FinoraColors.dark : FinoraColors.light;
    try {
      final studio = Provider.of<ThemeStudioController?>(this, listen: false);
      if (studio != null) {
        return FinoraColors(
          bgGradient: base.bgGradient,
          glowA: base.glowA,
          glowB: base.glowB,
          surface: studio.getCardFillColor(dark),
          surfaceElevated: studio.getCardFillColor(dark).withValues(alpha: (studio.glassOpacity + 0.12).clamp(0.25, 0.95)),
          highlight: base.highlight,
          textPrimary: base.textPrimary,
          textSecondary: base.textSecondary,
          textTertiary: base.textTertiary,
          hairline: studio.getBorderColor(dark),
          isDark: dark,
        );
      }
    } catch (_) {}
    return base;
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

ThemeData buildFinoraTheme(
  Brightness brightness, {
  PaletteMeta? palette,
  bool isAmoled = false,
  double buttonRadius = 999.0,
  double buttonHeight = 50.0,
  EdgeInsetsGeometry? buttonPadding,
  double? cardRadius,
  Border? cardBorder,
  Color? cardFillColor,
  Color? modalFillColor,
  String? fontFamily,
  List<String>? fontFamilyFallback,
}) {
  return ds.buildAppleTheme(
    brightness,
    primaryColor: palette?.primary,
    secondaryColor: palette?.secondary,
    lightBg: palette?.lightBg,
    darkBg: palette?.darkBg,
    isAmoled: isAmoled,
    buttonRadius: buttonRadius,
    buttonHeight: buttonHeight,
    buttonPadding: buttonPadding,
    cardRadius: cardRadius,
    cardBorder: cardBorder,
    cardFillColor: cardFillColor,
    modalFillColor: modalFillColor,
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
  );
}
