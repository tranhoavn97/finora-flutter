import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Hộp thoại chọn Tháng / Năm phong cách Apple iOS (CupertinoWheelPicker)
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
    return showCupertinoModalPopup<DateTime>(
      context: context,
      barrierDismissible: true,
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
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialDate.month;
    _selectedYear = widget.initialDate.year;

    _monthController =
        FixedExtentScrollController(initialItem: _selectedMonth - 1);
    _yearController =
        FixedExtentScrollController(initialItem: _selectedYear - widget.minYear);
  }

  @override
  void dispose() {
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final headerBorderColor =
        isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    final totalYears = widget.maxYear - widget.minYear + 1;

    return Container(
      height: 330,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Apple drag pill indicator
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(99),
              ),
            ),

            // Top Bar: [ Hủy ] ---- [ Chọn tháng ] ---- [ Xong ]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Hủy',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    'Chọn tháng',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    onPressed: () {
                      Navigator.of(context).pop(DateTime(_selectedYear, _selectedMonth));
                    },
                    child: const Text(
                      'Xong',
                      style: TextStyle(
                        color: Color(0xFF007AFF), // Apple iOS Blue
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: headerBorderColor),

            // Dual Wheel Picker: [ Tháng 1 .. 12 ] & [ 2020 .. 2035 ]
            Expanded(
              child: Stack(
                children: [
                  // Center selection indicator overlay (Apple glass row)
                  Center(
                    child: Container(
                      height: 42,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFF007AFF).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : const Color(0xFF007AFF).withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      // Month Wheel
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: _monthController,
                          itemExtent: 42,
                          selectionOverlay: const SizedBox.shrink(),
                          onSelectedItemChanged: (index) {
                            setState(() => _selectedMonth = index + 1);
                          },
                          children: List.generate(12, (index) {
                            final m = index + 1;
                            final isSel = _selectedMonth == m;
                            return Center(
                              child: Text(
                                'Tháng $m',
                                style: TextStyle(
                                  fontSize: isSel ? 18.5 : 16.5,
                                  fontWeight:
                                      isSel ? FontWeight.w700 : FontWeight.w400,
                                  color: isSel
                                      ? (isDark ? Colors.white : const Color(0xFF007AFF))
                                      : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      // Year Wheel
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: _yearController,
                          itemExtent: 42,
                          selectionOverlay: const SizedBox.shrink(),
                          onSelectedItemChanged: (index) {
                            setState(() => _selectedYear = widget.minYear + index);
                          },
                          children: List.generate(totalYears, (index) {
                            final y = widget.minYear + index;
                            final isSel = _selectedYear == y;
                            return Center(
                              child: Text(
                                '$y',
                                style: TextStyle(
                                  fontSize: isSel ? 18.5 : 16.5,
                                  fontWeight:
                                      isSel ? FontWeight.w700 : FontWeight.w400,
                                  color: isSel
                                      ? (isDark ? Colors.white : const Color(0xFF007AFF))
                                      : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
