import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  double get _height =>
      widget.height ??
      switch (widget.variant) {
        FinoraButtonVariant.primary => FinoraV8Metrics.primaryButton,
        FinoraButtonVariant.secondary ||
        FinoraButtonVariant.destructive =>
          FinoraV8Metrics.secondaryButton,
        FinoraButtonVariant.compact => FinoraV8Metrics.compactControl,
      };

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final enabled = widget.onPressed != null && !widget.loading;
    final accent = widget.color ??
        (widget.variant == FinoraButtonVariant.destructive
            ? FinoraV8Colors.expense
            : FinoraV8Colors.brand);
    final filled = widget.variant != FinoraButtonVariant.secondary;
    final foreground =
        filled ? Colors.white : (dark ? FinoraV8Colors.darkText : accent);
    final visual = AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: FinoraV8Motion.instant,
      curve: FinoraV8Motion.fastCurve,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : .48,
        duration: FinoraV8Motion.fast,
        child: Container(
          height: _height,
          constraints: const BoxConstraints(
            minWidth: FinoraV8Metrics.minTouchTarget,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: widget.variant == FinoraButtonVariant.compact ? 14 : 20,
          ),
          decoration: BoxDecoration(
            color: filled
                ? accent
                : (dark
                    ? Colors.white.withValues(alpha: .08)
                    : Colors.white.withValues(alpha: .82)),
            borderRadius: BorderRadius.circular(FinoraV8Radius.pill),
            border: Border.all(
              color: filled
                  ? accent.withValues(alpha: .85)
                  : accent.withValues(alpha: .32),
            ),
            boxShadow: filled && enabled
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: .22),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
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
    );

    final target = SizedBox(
      height: widget.variant == FinoraButtonVariant.compact
          ? FinoraV8Metrics.minTouchTarget
          : _height,
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox.square(
      dimension: FinoraV8Metrics.minTouchTarget,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        style: IconButton.styleFrom(
          fixedSize: const Size.square(FinoraV8Metrics.iconButton),
          backgroundColor: filled
              ? color
              : (dark
                  ? Colors.white.withValues(alpha: .08)
                  : Colors.white.withValues(alpha: .82)),
          foregroundColor:
              filled ? Colors.white : (dark ? FinoraV8Colors.darkText : color),
          shape: const CircleBorder(),
          side: filled
              ? BorderSide.none
              : BorderSide(color: color.withValues(alpha: .24)),
        ),
        icon: Icon(icon, size: 21),
      ),
    );
  }
}
