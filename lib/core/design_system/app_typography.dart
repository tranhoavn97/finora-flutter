import 'package:flutter/material.dart';

class AppTypography {
  static const String? fontFamily = null;

  static TextStyle get display => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
      );

  static TextStyle get largeTitle => display;

  static TextStyle get h1 => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      );

  static TextStyle get title1 => h1;

  static TextStyle get h2 => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      );

  static TextStyle get title2 => h2;

  static TextStyle get h3 => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      );

  static TextStyle get title3 => h3;

  static TextStyle get title => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      );

  static TextStyle get headline => title;

  static TextStyle get body => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
      );

  static TextStyle get callout => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.3,
      );

  static TextStyle get subhead => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.15,
      );

  static TextStyle get footnote => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.05,
      );

  static TextStyle get caption => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.0,
      );

  static TextStyle get caption1 => caption;

  static TextStyle get caption2 => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.05,
      );

  static TextStyle get micro => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );

  static TextStyle get buttonLabel => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      );

  static TextStyle get numericValue => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      );
}
