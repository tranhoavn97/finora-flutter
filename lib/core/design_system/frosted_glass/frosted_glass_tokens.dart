import 'package:flutter/material.dart';

/// Finora Frosted Neo-Glass Design System Tokens.
/// Inspired by Apple VisionOS and iOS 18 Control Center.
/// Engineered specifically for high legibility of financial data.
abstract final class FrostedGlassTokens {
  // --- Blur Sigmas ---
  /// Subtle blur for small controls, tags, search inputs
  static const double blurSubtle = 12.0;

  /// Standard surface blur for financial cards, hero balance, list tiles
  static const double blurSurface = 24.0;

  /// Deep immersion blur for navigation bars, modals, bottom sheets
  static const double blurOverlay = 32.0;

  // --- Border Radii ---
  static const double radiusTag = 10.0;
  static const double radiusControl = 16.0;
  static const double radiusCard = 24.0;
  static const double radiusHero = 28.0;
  static const double radiusSheet = 32.0;
  static const double radiusPill = 999.0;

  // --- Brand & Financial Semantic Colors ---
  static const Color brandRoyalBlue = Color(0xFF6366F1);
  static const Color brandAzure = Color(0xFF38BDF8);
  static const Color incomeEmerald = Color(0xFF059669);
  static const Color expenseCoral = Color(0xFFE11D48);
  static const Color investmentAmber = Color(0xFFD97706);
  static const Color sharedIndigo = Color(0xFF6366F1);

  // --- Light Mode Frosted Palette ---
  static const Color lightScaffoldBg = Color(0xFFF1F0FB);
  static const Color lightGlassSurface = Color(0xE8FFFFFF);
  static const Color lightGlassSurfacePressed = Color(0xEBFFFFFF); // ~92% white
  static const Color lightTextPrimary = Color(0xFF202437);
  static const Color lightTextSecondary = Color(0xFF696878);
  static const Color lightTextMuted = Color(0xFF858091);

  // --- Dark Mode Frosted Palette ---
  static const Color darkScaffoldBg = Color(0xFF0C0A26);
  static const Color darkGlassSurface = Color(0xAA1E1B4B);
  static const Color darkGlassSurfacePressed = Color(0xDD312E81);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // --- Hairline Fresnel Border Gradients ---
  static const LinearGradient lightBorderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.45, 1.0],
    colors: [
      Color(0xE6FFFFFF), // 90% white top-left highlight
      Color(0x66E1DEEF),
      Color(0x24E1DEEF),
    ],
  );

  static const LinearGradient darkBorderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.45, 1.0],
    colors: [
      Color(0x4DFFFFFF), // 30% white rim
      Color(0x1AFFFFFF), // 10% white mid
      Color(0x0AFFFFFF), // 4% white base
    ],
  );

  static const LinearGradient brandBorderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
    colors: [
      Color(0x80818CF8),
      Color(0x336366F1),
    ],
  );

  // --- Atmospheric Diffuse Shadows ---
  static List<BoxShadow> lightCardShadows = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.05),
      blurRadius: 28,
      spreadRadius: -4,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.03),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> darkCardShadows = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.35),
      blurRadius: 32,
      spreadRadius: -4,
      offset: const Offset(0, 14),
    ),
    BoxShadow(
      color: const Color(0xFF005FEA).withValues(alpha: 0.08),
      blurRadius: 24,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];
}
