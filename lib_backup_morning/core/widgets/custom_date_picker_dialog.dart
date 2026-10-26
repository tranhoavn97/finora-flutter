import 'package:flutter/material.dart';

import '../design_system/app_colors.dart';
import '../design_system/app_radius.dart';
import '../design_system/app_spacing.dart';

class CustomDatePickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateSelected;

  const CustomDatePickerSheet({
    super.key,
    required this.initialDate,
    required this.onDateSelected,
  });

  static Future<DateTime?> show(BuildContext context,
      {required DateTime initialDate}) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CustomDatePickerSheet(
        initialDate: initialDate,
        onDateSelected: (d) => Navigator.pop(ctx, d),
      ),
    );
  }

  @override
  State<CustomDatePickerSheet> createState() => _CustomDatePickerSheetState();
}

class _CustomDatePickerSheetState extends State<CustomDatePickerSheet> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayedMonth =
        DateTime(widget.initialDate.year, widget.initialDate.month, 1);
  }

  void _selectToday() {
    final now = DateTime.now();
    setState(() {
      _selectedDate = now;
      _displayedMonth = DateTime(now.year, now.month, 1);
    });
  }

  void _selectYesterday() {
    final yest = DateTime.now().subtract(const Duration(days: 1));
    setState(() {
      _selectedDate = yest;
      _displayedMonth = DateTime(yest.year, yest.month, 1);
    });
  }

  void _selectStartOfMonth() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    setState(() {
      _selectedDate = firstDay;
      _displayedMonth = firstDay;
    });
  }

  void _prevMonth() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  void _selectMonth(int month) {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, month, 1);
    });
  }

  void _selectYear(int year) {
    setState(() {
      _displayedMonth = DateTime(year, _displayedMonth.month, 1);
    });
  }

  String _getWeekdayName(DateTime date) {
    final wd = date.weekday;
    switch (wd) {
      case DateTime.monday:
        return 'Thứ Hai';
      case DateTime.tuesday:
        return 'Thứ Ba';
      case DateTime.wednesday:
        return 'Thứ Tư';
      case DateTime.thursday:
        return 'Thứ Năm';
      case DateTime.friday:
        return 'Thứ Sáu';
      case DateTime.saturday:
        return 'Thứ Bảy';
      case DateTime.sunday:
        return 'Chủ Nhật';
      default:
        return '';
    }
  }

  String _getDateSubtitle(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Hôm nay';
    }
    final yest = now.subtract(const Duration(days: 1));
    if (date.year == yest.year &&
        date.month == yest.month &&
        date.day == yest.day) {
      return 'Hôm qua';
    }
    return '';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final sub = _getDateSubtitle(_selectedDate);

    // Calculate days in month
    final firstDayOfMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday
    final leadingEmptyCount = startWeekday - 1;

    final now = DateTime.now();
    final isTodaySelected = _isSameDay(_selectedDate, now);
    final isYesterdaySelected =
        _isSameDay(_selectedDate, now.subtract(const Duration(days: 1)));
    final isStartOfMonthSelected =
        _isSameDay(_selectedDate, DateTime(now.year, now.month, 1));

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Top Selected Date Badge
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.heroPurpleGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${_selectedDate.day}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getWeekdayName(_selectedDate)}, ${_selectedDate.day} tháng ${_selectedDate.month}, ${_selectedDate.year}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        if (sub.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            sub,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Quick Shortcuts Row
              Row(
                children: [
                  Expanded(
                    child: _buildQuickButton(
                        'Hôm nay', isTodaySelected, _selectToday, isDark),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickButton('Hôm qua', isYesterdaySelected,
                        _selectYesterday, isDark),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickButton('Đầu tháng',
                        isStartOfMonthSelected, _selectStartOfMonth, isDark),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Month and year navigator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: _prevMonth,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    Flexible(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPickerMenu<int>(
                            value: _displayedMonth.month,
                            values: List.generate(12, (index) => index + 1),
                            label: (value) => 'Tháng $value',
                            onChanged: _selectMonth,
                            isDark: isDark,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _buildPickerMenu<int>(
                            value: _displayedMonth.year,
                            values: List.generate(
                              21,
                              (index) => DateTime.now().year - 10 + index,
                            ),
                            label: (value) => '$value',
                            onChanged: _selectYear,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: _nextMonth,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Weekday Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWeekdayHeader('T2', isDark),
                  _buildWeekdayHeader('T3', isDark),
                  _buildWeekdayHeader('T4', isDark),
                  _buildWeekdayHeader('T5', isDark),
                  _buildWeekdayHeader('T6', isDark),
                  _buildWeekdayHeader('T7', isDark),
                  _buildWeekdayHeader('CN', isDark, isSunday: true),
                ],
              ),
              const SizedBox(height: 8),

              // Calendar Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.1,
                ),
                itemCount: leadingEmptyCount + daysInMonth,
                itemBuilder: (context, index) {
                  if (index < leadingEmptyCount) {
                    return const SizedBox();
                  }
                  final dayNumber = index - leadingEmptyCount + 1;
                  final cellDate = DateTime(
                      _displayedMonth.year, _displayedMonth.month, dayNumber);
                  final isSelected = _isSameDay(cellDate, _selectedDate);
                  final isSunday = cellDate.weekday == DateTime.sunday;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = cellDate;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isSelected ? AppColors.primary : Colors.transparent,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w900 : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : isSunday
                                    ? const Color(0xFFEF4444)
                                    : (isDark
                                        ? Colors.white
                                        : const Color(0xFF1E293B)),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Footer Actions
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          'Hủy',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppColors.heroPurpleGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.30),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => widget.onDateSelected(_selectedDate),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded,
                                color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Xác nhận ngày',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildPickerMenu<T>({
    required T value,
    required List<T> values,
    required String Function(T) label,
    required ValueChanged<T> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? .18 : .09),
        borderRadius: AppRadius.radiusSM,
        border: Border.all(color: AppColors.primary.withValues(alpha: .24)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          borderRadius: AppRadius.card,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.primary,
          ),
          style: TextStyle(
            color:
                isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.w800,
          ),
          dropdownColor:
              isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
          items: values
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(label(item)),
                ),
              )
              .toList(),
          onChanged: (item) {
            if (item != null) onChanged(item);
          },
        ),
      ),
    );
  }

  Widget _buildQuickButton(
      String text, bool active, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active
                ? AppColors.primary
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              color: active
                  ? Colors.white
                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekdayHeader(String text, bool isDark,
      {bool isSunday = false}) {
    return SizedBox(
      width: 32,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isSunday
                ? const Color(0xFFEF4444)
                : (isDark ? Colors.white54 : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }
}
