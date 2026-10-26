import 'dart:ui';
import 'package:flutter/material.dart';
import '../../state/theme_studio_controller.dart' show AppPrivacyStyle;
export '../../state/theme_studio_controller.dart' show AppPrivacyStyle;

/// Widget che mờ hoặc ẩn số dư tài chính theo phong cách Privacy Shield của Finora.
class FinoraPrivacyMask extends StatelessWidget {
  final Widget child;
  final bool isProtected;
  final AppPrivacyStyle style;
  final String fallbackDots;
  final TextStyle? textStyle;
  final Color? tintColor;

  const FinoraPrivacyMask({
    super.key,
    required this.child,
    bool? isProtected,
    bool? isMasked,
    this.style = AppPrivacyStyle.dots,
    String? fallbackDots,
    String? obscureText,
    this.textStyle,
    this.tintColor,
  })  : isProtected = isProtected ?? isMasked ?? false,
        fallbackDots = fallbackDots ?? obscureText ?? '••••••••';

  @override
  Widget build(BuildContext context) {
    if (!isProtected) return child;

    switch (style) {
      case AppPrivacyStyle.dots:
        return Text(
          fallbackDots,
          style: textStyle ??
              const TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
        );

      case AppPrivacyStyle.glassBlur:
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 8.5, sigmaY: 8.5),
                child: child,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (tintColor ?? Colors.black)
                      .withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shield_rounded,
                      size: 11,
                      color: Colors.white70,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Bảo mật',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }
}
