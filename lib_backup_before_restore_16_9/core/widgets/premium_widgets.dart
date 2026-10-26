import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../state/theme_studio_controller.dart';

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
              const Color(0xFF60A5FA).withOpacity(baseOpacity),
              const Color(0xFF60A5FA).withOpacity(0.0),
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
              const Color(0xFF2DD4BF).withOpacity(baseOpacity * 0.95),
              const Color(0xFF2DD4BF).withOpacity(0.0),
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
              const Color(0xFF06B6D4).withOpacity(baseOpacity * 0.85),
              const Color(0xFF06B6D4).withOpacity(0.0),
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
              const Color(0xFF38BDF8).withOpacity(baseOpacity * 0.6),
              const Color(0xFF38BDF8).withOpacity(0.0),
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

/// AmbientFloatingBackground: Rich ambient floating light spots + gradient
/// Gives full depth and refraction under all transparent floating glass cards.
class AmbientFloatingBackground extends StatelessWidget {
  final Widget child;
  const AmbientFloatingBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ThemeStudioController? studio;
    try {
      studio = context.watch<ThemeStudioController?>();
    } catch (_) {
      studio = null;
    }
    final meta = studio?.currentAmbientBlurMeta;

    final bgColors = isDark
        ? (meta?.bgColorsDark ??
            const [Color(0xFF070B14), Color(0xFF0F172A), Color(0xFF13192B)])
        : const [Color(0xFFEAF3F9), Color(0xFFF9FBFD), Color(0xFFEDF5FA)];

    final orbOpacity = isDark ? 0.20 : 0.07;
    final orb1Color = meta != null && isDark
        ? meta.orb1.withValues(alpha: orbOpacity * 1.2)
        : const Color(0xFF0969F2).withValues(alpha: orbOpacity * 1.2);
    final orb2Color = meta != null && isDark
        ? meta.orb2.withValues(alpha: orbOpacity * 0.95)
        : const Color(0xFF8BC5FF).withValues(alpha: orbOpacity * 0.9);
    final orb3Color = meta != null && isDark
        ? meta.orb3.withValues(alpha: orbOpacity * 0.85)
        : const Color(0xFFB8D8F0).withValues(alpha: orbOpacity * 0.8);
    final orb4Color = meta != null && isDark
        ? meta.orb4.withValues(alpha: orbOpacity * 0.8)
        : const Color(0xFFB8E6D5).withValues(alpha: orbOpacity * 0.75);

    final isAmoled = meta?.preset == AmbientBlurPreset.amoledPitch && isDark;

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: bgColors,
              ),
            ),
          ),
        ),
        if (!isAmoled) ...[
          Positioned(
            top: -60,
            left: -40,
            child: _buildOrb(size: 320, color: orb1Color),
          ),
          Positioned(
            top: 80,
            right: -80,
            child: _buildOrb(size: 280, color: orb2Color),
          ),
          Positioned(
            top: 360,
            left: -70,
            child: _buildOrb(size: 300, color: orb3Color),
          ),
          Positioned(
            bottom: -40,
            right: -50,
            child: _buildOrb(size: 340, color: orb4Color),
          ),
        ],
        Positioned.fill(child: child),
      ],
    );
  }

  Widget _buildOrb({required double size, required Color color}) {
    if (color.a == 0) return const SizedBox.shrink();
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

/// Grouped iOS surface with restrained translucency and a quiet hairline.
class FloatingGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final double blur;
  final Color? customFillColor;
  final Border? customBorder;
  final List<BoxShadow>? customShadows;
  final bool glow;
  final Color? glowColor;

  const FloatingGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 20,
    this.onTap,
    this.blur = 12.0,
    this.customFillColor,
    this.customBorder,
    this.customShadows,
    this.glow = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultFill = isDark
        ? const Color(0xFF1C1C1E).withValues(alpha: 0.94)
        : Colors.white.withValues(alpha: 0.96);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : const Color(0xFFC6C6C8).withValues(alpha: 0.42);

    final defaultShadows = [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.35)
            : Colors.black.withValues(alpha: 0.055),
        blurRadius: 14,
        offset: const Offset(0, 5),
        spreadRadius: -4,
      ),
      if (glow && glowColor != null)
        BoxShadow(
          color: glowColor!.withValues(alpha: isDark ? 0.14 : 0.08),
          blurRadius: 16,
          offset: const Offset(0, 3),
        ),
    ];

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
          child: content,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: customShadows ?? defaultShadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: customFillColor ?? defaultFill,
              borderRadius: BorderRadius.circular(radius),
              border: customBorder ??
                  Border.all(
                    color: borderColor,
                    width: 0.7,
                  ),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// 3. GlassCard: Upgraded with real BackdropFilter and floating glass styling.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool highlighted;
  final double radius;
  final VoidCallback? onTap;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.highlighted = false,
    this.radius = 20,
    this.onTap,
    this.blur = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingGlassCard(
      padding: padding,
      radius: radius,
      onTap: onTap,
      blur: blur,
      glow: highlighted,
      glowColor: const Color(0xFF007AFF),
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
              color: Colors.black.withOpacity(0.08),
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
            color: Colors.black.withOpacity(0.1),
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
