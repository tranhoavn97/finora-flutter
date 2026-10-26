import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FilterResult {
  final String owner; // 'all', 'husband', 'wife'
  final String type; // 'all', 'income', 'expense', 'investment'
  final String query;
  final String category;
  final String timeRange; // 'all', 'today', 'yesterday', 'this_week', 'this_month', 'this_year', 'custom'
  final int? selectedMonth;
  final int? selectedYear;
  final DateTime? customDate;

  const FilterResult({
    this.owner = 'all',
    this.type = 'all',
    this.query = '',
    this.category = 'all',
    this.timeRange = 'all',
    this.selectedMonth,
    this.selectedYear,
    this.customDate,
  });
}

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

  static Future<FilterResult?> show(BuildContext context, {
    required FilterResult initialFilter,
    List<String> categories = const [],
  }) {
    return showModalBottomSheet<FilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransactionFilterSheet(
        initialFilter: initialFilter,
        categories: categories,
        onApply: (res) => Navigator.pop(ctx, res),
      ),
    );
  }

  @override
  State<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  late String _owner;
  late String _type;
  late TextEditingController _searchCtrl;
  late String _timeRange;
  late String _category;
  int? _selectedMonth;
  int? _selectedYear;
  DateTime? _customDate;

  @override
  void initState() {
    super.initState();
    _owner = widget.initialFilter.owner;
    _type = widget.initialFilter.type;
    _searchCtrl = TextEditingController(text: widget.initialFilter.query);
    _timeRange = widget.initialFilter.timeRange;
    _category = widget.initialFilter.category;
    _selectedMonth = widget.initialFilter.selectedMonth;
    _selectedYear = widget.initialFilter.selectedYear;
    _customDate = widget.initialFilter.customDate;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _owner = 'all';
      _type = 'all';
      _searchCtrl.clear();
      _timeRange = 'all';
      _category = 'all';
      _selectedMonth = null;
      _selectedYear = null;
      _customDate = null;
    });
  }

  void _openCalendar() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _customDate = picked;
        _timeRange = 'custom';
        _selectedMonth = null;
        _selectedYear = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final now = DateTime.now();

    // Generate recent 6 months
    final recentMonths = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      return {
        'month': d.month,
        'year': d.year,
        'label': i == 0 ? 'Tháng này' : 'Tháng ${d.month}/${d.year}'
      };
    });

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
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
        child: Column(
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

            // Header: Title + Reset Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bộ lọc giao dịch',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                TextButton(
                  onPressed: _reset,
                  child: const Text(
                    'Đặt lại',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section 1: PHẠM VI THÀNH VIÊN
                    _buildSectionHeader('PHẠM VI THÀNH VIÊN', isDark),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildPill('Tất cả', _owner == 'all', () => setState(() => _owner = 'all'), isDark)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildPill('Chồng', _owner == 'husband', () => setState(() => _owner = 'husband'), isDark)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildPill('Vợ', _owner == 'wife', () => setState(() => _owner = 'wife'), isDark)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Section 2: LOẠI GIAO DỊCH
                    _buildSectionHeader('LOẠI GIAO DỊCH', isDark),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildPill('Tất cả', _type == 'all', () => setState(() => _type = 'all'), isDark, isGradient: true)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildPill('Thu', _type == 'income', () => setState(() => _type = 'income'), isDark)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildPill('Chi', _type == 'expense', () => setState(() => _type = 'expense'), isDark)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildPill('Đầu tư', _type == 'investment', () => setState(() => _type = 'investment'), isDark)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildSectionHeader('DANH MỤC', isDark),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        _buildTimePillCustom('Tất cả', _category == 'all',
                            () => setState(() => _category = 'all'), isDark),
                        for (final category in widget.categories) ...[
                          const SizedBox(width: 8),
                          _buildTimePillCustom(category, _category == category,
                              () => setState(() => _category = category), isDark),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // Section 3: SEARCH BOX
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Tìm theo ghi chú, danh mục...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          ),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF3B82F6)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 4: THỜI GIAN
                    _buildSectionHeader('THỜI GIAN', isDark),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTimePill('Tất cả', 'all', isDark),
                          const SizedBox(width: 8),
                          _buildTimePill('Hôm nay', 'today', isDark),
                          const SizedBox(width: 8),
                          _buildTimePill('Hôm qua', 'yesterday', isDark),
                          const SizedBox(width: 8),
                          _buildTimePill('Tuần này', 'this_week', isDark),
                          const SizedBox(width: 8),
                          _buildTimePill('Tháng này', 'this_month', isDark),
                          const SizedBox(width: 8),
                          _buildTimePill('Năm nay', 'this_year', isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 5: CHỌN NHANH THÁNG
                    _buildSectionHeader('CHỌN NHANH THÁNG', isDark),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: recentMonths.map((m) {
                          final isSelected = _selectedMonth == m['month'] && _selectedYear == m['year'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildMonthPill(
                              m['label'] as String,
                              isSelected,
                              () {
                                setState(() {
                                  _selectedMonth = m['month'] as int;
                                  _selectedYear = m['year'] as int;
                                  _timeRange = 'month_select';
                                  _customDate = null;
                                });
                              },
                              isDark,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 6: TÙY CHỌN NGÀY CỤ THỂ
                    _buildSectionHeader('TÙY CHỌN NGÀY CỤ THỂ', isDark),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _openCalendar,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _customDate != null
                                ? const Color(0xFF3B82F6)
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined, color: Color(0xFF64748B), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _customDate != null
                                    ? 'Ngày: ${DateFormat('dd/MM/yyyy').format(_customDate!)}'
                                    : 'Chọn ngày cụ thể trên lịch...',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: _customDate != null ? FontWeight.w800 : FontWeight.w600,
                                  color: _customDate != null
                                      ? const Color(0xFF3B82F6)
                                      : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Apply Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(FilterResult(
                    owner: _owner,
                    type: _type,
                    query: _searchCtrl.text.trim(),
                    category: _category,
                    timeRange: _timeRange,
                    selectedMonth: _selectedMonth,
                    selectedYear: _selectedYear,
                    customDate: _customDate,
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.4),
                ),
                child: const Text(
                  'Áp dụng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: isDark ? Colors.white54 : const Color(0xFF64748B),
      ),
    );
  }

  Widget _buildTimePillCustom(
      String label, bool selected, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2563EB)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected
              ? const Color(0xFF2563EB)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
          fontWeight: FontWeight.w700,
        )),
      ),
    );
  }

  Widget _buildPill(String text, bool active, VoidCallback onTap, bool isDark, {bool isGradient = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? (isGradient ? const Color(0xFF2563EB) : (isDark ? const Color(0xFF334155) : const Color(0xFF1E293B)))
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active
                ? Colors.transparent
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

  Widget _buildTimePill(String text, String range, bool isDark) {
    final active = _timeRange == range;
    return GestureDetector(
      onTap: () {
        setState(() {
          _timeRange = range;
          _selectedMonth = null;
          _selectedYear = null;
          _customDate = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF2563EB)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active
                ? const Color(0xFF2563EB)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
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
    );
  }

  Widget _buildMonthPill(String label, bool active, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF2563EB)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active
                ? const Color(0xFF2563EB)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }
}
