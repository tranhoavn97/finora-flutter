import 'package:flutter/material.dart';
import '../widgets/premium_widgets.dart';

/// App-wide glassmorphism backdrop wrapper.
/// Upgraded to delegate rendering to the new premium GradientBackground 
/// and FloatingBubblesBackground.
class GlassBackground extends StatelessWidget {
  final Widget child;
  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: FloatingBubblesBackground(
        child: child,
      ),
    );
  }
}
