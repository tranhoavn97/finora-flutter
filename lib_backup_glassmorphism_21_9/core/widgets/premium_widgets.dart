import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system/glassmorphism_tokens.dart';
export 'liquid_glass/liquid_glass_card.dart';
export '../design_system/glassmorphism_tokens.dart';

/// 1. GradientBackground: Beautiful pastel gradient (blue -> purple -> pink).
/// Adapts dynamically to light and dark theme context.
class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Smooth continuous gradient running full screen to look beautiful under glass cards
    final gradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // Midnight slate
              Color(0xFF0A2242), // Accent deep sapphire glow
              Color(0xFF070C16), // Deep midnight black
            ],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0F9FF), // Ice blue
              Color(0xFFE0F2FE), // Light sky cyan
              Color(0xFFF8FAFC), // Pure slate canvas
            ],
          );

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
      ),
      child: child,
    );
  }
}

/// 2. FloatingBubblesBackground: Adds floating semi-transparent 3D bubbles in the background.
class FloatingBubblesBackground extends StatelessWidget {
  final Widget child;
  const FloatingBubblesBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Enable soft glowing bubbles in both light and dark modes to highlight glassmorphism blur
    final baseOpacity = isDark ? 0.08 : 0.06;

    return Stack(
      children: [
        // Bubble 1 (Top Left - Glowing Blue)
        Positioned(
          top: -40,
          left: -40,
          child: _buildBubble(
            size: 280,
            colors: [
              const Color(0xFF60A5FA).withValues(alpha: baseOpacity),
              const Color(0xFF60A5FA).withValues(alpha: 0.0),
            ],
          ),
        ),
        // Bubble 2 (Right Middle - Glowing Mint/Teal)
        Positioned(
          top: 220,
          right: -80,
          child: _buildBubble(
            size: 340,
            colors: [
              const Color(0xFF2DD4BF).withValues(alpha: baseOpacity * 0.95),
              const Color(0xFF2DD4BF).withValues(alpha: 0.0),
            ],
          ),
        ),
        // Bubble 3 (Bottom Left - Glowing Cyan)
        Positioned(
          bottom: -60,
          left: -20,
          child: _buildBubble(
            size: 300,
            colors: [
              const Color(0xFF06B6D4).withValues(alpha: baseOpacity * 0.85),
              const Color(0xFF06B6D4).withValues(alpha: 0.0),
            ],
          ),
        ),
        // Bubble 4 (Center Top - Glowing Cyan/Blue)
        Positioned(
          top: 100,
          left: 140,
          child: _buildBubble(
            size: 180,
            colors: [
              const Color(0xFF38BDF8).withValues(alpha: baseOpacity * 0.6),
              const Color(0xFF38BDF8).withValues(alpha: 0.0),
            ],
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }

  Widget _buildBubble({required double size, required List<Color> colors}) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: colors,
          ),
        ),
      ),
    );
  }
}

/// AmbientFloatingBackground: Ethereal Multi-Orb Blur Aurora canvas
/// Inspired by modern fintech aurora aesthetics (soft pastel cyan, lilac, mint and royal mist).
class AmbientFloatingBackground extends StatelessWidget {
  final Widget child;
  final bool? isDark;
  final Color? accentColor;
  final double blurSigma;

  const AmbientFloatingBackground({
    super.key,
    required this.child,
    this.isDark,
    this.accentColor,
    this.blurSigma = GlassmorphismTokens.meshBlur,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDark =
        isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final size = MediaQuery.of(context).size;

    final baseGradient = effectiveDark
        ? GlassmorphismTokens.auroraCanvasDark
        : GlassmorphismTokens.auroraCanvasLight;

    final orb1Base = accentColor ??
        (effectiveDark
            ? GlassmorphismTokens.auroraDarkOrb1
            : GlassmorphismTokens.auroraLightOrb1);
    final orb1Color = orb1Base.withValues(alpha: effectiveDark ? 0.35 : 0.32);

    final orb2Color = (effectiveDark
            ? GlassmorphismTokens.auroraDarkOrb2
            : GlassmorphismTokens.auroraLightOrb2)
        .withValues(alpha: effectiveDark ? 0.28 : 0.25);

    final orb3Color = (effectiveDark
            ? GlassmorphismTokens.auroraDarkOrb3
            : GlassmorphismTokens.auroraLightOrb3)
        .withValues(alpha: effectiveDark ? 0.25 : 0.22);

    final orb4Color = (effectiveDark
            ? GlassmorphismTokens.auroraDarkOrb4
            : GlassmorphismTokens.auroraLightOrb4)
        .withValues(alpha: effectiveDark ? 0.32 : 0.20);

    return Stack(
      children: [
        // 1. Base Gradient Canvas
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: baseGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),

        // 2. Aurora Floating Light Orbs
        // Orb 1: Top-Left Cyan/Sapphire
        Positioned(
          top: -size.width * 0.2,
          left: -size.width * 0.15,
          width: size.width * 0.9,
          height: size.width * 0.9,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  orb1Color,
                  orb1Color.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),

        // Orb 2: Top-Right Lilac/Violet
        Positioned(
          top: size.height * 0.06,
          right: -size.width * 0.25,
          width: size.width * 0.95,
          height: size.width * 0.95,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  orb2Color,
                  orb2Color.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),

        // Orb 3: Center-Left Mint/Emerald
        Positioned(
          top: size.height * 0.40,
          left: -size.width * 0.3,
          width: size.width * 0.85,
          height: size.width * 0.85,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  orb3Color,
                  orb3Color.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),

        // Orb 4: Bottom-Right Shimmer/Indigo
        Positioned(
          bottom: size.height * 0.08,
          right: -size.width * 0.2,
          width: size.width * 0.9,
          height: size.width * 0.9,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  orb4Color,
                  orb4Color.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),

        // 3. Heavy Gaussian Frost/Aurora Blur Sheet
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: const SizedBox.expand(),
          ),
        ),

        // 4. Foreground Content - completely unblocked for interaction
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}

/// FloatingGlassCard: Frosted translucent liquid glass surface with specular hairline border
class FloatingGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final VoidCallback? onTap;
  final double blur;
  final Color? customFillColor;
  final Border? customBorder;
  final Gradient? borderGradient;
  final double borderWidth;
  final List<BoxShadow>? customShadows;
  final bool glow;
  final Color? glowColor;
  final bool enableSpecularHighlight;
  final double? width;
  final double? height;

  const FloatingGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = 20,
    this.onTap,
    this.blur = GlassmorphismTokens.surfaceBlurMedium,
    this.customFillColor,
    this.customBorder,
    this.borderGradient,
    this.borderWidth = GlassmorphismTokens.borderThin,
    this.customShadows,
    this.glow = false,
    this.glowColor,
    this.enableSpecularHighlight = true,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultFill = isDark
        ? GlassmorphismTokens.cardFillDark
        : GlassmorphismTokens.cardFillLight;

    final defaultShadows = GlassmorphismTokens.cardShadow(
      isDark,
      glowColor: glow ? (glowColor ?? GlassmorphismTokens.primary) : null,
    );

    final effectiveGradient =
        borderGradient ?? GlassmorphismTokens.cardBorderGradient(isDark);

    Widget content = Padding(
      padding: padding,
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
          borderRadius: BorderRadius.circular(radius),
          splashColor: Colors.white.withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.04),
          child: content,
        ),
      );
    }

    final card = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: customFillColor ?? defaultFill,
        borderRadius: BorderRadius.circular(radius),
        border: customBorder,
        boxShadow: customShadows ?? defaultShadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              content,
              if (customBorder == null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _GlassSpecularBorderPainter(
                        borderRadius: radius,
                        borderWidth: borderWidth,
                        borderGradient: effectiveGradient,
                        enableSpecularHighlight: enableSpecularHighlight,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return card;
  }
}

/// Directional Fresnel refraction border painter with top-left specular highlight apex.
class _GlassSpecularBorderPainter extends CustomPainter {
  final double borderRadius;
  final double borderWidth;
  final Gradient borderGradient;
  final bool enableSpecularHighlight;

  const _GlassSpecularBorderPainter({
    required this.borderRadius,
    this.borderWidth = 0.8,
    required this.borderGradient,
    this.enableSpecularHighlight = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final half = borderWidth / 2.0;
    final rect = Rect.fromLTWH(
      half,
      half,
      size.width - borderWidth,
      size.height - borderWidth,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(math.max(0.0, borderRadius - half)),
    );

    // Directional hairline border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = borderGradient.createShader(rect);

    canvas.drawRRect(rrect, borderPaint);

    // Specular apex highlight along top edge
    if (enableSpecularHighlight && size.width > 24 && size.height > 24) {
      final specularPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = borderWidth * 1.3
        ..shader = ui.Gradient.linear(
          Offset(half, half),
          Offset(size.width * 0.45, half + 6),
          const [
            Color(0xB3FFFFFF), // Crisp specular apex (70%)
            Color(0x33FFFFFF), // Dissipating specular (20%)
            Color(0x00FFFFFF), // Transparent
          ],
          const [0.0, 0.6, 1.0],
        );

      final startX = math.min(
        half + math.max(0.0, borderRadius) * 0.35,
        size.width * 0.4,
      );
      if (startX < size.width * 0.4) {
        final highlightPath = Path()
          ..moveTo(startX, half)
          ..lineTo(size.width * 0.4, half);

        canvas.drawPath(highlightPath, specularPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GlassSpecularBorderPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.borderGradient != borderGradient ||
      oldDelegate.enableSpecularHighlight != enableSpecularHighlight;
}

/// 3. GlassCard: Standardized Apple Inset Grouped / Liquid Glass surface with Glassmorphism 2.0 tokens.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final bool highlighted;
  final double radius;
  final VoidCallback? onTap;
  final double blur;
  final Color? customFillColor;
  final Border? customBorder;
  final Gradient? borderGradient;
  final double borderWidth;
  final bool enableSpecularHighlight;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.highlighted = false,
    this.radius = 16,
    this.onTap,
    this.blur = GlassmorphismTokens.surfaceBlurMedium,
    this.customFillColor,
    this.customBorder,
    this.borderGradient,
    this.borderWidth = GlassmorphismTokens.borderThin,
    this.enableSpecularHighlight = true,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingGlassCard(
      padding: padding,
      margin: margin,
      radius: radius,
      onTap: onTap,
      blur: blur,
      glow: highlighted,
      glowColor: GlassmorphismTokens.primary,
      customFillColor: customFillColor,
      customBorder: customBorder,
      borderGradient: borderGradient,
      borderWidth: borderWidth,
      enableSpecularHighlight: enableSpecularHighlight,
      width: width,
      height: height,
      child: child,
    );
  }
}

/// 4. GradientButton: Premium button with radius 18-24.
class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final List<Color> colors;
  final double height;
  final bool expand;
  final double radius;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.colors = const [
      Color(0xFF1877F2),
      Color(0xFF4DA3FF)
    ], // Brand blue gradient
    this.height = 54.0,
    this.expand = true,
    this.radius = 999.0,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    final button = DecoratedBox(
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : LinearGradient(colors: colors),
        color: onPressed == null
            ? Theme.of(context).disabledColor.withValues(alpha: .18)
            : null,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: onPressed == null
            ? null
            : [
                BoxShadow(
                  color: colors.first.withValues(alpha: .22),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: Size(48, height),
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: shape,
        ),
        child: child,
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
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
  });

  @override
  Widget build(BuildContext context) => TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 1.6),
        ),
      ));
}

/// 6. BankIconAvatar: Perfectly circular avatar displaying bank logos.
class BankIconAvatar extends StatelessWidget {
  final String? bankCode;
  final double size;

  const BankIconAvatar({
    super.key,
    required this.bankCode,
    this.size = 44.0,
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
      'CAKE': 'assets/banks/cake.jpg',
      'TIMO': 'assets/banks/timo.jpg',
      'MOMO': 'assets/banks/momo.jpg',
      'ZALO': 'assets/banks/zalo.jpg',
      'ZALOPAY': 'assets/banks/zalo.jpg',
      'VNPAY': 'assets/banks/vnpay.jpg',
      'SHOPEEPAY': 'assets/banks/shopeepay.jpg',
      'VIETTELMONEY': 'assets/banks/viettelmoney.jpg',
      'VNPTMONEY': 'assets/banks/vnptmoney.jpg',
      'SHOPEE': 'assets/banks/shopee.jpg',
      'LAZADA': 'assets/banks/lazada.jpg',
      'TIKTOK': 'assets/banks/tiktok.jpg',
      'WINMART': 'assets/banks/winmart.png',
    };

    final assetPath = registry[code];

    if (assetPath != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            assetPath,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallback(context, code);
            },
          ),
        ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 4,
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

class DotSeparatorTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) {
      return newValue.copyWith(
          text: '', selection: const TextSelection.collapsed(offset: 0));
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

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Neumorphic UI Elements (Soft UI)
class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final bool isPressed;
  final bool isCircle;
  final Color? color;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.onTap,
    this.isPressed = false,
    this.isCircle = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Background color is critical for Neumorphism
    final bgColor = color ?? (isDark ? const Color(0xFF1E1E24) : const Color(0xFFF3F4F6));
    
    // Shadows
    final lightShadowColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final darkShadowColor = isDark ? Colors.black.withValues(alpha: 0.5) : const Color(0xFFD1D5DB).withValues(alpha: 0.8);

    BoxDecoration decoration;
    
    if (isPressed) {
      // Inner shadow approximation using a gradient and border
      decoration = BoxDecoration(
        color: bgColor,
        borderRadius: isCircle ? null : BorderRadius.circular(radius),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        border: Border.all(
          color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      );
    } else {
      // Outer shadow (raised)
      decoration = BoxDecoration(
        color: bgColor,
        borderRadius: isCircle ? null : BorderRadius.circular(radius),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        boxShadow: [
          // Bottom-right dark shadow
          BoxShadow(
            color: darkShadowColor,
            offset: const Offset(6, 6),
            blurRadius: 12,
            spreadRadius: 1,
          ),
          // Top-left light shadow
          BoxShadow(
            color: lightShadowColor,
            offset: const Offset(-6, -6),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      );
    }

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      content = GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap!();
        },
        child: content,
      );
    }

    return content;
  }
}
