import 'package:flutter/material.dart';

/// FINORA V8 foundations. Feature screens should consume semantic roles instead
/// of introducing new numeric values for repeated UI patterns.
abstract final class FinoraV8Colors {
  static const brand = Color(0xFF007AFF); // Apple Blue
  static const brandPressed = Color(0xFF0051A8);
  static const neutral = Color(0xFF8E8E93); // Apple Secondary Label
  static const income = Color(0xFF34C759); // Apple Green
  static const expense = Color(0xFFFF3B30); // Apple Red
  static const investment = Color(0xFFFF9500); // Apple Orange
  static const saving = Color(0xFF5AC8FA); // Apple Cyan
  static const husband = Color(0xFF007AFF);
  static const wife = Color(0xFFFF2D55); // Apple Pink
  static const shared = Color(0xFF5856D6); // Apple Purple

  static const lightBackground = Color(0xFFF2F2F7); // Apple System Grouped
  static const lightSurface = Color(0xFFFFFFFF); // Apple Secondary Grouped
  static const lightTrack = Color(0xFFE5E5EA);
  static const lightText = Color(0xFF000000);
  static const lightMuted = Color(0xFF8E8E93);
  static const lightBorder = Color(0xFFE5E5EA);

  static const darkBackground = Color(0xFF000000); // Apple Dark Canvas
  static const darkSurface = Color(0xFF1C1C1E); // Apple Dark Secondary Grouped
  static const darkTrack = Color(0xFF2C2C2E);
  static const darkText = Color(0xFFFFFFFF);
  static const darkMuted = Color(0xFF8E8E93);
  static const darkBorder = Color(0xFF38383A);
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
  static const pageTitle = TextStyle(
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
  );
  static const sectionTitle = TextStyle(
    fontSize: 16,
    height: 1.375,
    fontWeight: FontWeight.w700,
  );
  static const itemTitle = TextStyle(
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w700,
  );
  static const body = TextStyle(fontSize: 14, height: 1.43);
  static const label = TextStyle(
    fontSize: 13,
    height: 1.38,
    fontWeight: FontWeight.w600,
  );
  static const caption = TextStyle(
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w500,
  );
  static const micro = TextStyle(
    fontSize: 11,
    height: 1.27,
    fontWeight: FontWeight.w600,
  );
  static const amount = TextStyle(
    fontSize: 16,
    height: 1.375,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const amountLarge = TextStyle(
    fontSize: 28,
    height: 1.21,
    fontWeight: FontWeight.w800,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
