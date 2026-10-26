import 'package:flutter/material.dart';

/// Clean Material 3 solid background widget, replacing legacy fluid mesh blur.
class FluidMeshBackground extends StatelessWidget {
  final Widget child;
  final bool animate;
  final double speedMultiplier;
  final Color baseColor;

  const FluidMeshBackground({
    super.key,
    required this.child,
    this.animate = true,
    this.speedMultiplier = 1.0,
    this.baseColor = const Color(0xFF040714),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: baseColor,
      child: child,
    );
  }
}
