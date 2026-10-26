import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../state/theme_studio_controller.dart';

class FinoraDatePickerSheet extends StatefulWidget {
  final bool isRangeMode;
  final bool allowModeToggle;
  final DateTime? initialDate;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final ValueChanged<DateTime>? onDateSelected;
  final void Function(DateTime start, DateTime end)? onRangeSelected;

  const FinoraDatePickerSheet({
    super.key,
    this.isRangeMode = false,
    this.allowModeToggle = true,
    this.initialDate,
    this.initialStartDate,
    this.initialEndDate,
    this.onDateSelected,
    this.onRangeSelected,
  });

  /// Show Single Date Picker Modal
  static Future<DateTime?> showSingleDate(
    BuildContext context, {
    DateTime? initialDate,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FinoraDatePickerSheet(
        isRangeMode: false,
        allowModeToggle: false,
        initialDate: initialDate ?? DateTime.now(),
        onDateSelected: (d) => Navigator.pop(ctx, d),
      ),
    );
  }

  /// Show Date Range Picker Modal
  static Future<DateTimeRange?> showDateRange(
    BuildContext context, {
    DateTime? initialStartDate,
    DateTime? initialEndDate,
  }) {
    return showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FinoraDatePickerSheet(
        isRangeMode: true,
        allowModeToggle: false,
        initialStartDate: initialStartDate ??
            DateTime.now().subtract(const Duration(days: 7)),
        initialEndDate: initialEndDate ?? DateTime.now(),
        onRangeSelected: (start, end) =>
            Navigator.pop(ctx, DateTimeRange(start: start, end: end)),
      ),
    );
  }

  /// Show Combined Modal (allows switching between Single Date and Date Range)
  static Future<dynamic> show(
    BuildContext context, {
    bool initialIsRange = false,
    DateTime? initialDate,
    DateTime? initialStartDate,
    DateTime? initialEndDate,
  }) {
    return showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FinoraDatePickerSheet(
        isRangeMode: initialIsRange,
        allowModeToggle: true,
        initialDate: initialDate ?? DateTime.now(),
        initialStartDate: initialStartDate ??
            DateTime.now().subtract(const Duration(days: 7)),
        initialEndDate: initialEndDate ?? DateTime.now(),
        onDateSelected: (d) => Navigator.pop(ctx, d),
        onRangeSelected: (start, end) =>
            Navigator.pop(ctx, DateTimeRange(start: start, end: end)),
      ),
    );
  }

  @override
  State<FinoraDatePickerSheet> createState() => _FinoraDatePickerSheetState();
}

class _FinoraDatePickerSheetState extends State<FinoraDatePickerSheet> {
  late bool _isRangeMode;
  late DateTime _selectedDate;
  DateTime? _startDate;
  DateTime? _endDate;
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _isRangeMode = widget.isRangeMode;
    final now = DateTime.now();
    _selectedDate = widget.initialDate ?? now;
    _startDate =
        widget.initialStartDate ?? now.subtract(const Duration(days: 7));
    _endDate = widget.initialEndDate ?? now;

    final baseDate = _isRangeMode ? (_startDate ?? now) : _selectedDate;
    _displayedMonth = DateTime(baseDate.year, baseDate.month, 1);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _prevMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  void _handleDayTap(DateTime date) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_isRangeMode) {
        _selectedDate = date;
      } else {
        if (_startDate == null || (_startDate != null && _endDate != null)) {
          _startDate = date;
          _endDate = null;
        } else if (_startDate != null && _endDate == null) {
          if (date.isBefore(_startDate!)) {
            _endDate = _startDate;
            _startDate = date;
          } else {
            _endDate = date;
          }
        }
      }
    });
  }

  void _selectPreset(String preset) {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    setState(() {
      if (!_isRangeMode) {
        if (preset == 'today') {
          _selectedDate = today;
          _displayedMonth = DateTime(today.year, today.month, 1);
        } else if (preset == 'yesterday') {
          final yest = today.subtract(const Duration(days: 1));
          _selectedDate = yest;
          _displayedMonth = DateTime(yest.year, yest.month, 1);
        } else if (preset == 'monthStart') {
          final first = DateTime(today.year, today.month, 1);
          _selectedDate = first;
          _displayedMonth = first;
        }
      } else {
        if (preset == 'today') {
          _startDate = today;
          _endDate = today;
          _displayedMonth = DateTime(today.year, today.month, 1);
        } else if (preset == '7days') {
          _startDate = today.subtract(const Duration(days: 6));
          _endDate = today;
          _displayedMonth = DateTime(today.year, today.month, 1);
        } else if (preset == 'thisMonth') {
          _startDate = DateTime(today.year, today.month, 1);
          _endDate = today;
          _displayedMonth = DateTime(today.year, today.month, 1);
        } else if (preset == 'lastMonth') {
          final lastMonth = DateTime(today.year, today.month - 1, 1);
          final lastMonthEnd = DateTime(today.year, today.month, 0);
          _startDate = lastMonth;
          _endDate = lastMonthEnd;
          _displayedMonth = lastMonth;
        }
      }
    });
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studio = context.watch<ThemeStudioController?>();
    final brandPrimary = studio?.resolvedPrimary ?? const Color(0xFF005FEA);
    final btnGradient = studio?.resolvedButtonGradient ?? [brandPrimary, brandPrimary];
    final btnPrimary = studio?.resolvedButtonPrimary ?? brandPrimary;
    final btnRadius = studio?.getButtonRadius() ?? 999.0;

    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final firstDayOfMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final leadingEmptyCount = (firstDayOfMonth.weekday - 1) % 7;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        decoration: BoxDecoration(
          color: studio?.getModalFillColor(isDark) ??
              (isDark
                  ? const Color(0xFF0F172A)
                  : Colors.white),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: studio?.getModalBorderColor(isDark) ??
                  (isDark
                      ? const Color(0xFF334155).withValues(alpha: 0.5)
                      : const Color(0xFFE2E8F0)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 32,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.paddingOf(context).bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 2. Header: Title & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: brandPrimary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.calendar_month_rounded,
                          color: brandPrimary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isRangeMode
                            ? 'Chọn khoảng ngày'
                            : 'Chọn ngày giao dịch',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.white70 : Colors.black54,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. Segmented Toggle (if allowed - Pill Style)
              if (widget.allowModeToggle) ...[
                Container(
                  padding: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isRangeMode = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !_isRangeMode
                                  ? brandPrimary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Center(
                              child: Text(
                                'Ngày cụ thể',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: !_isRangeMode
                                      ? Colors.white
                                      : secondaryTextColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isRangeMode = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _isRangeMode
                                  ? brandPrimary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Center(
                              child: Text(
                                'Khoảng thời gian',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _isRangeMode
                                      ? Colors.white
                                      : secondaryTextColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 4. Quick Preset Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (!_isRangeMode) ...[
                      _buildPresetChip(
                          'Hôm nay', () => _selectPreset('today'), isDark),
                      const SizedBox(width: 8),
                      _buildPresetChip(
                          'Hôm qua', () => _selectPreset('yesterday'), isDark),
                      const SizedBox(width: 8),
                      _buildPresetChip('Đầu tháng',
                          () => _selectPreset('monthStart'), isDark),
                    ] else ...[
                      _buildPresetChip(
                          'Hôm nay', () => _selectPreset('today'), isDark),
                      const SizedBox(width: 8),
                      _buildPresetChip(
                          '7 ngày qua', () => _selectPreset('7days'), isDark),
                      const SizedBox(width: 8),
                      _buildPresetChip('Tháng này',
                          () => _selectPreset('thisMonth'), isDark),
                      const SizedBox(width: 8),
                      _buildPresetChip('Tháng trước',
                          () => _selectPreset('lastMonth'), isDark),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 5. Month & Year Navigator (Pill Style)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155).withValues(alpha: 0.5)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: _prevMonth,
                      color: primaryTextColor,
                      iconSize: 22,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    Text(
                      'Tháng ${_displayedMonth.month} năm ${_displayedMonth.year}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: _nextMonth,
                      color: primaryTextColor,
                      iconSize: 22,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // 6. Weekday Header
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
              const SizedBox(height: 6),

              // 7. Days Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 0,
                  childAspectRatio: 1.18,
                ),
                itemCount: leadingEmptyCount + daysInMonth,
                itemBuilder: (context, index) {
                  if (index < leadingEmptyCount) {
                    return const SizedBox();
                  }
                  final dayNumber = index - leadingEmptyCount + 1;
                  final cellDate = DateTime(
                      _displayedMonth.year, _displayedMonth.month, dayNumber);
                  final isSunday = cellDate.weekday == DateTime.sunday;

                  if (!_isRangeMode) {
                    final isSelected = _isSameDay(cellDate, _selectedDate);
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _handleDayTap(cellDate),
                      child: Center(
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? brandPrimary
                                : Colors.transparent,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: brandPrimary.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '$dayNumber',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w900
                                    : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : isSunday
                                        ? const Color(0xFFEF4444)
                                        : primaryTextColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  } else {
                    final isStart =
                        _startDate != null && _isSameDay(cellDate, _startDate!);
                    final isEnd =
                        _endDate != null && _isSameDay(cellDate, _endDate!);
                    final isInRange = _startDate != null &&
                        _endDate != null &&
                        cellDate.isAfter(_startDate!) &&
                        cellDate.isBefore(_endDate!);

                    final isSelectedEndpoint = isStart || isEnd;

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _handleDayTap(cellDate),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Range bridge
                          if (isInRange)
                            Positioned.fill(
                              child: Container(
                                color: brandPrimary
                                    .withValues(alpha: isDark ? 0.22 : 0.12),
                              ),
                            ),
                          if (isStart &&
                              _endDate != null &&
                              !_isSameDay(_startDate!, _endDate!))
                            Positioned(
                              left: 17,
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                color: brandPrimary
                                    .withValues(alpha: isDark ? 0.22 : 0.12),
                              ),
                            ),
                          if (isEnd &&
                              _startDate != null &&
                              !_isSameDay(_startDate!, _endDate!))
                            Positioned(
                              left: 0,
                              right: 17,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                color: brandPrimary
                                    .withValues(alpha: isDark ? 0.22 : 0.12),
                              ),
                            ),

                          // Day circle
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelectedEndpoint
                                  ? brandPrimary
                                  : Colors.transparent,
                              boxShadow: isSelectedEndpoint
                                  ? [
                                      BoxShadow(
                                        color: brandPrimary.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                '$dayNumber',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelectedEndpoint || isInRange
                                      ? FontWeight.w900
                                      : FontWeight.w600,
                                  color: isSelectedEndpoint
                                      ? Colors.white
                                      : isSunday && !isInRange
                                          ? const Color(0xFFEF4444)
                                          : (isInRange
                                              ? brandPrimary
                                              : primaryTextColor),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 14),

              // 8. Bottom Summary & Confirmation Bar (Pill Capsule)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isRangeMode
                          ? Icons.date_range_rounded
                          : Icons.event_available_rounded,
                      size: 16,
                      color: const Color(0xFF005FEA),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        !_isRangeMode
                            ? 'Đã chọn: ${_formatDate(_selectedDate)}'
                            : (_startDate != null && _endDate != null
                                ? 'Từ ${_formatDate(_startDate)} đến ${_formatDate(_endDate)}'
                                : (_startDate != null
                                    ? 'Từ ${_formatDate(_startDate)}...'
                                    : 'Chưa chọn khoảng')),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 9. Confirm Button (Pill Capsule)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          shape: const StadiumBorder(),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Text(
                          'Hủy',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: secondaryTextColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: studio?.getButtonHeight() ?? 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: btnGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(btnRadius),
                        boxShadow: [
                          BoxShadow(
                            color: btnPrimary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          if (!_isRangeMode) {
                            widget.onDateSelected?.call(_selectedDate);
                          } else {
                            if (_startDate != null && _endDate != null) {
                              widget.onRangeSelected
                                  ?.call(_startDate!, _endDate!);
                            } else if (_startDate != null) {
                              widget.onRangeSelected
                                  ?.call(_startDate!, _startDate!);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(btnRadius),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Áp dụng',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
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

  Widget _buildPresetChip(String label, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekdayHeader(String text, bool isDark,
      {bool isSunday = false}) {
    return SizedBox(
      width: 34,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isSunday
                ? const Color(0xFFEF4444)
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }
}
