import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/theme_studio_controller.dart';
import 'finora_modal_scope.dart';

/// Neutral card surfaces follow the shared opacity/blur controls. Brand fills,
/// gradients and fully transparent layout containers retain their appearance.
class AdaptiveGlassSurface extends StatelessWidget {
  final Widget? child;
  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? padding, margin;
  final Decoration? decoration, foregroundDecoration;
  final Color? color;
  final double? width, height;
  final BoxConstraints? constraints;
  final Matrix4? transform;
  final AlignmentGeometry? transformAlignment;
  final Clip clipBehavior;
  const AdaptiveGlassSurface(
      {super.key,
      this.child,
      this.alignment,
      this.padding,
      this.margin,
      this.decoration,
      this.foregroundDecoration,
      this.color,
      this.width,
      this.height,
      this.constraints,
      this.transform,
      this.transformAlignment,
      this.clipBehavior = Clip.none});

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<ThemeStudioController?>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final insideModal = FinoraModalScope.isInsideModal(context);
    final box =
        decoration is BoxDecoration ? decoration as BoxDecoration : null;
    final base = box?.color ?? color;
    final neutral = base != null &&
        base.a > 0.01 &&
        box?.gradient == null &&
        ((base.r >= .90 && base.g >= .90 && base.b >= .90) ||
            (base.r < .30 && base.g < .30 && base.b < .30));
    final fill = studio != null && neutral
        ? (dark ? const Color(0xFF142238) : Colors.white)
            .withValues(alpha: insideModal ? 1.0 : studio.glassOpacity)
        : base;
    final effective = box != null && neutral && studio != null
        ? box.copyWith(color: fill)
        : decoration;
    Widget body = Container(
        alignment: alignment,
        padding: padding,
        decoration: effective,
        color: effective == null ? fill : null,
        foregroundDecoration: foregroundDecoration,
        width: width,
        height: height,
        constraints: constraints,
        clipBehavior: clipBehavior,
        child: child);
    final blur = insideModal ? 0.0 : (studio?.glassBlur ?? 0).clamp(0.0, 18.0);
    // Cheap glass by default: skip per-card BackdropFilter when card fill is
    // mostly opaque (>= 0.75) unless the user explicitly opted into
    // cardBackdropBlur. Preserves real blur when glassOpacity is dialed down
    // (< 0.75) or cardBackdropBlur is enabled. Never blur inside modals.
    final wantsRealBlur = !insideModal &&
        studio != null &&
        ((studio.cardBackdropBlur && studio.glassOpacity < 1.0) ||
            (studio.glassOpacity > 0.0 && studio.glassOpacity < 0.75));
    if (neutral && blur > 0 && wantsRealBlur) {
      final radius = box?.borderRadius?.resolve(Directionality.of(context)) ??
          BorderRadius.zero;
      final filtered = BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: body);
      body = box?.shape == BoxShape.circle
          ? ClipOval(child: filtered)
          : ClipRRect(borderRadius: radius, child: filtered);
    }
    return Container(
        margin: margin,
        transform: transform,
        transformAlignment: transformAlignment,
        child: body);
  }
}
