import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_radius.dart';
import '../design_system/app_shadows.dart';

/// 1. GradientBackground: Warm white + pastel ambient gradient background.
class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.darkBg,
              AppColors.darkBg,
              Color(0xFF111217),
            ],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FAFF), Color(0xFFF4F8FB), Color(0xFFFFFBF5)],
          );

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
      ),
      child: child,
    );
  }
}

/// 2. FloatingBubblesBackground: Soft ambient Pastel Lavender / Sky Blue / Warm Peach glow.
class FloatingBubblesBackground extends StatelessWidget {
  final Widget child;
  const FloatingBubblesBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseOpacity = isDark ? 0.035 : 0.025;

    return Stack(
      children: [
        IgnorePointer(
          child: Stack(
            children: [
              // Top-left subtle lavender blob
              Positioned(
                top: -80,
                left: -70,
                child: _buildBubble(
                  size: 360,
                  colors: [
                    const Color(0xFF5B6FD4)
                        .withValues(alpha: baseOpacity * 1.8),
                    const Color(0xFFD3C3FC)
                        .withValues(alpha: baseOpacity * 0.8),
                    const Color(0xFF5B6FD4).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }

  Widget _buildBubble({required double size, required List<Color> colors}) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
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

/// 3. GlassCard: Floating rounded card with soft diffuse shadow and subtle sheen.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool highlighted;
  final double radius;
  final VoidCallback? onTap;
  final Color? color;
  final Border? customBorder;
  final List<BoxShadow>? customShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.highlighted = false,
    this.radius = 24.0,
    this.onTap,
    this.color,
    this.customBorder,
    this.customShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shape = BorderRadius.circular(radius);

    final cardColor = color ??
        (highlighted
            ? (isDark
                ? const Color(0xFF1B264A).withValues(alpha: .90)
                : const Color(0xFFEAF1FF).withValues(alpha: .82))
            : (isDark
                ? AppColors.darkSurface.withValues(alpha: .88)
                : Colors.white.withValues(alpha: .80)));

    final borderColor = highlighted
        ? AppColors.primary.withValues(alpha: 0.5)
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    Widget content = Padding(
      padding: padding,
      child: child,
    );

    Widget card = ClipRRect(
      borderRadius: shape,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: shape,
            border: customBorder ??
                Border.all(color: borderColor.withValues(alpha: .76), width: 1),
            boxShadow: customShadow ??
                (isDark
                    ? AppShadows.darkCardShadow
                    : AppShadows.lightCardShadow),
          ),
          child: content,
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: shape,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap!();
          },
          borderRadius: shape,
          child: card,
        ),
      );
    }

    return card;
  }
}

/// 4. GradientButton: Indigo to Sky Blue (or custom) gradient button with tactile scale.
class GradientButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final List<Color>? colors;
  final double radius;
  final double? height;
  final bool expand;
  final EdgeInsetsGeometry padding;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.colors,
    this.radius = 20.0,
    this.height,
    this.expand = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.isLoading = false,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final btnColors = widget.colors ?? [AppColors.primary, AppColors.primary];

    Widget btn = AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            colors: btnColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: btnColors.first.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onPressed,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            borderRadius: BorderRadius.circular(widget.radius),
            child: Padding(
              padding: widget.padding,
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : widget.child,
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.expand) {
      return SizedBox(
        width: double.infinity,
        child: btn,
      );
    }
    return btn;
  }
}

/// 5. FinoraTextField / GlassTextField
class FinoraTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final String? label;
  final bool obscure;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefix;
  final Widget? prefixIcon;
  final Widget? suffix;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final int maxLines;
  final bool autofocus;
  final bool readOnly;
  final double radius;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback? onTap;

  const FinoraTextField({
    super.key,
    this.controller,
    this.hint,
    this.label,
    this.obscure = false,
    this.obscureText = false,
    this.keyboardType,
    this.prefix,
    this.prefixIcon,
    this.suffix,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.maxLines = 1,
    this.autofocus = false,
    this.readOnly = false,
    this.radius = 20.0,
    this.inputFormatters,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final isObscure = obscure || obscureText;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF141F3C).withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isDark ? const Color(0xFF202D4E) : const Color(0xFFE8EEF8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        keyboardType: keyboardType,
        focusNode: focusNode,
        maxLines: maxLines,
        autofocus: autofocus,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        inputFormatters: inputFormatters,
        style: TextStyle(
          color: primaryTextColor,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          labelText: label,
          hintStyle: TextStyle(
            color: secondaryTextColor.withValues(alpha: 0.7),
            fontSize: 14.5,
          ),
          labelStyle: TextStyle(color: secondaryTextColor, fontSize: 13),
          prefix: prefix,
          prefixIcon: prefixIcon,
          suffix: suffix,
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        ),
      ),
    );
  }
}

/// 6. BankLogoView / BankIconAvatar
typedef BankIconAvatar = BankLogoView;

class BankLogoView extends StatelessWidget {
  final String? bankCode;
  final double size;
  const BankLogoView({super.key, this.bankCode, this.size = 38});

  @override
  Widget build(BuildContext context) {
    final code = (bankCode ?? '').trim().toLowerCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String? assetPath;
    if (code.contains('vcb') || code.contains('vietcombank')) {
      assetPath = 'assets/banks/vcb.webp';
    } else if (code.contains('tcb') || code.contains('techcombank')) {
      assetPath = 'assets/banks/tcb.webp';
    } else if (code.contains('mb') || code.contains('mbbank')) {
      assetPath = 'assets/banks/mb.webp';
    } else if (code.contains('acb')) {
      assetPath = 'assets/banks/acb.webp';
    } else if (code.contains('timo')) {
      assetPath = 'assets/banks/timo.webp';
    } else if (code.contains('tpb') || code.contains('tpbank')) {
      assetPath = 'assets/banks/tpb.webp';
    } else if (code.contains('stb') || code.contains('sacombank')) {
      assetPath = 'assets/banks/stb.webp';
    } else if (code.contains('vib')) {
      assetPath = 'assets/banks/vib.webp';
    } else if (code.contains('bidv')) {
      assetPath = 'assets/banks/bidv.png';
    } else if (code.contains('ctg') ||
        code.contains('vietinbank') ||
        code.contains('vtb')) {
      assetPath = 'assets/banks/ctg.png';
    } else if (code.contains('vpb') || code.contains('vpbank')) {
      assetPath = 'assets/banks/vpb.png';
    } else if (code.contains('hdb') || code.contains('hdbank')) {
      assetPath = 'assets/banks/hdb.png';
    } else if (code.contains('msb')) {
      assetPath = 'assets/banks/msb.png';
    } else if (code.contains('ocb')) {
      assetPath = 'assets/banks/ocb.png';
    } else if (code.contains('momo')) {
      assetPath = 'assets/banks/momo.png';
    } else if (code.contains('zalopay') || code.contains('zalo')) {
      assetPath = 'assets/banks/zalopay.png';
    }

    if (assetPath != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.30),
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => _fallback(code, isDark),
          ),
        ),
      );
    }

    return _fallback(code, isDark);
  }

  Widget _fallback(String code, bool isDark) {
    final emoji = code.contains('mặt') || code.contains('cash')
        ? '💵'
        : (code.contains('thẻ') || code.contains('card') ? '💳' : '🏦');
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18223D) : const Color(0xFFEBF1FA),
        borderRadius: BorderRadius.circular(size * 0.30),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: TextStyle(fontSize: size * 0.45)),
    );
  }
}

/// 7. DotSeparatorTextInputFormatter
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
