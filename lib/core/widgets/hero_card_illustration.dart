import 'package:flutter/material.dart';

/// HeroCardIllustration - Placeholder kept for backward compatibility.
/// 3D illustrations have been removed for clean flat fintech aesthetic.
class HeroCardIllustration extends StatelessWidget {
  final String imagePath;
  final double size;
  final Color? glowColor;
  final double opacity;
  final Offset offset;
  final double angle;

  const HeroCardIllustration({
    super.key,
    required this.imagePath,
    this.size = 110,
    this.glowColor,
    this.opacity = 0.88,
    this.offset = Offset.zero,
    this.angle = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
