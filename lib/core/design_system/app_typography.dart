import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';

class AppTypography {
  static String? activeFontFamily = 'BeVietnamPro';
  static List<String>? activeFontFamilyFallback = const [
    'BeVietnamPro',
    'PlusJakartaSans',
    'Inter',
    'Lexend',
    'Manrope',
    'Roboto',
    'sans-serif',
  ];
  static const String? fontFamily = 'BeVietnamPro';

  static TextStyle role(
    double size,
    double line,
    FontWeight weight, {
    double? letterSpacing,
    List<FontFeature>? fontFeatures,
    String? fontFamily,
    List<String>? fontFamilyFallback,
  }) =>
      TextStyle(
        fontFamily: fontFamily ?? activeFontFamily ?? 'BeVietnamPro',
        fontFamilyFallback:
            fontFamilyFallback ?? activeFontFamilyFallback ?? const ['PlusJakartaSans', 'Inter', 'sans-serif'],
        fontSize: size,
        height: line / size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        fontFeatures: fontFeatures,
      );

  static TextStyle get display =>
      role(36, 42, FontWeight.w800, letterSpacing: -0.75, fontFeatures: const [FontFeature.tabularFigures()]);
  static TextStyle get largeTitle =>
      role(30, 36, FontWeight.w800, letterSpacing: -0.55);
  static TextStyle get title1 =>
      role(24, 30, FontWeight.w800, letterSpacing: -0.45);
  static TextStyle get title2 =>
      role(20, 26, FontWeight.w700, letterSpacing: -0.35);
  static TextStyle get title3 =>
      role(17.5, 23, FontWeight.w700, letterSpacing: -0.25);
  static TextStyle get headline =>
      role(15.5, 21.5, FontWeight.w700, letterSpacing: -0.2);
  static TextStyle get body =>
      role(14.5, 21, FontWeight.w500, letterSpacing: -0.05);
  static TextStyle get callout =>
      role(14.5, 20.5, FontWeight.w600, letterSpacing: -0.1);
  static TextStyle get subhead =>
      role(13.5, 19, FontWeight.w600, letterSpacing: -0.05);
  static TextStyle get footnote =>
      role(12.5, 17.5, FontWeight.w500, letterSpacing: 0.0);
  static TextStyle get caption1 =>
      role(12, 16.5, FontWeight.w500, letterSpacing: 0.05);
  static TextStyle get caption2 =>
      role(11.5, 15.5, FontWeight.w600, letterSpacing: 0.1);
  static TextStyle get buttonLabel =>
      role(15, 20, FontWeight.w700, letterSpacing: -0.15);
  static TextStyle get numericValue => role(
        24,
        30,
        FontWeight.w800,
        letterSpacing: -0.45,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
  static TextStyle get numericLarge => role(
        32,
        38,
        FontWeight.w800,
        letterSpacing: -0.65,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
  static TextStyle get numericSmall => role(
        15.5,
        21,
        FontWeight.w700,
        letterSpacing: -0.2,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
