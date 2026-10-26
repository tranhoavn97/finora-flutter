import 'package:flutter/material.dart';

/// FINORA Warm Paper & Ink Minimalist Design Tokens ("Sổ tay tối giản")
/// Triết lý: Nền giấy ấm, chữ là chính, một màu nhấn, thanh lịch chuẩn mực, không gradient lòe loẹt hay kính mờ rối mắt.
class FinoraTokens {
  FinoraTokens._();

  // --- 1. Warm Paper & Ink Core Palette ---
  static const Color paperBgLight = Color(0xFFF6F5F2);
  static const Color paperSurfaceLight = Color(0xFFFFFFFF);
  static const Color paperSurface2Light = Color(0xFFEFEDE8);
  static const Color paperLineLight = Color(0xFFE6E3DC);
  static const Color paperLine2Light = Color(0xFFD9D5CC);
  static const Color inkPrimaryLight = Color(0xFF141518);
  static const Color inkSecondaryLight = Color(0xFF5E6168);
  static const Color inkTertiaryLight = Color(0xFF9A9CA1);

  // Dark Mode
  static const Color paperBgDark = Color(0xFF0E0F10);
  static const Color paperSurfaceDark = Color(0xFF17181A);
  static const Color paperSurface2Dark = Color(0xFF1F2023);
  static const Color paperLineDark = Color(0xFF25272A);
  static const Color paperLine2Dark = Color(0xFF303236);
  static const Color inkPrimaryDark = Color(0xFFECEBE7);
  static const Color inkSecondaryDark = Color(0xFFA3A5AA);
  static const Color inkTertiaryDark = Color(0xFF6D6F74);

  // Semantics
  static const Color posGreen = Color(0xFF2E7D55);
  static const Color moss = posGreen;
  static const Color posGreenDark = Color(0xFF62B587);
  static const Color negRed = Color(0xFFB5452F);
  static const Color negRedDark = Color(0xFFE07B63);
  static const Color warnAmber = Color(0xFFB07A1E);
  static const Color warnAmberDark = Color(0xFFD8A447);
  static const Color trackLight = Color(0xFFE8E5DE);
  static const Color trackDark = Color(0xFF2A2C2F);

  // Backwards compatible aliases
  static const Color sunkenLight = paperSurface2Light;
  static const Color sunkenDark = paperSurface2Dark;
  static const Color oledBlack = paperBgDark;
  static const Color titaniumBg = paperBgDark;
  static const Color titaniumSurface = paperSurfaceDark;
  static const Color titaniumCard = paperSurfaceDark;
  static const Color titaniumElevated = paperSurface2Dark;
  static const Color hairlineDark = Color(0x22FFFFFF);
  static const Color hairlineLight = paperLineLight;
  static const Color appleMint = posGreen;
  static const Color appleCoral = negRed;
  static const Color appleCobalt = Color(0xFF1B5FAA);
  static const Color appleAmber = warnAmber;
  static const Color applePurple = Color(0xFF5E6168);

  // Helpers
  static Color bg(bool isDark) => isDark ? paperBgDark : paperBgLight;
  static Color surface(bool isDark) => isDark ? paperSurfaceDark : paperSurfaceLight;
  static Color surface2(bool isDark) => isDark ? paperSurface2Dark : paperSurface2Light;
  static Color sunken(bool isDark) => surface2(isDark);
  static Color line(bool isDark) => isDark ? paperLineDark : paperLineLight;
  static Color line2(bool isDark) => isDark ? paperLine2Dark : paperLine2Light;
  static Color text(bool isDark) => isDark ? inkPrimaryDark : inkPrimaryLight;
  static Color ink(bool isDark) => isDark ? inkPrimaryDark : inkPrimaryLight;
  static Color inkSecondary(bool isDark) => isDark ? inkSecondaryDark : inkSecondaryLight;
  static Color inkTertiary(bool isDark) => isDark ? inkTertiaryDark : inkTertiaryLight;
  static Color primary(bool isDark) => isDark ? inkPrimaryDark : inkPrimaryLight;
  static Color card(bool isDark) => surface(isDark);
  static Color textSub(bool isDark) => isDark ? inkSecondaryDark : inkSecondaryLight;
  static Color textMuted(bool isDark) => isDark ? inkTertiaryDark : inkTertiaryLight;
  static Color pos(bool isDark) => isDark ? posGreenDark : posGreen;
  static Color neg(bool isDark) => isDark ? negRedDark : negRed;
  static Color warn(bool isDark) => isDark ? warnAmberDark : warnAmber;
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
  static const double radiusCard = 16.0;
  static const double radiusSheet = 24.0;
  static const double radiusPill = 999.0;

  // --- 4. Typography Scale ---
  static TextStyle bigAmount({required bool isDark, Color? color}) => TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: 34,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.8,
        height: 1.15,
        color: color ?? text(isDark),
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle largeTitle({required bool isDark, Color? color, FontWeight weight = FontWeight.w600}) => TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: 26,
        fontWeight: weight,
        letterSpacing: -0.6,
        height: 1.2,
        color: color ?? text(isDark),
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle title2({required bool isDark, Color? color, FontWeight weight = FontWeight.w600}) => TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: 18,
        fontWeight: weight,
        letterSpacing: -0.3,
        height: 1.25,
        color: color ?? text(isDark),
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle headline({bool isDark = false, Color? color, FontWeight weight = FontWeight.w600}) => TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: 15,
        fontWeight: weight,
        letterSpacing: -0.2,
        height: 1.3,
        color: color ?? text(isDark),
      );

  static TextStyle subhead({bool isDark = false, Color? color, FontWeight weight = FontWeight.w400}) => TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: 13,
        fontWeight: weight,
        letterSpacing: 0.0,
        height: 1.3,
        color: color ?? textSub(isDark),
      );

  static TextStyle footnote({bool isDark = false, Color? color, FontWeight weight = FontWeight.w400}) => TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: 11.5,
        fontWeight: weight,
        letterSpacing: 0.1,
        height: 1.25,
        color: color ?? textMuted(isDark),
      );

  static TextStyle microBadge({Color color = Colors.white}) => TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.2,
        color: color,
      );

  // --- 5. Clean Warm Paper Card Decoration ---
  static BoxDecoration calmCardDecoration({
    bool isDark = false,
    Color? surfaceColor,
    double radius = radiusCard,
    Border? border,
  }) {
    return BoxDecoration(
      color: surfaceColor ?? surface(isDark),
      borderRadius: BorderRadius.circular(radius),
      border: border ??
          Border.all(
            color: line(isDark),
            width: 1.0,
          ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  static BoxDecoration ambientIslandDecoration({bool isDark = false}) {
    return BoxDecoration(
      color: surface(isDark),
      borderRadius: BorderRadius.circular(radiusCard),
      border: Border.all(
        color: line(isDark),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
