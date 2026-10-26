import 'package:flutter/material.dart';

import '../../state/theme_studio_controller.dart';

/// Progress treatments shared by the real goal and budget screens.
class StudioGoalProgress extends StatelessWidget {
  const StudioGoalProgress({
    super.key,
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.style,
    this.height = 6,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final AppGoalStyle style;
  final double height;

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0);
    switch (style) {
      case AppGoalStyle.treasureChest:
        return ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: value,
            minHeight: height,
            backgroundColor: trackColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
      case AppGoalStyle.growingTree:
        return Row(
          children: List.generate(8, (index) {
            final active = value * 8 >= index + 0.5;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: height + 5 + index * 0.7,
                decoration: BoxDecoration(
                  color: active ? color : trackColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        );
      case AppGoalStyle.batteryCharge:
        return Row(
          children: [
            Expanded(
              child: Container(
                height: height + 12,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  border: Border.all(color: color, width: 1.5),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: FractionallySizedBox(
                  widthFactor: value,
                  alignment: Alignment.centerLeft,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            Container(width: 3, height: height + 4, color: color),
          ],
        );
    }
  }
}

class StudioBudgetProgress extends StatelessWidget {
  const StudioBudgetProgress({
    super.key,
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.style,
    this.height = 6,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final AppBudgetStyle style;
  final double height;

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0);
    switch (style) {
      case AppBudgetStyle.liquidBar:
        return ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: value,
            minHeight: height,
            backgroundColor: trackColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
      case AppBudgetStyle.speedometerGauge:
        return SizedBox(
          height: 14,
          child: LayoutBuilder(builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: trackColor,
                  ),
                ),
                Container(
                  width: constraints.maxWidth * value,
                  height: 14,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: color,
                  ),
                ),
                for (var index = 1; index < 5; index++)
                  Positioned(
                    left: constraints.maxWidth * index / 5,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 1, color: Colors.white54),
                  ),
              ],
            );
          }),
        );
      case AppBudgetStyle.minimalCapsule:
        return Row(
          children: List.generate(10, (index) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: height + 3,
                decoration: BoxDecoration(
                  color: value * 10 >= index + 0.5 ? color : trackColor,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            );
          }),
        );
    }
  }
}
