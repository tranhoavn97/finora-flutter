import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design_system/app_colors.dart';
import '../design_system/app_radius.dart';
import '../design_system/app_spacing.dart';
import '../../state/theme_studio_controller.dart';
import 'glass_widgets.dart';

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
    final studio = context.watch<ThemeStudioController?>();
    final primary = studio?.resolvedPrimary ?? AppColors.primary;
    final List<Color> heroGradient = studio?.currentPaletteMeta.heroGradient ?? AppColors.heroPurpleGradient.colors;
    final List<Color> btnGradient = studio?.resolvedButtonGradient ?? heroGradient;
    final btnPrimary = studio?.resolvedButtonPrimary ?? primary;
    final btnRadius = studio?.getButtonRadius() ?? 16.0;
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

    return GlassBottomSheet(
      radius: 28,
      showHandle: true,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Selected Date Badge
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: heroGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.35),
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
                        'Hôm nay', isTodaySelected, _selectToday, isDark, primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickButton('Hôm qua', isYesterdaySelected,
                        _selectYesterday, isDark, primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickButton('Đầu tháng',
                        isStartOfMonthSelected, _selectStartOfMonth, isDark, primary),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Month and year navigator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.035),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.black.withValues(alpha: 0.07),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: _prevMonth,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                            primary: primary,
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
                            primary: primary,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: _nextMonth,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                            isSelected ? primary : Colors.transparent,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color:
                                      primary.withValues(alpha: 0.4),
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
                            fontSize: 14.5,
                            fontWeight:
                                isSelected ? FontWeight.w900 : FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : isSunday
                                    ? const Color(0xFFEF4444)
                                    : (isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A)),
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
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.035),
                          shape: const StadiumBorder(),
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : Colors.black.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Text(
                          'Hủy',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
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
                        gradient: LinearGradient(
                          colors: btnGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(btnRadius),
                        boxShadow: [
                          BoxShadow(
                            color: btnPrimary.withValues(alpha: 0.30),
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
                          shape: const StadiumBorder(),
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
      );
  }

  Widget _buildPickerMenu<T>({
    required T value,
    required List<T> values,
    required String Function(T) label,
    required ValueChanged<T> onChanged,
    required bool isDark,
    required Color primary,
  }) {
    return Container(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? .18 : .09),
        borderRadius: AppRadius.radiusSM,
        border: Border.all(color: primary.withValues(alpha: .24)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          borderRadius: AppRadius.card,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: primary,
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
      String text, bool active, VoidCallback onTap, bool isDark, Color primary) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? primary
              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.035)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active
                ? primary
                : (isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.07)),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w800 : FontWeight.w700,
              color: active
                  ? Colors.white
                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
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
                : (isDark ? Colors.white70 : const Color(0xFF334155)),
          ),
        ),
      ),
    );
  }
}
