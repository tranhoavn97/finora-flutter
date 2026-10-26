import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
              Color(0xFF1E1B4B), // Accent navy/purple glow
              Color(0xFF0B0F19), // Deep midnight black
            ],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0E7FF), // Lavender blue
              Color(0xFFF3E8FF), // Light purple
              Color(0xFFEBF5FF), // Light sky blue
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

/// 3. GlassCard: Premium card (radius: 28-36) with drop shadow and borders.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool highlighted;
  final double radius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.highlighted = false,
    this.radius = 28.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shape = BorderRadius.circular(radius);

    // Translucent glass card fills in both modes to enable BackdropFilter blur
    final cardColor = highlighted
        ? (isDark ? const Color(0x4D1849A9) : const Color(0x1F1849A9))
        : (isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.60));
        
    final borderColor = highlighted
        ? const Color(0xFF1849A9).withOpacity(0.4)
        : (isDark ? Colors.white.withOpacity(0.14) : Colors.white.withOpacity(0.45));

    Widget content = Padding(
      padding: padding,
      child: child,
    );

    // If highlighted, auto-force nested text and icons to be white/teal glowing
    if (highlighted) {
      content = DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white),
        child: IconTheme.merge(
          data: const IconThemeData(color: Colors.white),
          child: content,
        ),
      );
    }

    Widget card = ClipRRect(
      borderRadius: shape,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: shape,
            border: Border.all(color: borderColor, width: highlighted ? 1.5 : 1.2),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: const Color(0x08000000), // Soft shadow
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ],
            gradient: highlighted
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1849A9).withOpacity(isDark ? 0.45 : 0.85),
                      const Color(0xFF3B71CA).withOpacity(isDark ? 0.25 : 0.6),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isDark ? Colors.white.withOpacity(0.18) : Colors.white.withOpacity(0.70),
                      isDark ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.35),
                    ],
                  ),
          ),
          child: content,
        ),
      ),
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        borderRadius: shape,
        child: InkWell(
          borderRadius: shape,
          onTap: onTap,
          child: card,
        ),
      );
    }

    return card;
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
    this.colors = const [Color(0xFF1877F2), Color(0xFF4DA3FF)], // Brand blue gradient
    this.height = 54.0,
    this.expand = true,
    this.radius = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    
    Widget btn = Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: shape,
        gradient: onPressed == null
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
        color: onPressed == null ? Colors.grey.withOpacity(0.3) : null,
        boxShadow: onPressed == null
            ? null
            : [
                BoxShadow(
                  color: colors.first.withOpacity(0.24),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Center(child: child),
    );

    if (onPressed != null) {
      btn = Material(
        color: Colors.transparent,
        borderRadius: shape,
        child: InkWell(
          borderRadius: shape,
          onTap: onPressed,
          child: btn,
        ),
      );
    }

    return expand ? SizedBox(width: double.infinity, child: btn) : btn;
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
    this.radius = 24.0,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final fillColor = isDark 
        ? Colors.white.withOpacity(0.04)
        : Colors.white.withOpacity(0.35); // Translucent text fields
        
    final borderColor = isDark 
        ? Colors.white.withOpacity(0.08) 
        : Colors.white.withOpacity(0.4);

    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF0F172A),
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : Colors.black38,
          fontSize: 15,
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: borderColor, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: borderColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(
            color: Color(0xFF1877F2), // Focus blue highlight
            width: 1.5,
          ),
        ),
        suffixIcon: suffix,
      ),
    );
  }
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
      'VCB': 'assets/banks/vcb.webp',
      'VIETCOMBANK': 'assets/banks/vcb.webp',
      'TCB': 'assets/banks/tcb.webp',
      'TECHCOMBANK': 'assets/banks/tcb.webp',
      'MB': 'assets/banks/mb.webp',
      'MBBANK': 'assets/banks/mb.webp',
      'VPB': 'assets/banks/vpb.png',
      'VPBANK': 'assets/banks/vpb.png',
      'ACB': 'assets/banks/acb.webp',
      'TPB': 'assets/banks/tpb.webp',
      'TPBANK': 'assets/banks/tpb.webp',
      'BIDV': 'assets/banks/bidv.png',
      'CTG': 'assets/banks/ctg.png',
      'VIETINBANK': 'assets/banks/ctg.png',
      'VTB': 'assets/banks/ctg.png',
      'VIB': 'assets/banks/vib.webp',
      'STB': 'assets/banks/stb.webp',
      'SACOMBANK': 'assets/banks/stb.webp',
      'HDB': 'assets/banks/hdb.png',
      'MSB': 'assets/banks/msb.png',
      'OCB': 'assets/banks/ocb.png',
      'TIMO': 'assets/banks/timo.webp',
      'MOMO': 'assets/banks/momo.png',
      'ZALOPAY': 'assets/banks/zalopay.png',
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

    final hash = code.split('').fold<int>(0, (prev, char) => prev + char.codeUnitAt(0));
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
      return newValue.copyWith(text: '', selection: const TextSelection.collapsed(offset: 0));
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
