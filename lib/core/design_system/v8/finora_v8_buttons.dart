import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../state/theme_studio_controller.dart';
import 'finora_v8_tokens.dart';

enum FinoraButtonVariant { primary, secondary, compact, destructive }

class FinoraButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final FinoraButtonVariant variant;
  final Color? color;
  final bool expand;
  final bool loading;
  final double? height;

  const FinoraButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = FinoraButtonVariant.primary,
    this.color,
    this.expand = false,
    this.loading = false,
    this.height,
  });

  @override
  State<FinoraButton> createState() => _FinoraButtonState();
}

class _FinoraButtonState extends State<FinoraButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final enabled = widget.onPressed != null && !widget.loading;
    final accent = widget.color ??
        (widget.variant == FinoraButtonVariant.destructive
            ? FinoraV8Colors.expense
            : (studio?.primaryColor ?? FinoraV8Colors.brand));
    final filled = widget.variant != FinoraButtonVariant.secondary;
    final foreground =
        filled ? Colors.white : (dark ? FinoraV8Colors.darkText : accent);

    final effectiveRadius = studio?.getButtonRadius() ?? FinoraV8Radius.pill;
    final baseHeight =
        studio?.getButtonHeight() ?? FinoraV8Metrics.primaryButton;
    final effectiveHeight = widget.height ??
        switch (widget.variant) {
          FinoraButtonVariant.primary => baseHeight,
          FinoraButtonVariant.secondary ||
          FinoraButtonVariant.destructive =>
            baseHeight * 0.92,
          FinoraButtonVariant.compact => (baseHeight * 0.76).clamp(34.0, 44.0),
        };

    final effectivePadding = widget.variant == FinoraButtonVariant.compact
        ? const EdgeInsets.symmetric(horizontal: 14)
        : (studio?.getButtonPadding() ??
            const EdgeInsets.symmetric(horizontal: 20));

    final visual = AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: FinoraV8Motion.instant,
      curve: FinoraV8Motion.fastCurve,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : .48,
        duration: FinoraV8Motion.fast,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(effectiveRadius),
            color: filled
                ? accent
                : (dark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                    : const Color(0xFFF1F5F9)),
            gradient: filled
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accent.withValues(alpha: 0.98),
                      Color.alphaBlend(
                          Colors.black.withValues(alpha: 0.10), accent),
                    ],
                  )
                : null,
            border: filled
                ? null
                : Border.all(
                    color: (dark ? Colors.white : Colors.black)
                        .withValues(alpha: dark ? 0.12 : 0.08),
                    width: 1.0,
                  ),
            boxShadow: filled && enabled
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: dark ? 0.32 : 0.20),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Container(
            height: effectiveHeight,
            constraints: const BoxConstraints(
              minWidth: FinoraV8Metrics.minTouchTarget,
            ),
            padding: effectivePadding,
            alignment: Alignment.center,
            child: widget.loading
                ? SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground,
                    ),
                  )
                : DefaultTextStyle.merge(
                    style: FinoraV8Type.label.copyWith(color: foreground),
                    child: IconTheme.merge(
                      data: IconThemeData(color: foreground, size: 18),
                      child: widget.child,
                    ),
                  ),
          ),
        ),
      ),
    );

    final target = SizedBox(
      height: widget.variant == FinoraButtonVariant.compact
          ? FinoraV8Metrics.minTouchTarget
          : effectiveHeight,
      child: Center(child: visual),
    );
    final interactive = Semantics(
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
        child: target,
      ),
    );
    return widget.expand
        ? SizedBox(width: double.infinity, child: interactive)
        : interactive;
  }
}

class FinoraIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color color;
  final bool filled;

  const FinoraIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.color = FinoraV8Colors.brand,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final buttonSize =
        studio?.getIconButtonSize() ?? FinoraV8Metrics.iconButton;
    final shapeRadius = studio?.getIconBorderRadius(buttonSize);

    final shape = shapeRadius != null &&
            studio?.iconStyle != AppIconStyle.round &&
            studio?.iconStyle != AppIconStyle.glassGlow
        ? RoundedRectangleBorder(borderRadius: shapeRadius)
        : const CircleBorder();

    return SizedBox.square(
      dimension: FinoraV8Metrics.minTouchTarget,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        style: IconButton.styleFrom(
          fixedSize: Size.square(buttonSize),
          backgroundColor: filled
              ? color
              : (dark
                  ? Colors.white.withValues(alpha: .08)
                  : Colors.white.withValues(alpha: .82)),
          foregroundColor:
              filled ? Colors.white : (dark ? FinoraV8Colors.darkText : color),
          shape: shape,
          side: filled
              ? BorderSide.none
              : BorderSide(color: color.withValues(alpha: .24)),
        ),
        icon: Icon(icon, size: buttonSize * 0.48),
      ),
    );
  }
}
