import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';

ThemeData buildAppleTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final primaryColor = AppColors.accent;

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: primaryColor,
    onPrimary: Colors.white,
    secondary: AppColors.accentLight,
    onSecondary: Colors.white,
    error: AppColors.error,
    onError: Colors.white,
    background: isDark ? AppColors.darkBg : AppColors.lightBg,
    onBackground: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
    surface: isDark ? AppColors.darkSurfaceSolid : AppColors.lightSurfaceSolid,
    onSurface: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
  );

  final textTheme = (isDark
          ? Typography.material2021(platform: TargetPlatform.android).white
          : Typography.material2021(platform: TargetPlatform.android).black)
      .apply(
        fontFamily: 'OPPOSans',
        bodyColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        displayColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: textTheme,
    dialogTheme: DialogThemeData(
      backgroundColor: isDark ? AppColors.darkSurfaceSolid : AppColors.lightSurfaceSolid,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.modal),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: isDark ? AppColors.darkSurfaceSolid : AppColors.lightSurfaceSolid,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.bottomSheet),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      contentTextStyle: TextStyle(
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSM),
    ),
    splashFactory: InkRipple.splashFactory,
  );
}
