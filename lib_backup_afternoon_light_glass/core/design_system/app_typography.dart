import 'package:flutter/material.dart';

class AppTypography {
  static const String? fontFamily = 'OPPOSans';

  static TextStyle get largeTitle => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.37,
      );

  static TextStyle get title1 => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.36,
      );

  static TextStyle get title2 => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.35,
      );

  static TextStyle get title3 => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.38,
      );

  static TextStyle get headline => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.41,
      );

  static TextStyle get body => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.41,
      );

  static TextStyle get callout => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.32,
      );

  static TextStyle get subhead => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.24,
      );

  static TextStyle get footnote => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.08,
      );

  static TextStyle get caption1 => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
      );

  static TextStyle get caption2 => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.07,
      );

  static TextStyle get buttonLabel => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.32,
      );

  static TextStyle get numericValue => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.35,
      );
}
