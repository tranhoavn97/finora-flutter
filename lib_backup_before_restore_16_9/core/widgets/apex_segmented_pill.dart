import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Apex Segmented Pill Switcher (Inspired by modern Mobile Banking UI)
/// Features a smooth pill track and a floating white/dark active pill capsule.
class ApexSegmentedPill extends StatelessWidget {
  final int selectedIndex;
  final List<String> tabs;
  final ValueChanged<int> onTabChanged;
  final EdgeInsetsGeometry padding;

  const ApexSegmentedPill({
    super.key,
    required this.selectedIndex,
    required this.tabs,
    required this.onTabChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark ? const Color(0xFF1E2633) : const Color(0xFFF1F3F7);
    final activeColor = isDark ? const Color(0xFF2C3647) : Colors.white;
    final activeTextColor = isDark ? Colors.white : const Color(0xFF111827);
    final inactiveTextColor = isDark ? const Color(0xFF8B98A9) : const Color(0xFF6B7280);

    return Padding(
      padding: padding,
      child: Container(
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabCount = tabs.length;
            final tabWidth = (constraints.maxWidth) / tabCount;

            return Stack(
              children: [
                // Animated sliding active pill
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  left: selectedIndex * tabWidth,
                  top: 0,
                  bottom: 0,
                  width: tabWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.35)
                              : const Color(0xFF111827).withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                // Text labels
                Row(
                  children: List.generate(tabCount, (index) {
                    final isSelected = selectedIndex == index;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (selectedIndex != index) {
                            HapticFeedback.lightImpact();
                            onTabChanged(index);
                          }
                        },
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              letterSpacing: 0.6,
                              color: isSelected ? activeTextColor : inactiveTextColor,
                            ),
                            child: Text(tabs[index]),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
