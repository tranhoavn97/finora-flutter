import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';
import 'v8/finora_v8_tokens.dart';

ThemeData buildAppleTheme(
  Brightness brightness, {
  Color? primaryColor,
  Color? secondaryColor,
  Color? lightBg,
  Color? darkBg,
  bool isAmoled = false,
}) {
  final dark = brightness == Brightness.dark;
  final effectiveSeed = primaryColor ?? AppColors.accent;
  final bg = dark
      ? (isAmoled ? Colors.black : (darkBg ?? AppColors.darkBg))
      : (lightBg ?? AppColors.lightBg);
  final surface = dark
      ? (isAmoled ? const Color(0xFF070B12) : AppColors.darkSurfaceSolid)
      : AppColors.lightSurfaceSolid;

  final scheme = ColorScheme.fromSeed(
    seedColor: effectiveSeed,
    brightness: brightness,
    primary: dark
        ? (isAmoled
            ? effectiveSeed
            : Color.lerp(effectiveSeed, Colors.white, 0.35)!)
        : effectiveSeed,
    onPrimary: dark ? const Color(0xFF071224) : Colors.white,
    secondary: secondaryColor ?? AppColors.secondary,
    surface: surface,
    onSurface: dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
    onSurfaceVariant:
        dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
    error: dark ? const Color(0xFFFF9B92) : AppColors.error,
    outline: dark
        ? (isAmoled ? const Color(0xFF1E2638) : AppColors.darkBorder)
        : AppColors.lightBorder,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    cardColor: surface,
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
        backgroundColor: bg,
        foregroundColor: scheme.onSurface,
        titleTextStyle:
            FinoraV8Type.pageTitle.copyWith(color: scheme.onSurface)),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: BorderSide(
          color: dark
              ? Colors.white.withValues(alpha: .10)
              : const Color(0xFFC6C6C8).withValues(alpha: .42),
          width: .7,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
            textStyle: FinoraV8Type.label,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14))),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 50),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      backgroundColor: dark
          ? Colors.white.withValues(alpha: .07)
          : Colors.white.withValues(alpha: .88),
      selectedColor: scheme.primary.withValues(alpha: .12),
      side: BorderSide(
        color: dark
            ? Colors.white.withValues(alpha: .08)
            : const Color(0xFFDCE7F1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: AppTypography.subhead,
    ),
    inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF2C2C2E) : const Color(0xFFEFEFF4),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        border: OutlineInputBorder(borderRadius: AppRadius.input),
        enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.input, borderSide: BorderSide.none),
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
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 105),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isAmoled
            ? const Color(0xFF1E293B)
            : (brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : const Color(0xFF0F172A)),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        )),
    dividerTheme:
        DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
  );
}
