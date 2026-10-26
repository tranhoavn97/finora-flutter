import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

ThemeData buildAppleTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: brightness,
    primary: dark ? const Color(0xFF9CBCFF) : AppColors.accent,
    onPrimary: dark ? const Color(0xFF10254B) : Colors.white,
    surface: dark ? AppColors.darkSurfaceSolid : AppColors.lightSurfaceSolid,
    onSurface: dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
    onSurfaceVariant:
        dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
    error: dark ? const Color(0xFFFF9B92) : AppColors.error,
    outline: dark ? AppColors.darkBorder : AppColors.lightBorder,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? AppColors.darkBg : AppColors.lightBg,
    textTheme: TextTheme(
      headlineLarge: AppTypography.largeTitle,
      headlineSmall: AppTypography.title2,
      titleLarge: AppTypography.title3,
      titleMedium: AppTypography.headline,
      bodyLarge: AppTypography.body,
      bodyMedium: AppTypography.body,
      bodySmall: AppTypography.footnote,
      labelLarge: AppTypography.buttonLabel,
      labelMedium: AppTypography.subhead,
      labelSmall: AppTypography.caption2,
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
    appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: dark ? AppColors.darkBg : AppColors.lightBg,
        foregroundColor: scheme.onSurface,
        titleTextStyle: AppTypography.title3.copyWith(color: scheme.onSurface)),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            minimumSize: const Size(48, 56),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
            textStyle: AppTypography.buttonLabel,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: scheme.outlineVariant),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: AppTypography.subhead,
    ),
    inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        border: OutlineInputBorder(borderRadius: AppRadius.input),
        enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.input,
            borderSide: BorderSide(color: scheme.outline)),
        focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.input,
            borderSide: BorderSide(color: scheme.primary, width: 2))),
    dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.modal)),
    bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape:
            const RoundedRectangleBorder(borderRadius: AppRadius.bottomSheet)),
    snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface)),
    dividerTheme:
        DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
  );
}
