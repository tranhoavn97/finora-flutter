import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/date_filter.dart';
import 'period_picker.dart';
import '../design_system/app_colors.dart';

class FinoraDateQuickBar extends StatelessWidget {
  final PeriodSelection selected;
  final ValueChanged<PeriodSelection> onSelected;

  const FinoraDateQuickBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final chips = [
      (DateFilterOption.allTime, 'Tất cả'),
      (DateFilterOption.today, 'Hôm nay'),
      (DateFilterOption.thisWeek, 'Tuần này'),
      (DateFilterOption.thisMonth, 'Tháng này'),
      (DateFilterOption.thisYear, 'Năm nay'),
    ];

    final isCustom = selected.option == DateFilterOption.customDate ||
        selected.option == DateFilterOption.customMonth ||
        selected.option == DateFilterOption.yesterday ||
        selected.option == DateFilterOption.lastMonth;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (opt, label) in chips) ...[
            _QuickChip(
              label: label,
              isSelected: !isCustom && selected.option == opt,
              isDark: isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                onSelected(PeriodSelection(opt));
              },
            ),
            const SizedBox(width: 8),
          ],
          _QuickChip(
            label: isCustom ? selected.label : '📅 Lịch...',
            isSelected: isCustom,
            isDark: isDark,
            isCalendar: true,
            onTap: () async {
              HapticFeedback.selectionClick();
              final picked = await PeriodPicker.show(context, initial: selected);
              if (picked != null) {
                onSelected(picked);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final bool isCalendar;
  final VoidCallback onTap;

  const _QuickChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    this.isCalendar = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = AppColors.accent;
    final inactiveBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final borderColor = isSelected
        ? AppColors.accent
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));
    final textColor = isSelected
        ? Colors.white
        : (isDark ? AppColors.darkTextPrimary : const Color(0xFF334155));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
