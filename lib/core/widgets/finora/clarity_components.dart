import 'dart:ui';
import 'package:flutter/material.dart';
import '../../utils/formatters.dart';
import '../premium_widgets.dart' show GlassCard;

/// Shared Frosted Neo-Glass surfaces for financial information.
/// Preserves the user-selected theme palette (scheme.surface) while giving it
/// authentic Apple VisionOS glassmorphism, Fresnel hairline rims, and diffuse depth.
class ClaritySurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? customColor;

  const ClaritySurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24.0,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) => GlassCard(
      padding: padding,
      radius: radius,
      customFillColor: customColor,
      child: child);
}

class ClarityAmount extends StatelessWidget {
  final num amount;
  final double size;
  final Color? color;
  final bool hidden;
  const ClarityAmount(
      {super.key,
      required this.amount,
      this.size = 30,
      this.color,
      this.hidden = false});

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          hidden ? '•••••• đ' : Formatters.formatCurrency(amount),
          maxLines: 1,
          style: TextStyle(
              fontSize: size,
              height: 1.25,
              fontWeight: FontWeight.w800,
              letterSpacing: -.6,
              color: color ?? Theme.of(context).colorScheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      );
}

class ClarityMetric extends StatelessWidget {
  final String label;
  final num amount;
  final Color color;
  final IconData icon;
  final bool hidden;
  const ClarityMetric(
      {super.key,
      required this.label,
      required this.amount,
      required this.color,
      required this.icon,
      this.hidden = false});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant))),
          ]),
          const SizedBox(height: 7),
          ClarityAmount(amount: amount, size: 17, color: color, hidden: hidden),
        ],
      );
}

class ClarityAddButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  const ClarityAddButton(
      {super.key, required this.onPressed, this.label = 'Thêm mới'});

  @override
  Widget build(BuildContext context) => IconButton.filled(
        onPressed: onPressed,
        tooltip: label,
        style: IconButton.styleFrom(
            minimumSize: const Size.square(48),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: const CircleBorder()),
        icon: const Icon(Icons.add_rounded, size: 24),
      );
}
