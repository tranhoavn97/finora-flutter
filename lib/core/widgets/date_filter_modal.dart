import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../state/theme_studio_controller.dart';
import '../utils/date_filter.dart';
import 'finora_date_picker_sheet.dart';
import 'glass_widgets.dart';

class DateFilterModalResult {
  final DateFilterOption option;
  final DateTime? customDate;
  final DateTimeRange? customRange;
  final int? customYear;
  final int? customMonth;

  const DateFilterModalResult({
    required this.option,
    this.customDate,
    this.customRange,
    this.customYear,
    this.customMonth,
  });
}

Future<DateFilterModalResult?> showDateFilterModal(
  BuildContext context, {
  required DateFilterOption currentOption,
  DateTime? currentCustomDate,
  DateTimeRange? currentCustomRange,
  int? currentCustomYear,
  int? currentCustomMonth,
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
      currentCustomYear: currentCustomYear,
      currentCustomMonth: currentCustomMonth,
      showAllTime: showAllTime,
    ),
  );
}

class DateFilterModalSheet extends StatefulWidget {
  final DateFilterOption currentOption;
  final DateTime? currentCustomDate;
  final DateTimeRange? currentCustomRange;
  final int? currentCustomYear;
  final int? currentCustomMonth;
  final bool showAllTime;

  const DateFilterModalSheet({
    super.key,
    required this.currentOption,
    this.currentCustomDate,
    this.currentCustomRange,
    this.currentCustomYear,
    this.currentCustomMonth,
    this.showAllTime = false,
  });

  @override
  State<DateFilterModalSheet> createState() => _DateFilterModalSheetState();
}

class _DateFilterModalSheetState extends State<DateFilterModalSheet> {
  late int _pickerYear;
  late int _pickerMonth;
  bool _showMonthGrid = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _pickerYear = widget.currentCustomYear ?? now.year;
    _pickerMonth = widget.currentCustomMonth ?? now.month;
    _showMonthGrid = widget.currentOption == DateFilterOption.customMonth;
  }

  void _stepMonth(int delta) {
    HapticFeedback.selectionClick();
    var m = _pickerMonth + delta;
    var y = _pickerYear;
    while (m < 1) {
      m += 12;
      y -= 1;
    }
    while (m > 12) {
      m -= 12;
      y += 1;
    }
    setState(() {
      _pickerYear = y;
      _pickerMonth = m;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final brandPrimary = studio?.resolvedPrimary ?? const Color(0xFF0F6E56);
    final brandSecondary =
        studio?.resolvedSecondary ?? const Color(0xFF14B8A6);
    final modalBg = studio?.getModalFillColor(isDark) ??
        (isDark ? const Color(0xFF0F172A) : Colors.white);
    final now = DateTime.now();
    final lastMonthDt = DateTime(now.year, now.month - 1, 1);

    final isCustomDateSelected =
        widget.currentOption == DateFilterOption.customDate &&
            widget.currentCustomDate != null;
    final isCustomRangeSelected =
        widget.currentOption == DateFilterOption.customRange &&
            widget.currentCustomRange != null;

    return FinoraDraggableSheetWrapper(
      onClose: () => Navigator.pop(context),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: Container(
          decoration: BoxDecoration(
            color: modalBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.12),
                blurRadius: 30,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            6,
            20,
            MediaQuery.paddingOf(context).bottom + 18,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.90,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Interactive Center drag handle
              FinoraSheetDragHandle(
                padding: const EdgeInsets.only(top: 6, bottom: 10),
                onClose: () => Navigator.pop(context),
              ),

              // 2. Header: Circular Badge + Title + Circular Close Button
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          brandPrimary.withValues(alpha: isDark ? 0.28 : 0.16),
                          brandSecondary.withValues(
                              alpha: isDark ? 0.16 : 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: brandPrimary.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Icon(
                      Icons.date_range_rounded,
                      size: 20,
                      color: brandPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chọn mốc thời gian',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.35,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Chọn nhanh theo tháng, ngày lẻ hoặc khoảng ngày',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FinoraCircleIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Đóng',
                    size: 34,
                    iconSize: 18,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 3. Hero Month & Year Selector Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              brandPrimary.withValues(
                                  alpha: isDark ? 0.16 : 0.08),
                              brandSecondary.withValues(
                                  alpha: isDark ? 0.08 : 0.03),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: brandPrimary.withValues(
                                alpha: isDark ? 0.34 : 0.22),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(999),
                                  onTap: () => _stepMonth(-1),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark
                                          ? const Color(0xFF0F172A)
                                              .withValues(alpha: 0.85)
                                          : Colors.white,
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.12)
                                            : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.chevron_left_rounded,
                                      size: 20,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() =>
                                          _showMonthGrid = !_showMonthGrid);
                                    },
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: (isDark
                                                  ? const Color(0xFF0F172A)
                                                  : Colors.white)
                                              .withValues(alpha: 0.86),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          border: Border.all(
                                            color: brandPrimary.withValues(
                                                alpha: 0.22),
                                          ),
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.calendar_month_rounded,
                                                size: 15,
                                                color: brandPrimary,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                'Tháng $_pickerMonth/$_pickerYear',
                                                maxLines: 1,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w900,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF0F172A),
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              Icon(
                                                _showMonthGrid
                                                    ? Icons
                                                        .keyboard_arrow_up_rounded
                                                    : Icons
                                                        .keyboard_arrow_down_rounded,
                                                size: 16,
                                                color: brandPrimary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  borderRadius: BorderRadius.circular(999),
                                  onTap: () => _stepMonth(1),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark
                                          ? const Color(0xFF0F172A)
                                              .withValues(alpha: 0.85)
                                          : Colors.white,
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.12)
                                            : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.chevron_right_rounded,
                                      size: 20,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(999),
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      if (_pickerYear == now.year &&
                                          _pickerMonth == now.month) {
                                        Navigator.pop(
                                          context,
                                          const DateFilterModalResult(
                                            option: DateFilterOption.thisMonth,
                                          ),
                                        );
                                      } else if (_pickerYear ==
                                              lastMonthDt.year &&
                                          _pickerMonth == lastMonthDt.month) {
                                        Navigator.pop(
                                          context,
                                          DateFilterModalResult(
                                            option: DateFilterOption.lastMonth,
                                            customYear: _pickerYear,
                                            customMonth: _pickerMonth,
                                          ),
                                        );
                                      } else {
                                        Navigator.pop(
                                          context,
                                          DateFilterModalResult(
                                            option:
                                                DateFilterOption.customMonth,
                                            customYear: _pickerYear,
                                            customMonth: _pickerMonth,
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      height: 36,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            brandPrimary,
                                            brandSecondary,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        boxShadow: [
                                          BoxShadow(
                                            color: brandPrimary.withValues(
                                                alpha: 0.28),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'Áp dụng',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_showMonthGrid) ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  InkWell(
                                    borderRadius: BorderRadius.circular(999),
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _pickerYear -= 1);
                                    },
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.08)
                                            : Colors.white,
                                        border: Border.all(
                                          color: brandPrimary.withValues(
                                              alpha: 0.20),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.chevron_left_rounded,
                                        size: 16,
                                        color: brandPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: brandPrimary.withValues(
                                          alpha: isDark ? 0.20 : 0.10),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Năm $_pickerYear',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: brandPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(999),
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _pickerYear += 1);
                                    },
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.08)
                                            : Colors.white,
                                        border: Border.all(
                                          color: brandPrimary.withValues(
                                              alpha: 0.20),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.chevron_right_rounded,
                                        size: 16,
                                        color: brandPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  mainAxisSpacing: 6,
                                  crossAxisSpacing: 6,
                                  childAspectRatio: 2.35,
                                ),
                                itemCount: 12,
                                itemBuilder: (_, idx) {
                                  final m = idx + 1;
                                  final selected = m == _pickerMonth;
                                  final isCurrentCalMonth =
                                      _pickerYear == now.year && m == now.month;
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(999),
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _pickerMonth = m);
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 160),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? brandPrimary
                                            : (isDark
                                                ? const Color(0xFF0F172A)
                                                    .withValues(alpha: 0.72)
                                                : Colors.white),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                          color: selected
                                              ? brandPrimary
                                              : (isCurrentCalMonth
                                                  ? brandPrimary.withValues(
                                                      alpha: 0.45)
                                                  : (isDark
                                                      ? Colors.white.withValues(
                                                          alpha: 0.08)
                                                      : const Color(
                                                          0xFFE2E8F0))),
                                          width: isCurrentCalMonth && !selected
                                              ? 1.2
                                              : 1.0,
                                        ),
                                        boxShadow: selected
                                            ? [
                                                BoxShadow(
                                                  color: brandPrimary.withValues(
                                                      alpha: 0.25),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Text(
                                        'Tháng $m',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: selected
                                              ? FontWeight.w800
                                              : (isCurrentCalMonth
                                                  ? FontWeight.w700
                                                  : FontWeight.w600),
                                          color: selected
                                              ? Colors.white
                                              : (isCurrentCalMonth
                                                  ? brandPrimary
                                                  : (isDark
                                                      ? Colors.white70
                                                      : const Color(
                                                          0xFF334155))),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 4. Quick Preset Bento Pills
                      Text(
                        'CHỌN NHANH',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildQuickPill(
                            context: context,
                            label: 'Tháng này',
                            isSelected: widget.currentOption ==
                                    DateFilterOption.thisMonth &&
                                widget.currentCustomDate == null &&
                                widget.currentCustomRange == null,
                            brandPrimary: brandPrimary,
                            isDark: isDark,
                            onTap: () => Navigator.pop(
                              context,
                              const DateFilterModalResult(
                                option: DateFilterOption.thisMonth,
                              ),
                            ),
                          ),
                          _buildQuickPill(
                            context: context,
                            label: 'Tháng trước',
                            isSelected: widget.currentOption ==
                                DateFilterOption.lastMonth,
                            brandPrimary: brandPrimary,
                            isDark: isDark,
                            onTap: () => Navigator.pop(
                              context,
                              DateFilterModalResult(
                                option: DateFilterOption.lastMonth,
                                customYear: lastMonthDt.year,
                                customMonth: lastMonthDt.month,
                              ),
                            ),
                          ),
                          _buildQuickPill(
                            context: context,
                            label: 'Hôm nay',
                            isSelected:
                                widget.currentOption == DateFilterOption.today &&
                                    widget.currentCustomDate == null &&
                                    widget.currentCustomRange == null,
                            brandPrimary: brandPrimary,
                            isDark: isDark,
                            onTap: () => Navigator.pop(
                              context,
                              const DateFilterModalResult(
                                option: DateFilterOption.today,
                              ),
                            ),
                          ),
                          _buildQuickPill(
                            context: context,
                            label: 'Hôm qua',
                            isSelected: widget.currentOption ==
                                    DateFilterOption.yesterday &&
                                widget.currentCustomDate == null &&
                                widget.currentCustomRange == null,
                            brandPrimary: brandPrimary,
                            isDark: isDark,
                            onTap: () => Navigator.pop(
                              context,
                              const DateFilterModalResult(
                                option: DateFilterOption.yesterday,
                              ),
                            ),
                          ),
                          _buildQuickPill(
                            context: context,
                            label: 'Tuần này',
                            isSelected: widget.currentOption ==
                                    DateFilterOption.thisWeek &&
                                widget.currentCustomDate == null &&
                                widget.currentCustomRange == null,
                            brandPrimary: brandPrimary,
                            isDark: isDark,
                            onTap: () => Navigator.pop(
                              context,
                              const DateFilterModalResult(
                                option: DateFilterOption.thisWeek,
                              ),
                            ),
                          ),
                          _buildQuickPill(
                            context: context,
                            label: 'Tuần trước',
                            isSelected:
                                widget.currentOption == DateFilterOption.lastWeek,
                            brandPrimary: brandPrimary,
                            isDark: isDark,
                            onTap: () => Navigator.pop(
                              context,
                              const DateFilterModalResult(
                                option: DateFilterOption.lastWeek,
                              ),
                            ),
                          ),
                          _buildQuickPill(
                            context: context,
                            label: 'Năm ${now.year}',
                            isSelected: widget.currentOption ==
                                    DateFilterOption.thisYear &&
                                widget.currentCustomDate == null &&
                                widget.currentCustomRange == null,
                            brandPrimary: brandPrimary,
                            isDark: isDark,
                            onTap: () => Navigator.pop(
                              context,
                              const DateFilterModalResult(
                                option: DateFilterOption.thisYear,
                              ),
                            ),
                          ),
                          if (widget.showAllTime)
                            _buildQuickPill(
                              context: context,
                              label: 'Tất cả thời gian',
                              isSelected: widget.currentOption ==
                                      DateFilterOption.allTime &&
                                  widget.currentCustomDate == null,
                              brandPrimary: brandPrimary,
                              isDark: isDark,
                              onTap: () => Navigator.pop(
                                context,
                                const DateFilterModalResult(
                                  option: DateFilterOption.allTime,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 5. Custom Date & Range Selection Cards (Side-by-side)
                      Text(
                        'TÙY CHỌN NÂNG CAO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          // Pick single date
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () async {
                                final picked =
                                    await FinoraDatePickerSheet.showSingleDate(
                                  context,
                                  initialDate: widget.currentCustomDate ?? now,
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
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isCustomDateSelected
                                      ? brandPrimary.withValues(
                                          alpha: isDark ? 0.20 : 0.08)
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isCustomDateSelected
                                        ? brandPrimary
                                        : (isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.08)
                                            : const Color(0xFFE2E8F0)),
                                    width: isCustomDateSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isCustomDateSelected
                                            ? brandPrimary
                                            : brandPrimary.withValues(
                                                alpha: isDark ? 0.20 : 0.10),
                                      ),
                                      child: Icon(
                                        Icons.today_rounded,
                                        size: 16,
                                        color: isCustomDateSelected
                                            ? Colors.white
                                            : brandPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '1 ngày cụ thể',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              color: isCustomDateSelected
                                                  ? brandPrimary
                                                  : (isDark
                                                      ? Colors.white
                                                      : const Color(
                                                          0xFF0F172A)),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isCustomDateSelected
                                                ? DateFormat('dd/MM/yyyy')
                                                    .format(widget
                                                        .currentCustomDate!)
                                                : 'Chọn trên lịch',
                                            style: TextStyle(
                                              fontSize: 10.8,
                                              fontWeight: FontWeight.w600,
                                              color: isCustomDateSelected
                                                  ? brandPrimary
                                                  : (isDark
                                                      ? const Color(0xFF94A3B8)
                                                      : const Color(
                                                          0xFF64748B)),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Pick date range
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () async {
                                final picked =
                                    await FinoraDatePickerSheet.showDateRange(
                                  context,
                                  initialStartDate:
                                      widget.currentCustomRange?.start,
                                  initialEndDate:
                                      widget.currentCustomRange?.end,
                                );
                                if (picked != null && context.mounted) {
                                  Navigator.pop(
                                    context,
                                    DateFilterModalResult(
                                      option: DateFilterOption.customRange,
                                      customRange: picked,
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isCustomRangeSelected
                                      ? brandPrimary.withValues(
                                          alpha: isDark ? 0.20 : 0.08)
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isCustomRangeSelected
                                        ? brandPrimary
                                        : (isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.08)
                                            : const Color(0xFFE2E8F0)),
                                    width: isCustomRangeSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isCustomRangeSelected
                                            ? brandPrimary
                                            : brandPrimary.withValues(
                                                alpha: isDark ? 0.20 : 0.10),
                                      ),
                                      child: Icon(
                                        Icons.date_range_rounded,
                                        size: 16,
                                        color: isCustomRangeSelected
                                            ? Colors.white
                                            : brandPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Khoảng ngày',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              color: isCustomRangeSelected
                                                  ? brandPrimary
                                                  : (isDark
                                                      ? Colors.white
                                                      : const Color(
                                                          0xFF0F172A)),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isCustomRangeSelected
                                                ? '${DateFormat('dd/MM').format(widget.currentCustomRange!.start)} - ${DateFormat('dd/MM').format(widget.currentCustomRange!.end)}'
                                                : 'Từ ngày - Đến ngày',
                                            style: TextStyle(
                                              fontSize: 10.8,
                                              fontWeight: FontWeight.w600,
                                              color: isCustomRangeSelected
                                                  ? brandPrimary
                                                  : (isDark
                                                      ? const Color(0xFF94A3B8)
                                                      : const Color(
                                                          0xFF64748B)),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPill({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required Color brandPrimary,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? brandPrimary
              : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? brandPrimary
                : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: brandPrimary.withValues(alpha: 0.30),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF334155)),
          ),
        ),
      ),
    );
  }
}
