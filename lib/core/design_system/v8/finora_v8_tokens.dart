import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_radius.dart';
import '../app_typography.dart';
import '../../theme/finora_tokens.dart';

/// FINORA V8 semantic tokens. Feature screens consume semantic roles mapped
/// directly to authoritative AppColors & FinoraTokens.
abstract final class FinoraV8Colors {
  static const brand = AppColors.accent;
  static const brandPressed = Color(0xFF00785E);
  static const primaryAction = AppColors.primaryActionGreen;
  static const neutral = AppColors.lightTextSecondary;
  static const income = AppColors.success;
  static const expense = AppColors.error;
  static const expenseAccent = Color(0xFFFF3B46);
  static const mint = AppColors.accentLight;
  static const butter = Color(0xFFFFF1BA);
  static const warning = AppColors.warning;
  static const investment = AppColors.husbandBlue; // Zero-purple guarantee
  static const saving = AppColors.jointTeal;
  static const husband = AppColors.husbandBlue;
  static const wife = AppColors.wifePink;
  static const shared = AppColors.jointTeal;

  static const lightBackground = AppColors.lightBg;
  static const lightSurface = AppColors.lightSurface;
  static const lightTrack = AppColors.lightSurfaceElevated;
  static const lightText = AppColors.lightTextPrimary;
  static const lightMuted = AppColors.lightTextSecondary;
  static const lightBorder = AppColors.lightBorder;

  static const darkBackground = AppColors.darkBg;
  static const darkSurface = AppColors.darkSurface;
  static const darkTrack = AppColors.darkSurfaceElevated;
  static const darkText = AppColors.darkTextPrimary;
  static const darkMuted = AppColors.darkTextSecondary;
  static const darkBorder = AppColors.darkBorder;
}

abstract final class FinoraV8Space {
  static const double x1 = FinoraTokens.space4;
  static const double x2 = FinoraTokens.space8;
  static const double x3 = FinoraTokens.space12;
  static const double x4 = FinoraTokens.space16;
  static const double x5 = FinoraTokens.space20;
  static const double x6 = FinoraTokens.space24;
  static const double x8 = FinoraTokens.space32;
}

abstract final class FinoraV8Radius {
  static const double icon = AppRadius.sm;
  static const double input = FinoraTokens.radiusChip;
  static const double card = FinoraTokens.radiusCard;
  static const double hero = FinoraTokens.radiusCard;
  static const double modal = FinoraTokens.radiusSheet;
  static const double pill = FinoraTokens.radiusPill;
}

abstract final class FinoraV8Metrics {
  static const double pageGutter = FinoraTokens.space16;
  static const double pageHeader = 44.0;
  static const double primaryButton = 52.0;
  static const double secondaryButton = 48.0;
  static const double compactControl = 36.0;
  static const double iconButton = 40.0;
  static const double minTouchTarget = 48.0;
  static const double segmented = 44.0;
  static const double segmentedCompact = 38.0;
  static const double listRow = 56.0;
  static const double leadingIcon = 40.0;
  static const double categoryIcon = 36.0;
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
  static TextStyle get pageTitle => AppTypography.title2;
  static TextStyle get sectionTitle => AppTypography.title3;
  static TextStyle get itemTitle => AppTypography.headline;
  static TextStyle get body => AppTypography.body;
  static TextStyle get label => AppTypography.subhead;
  static TextStyle get caption => AppTypography.caption1;
  static TextStyle get micro => AppTypography.caption2;
  static TextStyle get amount => AppTypography.numericSmall;
  static TextStyle get amountLarge => AppTypography.numericLarge;
}
