import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'v8/finora_v8_tokens.dart';

ThemeData buildAppleTheme(
  Brightness brightness, {
  Color? primaryColor,
  Color? secondaryColor,
  Color? lightBg,
  Color? darkBg,
  bool isAmoled = false,
  double buttonRadius = 999.0,
  double buttonHeight = 50.0,
  EdgeInsetsGeometry? buttonPadding,
  double? cardRadius,
  Color? cardFillColor,
  Color? modalFillColor,
  String? fontFamily,
  List<String>? fontFamilyFallback,
  Border? cardBorder,
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
    onPrimary: Colors.white,
    secondary: secondaryColor ?? AppColors.secondary,
    primaryContainer: Color.alphaBlend(
        effectiveSeed.withValues(alpha: dark ? 0.25 : 0.10), surface),
    onPrimaryContainer:
        dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
    secondaryContainer: Color.alphaBlend(
        effectiveSeed.withValues(alpha: dark ? 0.22 : 0.10), surface),
    onSecondaryContainer:
        dark ? AppColors.darkTextPrimary : AppColors.primaryDark,
    surface: surface,
    onSurface: dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
    onSurfaceVariant:
        dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
    error: dark ? const Color(0xFFFF9B92) : AppColors.error,
    outline: dark
        ? (isAmoled ? const Color(0xFF1E2638) : AppColors.darkBorder)
        : AppColors.lightBorder,
  );

  final OutlinedBorder buttonShape = buttonRadius >= 999.0
      ? const StadiumBorder()
      : RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius));

  final effectiveCardRadius = cardRadius ?? 24.0;
  final effectiveCardBorderSide = cardBorder?.top ??
      BorderSide(
        color: dark
            ? Colors.white.withValues(alpha: 0.12)
            : const Color(0xFFE2E8F0),
        width: 1.0,
      );
  final effectiveButtonPadding =
      buttonPadding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14);

  final effectiveFont =
      fontFamily ?? AppTypography.activeFontFamily ?? 'BeVietnamPro';
  final effectiveFallback = fontFamilyFallback ??
      AppTypography.activeFontFamilyFallback ??
      const ['BeVietnamPro', 'PlusJakartaSans', 'Inter', 'sans-serif'];

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: effectiveFont,
    fontFamilyFallback: effectiveFallback,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    cardColor: cardFillColor ?? scheme.surface,
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.primary.withValues(alpha: 0.10),
      circularTrackColor: scheme.primary.withValues(alpha: 0.10),
    ),
    cardTheme: CardThemeData(
      color: cardFillColor ?? scheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(effectiveCardRadius),
        side: cardBorder != null ? effectiveCardBorderSide : BorderSide.none,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: AppTypography.display,
      displayMedium: AppTypography.largeTitle,
      displaySmall: AppTypography.title1,
      headlineLarge: AppTypography.largeTitle,
      headlineMedium: AppTypography.title1,
      headlineSmall: AppTypography.title2,
      titleLarge: AppTypography.title3,
      titleMedium: AppTypography.headline,
      titleSmall: AppTypography.callout,
      bodyLarge: AppTypography.body,
      bodyMedium: AppTypography.body,
      bodySmall: AppTypography.footnote,
      labelLarge: AppTypography.buttonLabel,
      labelMedium: AppTypography.subhead,
      labelSmall: AppTypography.caption2,
    ).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
      fontFamily: effectiveFont,
      fontFamilyFallback: effectiveFallback,
    ),
    appBarTheme: AppBarTheme(
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle:
            FinoraV8Type.pageTitle.copyWith(color: scheme.onSurface)),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: Size(buttonHeight * 0.88, buttonHeight * 0.88),
        shape: buttonShape,
        foregroundColor: scheme.onSurface,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            minimumSize: Size(48, buttonHeight),
            shape: buttonShape,
            textStyle: AppTypography.buttonLabel,
            padding: effectiveButtonPadding)),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(48, buttonHeight),
        shape: buttonShape,
        padding: effectiveButtonPadding,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        textStyle: AppTypography.buttonLabel,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: Size(48, buttonHeight * 0.94),
        shape: buttonShape,
        padding: effectiveButtonPadding,
        textStyle: AppTypography.buttonLabel,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: buttonShape,
        textStyle: AppTypography.callout,
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
        hintStyle: AppTypography.body.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
          fontWeight: FontWeight.w400,
        ),
        labelStyle: AppTypography.subhead.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
                (effectiveCardRadius * 0.75).clamp(10.0, 24.0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
                (effectiveCardRadius * 0.75).clamp(10.0, 24.0)),
            borderSide: BorderSide(color: scheme.outline)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
                (effectiveCardRadius * 0.75).clamp(10.0, 24.0)),
            borderSide: BorderSide(color: scheme.primary, width: 2))),
    dialogTheme: DialogThemeData(
        backgroundColor: modalFillColor ?? scheme.surface,
        elevation: 0,
        titleTextStyle: AppTypography.title3.copyWith(color: scheme.onSurface),
        contentTextStyle:
            AppTypography.body.copyWith(color: scheme.onSurfaceVariant),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                (effectiveCardRadius * 1.1).clamp(16.0, 32.0)))),
    bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: modalFillColor ?? scheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(
                    (effectiveCardRadius * 1.25).clamp(20.0, 36.0))))),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? const Color(0xFF0F172A) : Colors.white,
      elevation: 0,
      indicatorColor: scheme.primary.withValues(alpha: dark ? 0.22 : 0.14),
      indicatorShape: const StadiumBorder(),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontFamily: effectiveFont,
          fontFamilyFallback: effectiveFallback,
          fontSize: 11.5,
          letterSpacing: -0.1,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          color: selected
              ? scheme.primary
              : (dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 22,
          color: selected
              ? scheme.primary
              : (dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        );
      }),
    ),
    snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        backgroundColor: isAmoled
            ? const Color(0xFF1E293B)
            : (brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : const Color(0xFF0F172A)),
        contentTextStyle: TextStyle(
          fontFamily: effectiveFont,
          fontFamilyFallback: effectiveFallback,
          color: Colors.white,
          fontSize: 13.5,
          letterSpacing: -0.1,
          fontWeight: FontWeight.w600,
        )),
    dividerTheme:
        DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
  );
}
