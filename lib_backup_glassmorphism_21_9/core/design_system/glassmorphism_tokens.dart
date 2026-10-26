import 'package:flutter/material.dart';

/// FINORA Glassmorphism 2.0 Design Tokens.
///
/// Encapsulates multi-layer optical refraction parameters, directional
/// specular hairline borders, translucent tint alphas, chromatic depth shadows,
/// and semantic color tokens for high-contrast fintech luxury UI.
abstract final class GlassmorphismTokens {
  // ---------------------------------------------------------------------------
  // 1. Multi-Layer Blur Sigmas
  // ---------------------------------------------------------------------------
  /// Low blur sigma (12.0) for micro-controls, pill chips, and badges.
  static const double surfaceBlurLow = 12.0;

  /// Medium blur sigma (20.0) for standard cards, lists, and modal sheets.
  static const double surfaceBlurMedium = 20.0;

  /// High blur sigma (32.0) for hero cards, floating dialogues, and liquid glass.
  static const double surfaceBlurHigh = 32.0;

  /// Navigation dock blur sigma (25.0) for floating island navigation.
  static const double navBlur = 25.0;

  /// Heavy Gaussian frost sigma (75.0) for background aurora mesh canvas.
  static const double meshBlur = 75.0;

  // Semantic blur aliases
  static const double sheetBlur = 24.0;
  static const double dialogBlur = 20.0;
  static const double controlBlur = 18.0;
  static const double bubbleBlur = 50.0;

  // ---------------------------------------------------------------------------
  // 2. Surface Opacities & Translucent Alphas
  // ---------------------------------------------------------------------------
  // Light Theme Alphas
  static const double surfaceLightAlpha = 0.76;
  static const double surfaceLightAlphaLow = 0.65;
  static const double surfaceLightAlphaHigh = 0.85;
  static const double trackLightAlpha = 0.40;
  static const double navLightAlpha = 0.72;

  // Dark Theme Alphas
  static const double surfaceDarkAlpha = 0.70;
  static const double surfaceDarkAlphaLow = 0.60;
  static const double surfaceDarkAlphaHigh = 0.82;
  static const double trackDarkAlpha = 0.50;
  static const double navDarkAlpha = 0.70;

  // Solid base surface colors before alpha blending
  static const Color surfaceBaseLight = Color(0xFFFFFFFF);
  static const Color surfaceBaseDark = Color(0xFF141721);
  static const Color surfaceElevatedDark = Color(0xFF18181B);

  // Ready-to-use surface fills
  static Color get cardFillLight =>
      surfaceBaseLight.withValues(alpha: surfaceLightAlpha);
  static Color get cardFillDark =>
      surfaceBaseDark.withValues(alpha: surfaceDarkAlpha);
  static Color get navFillLight =>
      surfaceBaseLight.withValues(alpha: navLightAlpha);
  static Color get navFillDark =>
      surfaceElevatedDark.withValues(alpha: navDarkAlpha);

  // ---------------------------------------------------------------------------
  // 3. Hairline Specular Borders & Directional Gradients
  // ---------------------------------------------------------------------------
  static const double hairlineBorderWidth = 0.5;
  static const double borderThin = 0.8;
  static const double borderMedium = 1.0;
  static const double borderThick = 1.25;

  // Specular Border Colors
  static const Color borderLightSolid = Color(0xFFE5E5EA);
  static const Color borderDarkSolid = Color(0xFF38383A);

  static Color get borderLightAlpha => Colors.white.withValues(alpha: 0.85);
  static Color get borderDarkAlpha => Colors.white.withValues(alpha: 0.14);

  // Directional Specular Gradients (Fresnel top-left light incidence)
  static const LinearGradient specularHighlightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.28, 0.65, 1.0],
    colors: [
      Color(0xB3FFFFFF), // 70% opacity specular apex highlight
      Color(0x33FFFFFF), // 20% opacity mid-edge dissipation
      Color(0x14FFFFFF), // 8% opacity low rim
      Color(0x59FFFFFF), // 35% opacity bottom-right ambient bounce
    ],
  );

  static const LinearGradient specularHighlightGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.28, 0.65, 1.0],
    colors: [
      Color(0x66FFFFFF), // 40% opacity specular top-left
      Color(0x24FFFFFF), // 14% opacity mid-edge
      Color(0x0EFFFFFF), // 5% opacity body rim
      Color(0x2EFFFFFF), // 18% opacity ambient bounce
    ],
  );

  /// Resolves directional border gradient based on active theme brightness.
  static LinearGradient cardBorderGradient(bool isDark) =>
      isDark ? specularHighlightGradientDark : specularHighlightGradient;

  // ---------------------------------------------------------------------------
  // 4. Semantic Color Tokens (High Contrast)
  // ---------------------------------------------------------------------------
  static const Color primary = Color(0xFF007AFF); // Apple System Blue
  static const Color primaryPressed = Color(0xFF0051A8);
  static const Color income = Color(0xFF34C759); // Apple System Green
  static const Color expense = Color(0xFFFF3B30); // Apple System Red
  static const Color warning = Color(0xFFFF9500); // Apple System Orange
  static const Color balance = Color(0xFF007AFF); // Liquid Electric Blue
  static const Color saving = Color(0xFF5AC8FA); // Apple System Cyan
  static const Color purple = Color(0xFFAF52DE); // Apple System Purple
  static const Color indigo = Color(0xFF5856D6); // Apple System Indigo
  static const Color neutral = Color(0xFF8E8E93); // Apple Secondary Label

  // Family Sub-palette
  static const Color familyHusband = Color(0xFF007AFF); // Electric Blue
  static const Color familyWife = Color(0xFFFF2D55); // Rose Pink
  static const Color familyShared = Color(0xFF5856D6); // Royal Purple

  // Semantic Glows (for outer diffuse chromatic shadows)
  static Color get primaryGlow => primary.withValues(alpha: 0.28);
  static Color get incomeGlow => income.withValues(alpha: 0.24);
  static Color get expenseGlow => expense.withValues(alpha: 0.24);
  static Color get warningGlow => warning.withValues(alpha: 0.24);

  // ---------------------------------------------------------------------------
  // 5. Aurora Orbs Palette
  // ---------------------------------------------------------------------------
  // Light Canvas Orbs
  static const Color auroraLightOrb1 = Color(0xFF38BDF8); // Cyan Pastel
  static const Color auroraLightOrb2 = Color(0xFFC084FC); // Soft Lilac
  static const Color auroraLightOrb3 = Color(0xFF34D399); // Mint Glow
  static const Color auroraLightOrb4 = Color(0xFFF472B6); // Rose Gold Shimmer

  // Dark Canvas Orbs
  static const Color auroraDarkOrb1 = Color(0xFF1E3A8A); // Electric Deep Sapphire
  static const Color auroraDarkOrb2 = Color(0xFF4C1D95); // Space Violet
  static const Color auroraDarkOrb3 = Color(0xFF065F46); // Deep Emerald
  static const Color auroraDarkOrb4 = Color(0xFF1E1B4B); // Midnight Indigo

  // Canvas Base Gradients
  static const List<Color> auroraCanvasLight = [
    Color(0xFFF1F5F9), // Pearl canvas
    Color(0xFFE8EFF8), // Soft sky mist
    Color(0xFFF4F1FA), // Lilac pearl
  ];

  static const List<Color> auroraCanvasDark = [
    Color(0xFF0A0E17), // Deep space black
    Color(0xFF0F172A), // Midnight slate
    Color(0xFF0B101D), // Obsidian navy
  ];

  // ---------------------------------------------------------------------------
  // 6. Chromatic Depth Shadows
  // ---------------------------------------------------------------------------
  static List<BoxShadow> cardShadow(bool isDark, {Color? glowColor}) {
    final baseShadow = BoxShadow(
      color: isDark
          ? Colors.black.withValues(alpha: 0.32)
          : const Color(0xFF1E293B).withValues(alpha: 0.06),
      blurRadius: 18,
      offset: const Offset(0, 6),
    );

    if (glowColor != null) {
      return [
        baseShadow,
        BoxShadow(
          color: glowColor.withValues(alpha: isDark ? 0.28 : 0.18),
          blurRadius: 20,
          offset: const Offset(0, 4),
          spreadRadius: 1,
        ),
      ];
    }
    return [baseShadow];
  }

  static List<BoxShadow> navShadow(bool isDark) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
          blurRadius: 28,
          offset: const Offset(0, 10),
          spreadRadius: -2,
        ),
      ];

  // Helper resolvers based on BuildContext
  static bool isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color cardFill(BuildContext context) =>
      isDarkMode(context) ? cardFillDark : cardFillLight;

  static Border cardBorder(BuildContext context, {double width = borderThin}) {
    final dark = isDarkMode(context);
    return Border.all(
      color: dark ? borderDarkAlpha : borderLightAlpha,
      width: width,
    );
  }
}
