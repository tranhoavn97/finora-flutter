import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../state/theme_studio_controller.dart';

/// [FinoraThemedIcon]: Biểu tượng thương hiệu & danh mục FINORA phản hồi thời gian thực
/// theo phong cách ColorOS / HyperOS / Squircle / Pebble / Rounded được cấu hình trong Theme Studio.
class FinoraThemedIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double baseSize;
  final VoidCallback? onTap;
  final String? label;
  final bool showShadow;

  const FinoraThemedIcon({
    super.key,
    required this.icon,
    required this.color,
    this.baseSize = 44.0,
    this.onTap,
    this.label,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studio = Provider.of<ThemeStudioController?>(context);

    final scale = studio?.iconScale ?? 1.0;
    final cornerRadius = studio?.iconCornerRadius ?? 18.0;
    final effectiveSize = (baseSize * scale).clamp(28.0, 72.0);
    final iconSize = effectiveSize * 0.52;

    final shapeStyle = studio?.categoryIconStyle ?? AppCategoryIconStyle.modernSquircle;
    final decoration = studio?.getPreviewDecorationForCategoryStyle(
          shapeStyle,
          color: color,
          isDark: isDark,
          size: effectiveSize,
        ) ??
        BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(cornerRadius),
        );

    // Dynamic Squircle / Rounded container
    Widget iconBox = Container(
      width: effectiveSize,
      height: effectiveSize,
      decoration: decoration is BoxDecoration
          ? decoration.copyWith(
              borderRadius: shapeStyle == AppCategoryIconStyle.minimalCircle ||
                      shapeStyle == AppCategoryIconStyle.glassSphere
                  ? null
                  : BorderRadius.circular(cornerRadius),
            )
          : decoration,
      child: Center(
        child: Icon(
          icon,
          size: iconSize,
          color: studio?.resolveIconGlyphColor(color, isDark) ?? Colors.white,
        ),
      ),
    );

    if (onTap != null) {
      iconBox = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap!();
          },
          borderRadius: BorderRadius.circular(cornerRadius),
          child: iconBox,
        ),
      );
    }

    if (label == null) return iconBox;

    final labelScale = studio?.iconLabelScale ?? 1.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconBox,
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: (11.0 * labelScale).clamp(8.5, 14.0),
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}
