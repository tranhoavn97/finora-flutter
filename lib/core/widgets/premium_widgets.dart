import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../state/theme_studio_controller.dart';
import '../../features/dashboard/dashboard_theme_painters.dart';
import '../theme/finora_tokens.dart';
import '../design_system/v9_liquid/liquid_aurora.dart';
import 'finora_modal_scope.dart';
import 'liquid_glass/liquid_glass_card.dart';

/// 1. GradientBackground: Clean Warm Paper & Ink minimal background (Finora 2026).
class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: FinoraTokens.bg(isDark),
      child: child,
    );
  }
}

/// 2. FloatingBubblesBackground: Clean background wrapper (no glowing chromatic bubbles).
class FloatingBubblesBackground extends StatelessWidget {
  final Widget child;
  const FloatingBubblesBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _AmbientScope extends InheritedWidget {
  const _AmbientScope({required super.child});

  static bool hasAncestor(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_AmbientScope>() != null;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

/// AmbientFloatingBackground: Rich ambient floating multi-color light spots + mesh gradient
/// Gives full depth, vibrant chromatic refraction under all transparent floating glass and UI cards.
class AmbientFloatingBackground extends StatelessWidget {
  final Widget child;
  const AmbientFloatingBackground({super.key, required this.child});

  bool _usesCalmBackdrop(ThemeStudioController? studio) =>
      studio == null ||
      studio.customPrimaryAccentColor != null ||
      studio.ambientBlur == AmbientBlurPreset.emeraldMatrix ||
      studio.palette == AppColorPalette.emeraldWealth;

  @override
  Widget build(BuildContext context) {
    // If an ancestor already provides ambient floating background, avoid stacking duplicate backgrounds & orbs
    if (_AmbientScope.hasAncestor(context)) {
      return child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    ThemeStudioController? studio;
    try {
      studio = Provider.of<ThemeStudioController?>(context);
    } catch (_) {
      studio = null;
    }
    final useCalmEmerald = _usesCalmBackdrop(studio);
    if (studio?.freshAppearance == true) {
      return _AmbientScope(
        child: ColoredBox(color: FinoraTokens.bg(isDark), child: child),
      );
    }
    final meta = studio?.currentAmbientBlurMeta;
    final vibrancy = studio?.gradientVibrancy ?? 1.15;
    final paletteHeroGradient = studio?.currentPaletteMeta.heroGradient ??
        const [
          Color(0xFF005FEA),
          Color(0xFF00C2FA),
        ];
    final primaryColor = studio?.resolvedPrimary ?? paletteHeroGradient.first;
    final secondaryColor = studio?.resolvedSecondary ??
        (paletteHeroGradient.length > 1
            ? paletteHeroGradient[1]
            : primaryColor);

    final seasonalTheme = studio?.seasonalTheme ?? AppSeasonalTheme.none;
    final (Color, Color)? seasonalPair = switch (seasonalTheme) {
      AppSeasonalTheme.springTet => (
          const Color(0xFFDC2626),
          const Color(0xFFF59E0B)
        ),
      AppSeasonalTheme.summerBreeze => (
          const Color(0xFF00C4B4),
          const Color(0xFF0284C7)
        ),
      AppSeasonalTheme.autumnAmber => (
          const Color(0xFFD97706),
          const Color(0xFFEA580C)
        ),
      AppSeasonalTheme.winterChristmas => (
          const Color(0xFF059669),
          const Color(0xFFDC2626)
        ),
      AppSeasonalTheme.none => null,
    };

    final isDefaultAurora = meta?.preset == AmbientBlurPreset.rainbowAurora;
    final paletteDarkBg =
        studio?.currentPaletteMeta.darkBg ?? const Color(0xFF0B0D11);
    final paletteLightBg =
        studio?.currentPaletteMeta.lightBg ?? const Color(0xFFF8FAFC);

    final List<Color> ambientBgColors;
    if (meta?.preset == AmbientBlurPreset.amoledPitch && isDark) {
      ambientBgColors = const [
        Color(0xFF000000),
        Color(0xFF000000),
        Color(0xFF000000),
        Color(0xFF000000),
      ];
    } else if (useCalmEmerald) {
      ambientBgColors = isDark
          ? [
              Color.alphaBlend(
                primaryColor.withValues(alpha: 0.09),
                const Color(0xFF060A12),
              ),
              Color.alphaBlend(
                secondaryColor.withValues(alpha: 0.07),
                const Color(0xFF09111E),
              ),
              Color.alphaBlend(
                const Color(0xFF0284C7).withValues(alpha: 0.06),
                const Color(0xFF0B1626),
              ),
              Color.alphaBlend(
                primaryColor.withValues(alpha: 0.05),
                const Color(0xFF070C16),
              ),
            ]
          : [
              Color.alphaBlend(
                primaryColor.withValues(alpha: 0.035),
                const Color(0xFFF6F9FC),
              ),
              Color.alphaBlend(
                secondaryColor.withValues(alpha: 0.025),
                const Color(0xFFF2F6FA),
              ),
              Color.alphaBlend(
                const Color(0xFF0284C7).withValues(alpha: 0.025),
                const Color(0xFFEEF4F9),
              ),
              Color.alphaBlend(
                primaryColor.withValues(alpha: 0.02),
                const Color(0xFFF7FAFC),
              ),
            ];
    } else {
      // Tint custom preset with active palette primary so palette choice transforms the screen cleanly
      final rawColors = isDark
          ? (meta?.bgColorsDark ??
              [paletteDarkBg, paletteDarkBg, paletteDarkBg])
          : (meta?.bgColorsLight ??
              [paletteLightBg, paletteLightBg, paletteLightBg]);
      ambientBgColors = rawColors
          .map((c) => Color.alphaBlend(
              primaryColor.withValues(alpha: isDark ? 0.08 : 0.03), c))
          .toList();
    }

    final styleBgColors = studio?.getStyleBackgroundColors(isDark);
    final bgColors = styleBgColors == null
        ? ambientBgColors
        : List<Color>.generate(
            styleBgColors.length,
            (i) => Color.lerp(
              styleBgColors[i],
              ambientBgColors[i % ambientBgColors.length],
              studio?.prefersQuietBackground == true ? 0.45 : 0.65,
            )!,
          );

    final isAmoled = meta?.preset == AmbientBlurPreset.amoledPitch && isDark;
    final List<Color> effectiveBgColors;
    if (studio?.useCustomRgbMeshBg == true &&
        !isAmoled &&
        (studio?.customBgIntensity ?? 0.18) > 0.002) {
      final intensity = (studio?.customBgIntensity ?? 0.18).clamp(0.05, 0.45);
      final c1 = studio?.customBgColor1 ?? const Color(0xFF10B981);
      final c2 = studio?.customBgColor2 ?? const Color(0xFF0284C7);
      final c3 = studio?.customBgColor3 ?? const Color(0xFF059669);
      if (isDark) {
        effectiveBgColors = [
          Color.alphaBlend(
              c1.withValues(alpha: intensity * 0.40), paletteDarkBg),
          Color.alphaBlend(
              c2.withValues(alpha: intensity * 0.30), paletteDarkBg),
          Color.alphaBlend(
              c3.withValues(alpha: intensity * 0.36), paletteDarkBg),
        ];
      } else {
        effectiveBgColors = [
          Color.alphaBlend(
              c1.withValues(alpha: intensity * 0.30), paletteLightBg),
          Color.alphaBlend(
              c2.withValues(alpha: intensity * 0.22), const Color(0xFFF8FAF9)),
          Color.alphaBlend(
              c3.withValues(alpha: intensity * 0.26), paletteLightBg),
        ];
      }
    } else if (studio?.useCustomBgGradient == true &&
        (studio?.getEffectiveCustomBgGradientColors(isDark).length ?? 0) >= 2) {
      effectiveBgColors = studio!.getEffectiveCustomBgGradientColors(isDark);
    } else {
      effectiveBgColors = bgColors;
    }

    final orbOpacity = (isDark ? 0.12 : 0.075) *
        vibrancy.clamp(0.7, 1.25) *
        (studio?.backgroundTintOpacity ?? 0.85) *
        (studio?.prefersQuietBackground == true ? 0.45 : 1.0);

    // Harmonious analogous aurora orbs (never mix green with yellow/orange to avoid muddy olive tones)
    final Color rawOrb1;
    final Color rawOrb2;
    final Color rawOrb3;
    final Color rawOrb4;
    final Color rawOrb5;
    final Color rawOrb6;

    if (isDefaultAurora || meta == null || useCalmEmerald) {
      rawOrb1 = primaryColor;
      rawOrb2 = secondaryColor;
      rawOrb3 = paletteHeroGradient.length > 2 &&
              studio?.customPrimaryAccentColor == null
          ? paletteHeroGradient[2]
          : Color.lerp(primaryColor, secondaryColor, 0.5)!;
      rawOrb4 = seasonalPair != null
          ? seasonalPair.$2
          : Color.lerp(secondaryColor, primaryColor, 0.35)!;
      rawOrb5 = seasonalPair != null
          ? seasonalPair.$1
          : Color.lerp(primaryColor, secondaryColor, 0.65)!;
      rawOrb6 = Color.lerp(secondaryColor, primaryColor, 0.5)!;
    } else {
      rawOrb1 = Color.lerp(meta.orb1, primaryColor, 0.50)!;
      rawOrb2 = Color.lerp(meta.orb2, secondaryColor, 0.50)!;
      rawOrb3 = Color.lerp(meta.orb3, paletteHeroGradient.last, 0.45)!;
      rawOrb4 = seasonalPair != null
          ? seasonalPair.$2
          : Color.lerp(meta.orb4, secondaryColor, 0.45)!;
      rawOrb5 = seasonalPair != null
          ? seasonalPair.$1
          : Color.lerp(primaryColor, const Color(0xFF0284C7), 0.35)!;
      rawOrb6 = Color.lerp(secondaryColor, primaryColor, 0.5)!;
    }

    final orb1Color =
        rawOrb1.withValues(alpha: (orbOpacity * 1.35).clamp(0.0, 1.0));
    final orb2Color =
        rawOrb2.withValues(alpha: (orbOpacity * 1.15).clamp(0.0, 1.0));
    final orb3Color =
        rawOrb3.withValues(alpha: (orbOpacity * 1.0).clamp(0.0, 1.0));
    final orb4Color =
        rawOrb4.withValues(alpha: (orbOpacity * 0.95).clamp(0.0, 1.0));
    final orb5Color =
        rawOrb5.withValues(alpha: (orbOpacity * 0.85).clamp(0.0, 1.0));
    final orb6Color =
        rawOrb6.withValues(alpha: (orbOpacity * 0.90).clamp(0.0, 1.0));

    final wallpaperMeta = studio?.currentWallpaperMeta;
    final hasWallpaper = wallpaperMeta != null &&
        wallpaperMeta.preset != AppWallpaperPreset.none &&
        wallpaperMeta.assetPath != null;

    return _AmbientScope(
      child: Stack(
        children: [
          if (hasWallpaper) ...[
            Positioned.fill(
              child: Opacity(
                opacity: (studio?.ambientIntensity ?? 0.65).clamp(0.1, 1.0),
                child: Image.asset(
                  wallpaperMeta.assetPath!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: bgColors,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Subtle protective contrast veil to keep text and numbers 100% readable
            Positioned.fill(
              child: Container(
                color: isDark
                    ? Colors.black.withValues(
                        alpha: (0.42 *
                                (1.1 -
                                    (studio?.ambientIntensity ?? 0.65) * 0.25))
                            .clamp(0.2, 0.55))
                    : Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ] else if (studio?.useCustomBgGradient == true ||
              studio?.wallpaperPreset == AppWallpaperPreset.customGradient) ...[
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: studio?.customBgGradientAngle == 3
                      ? RadialGradient(
                          center: Alignment.center,
                          radius: 1.2,
                          colors: studio?.getEffectiveCustomBgGradientColors(
                                  isDark) ??
                              bgColors,
                        )
                      : LinearGradient(
                          begin: studio?.customBgGradientAngle == 1
                              ? Alignment.topCenter
                              : studio?.customBgGradientAngle == 2
                                  ? Alignment.centerLeft
                                  : Alignment.topLeft,
                          end: studio?.customBgGradientAngle == 1
                              ? Alignment.bottomCenter
                              : studio?.customBgGradientAngle == 2
                                  ? Alignment.centerRight
                                  : Alignment.bottomRight,
                          colors: studio?.getEffectiveCustomBgGradientColors(
                                  isDark) ??
                              bgColors,
                        ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                color: isDark
                    ? Colors.black.withValues(
                        alpha: (1.0 - (studio?.backgroundTintOpacity ?? 0.85))
                            .clamp(0.0, 0.95))
                    : Colors.white.withValues(
                        alpha: (1.0 - (studio?.backgroundTintOpacity ?? 0.85))
                            .clamp(0.0, 0.95)),
              ),
            ),
          ] else ...[
            // Default Ambient Gradient Background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: effectiveBgColors,
                  ),
                ),
              ),
            ),
          ],

          // Custom RGB Mesh Gradient Blur Backdrop (Group A Dynamic RGB Mixer)
          if (!isAmoled &&
              (studio?.useCustomRgbMeshBg ?? false) &&
              (studio?.customBgIntensity ?? 0.18) > 0.002)
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: CustomRgbMeshBlurPainter(
                      color1: studio?.customBgColor1 ?? const Color(0xFF10B981),
                      color2: studio?.customBgColor2 ?? const Color(0xFF0284C7),
                      color3: studio?.customBgColor3 ?? const Color(0xFF059669),
                      intensity:
                          (studio?.customBgIntensity ?? 0.18).clamp(0.0, 0.45),
                      blurSigma:
                          (studio?.customBgBlur ?? 65.0).clamp(20.0, 100.0),
                      blendStyle:
                          studio?.meshBlendStyle ?? MeshBlendStyle.radialMesh,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
            ),

          // Subtle Architectural Radial Halos (harmonized with active primary & secondary colors)
          if (!isAmoled) ...[
            Positioned(
              top: -90,
              right: -70,
              child: _buildOrb(
                size: 420,
                color: primaryColor.withValues(alpha: isDark ? 0.11 : 0.065),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -90,
              child: _buildOrb(
                size: 400,
                color: Color.lerp(secondaryColor, const Color(0xFF0284C7), 0.35)!
                    .withValues(alpha: isDark ? 0.085 : 0.05),
              ),
            ),
            Positioned(
              top: 240,
              left: -110,
              child: _buildOrb(
                size: 340,
                color: secondaryColor.withValues(alpha: isDark ? 0.07 : 0.045),
              ),
            ),
          ],

          // Liquid drifting aurora orbs (Liquid Glass signature layer)
          if (!isAmoled &&
              (studio?.systemWideLiquidGlass ?? false) &&
              !(studio?.prefersQuietBackground ?? true))
            Positioned.fill(
              child: LiquidAuroraLayer(
                isDark: isDark,
                colors: [
                  orb1Color,
                  orb2Color,
                  orb3Color,
                  orb4Color,
                  orb5Color,
                  orb6Color,
                ],
              ),
            ),

          // Seasonal Festive Subtle Accent Orbs
          if (studio?.seasonalTheme != null &&
              studio!.seasonalTheme != AppSeasonalTheme.none) ...[
            if (studio.seasonalTheme == AppSeasonalTheme.springTet) ...[
              Positioned(
                top: -30,
                right: 20,
                child: _buildOrb(
                  size: 260,
                  color: const Color(0xFFEF4444)
                      .withValues(alpha: isDark ? 0.20 : 0.12),
                ),
              ),
              Positioned(
                top: 80,
                right: -20,
                child: _buildOrb(
                  size: 200,
                  color: const Color(0xFFFBBF24)
                      .withValues(alpha: isDark ? 0.22 : 0.14),
                ),
              ),
            ] else if (studio.seasonalTheme ==
                AppSeasonalTheme.summerBreeze) ...[
              Positioned(
                top: 20,
                left: -40,
                child: _buildOrb(
                  size: 280,
                  color: const Color(0xFF06B6D4)
                      .withValues(alpha: isDark ? 0.18 : 0.10),
                ),
              ),
            ] else if (studio.seasonalTheme ==
                AppSeasonalTheme.autumnAmber) ...[
              Positioned(
                top: 140,
                right: -30,
                child: _buildOrb(
                  size: 270,
                  color: const Color(0xFFF97316)
                      .withValues(alpha: isDark ? 0.18 : 0.10),
                ),
              ),
            ] else if (studio.seasonalTheme ==
                AppSeasonalTheme.winterChristmas) ...[
              Positioned(
                top: -20,
                left: 40,
                child: _buildOrb(
                  size: 260,
                  color: const Color(0xFF38BDF8)
                      .withValues(alpha: isDark ? 0.16 : 0.09),
                ),
              ),
              Positioned(
                bottom: 200,
                right: -20,
                child: _buildOrb(
                  size: 220,
                  color: const Color(0xFF10B981)
                      .withValues(alpha: isDark ? 0.15 : 0.08),
                ),
              ),
            ],
          ],
          if ((studio?.particleSparkles ?? false) &&
              (studio?.systemWideLiquidGlass ?? false))
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: GoldSparklesPainter(
                    isDark: isDark,
                    intensity: studio?.ambientIntensity ?? 0.65,
                  ),
                ),
              ),
            ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }

  Widget _buildOrb({required double size, required Color color}) {
    if (color.a == 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

/// CustomPainter rendering a 120Hz-optimized RGB Mesh Gradient Blur backdrop
class CustomRgbMeshBlurPainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final Color color3;
  final double intensity;
  final double blurSigma;
  final MeshBlendStyle blendStyle;
  final bool isDark;

  const CustomRgbMeshBlurPainter({
    required this.color1,
    required this.color2,
    required this.color3,
    required this.intensity,
    required this.blurSigma,
    this.blendStyle = MeshBlendStyle.radialMesh,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || intensity <= 0.002) return;

    final shortest = size.shortestSide > 0 ? size.shortestSide : 390.0;
    final blurFactor = (blurSigma / 65.0).clamp(0.60, 1.60);
    final effectiveAlpha =
        (intensity * (isDark ? 1.55 : 1.35)).clamp(0.12, 0.70);

    switch (blendStyle) {
      case MeshBlendStyle.auroraWave:
        _paintAuroraWave(canvas, size, shortest, blurFactor, effectiveAlpha);
        break;

      case MeshBlendStyle.linearFlow:
        _paintLinearFlow(canvas, size, shortest, blurFactor, effectiveAlpha);
        break;

      case MeshBlendStyle.centerAura:
        _paintCenterAura(canvas, size, shortest, blurFactor, effectiveAlpha);
        break;

      case MeshBlendStyle.prismaticFusion:
        _paintPrismaticFusion(
            canvas, size, shortest, blurFactor, effectiveAlpha);
        break;

      case MeshBlendStyle.radialMesh:
        _paintRadialMesh(canvas, size, shortest, blurFactor, effectiveAlpha);
        break;
    }
  }

  void _paintRadialMesh(Canvas canvas, Size size, double shortest,
      double blurFactor, double effectiveAlpha) {
    // Blob 1: Top-Left (Primary RGB Orb)
    final center1 = Offset(size.width * 0.12, size.height * 0.10);
    final radius1 = shortest * 1.10 * blurFactor;
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          color1.withValues(alpha: effectiveAlpha),
          color1.withValues(alpha: effectiveAlpha * 0.50),
          color1.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center1, radius: radius1));
    canvas.drawCircle(center1, radius1, paint1);

    // Blob 2: Top-Right / Upper-Center (Secondary RGB Orb)
    final center2 = Offset(size.width * 0.90, size.height * 0.35);
    final radius2 = shortest * 1.05 * blurFactor;
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          color2.withValues(alpha: (effectiveAlpha * 0.95).clamp(0.0, 0.70)),
          color2.withValues(alpha: effectiveAlpha * 0.45),
          color2.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center2, radius: radius2));
    canvas.drawCircle(center2, radius2, paint2);

    // Blob 3: Bottom-Left / Lower-Center (Tertiary RGB Orb)
    final center3 = Offset(size.width * 0.28, size.height * 0.85);
    final radius3 = shortest * 1.15 * blurFactor;
    final paint3 = Paint()
      ..shader = RadialGradient(
        colors: [
          color3.withValues(alpha: (effectiveAlpha * 0.92).clamp(0.0, 0.70)),
          color3.withValues(alpha: effectiveAlpha * 0.42),
          color3.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.58, 1.0],
      ).createShader(Rect.fromCircle(center: center3, radius: radius3));
    canvas.drawCircle(center3, radius3, paint3);

    // Blob 4: Mid-Lower Center (Chromatic Blend Bridge)
    final center4 = Offset(size.width * 0.75, size.height * 0.70);
    final radius4 = shortest * 0.85 * blurFactor;
    final midColor = Color.lerp(color1, color2, 0.5) ?? color2;
    final paint4 = Paint()
      ..shader = RadialGradient(
        colors: [
          midColor.withValues(alpha: (effectiveAlpha * 0.65).clamp(0.0, 0.55)),
          midColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center4, radius: radius4));
    canvas.drawCircle(center4, radius4, paint4);
  }

  void _paintAuroraWave(Canvas canvas, Size size, double shortest,
      double blurFactor, double effectiveAlpha) {
    // Upper Aurora Wave (Sweeping ribbon from left to right)
    final rect1 = Rect.fromLTWH(-size.width * 0.2, -size.height * 0.1,
        size.width * 1.4, size.height * 0.55);
    final paint1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color1.withValues(alpha: effectiveAlpha * 1.1),
          color2.withValues(alpha: effectiveAlpha * 0.75),
          color2.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect1);
    canvas.drawRect(rect1, paint1);

    // Mid Aurora Wave (Diagonal chromatic ripple)
    final rect2 = Rect.fromLTWH(
        0, size.height * 0.30, size.width * 1.2, size.height * 0.50);
    final paint2 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          color2.withValues(alpha: 0.0),
          color2.withValues(alpha: effectiveAlpha * 0.85),
          color3.withValues(alpha: effectiveAlpha * 0.70),
          color3.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.35, 0.75, 1.0],
      ).createShader(rect2);
    canvas.drawRect(rect2, paint2);

    // Lower Deep Aurora Glow
    final center3 = Offset(size.width * 0.50, size.height * 0.92);
    final radius3 = shortest * 1.20 * blurFactor;
    final paint3 = Paint()
      ..shader = RadialGradient(
        colors: [
          color3.withValues(alpha: effectiveAlpha * 0.95),
          color1.withValues(alpha: effectiveAlpha * 0.45),
          color1.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.60, 1.0],
      ).createShader(Rect.fromCircle(center: center3, radius: radius3));
    canvas.drawCircle(center3, radius3, paint3);
  }

  void _paintLinearFlow(Canvas canvas, Size size, double shortest,
      double blurFactor, double effectiveAlpha) {
    // Primary Diagonal Flow
    final rect1 = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color1.withValues(alpha: effectiveAlpha * 1.05),
          color2.withValues(alpha: effectiveAlpha * 0.80),
          color3.withValues(alpha: effectiveAlpha * 0.90),
        ],
        stops: const [0.0, 0.48, 1.0],
      ).createShader(rect1);
    canvas.drawRect(rect1, paint1);

    // Secondary Cross-Flow Sheen
    final paint2 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          color2.withValues(alpha: effectiveAlpha * 0.60),
          Colors.transparent,
          color1.withValues(alpha: effectiveAlpha * 0.40),
        ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(rect1);
    canvas.drawRect(rect1, paint2);
  }

  void _paintCenterAura(Canvas canvas, Size size, double shortest,
      double blurFactor, double effectiveAlpha) {
    final center = Offset(size.width * 0.50, size.height * 0.40);
    final radius = shortest * 1.35 * blurFactor;

    // Core Aura
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          color1.withValues(alpha: effectiveAlpha * 1.2),
          color2.withValues(alpha: effectiveAlpha * 0.85),
          color3.withValues(alpha: effectiveAlpha * 0.45),
          color3.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.35, 0.70, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint1);

    // Peripheral Accent Orb
    final subCenter = Offset(size.width * 0.50, size.height * 0.88);
    final subRadius = shortest * 0.95 * blurFactor;
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          color3.withValues(alpha: effectiveAlpha * 0.85),
          color2.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: subCenter, radius: subRadius));
    canvas.drawCircle(subCenter, subRadius, paint2);
  }

  void _paintPrismaticFusion(Canvas canvas, Size size, double shortest,
      double blurFactor, double effectiveAlpha) {
    // Vertex 1: Top-Left (Color 1)
    final c1 = Offset(size.width * 0.15, size.height * 0.15);
    final r1 = shortest * 1.05 * blurFactor;
    final p1 = Paint()
      ..shader = RadialGradient(
        colors: [
          color1.withValues(alpha: effectiveAlpha * 1.1),
          color1.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: c1, radius: r1));
    canvas.drawCircle(c1, r1, p1);

    // Vertex 2: Top-Right (Color 2)
    final c2 = Offset(size.width * 0.85, size.height * 0.28);
    final r2 = shortest * 1.05 * blurFactor;
    final p2 = Paint()
      ..shader = RadialGradient(
        colors: [
          color2.withValues(alpha: effectiveAlpha * 1.05),
          color2.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: c2, radius: r2));
    canvas.drawCircle(c2, r2, p2);

    // Vertex 3: Bottom-Center (Color 3)
    final c3 = Offset(size.width * 0.50, size.height * 0.82);
    final r3 = shortest * 1.15 * blurFactor;
    final p3 = Paint()
      ..shader = RadialGradient(
        colors: [
          color3.withValues(alpha: effectiveAlpha * 1.1),
          color3.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: c3, radius: r3));
    canvas.drawCircle(c3, r3, p3);

    // Central Chromatic Prismatic Bridge
    final c4 = Offset(size.width * 0.50, size.height * 0.48);
    final r4 = shortest * 0.75 * blurFactor;
    final bridgeColor = Color.lerp(color1, color3, 0.5) ?? color1;
    final p4 = Paint()
      ..shader = RadialGradient(
        colors: [
          bridgeColor.withValues(alpha: effectiveAlpha * 0.70),
          bridgeColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: c4, radius: r4));
    canvas.drawCircle(c4, r4, p4);
  }

  @override
  bool shouldRepaint(covariant CustomRgbMeshBlurPainter oldDelegate) {
    return oldDelegate.color1 != color1 ||
        oldDelegate.color2 != color2 ||
        oldDelegate.color3 != color3 ||
        oldDelegate.intensity != intensity ||
        oldDelegate.blurSigma != blurSigma ||
        oldDelegate.blendStyle != blendStyle ||
        oldDelegate.isDark != isDark;
  }
}

/// FloatingGlassCard: Authentic frosted glassmorphism & deep UI/UX styling.
/// Seamlessly adapts to selected AppUiUxStyle (Liquid Glass, Neumorphic Soft, Cyber Neon, Cupertino Minimal, Luxury Obsidian).
class FloatingGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? radius;
  final VoidCallback? onTap;
  final double? blur;
  final Color? customFillColor;
  final Border? customBorder;
  final List<BoxShadow>? customShadows;
  final bool glow;
  final Color? glowColor;

  const FloatingGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius,
    this.onTap,
    this.blur,
    this.customFillColor,
    this.customBorder,
    this.customShadows,
    this.glow = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final insideModal = FinoraModalScope.isInsideModal(context);

    final effectiveBlur =
        insideModal ? 0.0 : (blur ?? (studio?.glassBlur ?? 18.0));
    final effectiveRadius = radius ?? (studio?.cardCornerRadius ?? 22.0);
    final effectivePadding =
        padding ?? (studio?.getCardInsets() ?? const EdgeInsets.all(18));

    final dec = studio?.getWidgetCardDecoration(
          isDark: isDark,
          customRadius: effectiveRadius,
          customBg: customFillColor,
          customBorder: customBorder,
          forceOpaque: insideModal,
        ) ??
        studio?.getCardDecoration(
          isDark: isDark,
          radius: effectiveRadius,
          customFill: customFillColor,
          customBorder: customBorder,
          customShadows: customShadows,
          forceOpaque: insideModal,
        );

    Widget content = Padding(
      padding: effectivePadding,
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap!();
          },
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: content,
        ),
      );
    }

    final isLiquidGlass =
        !insideModal && (studio?.isSystemWideLiquidGlass ?? false);
    final wantsGlassLook = !insideModal &&
        ((studio?.glassOpacity ?? 1.0) < 0.98 || isLiquidGlass);
    // Cheap glass by default: keep the translucent fill + specular rim + glow
    // but skip the per-card BackdropFilter. Card fills are 88-98% opaque, so
    // the blur is nearly invisible yet costs a full GPU pass per card per
    // frame (the main source of jank). Real per-card blur is opt-in.
    final realBlur = !insideModal &&
        (studio?.cardBackdropBlur ?? false) &&
        effectiveBlur > 0.5 &&
        wantsGlassLook;

    if (wantsGlassLook) {
      final primaryColor = studio?.resolvedPrimary ?? const Color(0xFF005FEA);
      final tintColor = isDark ? Colors.white : primaryColor;
      final enableSpecular = studio?.liquidGlassSpecularHighlight ?? false;
      final enableCaustics = studio?.liquidGlassCausticRefraction ?? false;

      final List<BoxShadow> effectiveShadows = [
        if (dec?.boxShadow != null) ...dec!.boxShadow!,
        if (isLiquidGlass)
          BoxShadow(
            color: (glow ? (glowColor ?? primaryColor) : primaryColor)
                .withValues(alpha: isDark ? 0.06 : 0.02),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 6),
          ),
      ];

      final glassStack = Stack(
        fit: StackFit.passthrough,
        children: [
                // Layer 1: Base Container / Gradient Fill
                Container(
                  decoration: BoxDecoration(
                    color: dec?.gradient != null
                        ? null
                        : (dec?.color ??
                            (isDark
                                ? const Color(0xFF142238).withValues(
                                    alpha: (studio?.glassOpacity ?? 0.88)
                                        .clamp(0.15, 0.98))
                                : Colors.white.withValues(
                                    alpha: (studio?.glassOpacity ?? 0.94)
                                        .clamp(0.15, 0.98)))),
                    gradient: dec?.gradient,
                    borderRadius: BorderRadius.circular(effectiveRadius),
                    border: isLiquidGlass ? null : dec?.border,
                  ),
                ),

              // Layer 2: Simulated Caustic Refraction Sheen & Subtle Rim
              if (isLiquidGlass && enableCaustics)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: LiquidRefractionPainter(
                        borderRadius: effectiveRadius,
                        tintColor: tintColor,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),

              // Layer 3: Content Body
              content,

              // Layer 4: Micro-Specular Rim & Directional Gradient Border
              if (isLiquidGlass && enableSpecular)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: LiquidSpecularBorderPainter(
                        borderRadius: effectiveRadius,
                        borderWidth:
                            (studio?.widgetBorderWidth ?? 1.25).clamp(0.8, 1.8),
                        borderGradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: const [0.0, 0.25, 0.62, 1.0],
                          colors: isDark
                              ? const [
                                  Color(0x4DFFFFFF),
                                  Color(0x0FFFFFFF),
                                  Color(0x00FFFFFF),
                                  Color(0x0AFFFFFF),
                                ]
                              : const [
                                  Color(0x8CFFFFFF),
                                  Color(0x1FFFFFFF),
                                  Color(0x00FFFFFF),
                                  Color(0x14FFFFFF),
                                ],
                        ),
                        enableSpecularHighlight: true,
                      ),
                    ),
                  ),
                ),
        ],
      );

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(effectiveRadius),
          boxShadow: effectiveShadows,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: realBlur
              ? BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: effectiveBlur.clamp(0.0, 32.0),
                    sigmaY: effectiveBlur.clamp(0.0, 32.0),
                  ),
                  child: glassStack,
                )
              : glassStack,
        ),
      );
    }

    return Container(
      decoration: dec,
      child: content,
    );
  }
}

/// 3. GlassCard: Upgraded with real BackdropFilter and floating glass styling.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool highlighted;
  final double? radius;
  final VoidCallback? onTap;
  final double? blur;
  final Color? customFillColor;
  final Border? customBorder;
  final List<BoxShadow>? customShadows;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.highlighted = false,
    this.radius,
    this.onTap,
    this.blur,
    this.customFillColor,
    this.customBorder,
    this.customShadows,
  });

  @override
  Widget build(BuildContext context) {
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final effectiveBlur = blur ?? (studio?.glassBlur ?? 16.0);
    final effectiveRadius = radius ?? (studio?.cardCornerRadius ?? 20.0);
    final effectivePadding =
        padding ?? (studio?.getCardInsets() ?? const EdgeInsets.all(16));

    return FloatingGlassCard(
      padding: effectivePadding,
      radius: effectiveRadius,
      onTap: onTap,
      blur: effectiveBlur,
      glow: highlighted,
      glowColor: studio?.primaryColor ?? const Color(0xFF2563EB),
      customFillColor: customFillColor,
      customBorder: customBorder,
      customShadows: customShadows,
      child: child,
    );
  }
}

/// 4. GradientButton: Solid Stadium Pill Button (`BorderRadius.circular(100)`) with 100% opaque fill and smooth loading state.
class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final List<Color> colors;
  final double height;
  final bool expand;
  final double radius;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.colors = const [Color(0xFF0F6E56), Color(0xFF10B981)],
    this.height = 54.0,
    this.expand = true,
    this.radius = 100.0,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const effectiveRadius = 100.0;
    final effectiveHeight = height == 54.0 && studio != null
        ? studio.getButtonHeight() + 4.0
        : height;
    final primary = studio?.resolvedButtonPrimary ??
        studio?.resolvedPrimary ??
        colors.first;
    final solidBrandColor = primary.withValues(alpha: 1.0);
    final enabled = onPressed != null && !isLoading;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(effectiveRadius),
    );

    final boxDecoration = BoxDecoration(
      color: enabled
          ? solidBrandColor
          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFEAF0ED)),
      borderRadius: BorderRadius.circular(effectiveRadius),
      boxShadow: enabled
          ? [
              BoxShadow(
                color: solidBrandColor.withValues(alpha: isDark ? 0.32 : 0.22),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ]
          : null,
    );

    final content = FilledButton(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        minimumSize: Size(48, effectiveHeight),
        backgroundColor: Colors.transparent,
        disabledBackgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        disabledForegroundColor:
            isDark ? Colors.white54 : const Color(0xFF64748B),
        shadowColor: Colors.transparent,
        shape: shape,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isLoading
            ? const SizedBox(
                key: ValueKey('loading'),
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : KeyedSubtree(
                key: const ValueKey('content'),
                child: child,
              ),
      ),
    );

    final button = DecoratedBox(decoration: boxDecoration, child: content);
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Solid Stadium Pill Primary & Secondary Button (`BorderRadius.circular(100)`)
class FinoraButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? color;
  final double height;
  final bool expand;
  final bool isLoading;
  final bool loading;
  final bool isSecondary;
  final EdgeInsetsGeometry? padding;

  const FinoraButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.height = 52.0,
    this.expand = false,
    this.isLoading = false,
    this.loading = false,
    this.isSecondary = false,
    this.padding,
  });

  @override
  State<FinoraButton> createState() => _FinoraButtonState();
}

class _FinoraButtonState extends State<FinoraButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final busy = widget.isLoading || widget.loading;
    final enabled = widget.onPressed != null && !busy;

    final primaryBrand = (widget.color ??
            studio?.resolvedButtonPrimary ??
            studio?.resolvedPrimary ??
            const Color(0xFF0F6E56))
        .withValues(alpha: 1.0);

    final bgColor = widget.isSecondary
        ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFEAF0ED))
        : primaryBrand;

    final fgColor = widget.isSecondary
        ? (isDark ? Colors.white : const Color(0xFF0F172A))
        : Colors.white;

    final effectiveHeight = widget.height == 52.0 && studio != null
        ? studio.getButtonHeight()
        : widget.height;

    final effectivePadding = widget.padding ??
        studio?.getButtonPadding() ??
        const EdgeInsets.symmetric(horizontal: 20, vertical: 12);

    final pill = AnimatedScale(
      scale: _pressed && enabled ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: widget.onPressed == null && !busy ? 0.52 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(100),
            border: widget.isSecondary
                ? Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFD5E0DC),
                    width: 1.0,
                  )
                : null,
            boxShadow: !widget.isSecondary && enabled
                ? [
                    BoxShadow(
                      color:
                          primaryBrand.withValues(alpha: isDark ? 0.30 : 0.20),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Container(
            height: effectiveHeight,
            constraints: const BoxConstraints(minWidth: 48),
            padding: effectivePadding,
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: busy
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : KeyedSubtree(
                      key: const ValueKey('child'),
                      child: DefaultTextStyle.merge(
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: fgColor,
                        ),
                        child: IconTheme.merge(
                          data: IconThemeData(color: fgColor, size: 18),
                          child: widget.child,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );

    final gesture = Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _pressed = false);
                HapticFeedback.lightImpact();
                widget.onPressed?.call();
              }
            : null,
        child: pill,
      ),
    );

    return widget.expand
        ? SizedBox(width: double.infinity, child: gesture)
        : gesture;
  }
}

/// Solid Stadium Action Pill (`BorderRadius.circular(100)`)
/// Primary uses 100% opaque brand color; secondary uses solid `#EAF0ED` light / `#1E293B` dark.
class FinoraActionPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool primary;
  final Color? color;
  final double height;
  final EdgeInsetsGeometry? padding;

  const FinoraActionPill({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.primary = false,
    this.color,
    this.height = 34.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandColor = (color ??
            studio?.resolvedButtonPrimary ??
            studio?.resolvedPrimary ??
            const Color(0xFF0F6E56))
        .withValues(alpha: 1.0);

    final bgColor = primary
        ? brandColor
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFEAF0ED));
    final fgColor = primary
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF0F172A));

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
        border: primary
            ? null
            : Border.all(
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFD5E0DC),
                width: 1.0,
              ),
        boxShadow: primary
            ? [
                BoxShadow(
                  color: brandColor.withValues(alpha: isDark ? 0.28 : 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          child: Container(
            height: height,
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: fgColor),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: fgColor,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Solid Stadium Section Action Pill (`BorderRadius.circular(100)`)
/// Uses solid `#EAF0ED` in Light mode / `#1E293B` in Dark mode (or 100% opaque brand fill when primary).
class FinoraSectionActionPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool? primary;

  const FinoraSectionActionPill({
    super.key,
    this.label = 'Xem tất cả',
    required this.onTap,
    this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isAddAction = primary ?? label.toLowerCase().contains('thêm');
    if (isAddAction) {
      return FinoraActionPill(
        icon: Icons.add_rounded,
        label: label,
        onTap: onTap,
        primary: true,
        height: 30.0,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      );
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFEAF0ED);
    final fgColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final chevronColor = isDark ? Colors.white70 : const Color(0xFF475569);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFD5E0DC),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: fgColor,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: chevronColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 5. FinoraTextField: Premium text field with radius 20-22 and beautiful design.
class FinoraTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final Widget? suffix;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final double radius;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization? textCapitalization;

  const FinoraTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.suffix,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.radius = 22.0,
    this.inputFormatters,
    this.textCapitalization,
  });

  @override
  Widget build(BuildContext context) {
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final liquid = studio?.isSystemWideLiquidGlass ?? true;
    final isNumber = keyboardType == TextInputType.number ||
        keyboardType == const TextInputType.numberWithOptions(decimal: true) ||
        keyboardType == const TextInputType.numberWithOptions(signed: true);
    final isPlainText = !isNumber &&
        !obscure &&
        keyboardType != TextInputType.emailAddress &&
        keyboardType != TextInputType.url &&
        keyboardType != TextInputType.visiblePassword;

    final List<TextInputFormatter> effectiveFormatters = [
      if (inputFormatters != null) ...inputFormatters!,
      if ((inputFormatters == null || inputFormatters!.isEmpty) && isNumber)
        const DotSeparatorTextInputFormatter(),
      if (isPlainText &&
          (inputFormatters == null ||
              !inputFormatters!.any((f) => f is FirstLetterUpperCaseFormatter)))
        const FirstLetterUpperCaseFormatter(),
    ];

    return LiquidGlassSurface(
      radius: radius,
      blur: (studio?.glassBlur ?? 20).clamp(0.0, 16.0),
      fillColor: isDark
          ? const Color(0xFF1E293B).withValues(alpha: 0.72)
          : const Color(0xFFF8FAFC).withValues(alpha: 0.88),
      enabled: liquid,
      specular: studio?.liquidGlassSpecularHighlight ?? true,
      refraction: studio?.liquidGlassCausticRefraction ?? true,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization ??
            (isPlainText
                ? TextCapitalization.sentences
                : TextCapitalization.none),
        onChanged: onChanged,
        inputFormatters: effectiveFormatters,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          filled: false,
          fillColor: Colors.transparent,
          hintText: hint,
          suffixIcon: suffix,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
      ),
    );
  }
}

/// 6. BankIconAvatar: Perfectly circular avatar displaying bank logos.
class BankIconAvatar extends StatelessWidget {
  final String? bankCode;
  final double size;
  final bool fullBleed;

  const BankIconAvatar({
    super.key,
    required this.bankCode,
    this.size = 44.0,
    this.fullBleed = false,
  });

  @override
  Widget build(BuildContext context) {
    final code = bankCode?.trim().toUpperCase() ?? '';
    final registry = {
      'VCB': 'assets/banks/vcb.jpg',
      'VIETCOMBANK': 'assets/banks/vcb.jpg',
      'TCB': 'assets/banks/tcb.jpg',
      'TECHCOMBANK': 'assets/banks/tcb.jpg',
      'MB': 'assets/banks/mbbank.jpg',
      'MBBANK': 'assets/banks/mbbank.jpg',
      'VPB': 'assets/banks/vpb.jpg',
      'VPBANK': 'assets/banks/vpb.jpg',
      'ACB': 'assets/banks/acb.jpg',
      'TPB': 'assets/banks/tpb.jpg',
      'TPBANK': 'assets/banks/tpb.jpg',
      'BIDV': 'assets/banks/bidv.jpg',
      'CTG': 'assets/banks/vtb.jpg',
      'VIETINBANK': 'assets/banks/vtb.jpg',
      'VTB': 'assets/banks/vtb.jpg',
      'VIB': 'assets/banks/vib.jpg',
      'STB': 'assets/banks/stb.jpg',
      'SACOMBANK': 'assets/banks/stb.jpg',
      'SHB': 'assets/banks/shb.jpg',
      'HDB': 'assets/banks/hdb.jpg',
      'HDBANK': 'assets/banks/hdb.jpg',
      'MSB': 'assets/banks/msb.jpg',
      'OCB': 'assets/banks/ocb.jpg',
      'SEA': 'assets/banks/sea.jpg',
      'SEABANK': 'assets/banks/sea.jpg',
      'EIB': 'assets/banks/eib.jpg',
      'EXIMBANK': 'assets/banks/eib.jpg',
      'AGRI': 'assets/banks/agri.jpg',
      'AGRIBANK': 'assets/banks/agri.jpg',
      'NCB': 'assets/banks/ncb.png',
      'QUOCDAN': 'assets/banks/ncb.png',
      'LPB': 'assets/banks/lpbank.png',
      'LPBANK': 'assets/banks/lpbank.png',
      'NAMABANK': 'assets/banks/namabank.png',
      'NAMA': 'assets/banks/namabank.png',
      'ABB': 'assets/banks/abbank.png',
      'ABBANK': 'assets/banks/abbank.png',
      'PVCB': 'assets/banks/pvcombank.png',
      'PVCOMBANK': 'assets/banks/pvcombank.png',
      'BAB': 'assets/banks/bacabank.png',
      'BACABANK': 'assets/banks/bacabank.png',
      'BVB': 'assets/banks/bvbank.png',
      'BVBANK': 'assets/banks/bvbank.png',
      'VIETCAPITALBANK': 'assets/banks/bvbank.png',
      'VAB': 'assets/banks/vietabank.png',
      'VIETABANK': 'assets/banks/vietabank.png',
      'VBB': 'assets/banks/vietbank.png',
      'VIETBANK': 'assets/banks/vietbank.png',
      'KLB': 'assets/banks/kienlongbank.png',
      'KIENLONGBANK': 'assets/banks/kienlongbank.png',
      'PGB': 'assets/banks/pgbank.png',
      'PGBANK': 'assets/banks/pgbank.png',
      'SGB': 'assets/banks/saigonbank.png',
      'SAIGONBANK': 'assets/banks/saigonbank.png',
      'BAOVIET': 'assets/banks/baovietbank.png',
      'BAOVIETBANK': 'assets/banks/baovietbank.png',
      'GPB': 'assets/banks/gpbank.png',
      'GPBANK': 'assets/banks/gpbank.png',
      'OCEANBANK': 'assets/banks/oceanbank.png',
      'MBV': 'assets/banks/oceanbank.png',
      'CBB': 'assets/banks/cbbank.png',
      'CBBANK': 'assets/banks/cbbank.png',
      'VikkiBank': 'assets/banks/vikki.png',
      'SCB': 'assets/banks/scb.png',
      'COOPBANK': 'assets/banks/coopbank.png',
      'VBSP': 'assets/banks/vbsp.png',
      'VRB': 'assets/banks/vrb.png',
      'IVB': 'assets/banks/ivb.png',
      'INDOVINABANK': 'assets/banks/ivb.png',
      'CAKE': 'assets/banks/cake.jpg',
      'TIMO': 'assets/banks/timo.jpg',
      'TNEX': 'assets/banks/tnex.png',
      'UBANK': 'assets/banks/ubank.png',
      'LIOBANK': 'assets/banks/liobank.png',
      'VIKKI': 'assets/banks/vikki.png',
      'DONGA': 'assets/banks/vikki.png',
      'DONGABANK': 'assets/banks/vikki.png',
      'WOORI': 'assets/banks/wooribank.png',
      'WOORIBANK': 'assets/banks/wooribank.png',
      'SHINHAN': 'assets/banks/shinhan.png',
      'SHINHANBANK': 'assets/banks/shinhan.png',
      'HSBC': 'assets/banks/hsbc.png',
      'SCVN': 'assets/banks/standardchartered.png',
      'STANDARDCHARTERED': 'assets/banks/standardchartered.png',
      'UOB': 'assets/banks/uob.png',
      'PBVN': 'assets/banks/publicbank.png',
      'PUBLICBANK': 'assets/banks/publicbank.png',
      'HLBVN': 'assets/banks/hongleong.png',
      'HONGLEONG': 'assets/banks/hongleong.png',
      'HONGLEONGBANK': 'assets/banks/hongleong.png',
      'CIMB': 'assets/banks/cimb.png',
      'KBANK': 'assets/banks/kbank.png',
      'MOMO': 'assets/banks/momo.jpg',
      'ZALO': 'assets/banks/zalo.jpg',
      'ZALOPAY': 'assets/banks/zalo.jpg',
      'VNPAY': 'assets/banks/vnpay.jpg',
      'SHOPEEPAY': 'assets/banks/shopeepay.jpg',
      'VIETTELMONEY': 'assets/banks/viettelmoney.jpg',
      'VNPTMONEY': 'assets/banks/vnptmoney.jpg',
      'PAYOO': 'assets/banks/payoo.png',
      'VTCPAY': 'assets/banks/vtcpay.png',
      'FOXPAY': 'assets/banks/foxpay.png',
      'FPTPAY': 'assets/banks/foxpay.png',
      'MOBIFONEMONEY': 'assets/banks/mobifonemoney.png',
      'SMARTPAY': 'assets/banks/smartpay.png',
      '9PAY': 'assets/banks/9pay.png',
      'APPOTAPAY': 'assets/banks/appotapay.png',
      'VINID': 'assets/banks/vinid.png',
      'ONEU': 'assets/banks/vinid.png',
      'HOMECREDIT': 'assets/banks/homecredit.png',
      'FECREDIT': 'assets/banks/fecredit.png',
      'HDSAISON': 'assets/banks/hdsaison.png',
      'MIRAEASSET': 'assets/banks/miraeasset.png',
      'SHOPEE': 'assets/banks/shopee.jpg',
      'LAZADA': 'assets/banks/lazada.jpg',
      'TIKTOK': 'assets/banks/tiktok.jpg',
      'WINMART': 'assets/banks/winmart.png',
    };

    final assetPath = registry[code];

    if (assetPath != null) {
      final oval = ClipOval(
        child: Builder(
          builder: (context) {
            final cacheDim = (size * MediaQuery.devicePixelRatioOf(context))
                .round()
                .clamp(32, 256);
            return Image.asset(
              assetPath,
              width: size,
              height: size,
              cacheWidth: cacheDim,
              cacheHeight: cacheDim,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildFallback(context, code);
              },
            );
          },
        ),
      );
      if (fullBleed) {
        return SizedBox(width: size, height: size, child: oval);
      }
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.95),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: oval,
      );
    } else {
      return _buildFallback(context, code);
    }
  }

  Widget _buildFallback(BuildContext context, String code) {
    final displayText = code.isNotEmpty
        ? (code.length > 3 ? code.substring(0, 3) : code)
        : '🏦';

    // Generates a distinct gradient color based on the code to make fallback icons visually unique
    final gradients = [
      const LinearGradient(
        colors: [Color(0xFF60A5FA), Color(0xFFC084FC)], // Blue -> Purple
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFFF472B6), Color(0xFFC084FC)], // Pink -> Purple
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFF34D399), Color(0xFF60A5FA)], // Emerald -> Blue
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFFFBBF24), Color(0xFFF87171)], // Amber -> Red
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFF22D3EE), Color(0xFF38BDF8)], // Cyan -> Sky Blue
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ];

    final hash =
        code.split('').fold<int>(0, (prev, char) => prev + char.codeUnitAt(0));
    final gradient = gradients[code.isEmpty ? 0 : hash % gradients.length];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        border: fullBleed
            ? null
            : Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.0,
              ),
        boxShadow: fullBleed
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      alignment: Alignment.center,
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: size * 0.32,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Tự động viết hoa chữ cái đầu tiên khi nhập liệu ở mọi ô văn bản
class FirstLetterUpperCaseFormatter extends TextInputFormatter {
  const FirstLetterUpperCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    int firstCharIdx = 0;
    while (firstCharIdx < text.length && text[firstCharIdx].trim().isEmpty) {
      firstCharIdx++;
    }
    if (firstCharIdx >= text.length) return newValue;

    final firstChar = text[firstCharIdx];
    final upperChar = firstChar.toUpperCase();
    if (firstChar == upperChar) return newValue;

    final updatedText = text.substring(0, firstCharIdx) +
        upperChar +
        text.substring(firstCharIdx + 1);

    return newValue.copyWith(text: updatedText);
  }
}

/// Định dạng số tiền có dấu chấm ngăn cách hàng nghìn (1.500.000),
/// hỗ trợ chỉnh sửa, chèn và xóa chữ số mượt mà tại MỌI vị trí con trỏ.
class DotSeparatorTextInputFormatter extends TextInputFormatter {
  const DotSeparatorTextInputFormatter();

  static String formatDigits(String rawDigits) {
    final cleanText = rawDigits.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) return '';
    final parsed = int.tryParse(cleanText);
    if (parsed == null || parsed <= 0) return '';
    return formatNumber(parsed);
  }

  static String formatNumber(int amount) {
    if (amount <= 0) return '';
    final cleanText = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < cleanText.length; i++) {
      if (i > 0 && (cleanText.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(cleanText[i]);
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    String workingText = newValue.text;
    int cursorOffset = newValue.selection.end.clamp(0, workingText.length);

    // Nếu người dùng bấm Backspace xóa trúng dấu chấm '.', tự động xóa chữ số đứng ngay trước dấu chấm đó
    if (oldValue.text.length - newValue.text.length == 1 &&
        oldValue.selection.isCollapsed &&
        newValue.selection.isCollapsed) {
      final deletedIndex = newValue.selection.baseOffset;
      if (deletedIndex >= 0 &&
          deletedIndex < oldValue.text.length &&
          oldValue.text[deletedIndex] == '.' &&
          deletedIndex > 0) {
        workingText = workingText.substring(0, deletedIndex - 1) +
            workingText.substring(deletedIndex);
        cursorOffset = (deletedIndex - 1).clamp(0, workingText.length);
      }
    }

    // Đếm số lượng chữ số (0-9) nằm bên trái con trỏ hiện tại
    int digitsBeforeCursor = 0;
    for (int i = 0; i < cursorOffset && i < workingText.length; i++) {
      final code = workingText.codeUnitAt(i);
      if (code >= 48 && code <= 57) {
        digitsBeforeCursor++;
      }
    }

    var cleanText = workingText.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    if (cleanText.length > 1 && cleanText.startsWith('0')) {
      final trimmed = cleanText.replaceFirst(RegExp(r'^0+'), '');
      final removedZeros =
          cleanText.length - (trimmed.isEmpty ? 1 : trimmed.length);
      cleanText = trimmed.isEmpty ? '0' : trimmed;
      digitsBeforeCursor =
          (digitsBeforeCursor - removedZeros).clamp(0, cleanText.length);
    }

    final value = int.tryParse(cleanText);
    if (value == null) {
      return oldValue;
    }

    final buffer = StringBuffer();
    for (int i = 0; i < cleanText.length; i++) {
      if (i > 0 && (cleanText.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(cleanText[i]);
    }
    final formatted = buffer.toString();

    int newCursorOffset = 0;
    if (digitsBeforeCursor > 0) {
      int seenDigits = 0;
      for (int i = 0; i < formatted.length; i++) {
        final code = formatted.codeUnitAt(i);
        if (code >= 48 && code <= 57) {
          seenDigits++;
          if (seenDigits == digitsBeforeCursor) {
            newCursorOffset = i + 1;
            break;
          }
        }
      }
      if (seenDigits < digitsBeforeCursor) {
        newCursorOffset = formatted.length;
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: newCursorOffset.clamp(0, formatted.length),
      ),
    );
  }
}
