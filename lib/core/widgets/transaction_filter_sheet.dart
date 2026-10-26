import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/date_filter.dart';
import 'period_picker.dart';
import 'glass_widgets.dart';
import '../../state/theme_studio_controller.dart';

class FilterResult {
  final String owner; // 'all', 'husband', 'wife'
  final String type; // 'all', 'income', 'expense', 'investment'
  final String query;
  final String category;
  final String
      timeRange; // 'all', 'today', 'yesterday', 'this_week', 'this_month', 'this_year', 'custom'
  final int? selectedMonth;
  final int? selectedYear;
  final DateTime? customDate;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const FilterResult({
    this.owner = 'all',
    this.type = 'all',
    this.query = '',
    this.category = 'all',
    this.timeRange = 'all',
    this.selectedMonth,
    this.selectedYear,
    this.customDate,
    this.customStartDate,
    this.customEndDate,
  });

  PeriodSelection get period {
    if (customStartDate != null && customEndDate != null) {
      return PeriodSelection(DateFilterOption.customRange,
          startDate: customStartDate, endDate: customEndDate);
    }
    if (customDate != null) {
      return PeriodSelection(DateFilterOption.customDate, date: customDate);
    }
    if (selectedMonth != null && selectedYear != null) {
      return PeriodSelection(DateFilterOption.customMonth,
          date: DateTime(selectedYear!, selectedMonth!));
    }
    return PeriodSelection(DateFilterOption.values.firstWhere(
        (o) => o.key == timeRange,
        orElse: () => DateFilterOption.allTime));
  }

  FilterResult withPeriod(PeriodSelection value) => FilterResult(
      owner: owner,
      type: type,
      query: query,
      category: category,
      timeRange: value.option.key,
      customDate:
          value.option == DateFilterOption.customDate ? value.date : null,
      customStartDate:
          value.option == DateFilterOption.customRange ? value.startDate : null,
      customEndDate:
          value.option == DateFilterOption.customRange ? value.endDate : null,
      selectedMonth: value.option == DateFilterOption.customMonth
          ? value.date?.month
          : null,
      selectedYear: value.option == DateFilterOption.customMonth
          ? value.date?.year
          : null);

  FilterResult copyWith({
    String? owner,
    String? type,
    String? query,
    String? category,
    String? timeRange,
    int? selectedMonth,
    int? selectedYear,
    DateTime? customDate,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) =>
      FilterResult(
        owner: owner ?? this.owner,
        type: type ?? this.type,
        query: query ?? this.query,
        category: category ?? this.category,
        timeRange: timeRange ?? this.timeRange,
        selectedMonth: selectedMonth ?? this.selectedMonth,
        selectedYear: selectedYear ?? this.selectedYear,
        customDate: customDate ?? this.customDate,
        customStartDate: customStartDate ?? this.customStartDate,
        customEndDate: customEndDate ?? this.customEndDate,
      );
}

/// Modal Bộ Lọc Giao Dịch thiết kế phong cách Apple iOS hiện đại, sang trọng
class TransactionFilterSheet extends StatefulWidget {
  final FilterResult initialFilter;
  final ValueChanged<FilterResult> onApply;
  final List<String> categories;

  const TransactionFilterSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
    this.categories = const [],
  });

  static Future<FilterResult?> show(
    BuildContext context, {
    required FilterResult initialFilter,
    List<String> categories = const [],
  }) {
    return showModalBottomSheet<FilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.50),
      builder: (ctx) => TransactionFilterSheet(
        initialFilter: initialFilter,
        categories: categories,
        onApply: (v) => Navigator.pop(ctx, v),
      ),
    );
  }

  @override
  State<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  late String owner, type, category;
  late PeriodSelection period;

  @override
  void initState() {
    super.initState();
    owner = widget.initialFilter.owner;
    type = widget.initialFilter.type;
    category = widget.initialFilter.category;
    period = widget.initialFilter.period;
  }

  void _resetAll() {
    setState(() {
      owner = 'all';
      type = 'all';
      category = 'all';
      period = const PeriodSelection(DateFilterOption.allTime);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final primaryColor = studio?.primaryColor ?? Theme.of(context).colorScheme.primary;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = const Color(0xFF64748B);
    final surfaceColor = studio?.getCardFillColor(isDark) ??
        (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF8FAFC));
    final borderColor = studio?.getBorderColor(isDark) ??
        (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0));
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return FractionallySizedBox(
      heightFactor: 0.86,
      child: GlassBottomSheet(
        radius: 28,
        showHandle: true,
        isExpanded: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FinoraSheetHeader(
              title: 'Bộ lọc nâng cao',
              subtitle: 'Tùy chỉnh tiêu chí để tìm nhanh giao dịch',
              icon: Icons.tune_rounded,
              showHandle: false,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: _resetAll,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      backgroundColor:
                          isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      'Đặt lại',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FinoraIconAction(
                    icon: Icons.close_rounded,
                    label: 'Đóng',
                    size: 36,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section 1: Thành viên (Apple Segmented Style)
                    _buildSectionHeader(
                      icon: Icons.people_outline_rounded,
                      title: 'Thành viên sở hữu',
                      isDark: isDark,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 10),
                    _buildAppleSegmentedControl(
                      options: const [
                        ('all', 'Tất cả'),
                        ('husband', 'Chồng'),
                        ('wife', 'Vợ'),
                      ],
                      selected: owner,
                      onChanged: (v) => setState(() => owner = v),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 22),

                    // Section 2: Loại giao dịch
                    _buildSectionHeader(
                      icon: Icons.swap_horiz_rounded,
                      title: 'Loại giao dịch',
                      isDark: isDark,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 10),
                    _buildAppleSegmentedControl(
                      options: const [
                        ('all', 'Tất cả'),
                        ('expense', 'Chi tiêu'),
                        ('income', 'Thu nhập'),
                        ('investment', 'Đầu tư'),
                      ],
                      selected: type,
                      onChanged: (v) => setState(() => type = v),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 22),

                    // Section 3: Khoảng thời gian (Apple Card Tile)
                    _buildSectionHeader(
                      icon: Icons.calendar_month_outlined,
                      title: 'Thời gian áp dụng',
                      isDark: isDark,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        final picked =
                            await PeriodPicker.show(context, initial: period);
                        if (picked != null && mounted) {
                          setState(() => period = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF007AFF)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.date_range_rounded,
                                size: 19,
                                color: Color(0xFF007AFF),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Khoảng thời gian',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    period.label,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: secondaryTextColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Section 4: Danh mục (Apple Dropdown Card)
                    _buildSectionHeader(
                      icon: Icons.grid_view_rounded,
                      title: 'Danh mục chi tiêu',
                      isDark: isDark,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: widget.categories.contains(category)
                              ? category
                              : 'all',
                          isExpanded: true,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: secondaryTextColor,
                          ),
                          dropdownColor: bgColor,
                          borderRadius: BorderRadius.circular(16),
                          items: [
                            DropdownMenuItem(
                              value: 'all',
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF007AFF),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Tất cả danh mục',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            for (final name in widget.categories.toSet())
                              DropdownMenuItem(
                                value: name,
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => category = value ?? 'all'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom Action: Unified Button
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
              child: Container(
                height: studio?.getButtonHeight() ?? 48.0,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: studio?.resolvedButtonGradient ?? [primaryColor, primaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(
                      studio?.getButtonRadius() ?? 16.0),
                  boxShadow: [
                    BoxShadow(
                      color: (studio?.resolvedButtonPrimary ?? primaryColor).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(
                        studio?.getButtonRadius() ?? 16.0),
                    onTap: () => widget.onApply(FilterResult(
                      owner: owner,
                      type: type,
                      category: category,
                      query: widget.initialFilter.query,
                    ).withPeriod(period)),
                    child: const Center(
                      child: Text(
                        'Áp dụng bộ lọc',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required bool isDark,
    required Color textColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildAppleSegmentedControl({
    required List<(String, String)> options,
    required String selected,
    required ValueChanged<String> onChanged,
    required bool isDark,
  }) {
    final containerBg =
        isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9);
    final activeBg = isDark ? const Color(0xFF2C2C34) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final opt in options) ...[
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(opt.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: selected == opt.$1 ? activeBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: selected == opt.$1
                        ? [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.28 : 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    opt.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected == opt.$1
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selected == opt.$1
                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                          : (isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
