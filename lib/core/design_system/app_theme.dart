import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';

ThemeData buildAppleTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final background = dark ? AppColors.darkBg : AppColors.lightBg;
  final surface =
      dark ? AppColors.darkSurfaceSolid : AppColors.lightSurfaceSolid;
  final text = dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  final muted =
      dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  final border = dark ? AppColors.darkBorder : AppColors.lightBorder;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: brightness,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    tertiary: AppColors.accent,
    error: AppColors.error,
    surface: surface,
  );
  final baseText = (dark
          ? Typography.material2021(platform: TargetPlatform.android).white
          : Typography.material2021(platform: TargetPlatform.android).black)
      .apply(bodyColor: text, displayColor: text);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: background,
    textTheme: baseText,
    dividerColor: border,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: text,
      titleTextStyle: TextStyle(
          color: text,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: surface,
      shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card, side: BorderSide(color: border)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor:
          dark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
      selectedColor: AppColors.primary.withValues(alpha: dark ? .24 : .12),
      side: BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelStyle: TextStyle(color: text, fontWeight: FontWeight.w600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
      hintStyle: TextStyle(color: muted),
      border: OutlineInputBorder(
          borderRadius: AppRadius.input, borderSide: BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input, borderSide: BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    ),
    dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.dialog)),
    bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.bottomSheet)),
    snackBarTheme: SnackBarThemeData(
      backgroundColor:
          dark ? AppColors.darkSurfaceElevated : AppColors.lightTextPrimary,
      contentTextStyle: const TextStyle(color: AppColors.darkTextPrimary),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSM),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: AppColors.primary.withValues(alpha: 0.12),
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : muted,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          )),
    ),
  );
}
