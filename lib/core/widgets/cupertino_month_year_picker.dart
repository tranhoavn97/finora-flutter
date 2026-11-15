import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../state/theme_studio_controller.dart';
import 'finora_modal_scope.dart';
import 'glass_widgets.dart';

/// Modal chọn Tháng / Năm đồng bộ phong cách FINORA Glass & Theme Studio.
class CupertinoMonthYearPickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final int minYear;
  final int maxYear;

  const CupertinoMonthYearPickerSheet({
    super.key,
    required this.initialDate,
    this.minYear = 2020,
    this.maxYear = 2035,
  });

  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialDate,
    int minYear = 2020,
    int maxYear = 2035,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CupertinoMonthYearPickerSheet(
        initialDate: initialDate,
        minYear: minYear,
        maxYear: maxYear,
      ),
    );
  }

  @override
  State<CupertinoMonthYearPickerSheet> createState() =>
      _CupertinoMonthYearPickerSheetState();
}

class _CupertinoMonthYearPickerSheetState
    extends State<CupertinoMonthYearPickerSheet> {
  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialDate.month.clamp(1, 12);
    _selectedYear =
        widget.initialDate.year.clamp(widget.minYear, widget.maxYear);
  }

  void _selectPreset(DateTime target) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedYear = target.year.clamp(widget.minYear, widget.maxYear);
      _selectedMonth = target.month.clamp(1, 12);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ThemeStudioController? studio;
    try {
      studio = Provider.of<ThemeStudioController?>(context, listen: true);
    } catch (_) {}

    final primary =
        studio?.resolvedPrimary ?? Theme.of(context).colorScheme.primary;
    final secondary =
        studio?.resolvedSecondary ?? Color.lerp(primary, Colors.white, 0.2)!;
    final textPrimary =
        isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final surfaceTile =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderTile =
        isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0);

    final now = DateTime.now();
    final prevMonth = DateTime(now.year, now.month - 1);
    final isCurrentMonthSelected =
        _selectedYear == now.year && _selectedMonth == now.month;
    final isPrevMonthSelected =
        _selectedYear == prevMonth.year && _selectedMonth == prevMonth.month;

    return FinoraModalScope(
      child: Theme(
        data: FinoraModalScope.opaqueModalTheme(context),
        child: GlassBottomSheet(
          showHandle: true,
          radius: 30,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header Row
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [primary, secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chọn tháng & năm',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Xem số liệu thu chi cho kỳ $_selectedMonth/$_selectedYear',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFF1F5F9),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 2. Quick Preset Pills & Year Stepper Row
                  Row(
                    children: [
                      _QuickMonthChip(
                        label: 'Tháng này',
                        selected: isCurrentMonthSelected,
                        primary: primary,
                        isDark: isDark,
                        onTap: () => _selectPreset(now),
                      ),
                      const SizedBox(width: 6),
                      _QuickMonthChip(
                        label: 'Tháng trước',
                        selected: isPrevMonthSelected,
                        primary: primary,
                        isDark: isDark,
                        onTap: () => _selectPreset(prevMonth),
                      ),
                      const Spacer(),
                      Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: surfaceTile,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: borderTile),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _YearStepBtn(
                              icon: Icons.chevron_left_rounded,
                              enabled: _selectedYear > widget.minYear,
                              color: primary,
                              textSecondary: textSecondary,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedYear--);
                              },
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                '$_selectedYear',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ),
                            _YearStepBtn(
                              icon: Icons.chevron_right_rounded,
                              enabled: _selectedYear < widget.maxYear,
                              color: primary,
                              textSecondary: textSecondary,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedYear++);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 3. 3x4 Month Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 12,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.55,
                    ),
                    itemBuilder: (_, idx) {
                      final m = idx + 1;
                      final isSelected = m == _selectedMonth;
                      final isThisMonth =
                          _selectedYear == now.year && m == now.month;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedMonth = m);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [primary, secondary],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelected ? null : surfaceTile,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? primary
                                    : (isThisMonth
                                        ? primary.withValues(alpha: 0.45)
                                        : borderTile),
                                width: isSelected || isThisMonth ? 1.3 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: primary.withValues(
                                            alpha: isDark ? 0.35 : 0.24),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isThisMonth && !isSelected) ...[
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                ],
                                Text(
                                  'Tháng $m',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color:
                                        isSelected ? Colors.white : textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // 4. Pill Action Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                            shape: const StadiumBorder(),
                            side: BorderSide(color: borderTile),
                          ),
                          child: Text(
                            'Hủy',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primary, secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.28),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                Navigator.of(context).pop(
                                  DateTime(_selectedYear, _selectedMonth),
                                );
                              },
                              child: Center(
                                child: Text(
                                  'Áp dụng ($_selectedMonth/$_selectedYear)',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
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
        ),
      ),
    );
  }
}

class _QuickMonthChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickMonthChip({
    required this.label,
    required this.selected,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: isDark ? 0.24 : 0.14)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(999),
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
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: selected
                ? primary
                : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }
}

class _YearStepBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final Color color;
  final Color textSecondary;
  final VoidCallback onTap;

  const _YearStepBtn({
    required this.icon,
    required this.enabled,
    required this.color,
    required this.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 28,
        height: 28,
        child: Icon(
          icon,
          size: 19,
          color: enabled ? color : textSecondary.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
