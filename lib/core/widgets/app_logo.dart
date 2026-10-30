import 'package:flutter/material.dart';
import 'fresh_design.dart';

class FinoraLogo extends StatelessWidget {
  final double size;
  final Color? color;
  const FinoraLogo({super.key, this.size = 64, this.color});
  @override
  Widget build(BuildContext context) => FioAppIcon(size: size);
}

class FinoraBrandLogo extends StatelessWidget {
  final double width, height;
  final Color? color;
  const FinoraBrandLogo(
      {super.key, this.width = 192, this.height = 60, this.color});
  @override
  Widget build(BuildContext context) => SizedBox(
      width: width,
      height: height,
      child: FittedBox(
          fit: BoxFit.contain,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            FioAppIcon(size: height * 0.8),
            SizedBox(width: height * 0.18),
            Text('finora',
                style: TextStyle(
                    fontSize: height * 0.62,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.8,
                    color: color ?? Theme.of(context).colorScheme.onSurface)),
          ])));
}
