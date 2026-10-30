import 'package:flutter/material.dart';
import '../app_typography.dart';

/// FINORA V8 foundations. Feature screens should consume semantic roles instead
/// of introducing new numeric values for repeated UI patterns.
abstract final class FinoraV8Colors {
  static const brand = Color(0xFF00866A);
  static const brandPressed = Color(0xFF00785E);
  static const primaryAction = Color(0xFF00866A);
  static const neutral = Color(0xFF58697B);
  static const income = Color(0xFF00835F);
  static const expense = Color(0xFFDA6263);
  static const expenseAccent = Color(0xFFFF3B46);
  static const mint = Color(0xFFBDEDD6);
  static const butter = Color(0xFFFFF1BA);
  static const warning = Color(0xFF936100);
  static const investment = Color(0xFF0066CC);
  static const saving = Color(0xFF147D64);
  static const husband = Color(0xFF0066CC);
  static const wife = Color(0xFFDB2777);
  static const shared = Color(0xFF147D64);

  static const lightBackground = Color(0xFFF9FBFA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightTrack = Color(0xFFF0F6F2);
  static const lightText = Color(0xFF152B29);
  static const lightMuted = Color(0xFF7A8C85);
  static const lightBorder = Color(0xFFE6EEEA);

  static const darkBackground = Color(0xFF111820);
  static const darkSurface = Color(0xFF1B2531);
  static const darkTrack = Color(0xFF263342);
  static const darkText = Color(0xFFEEF2F5);
  static const darkMuted = Color(0xFFB4C0CC);
  static const darkBorder = Color(0xFF354352);
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
  static const double card = 24;
  static const double hero = 24;
  static const double modal = 32;
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
  static String get _font => AppTypography.activeFontFamily ?? 'BeVietnamPro';
  static List<String> get _fallback =>
      AppTypography.activeFontFamilyFallback ??
      const ['BeVietnamPro', 'PlusJakartaSans', 'Inter', 'sans-serif'];

  static TextStyle get pageTitle => TextStyle(
        fontFamily: _font,
        fontFamilyFallback: _fallback,
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      );
  static TextStyle get sectionTitle => TextStyle(
        fontFamily: _font,
        fontFamilyFallback: _fallback,
        fontSize: 16,
        height: 1.32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
      );
  static TextStyle get itemTitle => TextStyle(
        fontFamily: _font,
        fontFamilyFallback: _fallback,
        fontSize: 14.5,
        height: 1.36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.15,
      );
  static TextStyle get body => TextStyle(
        fontFamily: _font,
        fontFamilyFallback: _fallback,
        fontSize: 14,
        height: 1.42,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.05,
      );
  static TextStyle get label => TextStyle(
        fontFamily: _font,
        fontFamilyFallback: _fallback,
        fontSize: 13,
        height: 1.35,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      );
  static TextStyle get caption => TextStyle(
        fontFamily: _font,
        fontFamilyFallback: _fallback,
        fontSize: 12,
        height: 1.33,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
      );
  static TextStyle get micro => TextStyle(
        fontFamily: _font,
        fontFamilyFallback: _fallback,
        fontSize: 11,
        height: 1.27,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      );
  static TextStyle get amount => TextStyle(
        fontFamily: _font,
        fontFamilyFallback: _fallback,
        fontSize: 16,
        height: 1.32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.25,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
  static TextStyle get amountLarge => TextStyle(
        fontFamily: _font,
        fontFamilyFallback: _fallback,
        fontSize: 28,
        height: 1.18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.55,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
