import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../utils/date_filter.dart';
import '../../state/theme_studio_controller.dart';
import 'finora_date_picker_sheet.dart';

class DateFilterModalResult {
  final DateFilterOption option;
  final DateTime? customDate;
  final DateTimeRange? customRange;

  const DateFilterModalResult({
    required this.option,
    this.customDate,
    this.customRange,
  });
}

Future<DateFilterModalResult?> showDateFilterModal(
  BuildContext context, {
  required DateFilterOption currentOption,
  DateTime? currentCustomDate,
  DateTimeRange? currentCustomRange,
  bool showAllTime = true,
}) {
  return showModalBottomSheet<DateFilterModalResult>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => DateFilterModalSheet(
      currentOption: currentOption,
      currentCustomDate: currentCustomDate,
      currentCustomRange: currentCustomRange,
      showAllTime: showAllTime,
    ),
  );
}

class DateFilterModalSheet extends StatelessWidget {
  final DateFilterOption currentOption;
  final DateTime? currentCustomDate;
  final DateTimeRange? currentCustomRange;
  final bool showAllTime;

  const DateFilterModalSheet({
    super.key,
    required this.currentOption,
    this.currentCustomDate,
    this.currentCustomRange,
    this.showAllTime = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studio = context.watch<ThemeStudioController?>();
    final primary = studio?.resolvedPrimary ?? const Color(0xFF0F6E56);
    final now = DateTime.now();

    final quickPills = <(DateFilterOption, String)>[
      (DateFilterOption.today, 'Hôm nay'),
      (DateFilterOption.yesterday, 'Hôm qua'),
      (DateFilterOption.thisWeek, 'Tuần này'),
      (DateFilterOption.thisMonth, 'Tháng này'),
      (DateFilterOption.lastMonth, 'Tháng trước'),
      (DateFilterOption.thisYear, 'Năm nay'),
      if (showAllTime) (DateFilterOption.allTime, 'Tất cả'),
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Chọn mốc thời gian',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Single-line quick stadium pills
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: quickPills.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final (opt, label) = quickPills[i];
                    final selected = currentOption == opt &&
                        currentCustomDate == null &&
                        currentCustomRange == null;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.pop(
                          context,
                          DateFilterModalResult(option: opt),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? primary
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: selected
                                ? primary
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.10)
                                    : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : (isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF334155)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              _buildOptionTile(
                context,
                title: 'Hôm nay',
                subtitle: 'Số liệu thu chi trong ngày',
                icon: Icons.today_rounded,
                color: const Color(0xFF0D9488),
                isSelected: currentOption == DateFilterOption.today &&
                    currentCustomDate == null,
                isDark: isDark,
                onTap: () => Navigator.pop(
                  context,
                  const DateFilterModalResult(option: DateFilterOption.today),
                ),
              ),
              _buildOptionTile(
                context,
                title: 'Tuần này',
                subtitle: 'Tính từ đầu tuần đến nay',
                icon: Icons.date_range_rounded,
                color: const Color(0xFF0284C7),
                isSelected: currentOption == DateFilterOption.thisWeek &&
                    currentCustomDate == null,
                isDark: isDark,
                onTap: () => Navigator.pop(
                  context,
                  const DateFilterModalResult(
                    option: DateFilterOption.thisWeek,
                  ),
                ),
              ),
              _buildOptionTile(
                context,
                title: 'Tháng này',
                subtitle: 'Tháng hiện tại (${now.month}/${now.year})',
                icon: Icons.calendar_month_rounded,
                color: const Color(0xFF10B981),
                isSelected: currentOption == DateFilterOption.thisMonth &&
                    currentCustomDate == null,
                isDark: isDark,
                onTap: () => Navigator.pop(
                  context,
                  const DateFilterModalResult(
                    option: DateFilterOption.thisMonth,
                  ),
                ),
              ),
              _buildOptionTile(
                context,
                title: 'Tháng trước',
                subtitle: 'Số liệu tháng vừa qua',
                icon: Icons.history_rounded,
                color: const Color(0xFF6366F1),
                isSelected: currentOption == DateFilterOption.lastMonth &&
                    currentCustomDate == null,
                isDark: isDark,
                onTap: () => Navigator.pop(
                  context,
                  const DateFilterModalResult(
                    option: DateFilterOption.lastMonth,
                  ),
                ),
              ),
              _buildOptionTile(
                context,
                title: 'Năm nay',
                subtitle: 'Tổng hợp cả năm ${now.year}',
                icon: Icons.calendar_today_rounded,
                color: const Color(0xFFF59E0B),
                isSelected: currentOption == DateFilterOption.thisYear &&
                    currentCustomDate == null,
                isDark: isDark,
                onTap: () => Navigator.pop(
                  context,
                  const DateFilterModalResult(
                    option: DateFilterOption.thisYear,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildSolidStadiumButton(
                      label: currentCustomDate != null
                          ? 'Ngày: ${DateFormat('dd/MM').format(currentCustomDate!)}'
                          : 'Chọn 1 ngày...',
                      icon: Icons.event_rounded,
                      color: const Color(0xFF0D9488),
                      isSelected: currentOption == DateFilterOption.customDate,
                      isDark: isDark,
                      onTap: () async {
                        final picked =
                            await FinoraDatePickerSheet.showSingleDate(
                          context,
                          initialDate: currentCustomDate ?? now,
                        );
                        if (picked != null && context.mounted) {
                          Navigator.pop(
                            context,
                            DateFilterModalResult(
                              option: DateFilterOption.customDate,
                              customDate: picked,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSolidStadiumButton(
                      label: currentCustomRange != null
                          ? '${DateFormat('dd/MM').format(currentCustomRange!.start)}-${DateFormat('dd/MM').format(currentCustomRange!.end)}'
                          : 'Khoảng ngày...',
                      icon: Icons.date_range_rounded,
                      color: const Color(0xFF2563EB),
                      isSelected: currentOption == DateFilterOption.customRange,
                      isDark: isDark,
                      onTap: () async {
                        final range = await FinoraDatePickerSheet.showDateRange(
                          context,
                          initialStartDate: currentCustomRange?.start,
                          initialEndDate: currentCustomRange?.end,
                        );
                        if (range != null && context.mounted) {
                          Navigator.pop(
                            context,
                            DateFilterModalResult(
                              option: DateFilterOption.customRange,
                              customRange: range,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.20 : 0.10)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.20 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSolidStadiumButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isSelected ? 0.35 : 0.20),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 15),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
