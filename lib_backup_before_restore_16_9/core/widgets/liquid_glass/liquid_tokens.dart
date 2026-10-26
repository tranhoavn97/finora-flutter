import 'package:flutter/material.dart';

/// FINORA 2026 — Luminous Liquid Glass Design Tokens.
/// Provides strictly normalized dimensions, typography, and optical color tokens.
abstract class LiquidButtonSizes {
  /// Primary CTA button height (pill shape, 9999px radius).
  static const double primaryHeight = 46.0;

  /// Secondary glass button height (translucent glass, 9999px radius).
  static const double secondaryHeight = 40.0;

  /// Segmented filter pill height (period/owner filters, 9999px radius).
  static const double filterPillHeight = 36.0;

  /// Quick action dock vessel diameter (52x52px pure circle).
  static const double quickActionVesselSize = 52.0;

  /// TopBar / Header icon action button diameter (42x42px pure circle).
  static const double iconActionSize = 42.0;

  /// Metric status badge height (26px pill).
  static const double badgeHeight = 26.0;

  /// Standard border radius for pill controls.
  static const double radiusPill = 9999.0;

  /// Ultra-curved border radius for liquid bento cards.
  static const double radiusCardLg = 34.0;

  /// Standard border radius for compact liquid cards.
  static const double radiusCardMd = 24.0;

  /// Standard border radius for inner modules & lists.
  static const double radiusCardSm = 18.0;
}

/// Normalized typography hierarchy for FINORA Liquid Glass.
abstract class LiquidTypography {
  /// Hero monetary metric (32px, Black 900, Tabular).
  static const TextStyle hero = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.0,
    height: 1.15,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Section group header (15px, Bold 700).
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  /// Card primary monetary metric (17px, ExtraBold 800, Tabular).
  static const TextStyle cardMetric = TextStyle(
    fontSize: 17.0,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Primary list item or category title (13.5px, SemiBold 600).
  static const TextStyle bodyTitle = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.0,
  );

  /// Secondary subtitle or meta tag (12px, Medium 500).
  static const TextStyle subtitle = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  /// Micro caption / overline (11px, Bold 700, Tabular).
  static const TextStyle microCaption = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  /// Button label typography (14px, Bold 700).
  static const TextStyle buttonPrimary = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  /// Filter pill label typography (12.5px, SemiBold 600).
  static const TextStyle filterPill = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );
}

/// Luminous optical color tokens for FINORA Liquid Glass.
abstract class LiquidColors {
  /// Electric Cobalt Brand (Primary CTA & Highlights).
  static const Color cobaltElectric = Color(0xFF0062FF);
  static const Color cobaltSapphire = Color(0xFF0284C7);

  /// Emerald Mint (Income, Positive Growth, Surplus).
  static const Color emeraldMint = Color(0xFF10B981);
  static const Color emeraldDark = Color(0xFF059669);

  /// Coral Rose (Expense, Alert, Negative Flow).
  static const Color coralRose = Color(0xFFF43F5E);
  static const Color coralDark = Color(0xFFE11D48);

  /// Sunburst Amber (Budgets, Warnings, Due Dates).
  static const Color sunburstAmber = Color(0xFFF59E0B);
  static const Color amberDark = Color(0xFFD97706);

  /// Vibrant Violet (Investments, Family Sharing).
  static const Color vibrantViolet = Color(0xFF8B5CF6);
  static const Color violetDark = Color(0xFF7C3AED);

  /// Cyber Cyan (Aurora Pulses, Waveforms).
  static const Color cyberCyan = Color(0xFF06B6D4);
  static const Color cyanDark = Color(0xFF0284C7);

  /// Light Mode Canvas Background.
  static const Color lightCanvas = Color(0xFFF2F6FC);

  /// Dark Mode Canvas Background (Obsidian Deep Space OLED).
  static const Color darkCanvas = Color(0xFF030712);

  /// Light Mode Glass Card Tint.
  static const Color lightGlassCard = Color(0xBFFFFFFF); // ~75% White

  /// Dark Mode Glass Card Tint (Deep Space Luminous Slate).
  static const Color darkGlassCard = Color(0x940F172A); // ~58% Slate
}
