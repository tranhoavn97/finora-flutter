import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../utils/date_filter.dart';
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
  bool showAllTime = false,
}) {
  HapticFeedback.mediumImpact();
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
    this.showAllTime = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.12),
              blurRadius: 28,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.paddingOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Center drag handle
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.22)
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 2. Header: Title + Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Chọn mốc thời gian',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF263342) : const Color(0xFFEDF3FA),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Option 1: Hôm nay
            _buildOptionCard(
              context: context,
              title: 'Hôm nay',
              subtitle: 'Số liệu thu chi trong ngày',
              icon: Icons.calendar_today_rounded,
              iconColor: const Color(0xFF2563EB),
              iconBgColor: isDark
                  ? const Color(0xFF1E3A8A).withValues(alpha: 0.40)
                  : const Color(0xFFDBEAFE),
              isSelected: currentOption == DateFilterOption.today &&
                  currentCustomDate == null &&
                  currentCustomRange == null,
              isDark: isDark,
              onTap: () => Navigator.pop(
                context,
                const DateFilterModalResult(option: DateFilterOption.today),
              ),
            ),

            // Option 2: Hôm qua
            _buildOptionCard(
              context: context,
              title: 'Hôm qua',
              subtitle: 'Giao dịch ngày hôm qua',
              icon: Icons.access_time_filled_rounded,
              iconColor: const Color(0xFF0284C7),
              iconBgColor: isDark
                  ? const Color(0xFF0369A1).withValues(alpha: 0.40)
                  : const Color(0xFFE0F2FE),
              isSelected: currentOption == DateFilterOption.yesterday &&
                  currentCustomDate == null &&
                  currentCustomRange == null,
              isDark: isDark,
              onTap: () => Navigator.pop(
                context,
                const DateFilterModalResult(option: DateFilterOption.yesterday),
              ),
            ),

            // Option 3: Tuần này
            _buildOptionCard(
              context: context,
              title: 'Tuần này',
              subtitle: 'Tính từ đầu tuần đến nay',
              icon: Icons.date_range_rounded,
              iconColor: const Color(0xFF0EA5E9),
              iconBgColor: isDark
                  ? const Color(0xFF0369A1).withValues(alpha: 0.40)
                  : const Color(0xFFE0F2FE),
              isSelected: currentOption == DateFilterOption.thisWeek &&
                  currentCustomDate == null &&
                  currentCustomRange == null,
              isDark: isDark,
              onTap: () => Navigator.pop(
                context,
                const DateFilterModalResult(option: DateFilterOption.thisWeek),
              ),
            ),

            // Option 4: Tháng này
            _buildOptionCard(
              context: context,
              title: 'Tháng này',
              subtitle: 'Tháng hiện tại (${now.month}/${now.year})',
              icon: Icons.calendar_month_rounded,
              iconColor: const Color(0xFF10B981),
              iconBgColor: isDark
                  ? const Color(0xFF065F46).withValues(alpha: 0.40)
                  : const Color(0xFFD1FAE5),
              isSelected: currentOption == DateFilterOption.thisMonth &&
                  currentCustomDate == null &&
                  currentCustomRange == null,
              isDark: isDark,
              onTap: () => Navigator.pop(
                context,
                const DateFilterModalResult(option: DateFilterOption.thisMonth),
              ),
            ),

            // Option 5: Năm nay
            _buildOptionCard(
              context: context,
              title: 'Năm nay',
              subtitle: 'Tổng hợp cả năm ${now.year}',
              icon: Icons.calendar_today_rounded,
              iconColor: const Color(0xFFF59E0B),
              iconBgColor: isDark
                  ? const Color(0xFF78350F).withValues(alpha: 0.40)
                  : const Color(0xFFFEF3C7),
              isSelected: currentOption == DateFilterOption.thisYear &&
                  currentCustomDate == null &&
                  currentCustomRange == null,
              isDark: isDark,
              onTap: () => Navigator.pop(
                context,
                const DateFilterModalResult(option: DateFilterOption.thisYear),
              ),
            ),

            // Option 6: Chọn ngày cụ thể...
            _buildOptionCard(
              context: context,
              title: 'Chọn ngày cụ thể...',
              subtitle: currentCustomDate != null
                  ? 'Đang chọn: ${DateFormat('dd/MM/yyyy').format(currentCustomDate!)}'
                  : 'Xem số liệu của một ngày bất kỳ',
              icon: Icons.edit_calendar_rounded,
              iconColor: const Color(0xFF005FEA),
              iconBgColor: isDark
                  ? const Color(0xFF1E3A8A).withValues(alpha: 0.40)
                  : const Color(0xFFDBEAFE),
              isSelected: currentOption == DateFilterOption.customDate ||
                  currentCustomDate != null,
              isDark: isDark,
              onTap: () async {
                final picked = await FinoraDatePickerSheet.showSingleDate(
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

            if (showAllTime) ...[
              _buildOptionCard(
                context: context,
                title: 'Tất cả thời gian',
                subtitle: 'Xem toàn bộ giao dịch từ trước đến nay',
                icon: Icons.all_inclusive_rounded,
                iconColor: const Color(0xFF64748B),
                iconBgColor: isDark
                    ? const Color(0xFF334155).withValues(alpha: 0.40)
                    : const Color(0xFFF1F5F9),
                isSelected: currentOption == DateFilterOption.allTime &&
                    currentCustomDate == null,
                isDark: isDark,
                onTap: () => Navigator.pop(
                  context,
                  const DateFilterModalResult(option: DateFilterOption.allTime),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    const activeBorderColor = Color(0xFF2563EB);
    final activeBgColor = isDark
        ? const Color(0xFF1E3A8A).withValues(alpha: 0.22)
        : const Color(0xFFF0F6FF);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? activeBgColor
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? activeBorderColor
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
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
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2563EB),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
