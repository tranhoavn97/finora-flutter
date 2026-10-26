import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/design_system/v8/finora_v8.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/bank_icon.dart';
import '../../data/models/category.dart';
import '../../data/services/supabase_bridge.dart';
import '../../state/more_provider.dart';
import '../../state/transaction_provider.dart';
import '../../core/utils/date_filter.dart';
import '../../core/widgets/cupertino_month_year_picker.dart';
import '../../domain/finance/finance_summary.dart';
import '../transaction/transaction_history_sheet.dart';

/// Parses a "#RRGGBB" / "#AARRGGBB" hex string into a [Color], or null.
Color? _parseHexColor(String? hex) {
  if (hex == null) return null;
  var clean = hex.trim().replaceFirst('#', '');
  if (clean.length == 6) clean = 'FF$clean';
  if (clean.length != 8) return null;
  final value = int.tryParse(clean, radix: 16);
  if (value == null) return null;
  return Color(value);
}

bool _matchesGroup(Category cat, String group) {
  if (group == 'all') return true;
  if (group == 'investment') {
    return cat.categoryGroup == 'investment' || cat.categoryGroup == 'saving';
  }
  return cat.categoryGroup == group;
}

/// Category management page — custom + default categories grouped by type.
class CategoryScreen extends StatefulWidget {
  final String userId;
  const CategoryScreen({super.key, required this.userId});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  StreamSubscription<String>? _eventsSub;
  String _group = 'all'; // all | expense | income | investment
  DateTime _currentMonth = DateTime.now();
  String _statusFilter = 'all'; // 'all' | 'used'
  bool _isListView = false; // Toggle between Grid & List view
  bool _isSearching = false; // Search expansion toggle
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _restoreViewSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<MoreProvider>();
      provider.load(widget.userId);
      context.read<TransactionProvider>().load(widget.userId);
      _eventsSub = provider.events.listen((msg) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(msg)));
      });
    });
  }

  Future<void> _restoreViewSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final prefix = 'category_view_${widget.userId}';
    setState(() {
      _group = prefs.getString('${prefix}_group') ?? _group;
      _statusFilter = prefs.getString('${prefix}_status') ?? _statusFilter;
      _isListView = prefs.getBool('${prefix}_list') ?? _isListView;
      final month = prefs.getInt('${prefix}_month');
      if (month != null)
        _currentMonth = DateTime.fromMillisecondsSinceEpoch(month);
    });
  }

  Future<void> _saveViewSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'category_view_${widget.userId}';
    await prefs.setString('${prefix}_group', _group);
    await prefs.setString('${prefix}_status', _statusFilter);
    await prefs.setBool('${prefix}_list', _isListView);
    await prefs.setInt('${prefix}_month', _currentMonth.millisecondsSinceEpoch);
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickMonthYear() async {
    final picked = await CupertinoMonthYearPickerSheet.show(
      context,
      initialDate: _currentMonth,
      minYear: 2020,
      maxYear: 2035,
    );
    if (picked != null) {
      setState(() {
        _currentMonth = DateTime(picked.year, picked.month);
      });
      _saveViewSettings();
    }
  }

  void _openAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCategoryModal(
        userId: widget.userId,
        defaultGroup: _group == 'investment' ? 'investment' : _group,
      ),
    );
  }

  void _openEdit(Category cat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCategoryModal(
          userId: widget.userId,
          defaultGroup: cat.categoryGroup,
          existing: cat),
    );
  }

  void _showActions(Category cat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => GlassBottomSheet(
        radius: 28,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CategoryIconBadge(
                      icon: cat.icon,
                      categoryName: cat.name,
                      colorHex: cat.color,
                      size: 46,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cat.categoryGroup == 'income'
                                ? 'Danh mục thu nhập'
                                : (cat.categoryGroup == 'investment'
                                    ? 'Danh mục đầu tư'
                                    : 'Danh mục chi tiêu'),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  tileColor: const Color(0xFF007AFF)
                      .withValues(alpha: isDark ? 0.15 : 0.08),
                  leading:
                      const Icon(Icons.edit_rounded, color: Color(0xFF007AFF)),
                  title: const Text(
                    'Chỉnh sửa danh mục',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: Color(0xFF007AFF)),
                  ),
                  subtitle: const Text('Thay đổi tên, icon hoặc màu sắc'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openEdit(cat);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  leading: Icon(Icons.receipt_long_rounded,
                      color: isDark ? Colors.white70 : const Color(0xFF475569)),
                  title: Text(
                    'Xem lịch sử giao dịch',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                  subtitle: const Text('Các khoản chi gắn với danh mục này'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showHistory(cat);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  leading: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444)),
                  title: const Text(
                    'Xóa danh mục',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Color(0xFFEF4444)),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _confirmDelete(cat);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(Category cat) async {
    final confirm = await showConfirmDeleteDialog(
      context: context,
      title: 'Xóa danh mục?',
      content: "Bạn có chắc chắn muốn xóa danh mục '${cat.name}' không?",
    );
    if (confirm && mounted) {
      context.read<MoreProvider>().deleteCategory(widget.userId, cat.id);
    }
  }

  void _showHistory(Category category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.90,
        child: TransactionHistorySheet(
          userId: widget.userId,
          categoryId: category.id,
          categoryName: category.name,
          categoryIcon: category.icon,
          categoryColor: category.color,
          categoryGroup: category.categoryGroup,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final provider = context.watch<MoreProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final targetMonthKey =
        '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}';

    // Aggregate by categoryId (with fallback to name) for targetMonthKey
    final categoryTotals = <String, int>{};
    final categoryCounts = <String, int>{};
    for (final tx in txProvider.transactions) {
      if (monthKeyOf(tx.date) != targetMonthKey) continue;
      final belongsToGroup = switch (_group) {
        'income' => FinanceSummary.isIncome(tx),
        'investment' => tx.type == 'investment' || tx.type == 'saving',
        _ => FinanceSummary.isExpense(tx),
      };
      if (!belongsToGroup) continue;

      for (final c in provider.categories) {
        if ((tx.categoryId != null && tx.categoryId == c.id) ||
            (tx.categoryId == null &&
                tx.categoryName != null &&
                tx.categoryName!.trim().toLowerCase() ==
                    c.name.trim().toLowerCase())) {
          categoryTotals[c.id] = (categoryTotals[c.id] ?? 0) + tx.amount;
          categoryCounts[c.id] = (categoryCounts[c.id] ?? 0) + 1;
        }
      }
    }

    final query = _searchController.text.trim().toLowerCase();
    final customFiltered = provider.categories.where((cat) {
      if (!_matchesGroup(cat, _group)) return false;
      if (query.isNotEmpty && !cat.name.toLowerCase().contains(query))
        return false;
      if (_statusFilter == 'used') {
        final count = categoryCounts[cat.id] ?? 0;
        if (count == 0) return false;
      }
      return true;
    }).toList();

    return GlassScaffold(
      appBar: GlassTopBar(
        title: 'Danh mục',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Liquid Glass Tab Bar (Chi tiêu | Thu nhập | Đầu tư)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _buildLiquidGlassTabBar(isDark),
          ),

          // 2. Control Bar (Tháng 9/2026, Tất cả / Đã dùng, Tìm kiếm, Thêm danh mục)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _buildUnifiedControlBar(
                isDark, primaryTextColor, secondaryTextColor),
          ),

          // Search Field expansion (if search active)
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _buildSearchExpandedBar(
                  isDark, primaryTextColor, secondaryTextColor),
            ),

          const SizedBox(height: 14),

          // 3. Category Items (Grid or List View)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
              children: [
                if (customFiltered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.category_outlined,
                              size: 48,
                              color: secondaryTextColor.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'Chưa có danh mục nào',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Bấm nút (+) để thêm danh mục mới',
                            style: TextStyle(
                              fontSize: 13,
                              color: secondaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _openAdd,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Thêm danh mục'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007AFF),
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_isListView)
                  _buildCategoryListView(
                    customFiltered,
                    categoryTotals,
                    categoryCounts,
                    isDark,
                    primaryTextColor,
                    secondaryTextColor,
                  )
                else
                  _CategoryGrid(
                    categories: customFiltered,
                    totals: categoryTotals,
                    counts: categoryCounts,
                    isDefault: false,
                    onTapItem: _showActions,
                    onEditItem: _openEdit,
                    onLongPressItem: _showActions,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Liquid Glass Tab Bar [Tất cả | Chi tiêu | Thu nhập | Đầu tư]
  Widget _buildLiquidGlassTabBar(bool isDark) {
    const groups = ['all', 'expense', 'income', 'investment'];
    final idx = groups.indexOf(_group);
    return BouncyPillTabs(
        height: 38,
        labels: const ['Tất cả', 'Chi tiêu', 'Thu nhập', 'Đầu tư'],
        selectedIndex: idx < 0 ? 0 : idx,
        colors: const [
          Color(0xFF475569), // Tất cả - Slate
          Color(0xFFE11D48), // Chi tiêu - Rose Red
          Color(0xFF059669), // Thu nhập - Emerald Green
          Color(0xFFD97706), // Đầu tư - Amber
        ],
        onChanged: (index) {
          setState(() => _group = groups[index]);
          _saveViewSettings();
        });
  }

  /// 2. Single-row compact toolbar: Month picker, Status filter, Search, Grid/List view, and '+ Thêm' button.
  Widget _buildUnifiedControlBar(
      bool isDark, Color primaryTextColor, Color secondaryTextColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // Month picker
          InkWell(
            onTap: _pickMonthYear,
            borderRadius: BorderRadius.circular(100),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_month_rounded,
                      size: 15, color: Color(0xFF005FEA)),
                  const SizedBox(width: 5),
                  Text(
                    'T${_currentMonth.month}/${_currentMonth.year}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 15, color: secondaryTextColor),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Status filter toggle (Tất cả / Đã dùng)
          Container(
            height: 36,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusPill('all', 'Tất cả', isDark),
                _buildStatusPill('used', 'Đã dùng', isDark),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Search button
          InkWell(
            onTap: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchController.clear();
              });
            },
            borderRadius: BorderRadius.circular(100),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _isSearching || _searchController.text.isNotEmpty
                    ? const Color(0xFF005FEA).withValues(alpha: 0.15)
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isSearching || _searchController.text.isNotEmpty
                      ? const Color(0xFF005FEA)
                      : (isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0)),
                ),
              ),
              child: const Icon(Icons.search_rounded,
                  size: 17, color: Color(0xFF005FEA)),
            ),
          ),
          const SizedBox(width: 6),

          // Grid/List toggle button
          InkWell(
            onTap: () {
              setState(() => _isListView = !_isListView);
              _saveViewSettings();
            },
            borderRadius: BorderRadius.circular(100),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Icon(
                _isListView ? Icons.grid_view_rounded : Icons.view_list_rounded,
                size: 17,
                color: secondaryTextColor,
              ),
            ),
          ),
          const SizedBox(width: 6),

          FinoraSectionAddButton(
            onTap: _openAdd,
            label: 'Thêm',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String key, String label, bool isDark) {
    final isSelected = _statusFilter == key;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() => _statusFilter = key);
        _saveViewSettings();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2C2C34) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  /// Search Field expanded view
  Widget _buildSearchExpandedBar(
      bool isDark, Color primaryTextColor, Color secondaryTextColor) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF007AFF).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 18, color: Color(0xFF007AFF)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(fontSize: 13.5, color: primaryTextColor),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tên danh mục...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: secondaryTextColor.withValues(alpha: 0.6),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {});
              },
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    size: 12, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  /// Category List View mode
  Widget _buildCategoryListView(
    List<Category> categories,
    Map<String, int> totals,
    Map<String, int> counts,
    bool isDark,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return Column(
      children: [
        for (final cat in categories) ...[
          _CategoryListTile(
            category: cat,
            amount: totals[cat.id] ?? 0,
            count: counts[cat.id] ?? 0,
            isDark: isDark,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            onTap: () => _showActions(cat),
            onEdit: () => _openEdit(cat),
            onLongPress: () => _showActions(cat),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Category List Item (List View Mode)
class _CategoryListTile extends StatelessWidget {
  final Category category;
  final int amount;
  final int count;
  final bool isDark;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onLongPress;

  const _CategoryListTile({
    required this.category,
    required this.amount,
    required this.count,
    required this.isDark,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.onTap,
    required this.onEdit,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final tint = _parseHexColor(category.color) ?? const Color(0xFF007AFF);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFF1F5F9),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Circular Glass Icon Badge
            CategoryIconBadge(
              icon: category.icon,
              categoryName: category.name,
              colorHex: category.color,
              size: 44,
              isDark: isDark,
            ),
            const SizedBox(width: 12),

            // Category Name & Transaction count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: primaryTextColor,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    count > 0 ? '$count giao dịch' : 'Chưa có giao dịch',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: secondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Total Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount > 0 ? formatVND(amount) : 'Chưa chi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: amount > 0
                        ? tint
                        : secondaryTextColor.withValues(alpha: 0.6),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Chỉnh sửa danh mục',
              onPressed: onEdit,
              icon: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF007AFF).withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  size: 15,
                  color: Color(0xFF007AFF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 2-column grid of category tiles using [Wrap].
class _CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final Map<String, int> totals;
  final Map<String, int> counts;
  final bool isDefault;
  final ValueChanged<Category> onTapItem;
  final ValueChanged<Category> onEditItem;
  final ValueChanged<Category> onLongPressItem;

  const _CategoryGrid({
    required this.categories,
    required this.totals,
    required this.counts,
    required this.isDefault,
    required this.onTapItem,
    required this.onEditItem,
    required this.onLongPressItem,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final tileWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final cat in categories)
              SizedBox(
                width: tileWidth,
                child: _CategoryTile(
                  category: cat,
                  amount: totals[cat.id] ?? 0,
                  count: counts[cat.id] ?? 0,
                  isDefault: isDefault,
                  onTap: () => onTapItem(cat),
                  onEdit: () => onEditItem(cat),
                  onLongPress: () => onLongPressItem(cat),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Circular Glass Category Card (Grid View Mode)
class _CategoryTile extends StatelessWidget {
  final Category category;
  final int amount;
  final int count;
  final bool isDefault;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onLongPress;

  const _CategoryTile({
    required this.category,
    this.amount = 0,
    this.count = 0,
    required this.isDefault,
    required this.onTap,
    required this.onEdit,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final tint = _parseHexColor(category.color) ?? const Color(0xFF007AFF);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFF1F5F9),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Circular Glass Icon Badge
                    CategoryIconBadge(
                      icon: category.icon,
                      categoryName: category.name,
                      colorHex: category.color,
                      size: 44,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (amount > 0)
                      Text(
                        formatVND(amount),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: tint,
                        ),
                      )
                    else
                      Text(
                        'Chưa chi',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: secondaryTextColor.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: IconButton(
                  tooltip: 'Chỉnh sửa danh mục',
                  onPressed: onEdit,
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF007AFF).withValues(alpha: 0.12),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: Color(0xFF007AFF),
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
}

/// Modal thêm danh mục mới chuẩn Apple iOS sang trọng
class AddCategoryModal extends StatefulWidget {
  final String userId;
  final String defaultGroup;
  final Category? existing;

  const AddCategoryModal({
    super.key,
    required this.userId,
    required this.defaultGroup,
    this.existing,
  });

  @override
  State<AddCategoryModal> createState() => _AddCategoryModalState();
}

class _AddCategoryModalState extends State<AddCategoryModal> {
  final _nameController = TextEditingController();
  final _emojiController = TextEditingController(text: '🍔');
  late String _group;
  String _color = '#007AFF';
  String _iconType = 'lucide'; // 'lucide' | 'emoji'
  bool _isSaving = false;
  bool _isUploadingIcon = false;

  static const _popularEmojis = [
    // Ẩm thực & Đồ uống
    '🍜', '🍔', '☕', '🍕', '🍰', '🍺', '🥐', '🍎', '🥤', '🍣', '🍲', '🥦',
    // Mua sắm & Tiêu dùng
    '🛍️', '🛒', '👕', '👗', '👟', '🎁', '💎', '📦', '🏷️', '💄',
    // Đi lại & Xe cộ
    '🚗', '🛵', '🚲', '⛽', '🚌', '🚆', '✈️', '🚕', '🚢',
    // Nhà cửa & Tiện ích
    '🏠', '🏢', '⚡', '💧', '🔥', '🔧', '🛋️', '🧹', '🚪',
    // Giải trí & Đời sống
    '🎮', '🎬', '🎵', '📺', '🎧', '🎟️', '⚽', '🏋️', '🏖️',
    // Sức khỏe & Y tế
    '❤️', '💊', '🩺', '🩹', '🏥', '🧘', '🦷',
    // Giáo dục & Công việc
    '🎓', '📚', '📖', '💼', '💻', '📱', '📷', '🎨', '✏️',
    // Tài chính & Đầu tư
    '💰', '💳', '💵', '🪙', '📈', '🐷', '🏦', '🧾',
    // Gia đình & Thú cưng
    '👶', '🐶', '🐱', '🌸', '✨', '☀️', '🏆', '🔑', '🛡️',
  ];

  static const _colors = [
    '#007AFF',
    '#34C759',
    '#FF9500',
    '#FF2D55',
    '#AF52DE',
    '#5856D6',
    '#00C7BE',
    '#30B0C7',
    '#FF3B30',
    '#8E8E93',
  ];

  @override
  void initState() {
    super.initState();
    _group = widget.existing?.categoryGroup ?? widget.defaultGroup;
    if (widget.existing != null) {
      _nameController.text = widget.existing!.name;
      _emojiController.text = widget.existing!.icon;
      _color = widget.existing!.color ?? '#007AFF';
      if (categoryLucideIconKeys
          .contains(widget.existing!.icon.toLowerCase())) {
        _iconType = 'lucide';
      } else if (widget.existing!.icon.startsWith('http')) {
        _iconType = 'image';
      } else {
        _iconType = 'emoji';
      }
    }
    _nameController.addListener(() => setState(() {}));
    _emojiController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final emoji = _emojiController.text.trim();
      final now = DateTime.now().millisecondsSinceEpoch;
      final category = Category(
        id: widget.existing?.id ?? '',
        userId: widget.existing?.userId ?? widget.userId,
        name: name,
        icon: emoji.isEmpty ? '🍔' : emoji,
        color: _color,
        categoryGroup: _group,
        createdAt: widget.existing?.createdAt ?? now,
        isArchived: widget.existing?.isArchived ?? false,
        updatedAt: now,
      );
      final provider = context.read<MoreProvider>();
      if (widget.existing == null) {
        await provider.addCategory(widget.userId, category);
      } else {
        await provider.updateCategory(
            widget.userId, widget.existing!.id, category);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImageIcon() async {
    if (_isUploadingIcon) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 82,
    );
    if (picked == null || !mounted) return;
    final length = await picked.length();
    if (length > 2 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ảnh icon phải nhỏ hơn 2 MB.')),
        );
      }
      return;
    }

    setState(() => _isUploadingIcon = true);
    try {
      final url = await SupabaseBridge.uploadCategoryIcon(
        userId: widget.userId,
        image: picked,
      );
      if (url == null) throw StateError('Supabase Storage chưa được cấu hình.');
      if (!mounted) return;
      final resolvedUrl = url;
      setState(() {
        _emojiController.text = resolvedUrl;
        _iconType = 'image';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã chọn ảnh làm icon danh mục.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tải ảnh icon. Vui lòng thử lại.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingIcon = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final surfaceColor =
        isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF8FAFC);
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);
    final previewTint = _parseHexColor(_color) ?? const Color(0xFF007AFF);
    final previewEmoji = _emojiController.text.trim().isEmpty
        ? '🍔'
        : _emojiController.text.trim();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
            // Apple Drag Handle
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

            // Modal Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.existing == null
                              ? 'Thêm danh mục mới'
                              : 'Sửa danh mục',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tùy biến tên, biểu tượng và nhóm chi tiêu',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color:
                            isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: secondaryTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: borderColor),

            // Form Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Live Preview Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: previewTint.withValues(alpha: 0.15),
                              border: Border.all(
                                color: previewTint.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: previewTint.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Center(
                              child: CategoryIconWidget(
                                  icon: previewEmoji,
                                  size: 52,
                                  color: previewTint),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameController.text.trim().isEmpty
                                      ? 'Tên danh mục'
                                      : _nameController.text.trim(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _group == 'expense'
                                      ? 'Khoản Chi tiêu'
                                      : (_group == 'income'
                                          ? 'Khoản Thu nhập'
                                          : 'Khoản Đầu tư'),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: previewTint,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Input: Tên danh mục
                    Text(
                      'TÊN DANH MỤC',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: secondaryTextColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Center(
                        child: TextField(
                          controller: _nameController,
                          style: TextStyle(fontSize: 14.5, color: textColor),
                          decoration: InputDecoration(
                            hintText: 'Ví dụ: Ăn uống, Tiền điện, Cà phê...',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: secondaryTextColor.withValues(alpha: 0.6),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Nhóm danh mục (Segmented Control)
                    Text(
                      'NHÓM DANH MỤC',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: secondaryTextColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildModalSegmentedControl(isDark),
                    const SizedBox(height: 20),

                    // Chọn Biểu tượng (Web Icons / Emoji)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CHỌN BIỂU TƯỢNG',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: secondaryTextColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _iconType = 'lucide'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _iconType == 'lucide'
                                        ? const Color(0xFF005FEA)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    'Web Icons',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _iconType == 'lucide'
                                          ? Colors.white
                                          : secondaryTextColor,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _iconType = 'emoji'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _iconType == 'emoji'
                                        ? const Color(0xFF005FEA)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    'Emoji',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _iconType == 'emoji'
                                          ? Colors.white
                                          : secondaryTextColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          shape: const StadiumBorder(),
                          foregroundColor: const Color(0xFF059669),
                          side: const BorderSide(color: Color(0xFF10B981)),
                        ),
                        onPressed: _isUploadingIcon ? null : _pickImageIcon,
                        icon: _isUploadingIcon
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF059669),
                                ),
                              )
                            : const Icon(Icons.add_photo_alternate_rounded),
                        label: Text(_isUploadingIcon
                            ? 'Đang tải ảnh...'
                            : _iconType == 'image'
                                ? 'Đổi ảnh icon'
                                : 'Chọn ảnh làm icon'),
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (_iconType == 'image')
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            CategoryIconWidget(
                              icon: previewEmoji,
                              size: 52,
                              color: previewTint,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Ảnh được cắt tròn và đồng bộ trên web lẫn ứng dụng.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_iconType == 'lucide')
                      SizedBox(
                        height: 180,
                        child: GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: categoryLucideIconKeys.length,
                          itemBuilder: (context, idx) {
                            final key = categoryLucideIconKeys[idx];
                            final isSelected =
                                previewEmoji.toLowerCase() == key.toLowerCase();
                            final iconData = categoryLucideIcons[key] ??
                                Icons.category_rounded;
                            return GestureDetector(
                              onTap: () => _emojiController.text = key,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? previewTint.withValues(alpha: 0.18)
                                      : surfaceColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color:
                                        isSelected ? previewTint : borderColor,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    iconData,
                                    size: 20,
                                    color: isSelected
                                        ? previewTint
                                        : (isDark
                                            ? Colors.white70
                                            : const Color(0xFF475569)),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      SizedBox(
                        height: 180,
                        child: GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: _popularEmojis.length,
                          itemBuilder: (context, idx) {
                            final emoji = _popularEmojis[idx];
                            final isSelected = previewEmoji == emoji;
                            return GestureDetector(
                              onTap: () => _emojiController.text = emoji,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? previewTint.withValues(alpha: 0.18)
                                      : surfaceColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color:
                                        isSelected ? previewTint : borderColor,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(emoji,
                                      style: const TextStyle(fontSize: 18)),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Chọn màu đại diện
                    Text(
                      'MÀU ĐẠI DIỆN',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: secondaryTextColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        for (final hex in _colors)
                          GestureDetector(
                            onTap: () => setState(() => _color = hex),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _parseHexColor(hex) ??
                                    const Color(0xFF007AFF),
                                border: Border.all(
                                  color: _color == hex
                                      ? (isDark ? Colors.white : Colors.black87)
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_parseHexColor(hex) ??
                                            const Color(0xFF007AFF))
                                        .withValues(alpha: 0.3),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom Button
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF007AFF), Color(0xFF0051D4)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF007AFF).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _isSaving ? null : _submit,
                    child: Center(
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Lưu danh mục',
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

  Widget _buildModalSegmentedControl(bool isDark) {
    const groups = ['expense', 'income', 'investment'];
    return BouncyPillTabs(
        labels: const ['Chi tiêu', 'Thu nhập', 'Đầu tư'],
        selectedIndex: groups.indexOf(_group),
        colors: const [Color(0xFF2563EB), Color(0xFF059669), Color(0xFF8B5CF6)],
        onChanged: (index) => setState(() => _group = groups[index]));
  }
}
