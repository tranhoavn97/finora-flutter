import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';

class AppTypography {
  static const String? fontFamily = null;
  static TextStyle role(double size, double line, FontWeight weight, {List<FontFeature>? fontFeatures}) =>
      TextStyle(
        fontSize: size,
        height: line / size,
        fontWeight: weight,
        fontFeatures: fontFeatures,
      );
  static TextStyle get largeTitle => role(32, 40, FontWeight.w700);
  static TextStyle get title1 => role(24, 32, FontWeight.w700);
  static TextStyle get title2 => role(24, 32, FontWeight.w700);
  static TextStyle get title3 => role(18, 24, FontWeight.w600);
  static TextStyle get headline => role(16, 24, FontWeight.w600);
  static TextStyle get body => role(16, 24, FontWeight.w400);
  static TextStyle get callout => role(16, 24, FontWeight.w500);
  static TextStyle get subhead => role(14, 20, FontWeight.w500);
  static TextStyle get footnote => role(13, 18, FontWeight.w400);
  static TextStyle get caption1 => role(13, 18, FontWeight.w400);
  static TextStyle get caption2 => role(12, 16, FontWeight.w500);
  static TextStyle get buttonLabel => role(16, 24, FontWeight.w600);
  static TextStyle get numericValue =>
      role(24, 32, FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()]);
  static TextStyle get numericLarge =>
      role(32, 40, FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()]);
  static TextStyle get numericSmall =>
      role(16, 22, FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()]);
}
