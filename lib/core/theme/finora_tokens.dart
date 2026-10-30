import 'package:flutter/material.dart';
import '../design_system/app_typography.dart';

/// FINORA Apple Minimalist & Calm Design Tokens (v27 Design System)
/// Triết lý: Deep Titanium OLED, Apple HIG Typography, Finora Smart Ambient Island,
/// Màu ngữ nghĩa chuẩn Apple (Mint, Coral, Cobalt, Amber) và viền hairline mờ tĩnh lặng.
class FinoraTokens {
  FinoraTokens._();

  // --- 1. Apple Minimalist & Deep Titanium OLED (v27 Design System) ---
  static const Color oledBlack = Color(0xFF0B0D11);
  static const Color titaniumBg = Color(0xFF10131A);
  static const Color titaniumSurface = Color(0xFF161B24);
  static const Color titaniumCard = Color(0xFF1D232F);
  static const Color titaniumElevated = Color(0xFF252D3D);

  // Brand & Actions
  static const Color brandBlueLight = Color(0xFF00866A);
  static const Color brandBlueDark = Color(0xFF10B981);
  static const Color primaryActionLight = Color(0xFF00866A);
  static const Color primaryActionDark = Color(0xFF10B981);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color onPrimaryDark = Color(0xFFFFFFFF);

  // Soft Accents
  static const Color accentMintLight = Color(0xFF30D158);
  static const Color accentMintDark = Color(0xFF30D158);
  static const Color accentButterLight = Color(0xFFFF9F0A);
  static const Color accentButterDark = Color(0xFFFF9F0A);

  // Financial Status Semantics (Apple HIG)
  static const Color incomeLight = Color(0xFF00835F);
  static const Color incomeDark = Color(0xFF30D158);
  static const Color expenseLight = Color(0xFFDA6263);
  static const Color expenseDark = Color(0xFFFF453A);
  static const Color expenseAccentLight = Color(0xFFFF3B46);
  static const Color expenseAccentDark = Color(0xFFF5253E);
  static const Color warningLight = Color(0xFFFF9F0A);
  static const Color warningDark = Color(0xFFFF9F0A);
  static const Color infoTransferLight = Color(0xFF0284C7);
  static const Color infoTransferDark = Color(0xFF38BDF8);

  // Surface & Borders
  static const Color borderLight = Color(0xFFE6EEEA);
  static const Color borderDark = Color(0xFF252D3D);
  static const Color surfaceSubtleLight = Color(0xFFF1F5F9);
  static const Color surfaceSubtleDark = Color(0xFF1D232F);

  // Apple Semantics (v27 System Colors)
  static const Color appleMint = Color(0xFF30D158);
  static const Color appleCoral = Color(0xFFFF453A);
  static const Color appleCobalt = Color(0xFF0284C7);
  static const Color appleAmber = Color(0xFFFF9F0A);
  static const Color applePurple = Color(0xFF0D9488);

  // Core Palette aliases & semantics
  static const Color posGreen = appleMint;
  static const Color moss = appleMint;
  static const Color posGreenDark = appleMint;
  static const Color negRed = appleCoral;
  static const Color negRedDark = appleCoral;
  static const Color warnAmber = appleAmber;
  static const Color warnAmberDark = appleAmber;
  static const Color trackLight = borderLight;
  static const Color trackDark = Color(0xFF252D3D);

  // Paper/Sunken compatibility aliases
  static const Color paperBgLight = Color(0xFFF9FBFA);
  static const Color paperSurfaceLight = Color(0xFFFFFFFF);
  static const Color paperSurface2Light = surfaceSubtleLight;
  static const Color paperLineLight = borderLight;
  static const Color paperLine2Light = Color(0xFFCBD5E1);
  static const Color inkPrimaryLight = Color(0xFF152B29);
  static const Color inkSecondaryLight = Color(0xFF566B63);
  static const Color inkTertiaryLight = Color(0xFF86928C);

  static const Color paperBgDark = oledBlack;
  static const Color paperSurfaceDark = titaniumSurface;
  static const Color paperSurface2Dark = surfaceSubtleDark;
  static const Color paperLineDark = borderDark;
  static const Color paperLine2Dark = Color(0xFF334155);
  static const Color inkPrimaryDark = Color(0xFFEEF2F5);
  static const Color inkSecondaryDark = Color(0xFFB4C0CC);
  static const Color inkTertiaryDark = Color(0xFF64748B);

  static const Color sunkenLight = paperSurface2Light;
  static const Color sunkenDark = paperSurface2Dark;
  static const Color hairlineDark = Color(0x33FFFFFF);
  static const Color hairlineLight = Color(0x1AE2E8F0);

  // Helpers
  static Color bg(bool isDark) => isDark ? oledBlack : paperBgLight;
  static Color surface(bool isDark) =>
      isDark ? titaniumSurface : paperSurfaceLight;
  static Color surface2(bool isDark) =>
      isDark ? titaniumCard : paperSurface2Light;
  static Color surfaceSubtle(bool isDark) =>
      isDark ? surfaceSubtleDark : surfaceSubtleLight;
  static Color sunken(bool isDark) => surface2(isDark);
  static Color line(bool isDark) => isDark ? paperLineDark : paperLineLight;
  static Color line2(bool isDark) => isDark ? paperLine2Dark : paperLine2Light;
  static Color border(bool isDark) => isDark ? borderDark : borderLight;
  static Color text(bool isDark) => isDark ? inkPrimaryDark : inkPrimaryLight;
  static Color ink(bool isDark) => isDark ? inkPrimaryDark : inkPrimaryLight;
  static Color inkSecondary(bool isDark) =>
      isDark ? inkSecondaryDark : inkSecondaryLight;
  static Color inkTertiary(bool isDark) =>
      isDark ? inkTertiaryDark : inkTertiaryLight;
  static Color brand(bool isDark) => isDark ? brandBlueDark : brandBlueLight;
  static Color primary(bool isDark) =>
      isDark ? primaryActionDark : primaryActionLight;
  static Color onPrimary(bool isDark) =>
      isDark ? onPrimaryDark : onPrimaryLight;
  static Color mint(bool isDark) => isDark ? accentMintDark : accentMintLight;
  static Color butter(bool isDark) =>
      isDark ? accentButterDark : accentButterLight;
  static Color card(bool isDark) => surface(isDark);
  static Color textSub(bool isDark) =>
      isDark ? inkSecondaryDark : inkSecondaryLight;
  static Color textMuted(bool isDark) =>
      isDark ? inkTertiaryDark : inkTertiaryLight;
  static Color pos(bool isDark) => isDark ? incomeDark : incomeLight;
  static Color neg(bool isDark) => isDark ? expenseDark : expenseLight;
  static Color income(bool isDark) => isDark ? incomeDark : incomeLight;
  static Color expense(bool isDark) => isDark ? expenseDark : expenseLight;
  static Color expenseAccent(bool isDark) =>
      isDark ? expenseAccentDark : expenseAccentLight;
  static Color warn(bool isDark) => isDark ? warningDark : warningLight;
  static Color info(bool isDark) =>
      isDark ? infoTransferDark : infoTransferLight;
  static Color track(bool isDark) => isDark ? trackDark : trackLight;

  // --- 2. Spacing Scale ---
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  // --- 3. Corner Radii ---
  static const double radiusBadge = 8.0;
  static const double radiusChip = 16.0;
  static const double radiusCard = 24.0;
  static const double radiusSheet = 32.0;
  static const double radiusPill = 999.0;

  // --- 4. Typography Scale ---
  static String get _font => AppTypography.activeFontFamily ?? 'BeVietnamPro';
  static List<String> get _fallback =>
      AppTypography.activeFontFamilyFallback ??
      const ['BeVietnamPro', 'PlusJakartaSans', 'Inter', 'sans-serif'];

  static TextStyle bigAmount({required bool isDark, Color? color}) => TextStyle(
        fontFamily: _font,
        fontFamilyFallback: _fallback,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.75,
        height: 1.15,
        color: color ?? text(isDark),
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle largeTitle(
          {required bool isDark,
          Color? color,
          FontWeight weight = FontWeight.w800}) =>
      TextStyle(
        fontFamily: _font,
        fontFamilyFallback: _fallback,
        fontSize: 25,
        fontWeight: weight,
        letterSpacing: -0.55,
        height: 1.2,
        color: color ?? text(isDark),
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle title2(
          {required bool isDark,
          Color? color,
          FontWeight weight = FontWeight.w700}) =>
      TextStyle(
        fontFamily: _font,
        fontFamilyFallback: _fallback,
        fontSize: 18,
        fontWeight: weight,
        letterSpacing: -0.3,
        height: 1.25,
        color: color ?? text(isDark),
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle headline(
          {bool isDark = false,
          Color? color,
          FontWeight weight = FontWeight.w700}) =>
      TextStyle(
        fontFamily: _font,
        fontFamilyFallback: _fallback,
        fontSize: 15,
        fontWeight: weight,
        letterSpacing: -0.2,
        height: 1.3,
        color: color ?? text(isDark),
      );

  static TextStyle subhead(
          {bool isDark = false,
          Color? color,
          FontWeight weight = FontWeight.w500}) =>
      TextStyle(
        fontFamily: _font,
        fontFamilyFallback: _fallback,
        fontSize: 13,
        fontWeight: weight,
        letterSpacing: -0.05,
        height: 1.32,
        color: color ?? textSub(isDark),
      );

  static TextStyle footnote(
          {bool isDark = false,
          Color? color,
          FontWeight weight = FontWeight.w500}) =>
      TextStyle(
        fontFamily: _font,
        fontFamilyFallback: _fallback,
        fontSize: 11.5,
        fontWeight: weight,
        letterSpacing: 0.05,
        height: 1.28,
        color: color ?? textMuted(isDark),
      );

  static TextStyle microBadge({Color color = Colors.white}) => TextStyle(
        fontFamily: _font,
        fontFamilyFallback: _fallback,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.15,
        height: 1.2,
        color: color,
      );

  // --- 5. Clean Apple Minimalist Card & Ambient Island Decoration ---
  static BoxDecoration calmCardDecoration({
    bool isDark = false,
    Color? surfaceColor,
    double radius = radiusCard,
    Border? border,
  }) {
    return BoxDecoration(
      color: surfaceColor ?? (isDark ? titaniumSurface : Colors.white),
      borderRadius: BorderRadius.circular(radius),
      border: border ??
          Border.all(
            color: isDark ? const Color(0x22FFFFFF) : const Color(0x0F000000),
            width: 0.8,
          ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration ambientIslandDecoration({bool isDark = false}) {
    return BoxDecoration(
      color: isDark
          ? const Color(0xFF1B2531).withValues(alpha: 0.85)
          : Colors.white.withValues(alpha: 0.90),
      borderRadius: BorderRadius.circular(18.0),
      border: Border.all(
        color: isDark ? const Color(0x33FFFFFF) : const Color(0x1A000000),
        width: 0.8,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // --- 6. Emerald Fintech Design Tokens ---
  static const Color emeraldHeroPrimary = Color(0xFF043927);
  static const Color emeraldHeroSecondary = Color(0xFF0B6645);
  static const Color primaryActionGreen = Color(0xFF00875A);
  static const Color primaryActionGreenLight = Color(0xFF00A86B);
  static const Color mintSoftLight = Color(0xFFE6F7F0);
  static const Color mintSoftDark = Color(0xFF13382C);
  static const Color mintPodLight = Color(0xFFE6F7F0);
  static const Color mintPodDark = Color(0xFF13382C);

  static Color mintSoft(bool isDark) => isDark ? mintSoftDark : mintSoftLight;

  static const LinearGradient emeraldHeroGradient = LinearGradient(
    colors: [Color(0xFF043927), Color(0xFF0B6645)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxDecoration emeraldCardDecoration({
    bool isDark = false,
    double radius = radiusCard,
  }) {
    return BoxDecoration(
      gradient: emeraldHeroGradient,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0B6645).withValues(alpha: isDark ? 0.35 : 0.18),
          blurRadius: 18,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
