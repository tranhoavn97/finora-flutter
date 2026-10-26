import 'package:flutter/material.dart';
import '../app_typography.dart';

/// FINORA V8 foundations. Feature screens should consume semantic roles instead
/// of introducing new numeric values for repeated UI patterns.
abstract final class FinoraV8Colors {
  static const brand = Color(0xFF0F6E56);
  static const brandPressed = Color(0xFF0B4F3E);
  static const neutral = Color(0xFF475569);
  static const income = Color(0xFF059669);
  static const expense = Color(0xFFDC2626);
  static const investment = Color(0xFFD97706);
  static const saving = Color(0xFF0F766E);
  static const husband = Color(0xFF0F6E56);
  static const wife = Color(0xFFDB2777);
  static const shared = Color(0xFF10B981);

  static const lightBackground = Color(0xFFF6F8F7);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightTrack = Color(0xFFEAF0ED);
  static const lightText = Color(0xFF0F172A);
  static const lightMuted = Color(0xFF64748B);
  static const lightBorder = Color(0xFFE3EBE7);

  static const darkBackground = Color(0xFF0A100E);
  static const darkSurface = Color(0xFF121A17);
  static const darkTrack = Color(0xFF141E1A);
  static const darkText = Color(0xFFF8FAFC);
  static const darkMuted = Color(0xFF94A3B8);
  static const darkBorder = Color(0xFF1E2D27);
}

abstract final class FinoraV8Space {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
}

abstract final class FinoraV8Radius {
  static const double icon = 12;
  static const double input = 16;
  static const double card = 20;
  static const double hero = 24;
  static const double modal = 28;
  static const double pill = 999;
}

abstract final class FinoraV8Metrics {
  static const double pageGutter = 16;
  static const double pageHeader = 56;
  static const double primaryButton = 52;
  static const double secondaryButton = 48;
  static const double compactControl = 36;
  static const double iconButton = 40;
  static const double minTouchTarget = 48;
  static const double segmented = 44;
  static const double segmentedCompact = 38;
  static const double listRow = 56;
  static const double leadingIcon = 40;
  static const double categoryIcon = 36;
}

abstract final class FinoraV8Motion {
  static const instant = Duration(milliseconds: 100);
  static const fast = Duration(milliseconds: 180);
  static const standard = Duration(milliseconds: 260);
  static const spring = Duration(milliseconds: 480);
  static const fastCurve = Curves.easeOutCubic;
  static const standardCurve = Curves.easeInOutCubic;
  static const springCurve = Curves.elasticOut;
}

abstract final class FinoraV8Type {
  static TextStyle get pageTitle => TextStyle(
        fontFamily: AppTypography.activeFontFamily,
        fontFamilyFallback: AppTypography.activeFontFamilyFallback,
        fontSize: 20,
        height: 1.3,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      );
  static TextStyle get sectionTitle => TextStyle(
        fontFamily: AppTypography.activeFontFamily,
        fontFamilyFallback: AppTypography.activeFontFamilyFallback,
        fontSize: 16,
        height: 1.375,
        fontWeight: FontWeight.w700,
      );
  static TextStyle get itemTitle => TextStyle(
        fontFamily: AppTypography.activeFontFamily,
        fontFamilyFallback: AppTypography.activeFontFamilyFallback,
        fontSize: 14,
        height: 1.43,
        fontWeight: FontWeight.w700,
      );
  static TextStyle get body => TextStyle(
        fontFamily: AppTypography.activeFontFamily,
        fontFamilyFallback: AppTypography.activeFontFamilyFallback,
        fontSize: 14,
        height: 1.43,
      );
  static TextStyle get label => TextStyle(
        fontFamily: AppTypography.activeFontFamily,
        fontFamilyFallback: AppTypography.activeFontFamilyFallback,
        fontSize: 13,
        height: 1.38,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get caption => TextStyle(
        fontFamily: AppTypography.activeFontFamily,
        fontFamilyFallback: AppTypography.activeFontFamilyFallback,
        fontSize: 12,
        height: 1.33,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get micro => TextStyle(
        fontFamily: AppTypography.activeFontFamily,
        fontFamilyFallback: AppTypography.activeFontFamilyFallback,
        fontSize: 11,
        height: 1.27,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get amount => TextStyle(
        fontFamily: AppTypography.activeFontFamily,
        fontFamilyFallback: AppTypography.activeFontFamilyFallback,
        fontSize: 16,
        height: 1.375,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
  static TextStyle get amountLarge => TextStyle(
        fontFamily: AppTypography.activeFontFamily,
        fontFamilyFallback: AppTypography.activeFontFamilyFallback,
        fontSize: 28,
        height: 1.21,
        fontWeight: FontWeight.w800,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
