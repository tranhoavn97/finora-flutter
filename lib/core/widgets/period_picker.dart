import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../state/theme_studio_controller.dart';
import 'glass_widgets.dart';
import '../utils/date_filter.dart';

/// A period, not a single representative day. Shared by every overview filter.
class PeriodSelection {
  final DateFilterOption option;
  final DateTime? date;
  final DateTime? startDate;
  final DateTime? endDate;

  const PeriodSelection(
    this.option, {
    this.date,
    this.startDate,
    this.endDate,
  });

  String get label {
    if (option == DateFilterOption.customRange &&
        startDate != null &&
        endDate != null) {
      final s = DateFormat('dd/MM/yyyy').format(startDate!);
      final e = DateFormat('dd/MM/yyyy').format(endDate!);
      return '$s - $e';
    }
    if (option == DateFilterOption.customMonth && date != null) {
      return 'Tháng ${date!.month}/${date!.year}';
    }
    if (option == DateFilterOption.customDate && date != null) {
      return DateFormat('dd/MM/yyyy').format(date!);
    }
    return option.label;
  }

  bool matches(int timestamp) => isDateInFilterOption(
        timestamp > 100000000000 ? timestamp : timestamp * 1000,
        option,
        customDate: date,
        customStartDate: startDate,
        customEndDate: endDate,
        customYear: date?.year,
        customMonth: date?.month,
      );
}

/// Modal chọn khoảng thời gian phong cách Apple iOS cao cấp, hỗ trợ Chọn khoảng ngày (Từ ngày - Đến ngày)
class PeriodPicker extends StatefulWidget {
  final PeriodSelection initial;

  const PeriodPicker({super.key, required this.initial});

  static Future<PeriodSelection?> show(
    BuildContext context, {
    required PeriodSelection initial,
  }) =>
      showModalBottomSheet<PeriodSelection>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        builder: (_) => PeriodPicker(initial: initial),
      );

  @override
  State<PeriodPicker> createState() => _PeriodPickerState();
}

class _PeriodPickerState extends State<PeriodPicker> {
  late DateFilterOption _selectedOption;
  DateTime? _selectedDate;
  DateTime? _startDate;
  DateTime? _endDate;
  late DateTime _displayedMonth;

  // Preset options list
  final _quickOptions = const [
    (DateFilterOption.allTime, 'Tất cả'),
    (DateFilterOption.today, 'Hôm nay'),
    (DateFilterOption.yesterday, 'Hôm qua'),
    (DateFilterOption.thisWeek, 'Tuần này'),
    (DateFilterOption.lastWeek, 'Tuần trước'),
    (DateFilterOption.thisMonth, 'Tháng này'),
    (DateFilterOption.lastMonth, 'Tháng trước'),
    (DateFilterOption.thisYear, 'Năm nay'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.initial.option;
    _selectedDate = widget.initial.date;
    _startDate = widget.initial.startDate ?? DateTime.now().subtract(const Duration(days: 7));
    _endDate = widget.initial.endDate ?? DateTime.now();

    final anchor = _selectedDate ?? _startDate ?? DateTime.now();
    _displayedMonth = DateTime(anchor.year, anchor.month);
  }

  Future<void> _pickSingleDate(BuildContext context) async {
    final picked = await showFinoraDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'CHỌN NGÀY CỤ THỂ',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedOption = DateFilterOption.customDate;
      });
    }
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await showFinoraDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(const Duration(days: 7)),
        end: _endDate ?? DateTime.now(),
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'CHỌN TỪ NGÀY ĐẾN NGÀY',
      saveText: 'CHỌN',
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedOption = DateFilterOption.customRange;
      });
    }
  }

  PeriodSelection _buildResult() {
    switch (_selectedOption) {
      case DateFilterOption.customDate:
        return PeriodSelection(
          DateFilterOption.customDate,
          date: _selectedDate ?? DateTime.now(),
        );
      case DateFilterOption.customMonth:
        return PeriodSelection(
          DateFilterOption.customMonth,
          date: _displayedMonth,
        );
      case DateFilterOption.customRange:
        return PeriodSelection(
          DateFilterOption.customRange,
          startDate: _startDate,
          endDate: _endDate,
        );
      default:
        return PeriodSelection(_selectedOption);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = studio?.getModalFillColor(isDark) ??
        (isDark ? const Color(0xFF0F172A) : Colors.white);
    final primaryAccent =
        studio?.primaryColor ?? const Color(0xFF007AFF);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final surfaceColor =
        isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF8FAFC);
    final borderColor = studio?.getBorderColor(isDark) ??
        (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0));
    final modalRadius = studio?.getCardRadius(studio.globalDensity) ?? 28.0;

    final isCustomRange = _selectedOption == DateFilterOption.customRange;
    final isCustomDate = _selectedOption == DateFilterOption.customDate;
    final isCustomMonth = _selectedOption == DateFilterOption.customMonth;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(modalRadius)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(modalRadius)),
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
          ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                blurRadius: 36,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Apple Top Handle Bar
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Header Row: [ Khoảng thời gian ] ------------ [ ✕ ]
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Khoảng thời gian',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Lọc nhanh hoặc chọn khoảng ngày linh hoạt',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FinoraIconAction(
                        icon: Icons.close_rounded,
                        label: 'Đóng',
                        size: 38,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Divider(height: 1, color: borderColor),

            // Scrollable Options Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section 1: Khoảng ngày tùy chỉnh (Từ ngày - Đến ngày) -> Đặt lên vị trí nổi bật nhất!
                    Text(
                      'TÙY CHỈNH THỜI GIAN',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: secondaryTextColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Range Picker Tile [ Từ ngày ➔ Đến ngày ]
                    InkWell(
                      onTap: () => _pickDateRange(context),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isCustomRange
                              ? const Color(0xFF007AFF).withValues(alpha: isDark ? 0.2 : 0.08)
                              : surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCustomRange
                                ? const Color(0xFF007AFF)
                                : borderColor,
                            width: isCustomRange ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF007AFF)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.date_range_rounded,
                                size: 20,
                                color: Color(0xFF007AFF),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Từ ngày đến ngày',
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: isCustomRange
                                              ? const Color(0xFF007AFF)
                                              : textColor,
                                        ),
                                      ),
                                      if (isCustomRange) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF007AFF),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'Đang chọn',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _startDate != null && _endDate != null
                                        ? '${DateFormat('dd/MM/yyyy').format(_startDate!)}  ➔  ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                                        : 'Bấm để chọn khoảng ngày cụ thể',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: isCustomRange
                                          ? textColor
                                          : secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.edit_calendar_rounded,
                              size: 20,
                              color: isCustomRange
                                  ? const Color(0xFF007AFF)
                                  : secondaryTextColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Row: [ Chọn 1 ngày cụ thể ] & [ Chọn tháng ]
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickSingleDate(context),
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isCustomDate
                                    ? const Color(0xFF007AFF).withValues(alpha: isDark ? 0.2 : 0.08)
                                    : surfaceColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isCustomDate
                                      ? const Color(0xFF007AFF)
                                      : borderColor,
                                  width: isCustomDate ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.today_rounded,
                                    size: 18,
                                    color: isCustomDate
                                        ? const Color(0xFF007AFF)
                                        : secondaryTextColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isCustomDate && _selectedDate != null
                                          ? DateFormat('dd/MM/yyyy')
                                              .format(_selectedDate!)
                                          : 'Chọn 1 ngày',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isCustomDate
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: isCustomDate
                                            ? const Color(0xFF007AFF)
                                            : textColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedOption = DateFilterOption.customMonth;
                              });
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isCustomMonth
                                    ? const Color(0xFF007AFF).withValues(alpha: isDark ? 0.2 : 0.08)
                                    : surfaceColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isCustomMonth
                                      ? const Color(0xFF007AFF)
                                      : borderColor,
                                  width: isCustomMonth ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_view_month_rounded,
                                    size: 18,
                                    color: isCustomMonth
                                        ? const Color(0xFF007AFF)
                                        : secondaryTextColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isCustomMonth
                                          ? 'Tháng ${_displayedMonth.month}/${_displayedMonth.year}'
                                          : 'Chọn tháng',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isCustomMonth
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: isCustomMonth
                                            ? const Color(0xFF007AFF)
                                            : textColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section 2: Khoảng thời gian nhanh (Apple Grid Pills)
                    Text(
                      'CHỌN NHANH',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: secondaryTextColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final opt in _quickOptions) ...[
                          _buildQuickOptionPill(
                            option: opt.$1,
                            label: opt.$2,
                            isDark: isDark,
                            textColor: textColor,
                            surfaceColor: surfaceColor,
                            borderColor: borderColor,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom Action: Apple Button
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
              child: Container(
                height: studio?.getButtonHeight() ?? 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryAccent,
                      Color.lerp(primaryAccent, Colors.black, 0.15)!,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(
                      studio?.getButtonRadius() ?? 16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryAccent.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(
                        studio?.getButtonRadius() ?? 16),
                    onTap: () {
                      final result = _buildResult();
                      Navigator.pop(context, result);
                    },
                    child: Center(
                      child: Text(
                        'Áp dụng · ${_buildResult().label}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildQuickOptionPill({
    required DateFilterOption option,
    required String label,
    required bool isDark,
    required Color textColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    final isSelected = _selectedOption == option;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _selectedOption = option;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF007AFF)
              : surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF007AFF) : borderColor,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : textColor,
          ),
        ),
      ),
    );
  }
}
