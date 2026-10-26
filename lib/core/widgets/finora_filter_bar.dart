import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../state/theme_studio_controller.dart';

/// Model đại diện cho một mục bộ lọc trong [FinoraFilterBar]
class FinoraFilterItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final int? count;

  const FinoraFilterItem({
    required this.value,
    required this.label,
    this.icon,
    this.count,
  });
}

/// [FinoraFilterBar]: Thanh bộ lọc chuẩn hóa toàn diện cho FINORA.
/// - Luôn luôn nằm gọn trên đúng 1 hàng cuộn ngang mượt mà (BouncingScrollPhysics).
/// - Chiều cao cố định chính xác 38.0 px trên mọi màn hình.
/// - Màu sắc, góc bo và phong cách đồng nhất tuyệt đối theo ThemeStudioController.
class FinoraFilterBar<T> extends StatelessWidget {
  final List<FinoraFilterItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry padding;
  final double height;

  const FinoraFilterBar({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.height = 38.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studio = Provider.of<ThemeStudioController?>(context);
    final activeColor = studio?.resolvedButtonPrimary ??
        (isDark ? const Color(0xFF007AFF) : const Color(0xFF005FEA));
    final btnRadius = (studio?.buttonCornerRadius ?? 100.0).clamp(8.0, 100.0);

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: padding,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = item.value == selectedValue;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (isSelected) return;
                HapticFeedback.selectionClick();
                onSelected(item.value);
              },
              borderRadius: BorderRadius.circular(btnRadius),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                height: height,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(btnRadius),
                  border: Border.all(
                    color: isSelected
                        ? activeColor.withValues(alpha: 0.8)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.08)),
                    width: isSelected ? 1.4 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (item.icon != null) ...[
                      Icon(
                        item.icon,
                        size: 15,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                        letterSpacing: 0.1,
                      ),
                    ),
                    if (item.count != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.black.withValues(alpha: 0.08)),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${item.count}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
