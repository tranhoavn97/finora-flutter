import 'package:flutter/material.dart';

/// A spring-physics morphing icon widget inspired by Morphicons (morphicons.com).
/// Provides a lively tactile spring transition when changing between icons,
/// utilizing rotational drift and bouncy scale interpolation.
class MorphIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final Duration duration;
  final Curve curve;
  final bool enableHaptic;
  final String? semanticLabel;

  const MorphIcon({
    super.key,
    required this.icon,
    this.size = 20.0,
    this.color,
    this.duration = const Duration(milliseconds: 320),
    this.curve = Curves.easeOutBack,
    this.enableHaptic = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        final rotate = Tween<double>(begin: 0.12, end: 0.0).animate(
          CurvedAnimation(parent: animation, curve: curve),
        );
        final scale = Tween<double>(begin: 0.65, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: curve),
        );

        return RotationTransition(
          turns: rotate,
          child: ScaleTransition(
            scale: scale,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );
      },
      child: Icon(
        icon,
        key: ValueKey<int>(icon.codePoint),
        size: size,
        color: color,
        semanticLabel: semanticLabel,
      ),
    );
  }
}
