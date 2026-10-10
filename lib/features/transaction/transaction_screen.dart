import '../../core/widgets/finora_summary_card.dart';
import '../../core/widgets/ai_context_button.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/utils/date_filter.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../../state/transaction_provider.dart';
import '../../state/theme_studio_controller.dart';
import '../../data/services/wallet_repository.dart';
import 'add_transaction_page.dart';
import 'transaction_detail_screen.dart';

/// Redesigned Transaction History Screen:
/// - Luxury Obsidian & Royal Indigo compact Spending Card (clean, elegant, non-green)
/// - Streamlined dual-badge income/expense ribbon saving vertical height
/// - Quick calendar selector right inside the card header
/// - Sleek pill search bar and high-end filter pills
/// - Date-grouped transaction list with clear tags (Husband = sky blue, Wife = pink, Wallet = purple)
class TransactionScreen extends StatefulWidget {
  final String userId;
  final String? familyId;
  final VoidCallback? onBack;

  const TransactionScreen({
    super.key,
    required this.userId,
    this.familyId,
    this.onBack,
  });

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  bool _showBalances = true;
  bool _isSearchExpanded = false;
  late final TextEditingController _searchController;
  final ScrollController _typeScrollController = ScrollController();
  StreamSubscription<String>? _eventsSub;

  @override
  void initState() {
    super.initState();
    final initialQuery = context.read<TransactionProvider>().searchQuery;
    _isSearchExpanded = initialQuery.isNotEmpty;
    _searchController = TextEditingController(text: initialQuery);
    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<TransactionProvider>();
      provider.load(widget.userId, familyId: widget.familyId);
      _eventsSub = provider.events.listen((msg) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(msg)));
      });
    });
  }

  void _onSearchChanged() {
    context.read<TransactionProvider>().setSearchQuery(_searchController.text);
  }

  void _scrollToType(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_typeScrollController.hasClients) return;
      final targetOffset = (index * 58.0 - 24.0)
          .clamp(0.0, _typeScrollController.position.maxScrollExtent);
      _typeScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _typeScrollController.dispose();
    _eventsSub?.cancel();
    super.dispose();
  }

  void _openAdd({TransactionModel? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            AddTransactionPage(userId: widget.userId, existing: existing),
      ),
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FilterSheet(),
    );
  }

  void _openOwnerFilterModal() {
    final provider = context.read<TransactionProvider>();
    final currentTag = provider.selectedMemberTag ?? 'all';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showFinoraGlassModalBottomSheet(
      context: context,
      showHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            6,
            20,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF005FEA).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.people_alt_rounded,
                          color: Color(0xFF005FEA),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Phân loại chi tiêu',
                        style: TextStyle(
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  FinoraIconAction(
                    icon: Icons.close_rounded,
                    label: 'Đóng',
                    size: 36,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildOwnerOption(
                ctx,
                key: 'all',
                title: 'Tất cả thành viên',
                subtitle: 'Xem toàn bộ giao dịch cả Vợ & Chồng',
                icon: Icons.groups_rounded,
                color: const Color(0xFF0284C7),
                isSelected: currentTag == 'all' || currentTag.isEmpty,
                onTap: () {
                  provider.setSelectedMemberTag(null);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 10),
              _buildOwnerOption(
                ctx,
                key: 'husband',
                title: 'Chồng chi tiêu',
                subtitle: 'Chỉ hiển thị các khoản của Chồng',
                icon: Icons.male_rounded,
                color: const Color(0xFF0284C7),
                isSelected: currentTag == 'husband',
                onTap: () {
                  provider.setSelectedMemberTag('husband');
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 10),
              _buildOwnerOption(
                ctx,
                key: 'wife',
                title: 'Vợ chi tiêu',
                subtitle: 'Chỉ hiển thị các khoản của Vợ',
                icon: Icons.female_rounded,
                color: const Color(0xFFDB2777),
                isSelected: currentTag == 'wife',
                onTap: () {
                  provider.setSelectedMemberTag('wife');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOwnerOption(
    BuildContext context, {
    required String key,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.18 : 0.08)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }

  void _openTransactionStyleModal() {
    final studio = context.read<ThemeStudioController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showFinoraGlassModalBottomSheet(
      context: context,
      showHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            6,
            20,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF005FEA).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.dashboard_customize_rounded,
                          color: Color(0xFF005FEA),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Kiểu danh sách giao dịch',
                        style: TextStyle(
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  FinoraIconAction(
                    icon: Icons.close_rounded,
                    label: 'Đóng',
                    size: 36,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildTransactionStyleOption(
                ctx,
                style: AppTransactionListStyle.modernStreamlined,
                title: 'Hiện đại luồng sáng (Modern Streamlined)',
                subtitle:
                    'Thẻ bo góc mềm mượt với icon gradient & chi tiết tinh gọn',
                icon: Icons.dashboard_rounded,
                currentStyle: studio.transactionListStyle,
                onTap: () {
                  studio.setTransactionListStyle(
                      AppTransactionListStyle.modernStreamlined);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
              _buildTransactionStyleOption(
                ctx,
                style: AppTransactionListStyle.magazineLedger,
                title: 'Tạp chí tài chính (Magazine Ledger)',
                subtitle:
                    'Định dạng tạp chí tài chính cao cấp với số dư & phân tách rõ nét',
                icon: Icons.auto_stories_rounded,
                currentStyle: studio.transactionListStyle,
                onTap: () {
                  studio.setTransactionListStyle(
                      AppTransactionListStyle.magazineLedger);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
              _buildTransactionStyleOption(
                ctx,
                style: AppTransactionListStyle.bentoCards,
                title: 'Thẻ Bento Glass',
                subtitle: 'Thẻ nổi hiệu ứng kính mờ & viền sáng sang trọng',
                icon: Icons.view_agenda_rounded,
                currentStyle: studio.transactionListStyle,
                onTap: () {
                  studio.setTransactionListStyle(
                      AppTransactionListStyle.bentoCards);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
              _buildTransactionStyleOption(
                ctx,
                style: AppTransactionListStyle.timelineRail,
                title: 'Trục thời gian (Timeline Rail)',
                subtitle: 'Dây nối thời gian với nút phát sáng theo luồng tiền',
                icon: Icons.timeline_rounded,
                currentStyle: studio.transactionListStyle,
                onTap: () {
                  studio.setTransactionListStyle(
                      AppTransactionListStyle.timelineRail);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
              _buildTransactionStyleOption(
                ctx,
                style: AppTransactionListStyle.compactTable,
                title: 'Bảng sao kê gọn (Compact Ledger)',
                subtitle: 'Mật độ cao kiểu sao kê ngân hàng, hiển thị tối đa',
                icon: Icons.table_rows_rounded,
                currentStyle: studio.transactionListStyle,
                onTap: () {
                  studio.setTransactionListStyle(
                      AppTransactionListStyle.compactTable);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
              _buildTransactionStyleOption(
                ctx,
                style: AppTransactionListStyle.minimalDivided,
                title: 'Tối giản đường kẻ (Minimal Divided)',
                subtitle: 'Thiết kế phẳng OneUI / HyperOS siêu thanh mảnh',
                icon: Icons.view_headline_rounded,
                currentStyle: studio.transactionListStyle,
                onTap: () {
                  studio.setTransactionListStyle(
                      AppTransactionListStyle.minimalDivided);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionStyleOption(
    BuildContext context, {
    required AppTransactionListStyle style,
    required String title,
    required String subtitle,
    required IconData icon,
    required AppTransactionListStyle currentStyle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = style == currentStyle;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF005FEA).withValues(alpha: isDark ? 0.18 : 0.08)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF005FEA)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isSelected
                        ? const Color(0xFF005FEA)
                        : const Color(0xFF64748B))
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF005FEA)
                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF005FEA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }

  void _openDateFilterModal() {
    final provider = context.read<TransactionProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showFinoraGlassModalBottomSheet(
      context: context,
      showHandle: true,
      builder: (ctx) {
        final activeLabel = provider.activeDateFilterLabel;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            6,
            20,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF005FEA).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Color(0xFF005FEA),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Chọn kỳ thời gian',
                        style: TextStyle(
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF005FEA).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          activeLabel,
                          style: const TextStyle(
                            color: Color(0xFF005FEA),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FinoraIconAction(
                        icon: Icons.close_rounded,
                        label: 'Đóng',
                        size: 36,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  DateFilterOption.today,
                  DateFilterOption.yesterday,
                  DateFilterOption.thisWeek,
                  DateFilterOption.lastWeek,
                  DateFilterOption.thisMonth,
                  DateFilterOption.lastMonth,
                  DateFilterOption.thisYear,
                  DateFilterOption.allTime,
                ].map((opt) {
                  final isSelected = provider.selectedDateFilter == opt;
                  return ChoiceChip(
                    label: Text(opt.label),
                    selected: isSelected,
                    selectedColor: const Color(0xFF005FEA),
                    backgroundColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : const Color(0xFF334155)),
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100)),
                    onSelected: (_) {
                      provider.setSelectedDateFilter(opt);
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Custom Date Picker & Date Range Picker
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showFinoraDatePicker(
                          context: context,
                          initialDate: provider.customDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                          helpText: 'CHỌN NGÀY CỤ THỂ',
                        );
                        if (picked != null) {
                          provider.setCustomDate(picked);
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: provider.selectedDateFilter ==
                                  DateFilterOption.customDate
                              ? const Color(0xFF005FEA).withValues(alpha: 0.12)
                              : (isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: provider.selectedDateFilter ==
                                    DateFilterOption.customDate
                                ? const Color(0xFF005FEA)
                                : (isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0)),
                            width: provider.selectedDateFilter ==
                                    DateFilterOption.customDate
                                ? 1.5
                                : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event_rounded,
                                size: 18, color: Color(0xFF005FEA)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Tùy chọn ngày',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white60
                                          : const Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    provider.selectedDateFilter ==
                                                DateFilterOption.customDate &&
                                            provider.customDate != null
                                        ? '${provider.customDate!.day.toString().padLeft(2, '0')}/${provider.customDate!.month.toString().padLeft(2, '0')}/${provider.customDate!.year}'
                                        : 'Chọn ngày...',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
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
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final initialRange =
                            (provider.customStartDate != null &&
                                    provider.customEndDate != null)
                                ? DateTimeRange(
                                    start: provider.customStartDate!,
                                    end: provider.customEndDate!)
                                : DateTimeRange(
                                    start: DateTime.now()
                                        .subtract(const Duration(days: 7)),
                                    end: DateTime.now(),
                                  );
                        final range = await showFinoraDateRangePicker(
                          context: context,
                          initialDateRange: initialRange,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                          helpText: 'CHỌN TỪ NGÀY ĐẾN NGÀY',
                          saveText: 'CHỌN',
                        );
                        if (range != null) {
                          provider.setCustomRange(range.start, range.end);
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: provider.selectedDateFilter ==
                                  DateFilterOption.customRange
                              ? const Color(0xFF0284C7).withValues(alpha: 0.12)
                              : (isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: provider.selectedDateFilter ==
                                    DateFilterOption.customRange
                                ? const Color(0xFF0284C7)
                                : (isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0)),
                            width: provider.selectedDateFilter ==
                                    DateFilterOption.customRange
                                ? 1.5
                                : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.date_range_rounded,
                                size: 18, color: Color(0xFF0284C7)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Từ khoảng ngày',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white60
                                          : const Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    provider.selectedDateFilter ==
                                                DateFilterOption.customRange &&
                                            provider.customStartDate != null
                                        ? '${provider.customStartDate!.day.toString().padLeft(2, '0')}/${provider.customStartDate!.month.toString().padLeft(2, '0')} - ${provider.customEndDate?.day.toString().padLeft(2, '0')}/${provider.customEndDate?.month.toString().padLeft(2, '0')}'
                                        : 'Từ - Đến...',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
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
            ],
          ),
        );
      },
    );
  }

  DateTime _parseDate(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(
      timestamp > 100000000000 ? timestamp : timestamp * 1000,
    );
  }

  /// Resolves the corresponding BankBrand for a transaction from its wallet/bank
  BankBrand _resolveWalletBrand(TransactionModel tx, List<Wallet> wallets) {
    final targetWalletId = tx.walletId ?? tx.fromWalletId ?? tx.creditCardId;
    Wallet? matchingWallet;
    if (targetWalletId != null && targetWalletId.isNotEmpty) {
      matchingWallet = wallets.cast<Wallet?>().firstWhere(
            (w) => w?.id == targetWalletId,
            orElse: () => null,
          );
    }
    if (matchingWallet == null &&
        (tx.walletName != null || tx.fromWalletName != null)) {
      final matchName =
          (tx.walletName ?? tx.fromWalletName)!.trim().toLowerCase();
      matchingWallet = wallets.cast<Wallet?>().firstWhere(
            (w) =>
                w != null &&
                (w.name.trim().toLowerCase() == matchName ||
                    (w.bankName != null &&
                        w.bankName!.trim().toLowerCase() == matchName)),
            orElse: () => null,
          );
    }

    final code = matchingWallet?.bankCode;
    final name = matchingWallet?.bankName ??
        matchingWallet?.name ??
        tx.walletName ??
        tx.fromWalletName;
    return BankIconRegistry.resolve(code, bankName: name);
  }

  /// Groups transactions by formatted date with Vietnamese weekday (e.g. "Hôm nay, Thứ Sáu • 21/08/2026")
  Map<String, List<TransactionModel>> _groupTransactions(
      List<TransactionModel> txs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    const weekdays = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật'
    ];

    final map = <String, List<TransactionModel>>{};
    for (final tx in txs) {
      final d = _parseDate(tx.date);
      final dayStart = DateTime(d.year, d.month, d.day);
      final weekdayStr = weekdays[d.weekday - 1];
      final dateStr =
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

      String header;
      if (dayStart == today) {
        header = 'Hôm nay, $weekdayStr • $dateStr';
      } else if (dayStart == yesterday) {
        header = 'Hôm qua, $weekdayStr • $dateStr';
      } else {
        header = '$weekdayStr, $dateStr';
      }

      map.putIfAbsent(header, () => []).add(tx);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final provider = context.watch<TransactionProvider>();
    if (_searchController.text != provider.searchQuery) {
      _searchController.value = TextEditingValue(
        text: provider.searchQuery,
        selection: TextSelection.collapsed(offset: provider.searchQuery.length),
      );
    }
    final transactions = provider.filteredTransactions;

    // Period totals
    final periodIncome = transactions
        .where(
            (t) => {'income', 'borrowing', 'loan_repayment_received'}.contains(
                  WalletRepository.normalizeTransactionType(t.type),
                ))
        .fold<int>(0, (sum, t) => sum + t.amount);

    final periodExpense = transactions
        .where((t) => {'expense', 'loan', 'debt_repayment_paid'}.contains(
              WalletRepository.normalizeTransactionType(t.type),
            ))
        .fold<int>(0, (sum, t) => sum + t.amount);

    final selectedType = provider.selectedType;
    final selectedWalletId = provider.selectedWalletId;
    final selectedMemberTag = provider.selectedMemberTag;

    // Resolve wallet label
    String walletLabel = 'Tất cả ví';
    if (selectedWalletId != null) {
      final matched = provider.wallets.where((w) => w.id == selectedWalletId);
      if (matched.isNotEmpty) {
        walletLabel = matched.first.name;
      }
    }

    // Resolve member tag label
    String memberLabel = 'Vợ chồng';
    if (selectedMemberTag == 'husband') {
      memberLabel = 'Chồng';
    } else if (selectedMemberTag == 'wife') {
      memberLabel = 'Vợ';
    }

    final groupedMap = _groupTransactions(transactions);

    return GlassScaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassTopBar(
        title: 'Lịch sử giao dịch',
        showBottomDivider: false,
        showBack: false,
        onBack: null,
        actions: [AiContextButton(userId: widget.userId, screen: 'Giao dịch')],
      ),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // 1. Thẻ chi tiêu Obsidian & Deep Indigo Hero Card (Cuộn tự nhiên theo danh sách)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                14,
                GlassScaffold.topInset(context, 8),
                14,
                8,
              ),
              child: _buildCompactSpendingCard(
                periodExpense: periodExpense,
                periodIncome: periodIncome,
                dateLabel: provider.selectedDateFilter.label,
                isDark: isDark,
              ),
            ),
          ),

          // 2. Thanh tìm kiếm và bộ lọc (Cuộn tự nhiên theo danh sách)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
              child: _buildUnifiedToolbarRow(
                isDark: isDark,
                selectedType: selectedType,
                memberLabel: memberLabel,
                selectedMemberTag: selectedMemberTag,
                walletLabel: walletLabel,
                selectedWalletId: selectedWalletId,
                provider: provider,
              ),
            ),
          ),

          // 2. Grouped Transactions List
          if (transactions.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: EmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: 'Chưa có giao dịch nào',
                  subtitle: 'Hãy thêm giao dịch đầu tiên để quản lý chi tiêu.',
                  actionText: '+ Thêm giao dịch',
                  onAction: () => _openAdd(),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 130),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  groupedMap.entries.map((entry) {
                    final headerText = entry.key;
                    final dayTxs = entry.value;

                    // Calculate day totals
                    final dayIncome = dayTxs
                        .where((t) => {
                              'income',
                              'borrowing',
                              'loan_repayment_received'
                            }.contains(
                              WalletRepository.normalizeTransactionType(t.type),
                            ))
                        .fold<int>(0, (sum, t) => sum + t.amount);

                    final dayExpense = dayTxs
                        .where((t) =>
                            {'expense', 'loan', 'debt_repayment_paid'}.contains(
                              WalletRepository.normalizeTransactionType(t.type),
                            ))
                        .fold<int>(0, (sum, t) => sum + t.amount);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDayHeader(
                          headerText: headerText,
                          dayIncome: dayIncome,
                          dayExpense: dayExpense,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                        ...dayTxs.asMap().entries.map((txEntry) {
                          final txIdx = txEntry.key;
                          final tx = txEntry.value;
                          return _buildTransactionCard(
                            tx: tx,
                            isDark: isDark,
                            isFirstInDay: txIdx == 0,
                            isLastInDay: txIdx == dayTxs.length - 1,
                            onEdit: () => _openAdd(existing: tx),
                            onDelete: () async {
                              final confirm = await showConfirmDeleteDialog(
                                context: context,
                                title: 'Xóa giao dịch?',
                                content:
                                    'Bạn có chắc chắn muốn xóa giao dịch này không?',
                              );
                              if (confirm && mounted) {
                                if (!context.mounted) return;
                                context
                                    .read<TransactionProvider>()
                                    .deleteTransaction(widget.userId, tx);
                              }
                            },
                          );
                        }),
                        const SizedBox(height: 14),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Redesigned Cashflow & Spending Widget — Compact Pill Bar (~70px)
  Widget _buildCompactSpendingCard({
    required int periodExpense,
    required int periodIncome,
    required String dateLabel,
    required bool isDark,
  }) {
    final net = periodIncome - periodExpense;
    final isSurplus = net >= 0;
    return FinoraSummaryCard(
        title: 'DÒNG TIỀN RÒNG',
        masked: !_showBalances ||
            context.watch<ThemeStudioController>().isPrivacyShieldActive,
        amount: net,
        icon: Icons.swap_vert_rounded,
        accent: isSurplus ? const Color(0xFF007AFF) : const Color(0xFFFF3B30),
        subtitle: dateLabel,
        badgeText: isSurplus ? 'Thặng dư an toàn' : 'Thâm hụt chi',
        badgeColor:
            isSurplus ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
        metricColors: const [Color(0xFF34C759), Color(0xFFFF3B30)],
        metrics: [('Thu nhập', periodIncome), ('Chi tiêu', periodExpense)]);
  }

  /// Unified Single-Row Search, Type Switcher & Filter Toolbar
  /// Order: [ 6-type switcher ] [ 🔍 Search ] [ 👥 Member ] [ 🎚 Filter ]
  Widget _buildUnifiedToolbarRow({
    required bool isDark,
    required String? selectedType,
    required String memberLabel,
    required String? selectedMemberTag,
    required String walletLabel,
    required String? selectedWalletId,
    required TransactionProvider provider,
  }) {
    final hasActiveFilter =
        (selectedMemberTag != null && selectedMemberTag != 'all') ||
            selectedWalletId != null ||
            provider.selectedDateFilter != DateFilterOption.thisMonth;
    const typeValues = <String?>[
      null,
      'income',
      'expense',
      'transfer',
      'investment',
      'credit_card_payment'
    ];
    const typeLabels = ['Tất cả', 'Thu', 'Chi', 'Chuyển', 'Đầu tư', 'Trả thẻ'];
    const typeColors = [
      Color(0xFF005FEA),
      Color(0xFF059669),
      Color(0xFFDC2626),
      Color(0xFF0284C7),
      Color(0xFFD97706),
      Color(0xFF0891B2),
    ];
    final typeIndex = typeValues.indexOf(selectedType).clamp(0, 5);

    if (_isSearchExpanded) {
      return Row(
        children: [
          // Expanded Search Input
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF1E293B) : Colors.white)
                    .withValues(
                        alpha: context
                            .watch<ThemeStudioController>()
                            .glassOpacity),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: const Color(0xFF005FEA),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF005FEA).withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF005FEA),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Tìm kiếm ghi chú, danh mục, tiền...',
                        hintStyle: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      provider.setSearchQuery('');
                      setState(() => _isSearchExpanded = false);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Quick Member Filter Button (Icon only - 40x40 circle)
          GestureDetector(
            onTap: _openOwnerFilterModal,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (selectedMemberTag != null && selectedMemberTag != 'all')
                    ? (selectedMemberTag == 'wife'
                        ? const Color(0xFFDB2777).withValues(alpha: 0.14)
                        : const Color(0xFF0284C7).withValues(alpha: 0.14))
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color:
                      (selectedMemberTag != null && selectedMemberTag != 'all')
                          ? (selectedMemberTag == 'wife'
                              ? const Color(0xFFDB2777)
                              : const Color(0xFF0284C7))
                          : (isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0)),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  selectedMemberTag == 'wife'
                      ? Icons.female_rounded
                      : (selectedMemberTag == 'husband'
                          ? Icons.male_rounded
                          : Icons.people_alt_rounded),
                  size: 18,
                  color: selectedMemberTag == 'wife'
                      ? const Color(0xFFDB2777)
                      : (selectedMemberTag == 'husband'
                          ? const Color(0xFF0284C7)
                          : (isDark
                              ? Colors.white70
                              : const Color(0xFF64748B))),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Filter Button [ 🎚 ]
          GestureDetector(
            onTap: _openFilterSheet,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hasActiveFilter
                    ? const Color(0xFF005FEA)
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: hasActiveFilter
                      ? const Color(0xFF005FEA)
                      : (isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0)),
                  width: 1.2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: hasActiveFilter
                        ? Colors.white
                        : (isDark ? Colors.white70 : const Color(0xFF005FEA)),
                    size: 18,
                  ),
                  if (hasActiveFilter)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFBBF24),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          // List Style Switcher Button
          Builder(
            builder: (ctx) {
              final currentStyle =
                  ctx.watch<ThemeStudioController>().transactionListStyle;
              final styleIcon = switch (currentStyle) {
                AppTransactionListStyle.modernStreamlined =>
                  Icons.dashboard_rounded,
                AppTransactionListStyle.magazineLedger =>
                  Icons.auto_stories_rounded,
                AppTransactionListStyle.bentoCards => Icons.view_agenda_rounded,
                AppTransactionListStyle.timelineRail => Icons.timeline_rounded,
                AppTransactionListStyle.compactTable =>
                  Icons.table_rows_rounded,
                AppTransactionListStyle.minimalDivided =>
                  Icons.view_headline_rounded,
              };
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _openTransactionStyleModal();
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      styleIcon,
                      size: 18,
                      color: const Color(0xFF005FEA),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );
    }

    return Row(
      children: [
        // 1. Type Switcher [ Tất cả | Thu | Chi | Chuyển | Đầu tư | Trả thẻ ]
        Expanded(
          child: Container(
            height: 42,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF0F172A) : Colors.white)
                  .withValues(alpha: isDark ? 0.65 : 0.88),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : const Color(0xFFCBD5E1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: SingleChildScrollView(
                controller: _typeScrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    typeLabels.length,
                    (index) {
                      final isSelected = index == typeIndex;
                      return Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(100),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            provider.setSelectedType(typeValues[index]);
                            _scrollToType(index);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 13, vertical: 6.5),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? typeColors[index]
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: typeColors[index]
                                            .withValues(alpha: 0.35),
                                        blurRadius: 6,
                                        offset: const Offset(0, 1.5),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                typeLabels[index],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white70
                                          : const Color(0xFF64748B)),
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),

        // 2. Search Icon Button (placed to the right of tabs)
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _isSearchExpanded = true);
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF0F172A) : Colors.white)
                  .withValues(alpha: isDark ? 0.65 : 0.88),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: provider.searchQuery.isNotEmpty
                    ? const Color(0xFF005FEA)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.14)
                        : const Color(0xFFCBD5E1)),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.search_rounded,
              size: 19,
              color: provider.searchQuery.isNotEmpty
                  ? const Color(0xFF005FEA)
                  : (isDark ? Colors.white70 : const Color(0xFF64748B)),
            ),
          ),
        ),
        const SizedBox(width: 6),

        // 3. Member Filter Button [ 👥 / 👨 / 👩 ] (Icon only - circle, no text)
        GestureDetector(
          onTap: _openOwnerFilterModal,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (selectedMemberTag != null && selectedMemberTag != 'all')
                  ? (selectedMemberTag == 'wife'
                      ? const Color(0xFFDB2777).withValues(alpha: 0.18)
                      : const Color(0xFF0284C7).withValues(alpha: 0.18))
                  : (isDark ? const Color(0xFF0F172A) : Colors.white)
                      .withValues(alpha: isDark ? 0.65 : 0.88),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: (selectedMemberTag != null && selectedMemberTag != 'all')
                    ? (selectedMemberTag == 'wife'
                        ? const Color(0xFFDB2777)
                        : const Color(0xFF0284C7))
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.14)
                        : const Color(0xFFCBD5E1)),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                selectedMemberTag == 'wife'
                    ? Icons.female_rounded
                    : (selectedMemberTag == 'husband'
                        ? Icons.male_rounded
                        : Icons.people_alt_rounded),
                size: 18,
                color: selectedMemberTag == 'wife'
                    ? const Color(0xFFDB2777)
                    : (selectedMemberTag == 'husband'
                        ? const Color(0xFF0284C7)
                        : (isDark ? Colors.white70 : const Color(0xFF64748B))),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),

        // 4. Advanced Filter Button [ 🎚 ]
        GestureDetector(
          onTap: _openFilterSheet,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: hasActiveFilter
                  ? const Color(0xFF005FEA)
                  : (isDark ? const Color(0xFF0F172A) : Colors.white)
                      .withValues(alpha: isDark ? 0.65 : 0.88),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: hasActiveFilter
                    ? const Color(0xFF005FEA)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.14)
                        : const Color(0xFFCBD5E1)),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: hasActiveFilter
                      ? const Color(0xFF005FEA).withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: hasActiveFilter
                      ? Colors.white
                      : (isDark ? Colors.white70 : const Color(0xFF005FEA)),
                  size: 18,
                ),
                if (hasActiveFilter)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFBBF24), // Amber active dot
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),

        // 5. List Style Switcher Button [ 📑 ]
        Builder(
          builder: (ctx) {
            final currentStyle =
                ctx.watch<ThemeStudioController>().transactionListStyle;
            final styleIcon = switch (currentStyle) {
              AppTransactionListStyle.modernStreamlined =>
                Icons.dashboard_rounded,
              AppTransactionListStyle.magazineLedger =>
                Icons.auto_stories_rounded,
              AppTransactionListStyle.bentoCards => Icons.view_agenda_rounded,
              AppTransactionListStyle.timelineRail => Icons.timeline_rounded,
              AppTransactionListStyle.compactTable => Icons.table_rows_rounded,
              AppTransactionListStyle.minimalDivided =>
                Icons.view_headline_rounded,
            };
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _openTransactionStyleModal();
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF0F172A) : Colors.white)
                      .withValues(alpha: isDark ? 0.65 : 0.88),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.14)
                        : const Color(0xFFCBD5E1),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    styleIcon,
                    size: 18,
                    color: const Color(0xFF005FEA),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDayHeader({
    required String headerText,
    required int dayIncome,
    required int dayExpense,
    required bool isDark,
  }) {
    final isToday = headerText.startsWith('Hôm nay');

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Calendar Day Pill Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
            decoration: BoxDecoration(
              color: isToday
                  ? (isDark
                      ? const Color(0xFF005FEA).withValues(alpha: 0.22)
                      : const Color(0xFFE0F2FE))
                  : (isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isToday
                    ? const Color(0xFF005FEA).withValues(alpha: 0.35)
                    : (isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0)),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 11,
                  color: isToday
                      ? const Color(0xFF005FEA)
                      : (isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B)),
                ),
                const SizedBox(width: 6),
                Text(
                  headerText,
                  style: TextStyle(
                    color: isToday
                        ? const Color(0xFF005FEA)
                        : (isDark ? Colors.white : const Color(0xFF1E293B)),
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),

          // Right: Daily Inflow & Outflow Chips
          if (_showBalances && (dayIncome > 0 || dayExpense > 0))
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dayIncome > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669)
                          .withValues(alpha: isDark ? 0.18 : 0.10),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: const Color(0xFF059669).withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_downward_rounded,
                          size: 10,
                          color: Color(0xFF059669),
                        ),
                        const SizedBox(width: 2.5),
                        Text(
                          '+${formatVND(dayIncome)}',
                          style: const TextStyle(
                            color: Color(0xFF059669),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (dayExpense > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626)
                          .withValues(alpha: isDark ? 0.18 : 0.10),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_upward_rounded,
                          size: 10,
                          color: Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 2.5),
                        Text(
                          '-${formatVND(dayExpense)}',
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard({
    required TransactionModel tx,
    required bool isDark,
    bool isFirstInDay = false,
    bool isLastInDay = false,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final studio = context.watch<ThemeStudioController>();
    final cardRadius = studio.getCardRadius(studio.transactionDensity);
    final normType = WalletRepository.normalizeTransactionType(tx.type);
    final isInflow =
        {'income', 'borrowing', 'loan_repayment_received'}.contains(normType);
    final isTransfer = normType == 'transfer';

    final sign = isInflow ? '+' : (isTransfer ? '' : '-');
    final amountColor = isTransfer
        ? const Color(0xFF0284C7)
        : (isInflow ? const Color(0xFF059669) : const Color(0xFFDC2626));

    final amountStr = _showBalances ? '$sign${formatVND(tx.amount)}' : '*** đ';

    final title = (tx.note != null && tx.note!.trim().isNotEmpty)
        ? tx.note!
        : (tx.categoryName ?? 'Giao dịch');

    final d = _parseDate(tx.date);
    final timeStr =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    // Subtitle note
    final subtitleNote = (tx.note != null &&
            tx.note!.trim().isNotEmpty &&
            tx.categoryName != null)
        ? tx.categoryName!
        : (tx.categoryName ?? 'Giao dịch');

    // Wallet tag name & Bank brand resolution
    final walletName = tx.walletName ?? tx.fromWalletName ?? 'Ví';
    final wallets = context.read<TransactionProvider>().wallets;
    final walletBrand = _resolveWalletBrand(tx, wallets);

    // Member tag (Chồng or Vợ according to web)
    final isWife = tx.creatorTag == 'Vợ' ||
        tx.creatorTag?.toLowerCase() == 'wife' ||
        tx.ownerName?.toLowerCase() == 'vợ' ||
        tx.ownerName?.toLowerCase() == 'wife' ||
        tx.owner?.toLowerCase() == 'wife' ||
        tx.fromOwner?.toLowerCase() == 'wife' ||
        tx.paidByOwner?.toLowerCase() == 'wife' ||
        tx.tags.any(
            (tag) => tag.toLowerCase() == 'vợ' || tag.toLowerCase() == 'wife');
    final isHusband = !isWife;

    final liveCategory = context
        .read<TransactionProvider>()
        .categories
        .cast<dynamic>()
        .firstWhere(
          (category) =>
              (tx.categoryId?.isNotEmpty == true &&
                  category?.id == tx.categoryId) ||
              (tx.categoryName?.isNotEmpty == true &&
                  category?.name.toString().trim().toLowerCase() ==
                      tx.categoryName!.trim().toLowerCase()),
          orElse: () => null,
        );
    final resolvedCategoryIcon = liveCategory?.icon ?? tx.categoryIcon;
    final resolvedCategoryColor = liveCategory?.color ?? tx.categoryColor;
    final isAi = tx.tags.contains('Finora AI') || tx.creatorTag == 'AI';
    final mName = tx.merchantName?.trim().isNotEmpty == true
        ? tx.merchantName!.trim()
        : (tx.merchantId?.trim().isNotEmpty == true
            ? (tx.merchantId!.startsWith('brand-')
                ? (tx.merchantId == 'brand-shopee'
                    ? 'Shopee'
                    : tx.merchantId == 'brand-tiktok'
                        ? 'TikTok Shop'
                        : tx.merchantId == 'brand-lazada'
                            ? 'Lazada'
                            : tx.merchantId == 'brand-winmart'
                                ? 'WinMart'
                                : tx.merchantId == 'brand-tiki'
                                    ? 'Tiki'
                                    : tx.merchantId == 'brand-grab'
                                        ? 'Grab'
                                        : tx.merchantId!
                                            .replaceFirst('brand-', ''))
                : tx.merchantId!.trim())
            : null);

    Widget cardBody;

    switch (studio.transactionListStyle) {
      case AppTransactionListStyle.compactTable:
        cardBody = Container(
          margin: const EdgeInsets.only(bottom: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : const Color(0xFF64748B))
                    .withValues(alpha: isDark ? 0.25 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.55)
                      : Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.09)
                        : const Color(0xFFE2E8F0).withValues(alpha: 0.85),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    TransactionIconWidget(
                      type: tx.type,
                      categoryIcon: resolvedCategoryIcon,
                      categoryName:
                          liveCategory?.name ?? tx.categoryName ?? tx.note,
                      categoryColor: resolvedCategoryColor,
                      merchantId: tx.merchantId,
                      merchantName: mName,
                      bankBrand: walletBrand,
                      showBankBadge: true,
                      size: 30,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              SpenderBadgeWidget(
                                tag: tx.creatorTag,
                                ownerName: tx.ownerName,
                                isDark: isDark,
                                compact: true,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  '${mName != null ? '$mName · ' : ''}$walletName · $timeStr',
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      amountStr,
                      style: TextStyle(
                        color: amountColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        break;

      case AppTransactionListStyle.minimalDivided:
        cardBody = Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0).withValues(alpha: 0.85),
                width: 0.8,
              ),
            ),
          ),
          child: Row(
            children: [
              TransactionIconWidget(
                type: tx.type,
                categoryIcon: resolvedCategoryIcon,
                categoryName: liveCategory?.name ?? tx.categoryName ?? tx.note,
                categoryColor: resolvedCategoryColor,
                merchantId: tx.merchantId,
                merchantName: mName,
                bankBrand: walletBrand,
                showBankBadge: true,
                size: 38,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        SpenderBadgeWidget(
                          tag: tx.creatorTag,
                          ownerName: tx.ownerName,
                          isDark: isDark,
                          compact: true,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            [
                              if (subtitleNote.isNotEmpty &&
                                  subtitleNote.toLowerCase() !=
                                      title.toLowerCase())
                                subtitleNote,
                              if (mName != null) mName,
                              walletName,
                              timeStr,
                              if (isAi) 'AI',
                            ].join(' · '),
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                amountStr,
                style: TextStyle(
                  color: amountColor,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        );
        break;

      case AppTransactionListStyle.timelineRail:
        final bentoInner = Container(
          margin: const EdgeInsets.only(bottom: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cardRadius),
            boxShadow: [
              ...studio.cardShadows(isDark
                  ? Colors.black
                  : const Color(0xFF64748B).withValues(alpha: 0.10)),
              ...studio.getGlowShadows(isDark),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cardRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: math.max(studio.glassBlur, 12.0),
                sigmaY: math.max(studio.glassBlur, 12.0),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                decoration: BoxDecoration(
                  color: studio.getCardFillColor(isDark),
                  borderRadius: BorderRadius.circular(cardRadius),
                  border: studio.getCardBorder(isDark),
                ),
                child: Row(
                  children: [
                    TransactionIconWidget(
                      type: tx.type,
                      categoryIcon: resolvedCategoryIcon,
                      categoryName:
                          liveCategory?.name ?? tx.categoryName ?? tx.note,
                      categoryColor: resolvedCategoryColor,
                      merchantId: tx.merchantId,
                      merchantName: mName,
                      bankBrand: walletBrand,
                      showBankBadge: true,
                      size: 38,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              SpenderBadgeWidget(
                                tag: tx.creatorTag,
                                ownerName: tx.ownerName,
                                isDark: isDark,
                                compact: true,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  '${mName != null ? '$mName · ' : ''}$walletName · $timeStr',
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                    fontSize: 10.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      amountStr,
                      style: TextStyle(
                        color: amountColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        cardBody = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 18,
              child: Column(
                children: [
                  Container(
                    width: 2,
                    height: isFirstInDay ? 14 : 10,
                    color: isFirstInDay
                        ? Colors.transparent
                        : (isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFCBD5E1)),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: amountColor,
                      boxShadow: [
                        BoxShadow(
                          color: amountColor.withValues(alpha: 0.45),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 2,
                    height: isLastInDay ? 24 : 40,
                    color: isLastInDay
                        ? Colors.transparent
                        : (isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFCBD5E1)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Expanded(child: bentoInner),
          ],
        );
        break;

      case AppTransactionListStyle.bentoCards:
        final bentoDec = studio.getWidgetCardDecoration(
          isDark: isDark,
          customRadius: cardRadius,
        );
        cardBody = Container(
          margin: const EdgeInsets.only(bottom: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cardRadius),
            boxShadow: bentoDec.boxShadow ??
                [
                  ...studio.cardShadows(isDark
                      ? Colors.black
                      : const Color(0xFF64748B).withValues(alpha: 0.10)),
                  ...studio.getGlowShadows(isDark),
                ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cardRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: math.max(studio.glassBlur, 12.0),
                sigmaY: math.max(studio.glassBlur, 12.0),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: bentoDec,
                child: Row(
                  children: [
                    TransactionIconWidget(
                      type: tx.type,
                      categoryIcon: resolvedCategoryIcon,
                      categoryName:
                          liveCategory?.name ?? tx.categoryName ?? tx.note,
                      categoryColor: resolvedCategoryColor,
                      merchantId: tx.merchantId,
                      merchantName: mName,
                      bankBrand: walletBrand,
                      showBankBadge: true,
                      size: 42,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              SpenderBadgeWidget(
                                tag: tx.creatorTag,
                                ownerName: tx.ownerName,
                                isDark: isDark,
                                compact: true,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  [
                                    if (subtitleNote.isNotEmpty &&
                                        subtitleNote.toLowerCase() !=
                                            title.toLowerCase())
                                      subtitleNote,
                                    if (mName != null) mName,
                                    walletName,
                                    timeStr,
                                    if (isAi) 'AI',
                                  ].join(' · '),
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isInflow
                                ? const Color(0xFF059669)
                                    .withValues(alpha: isDark ? 0.25 : 0.12)
                                : (isTransfer
                                    ? const Color(0xFF0284C7)
                                        .withValues(alpha: isDark ? 0.25 : 0.12)
                                    : const Color(0xFFDC2626).withValues(
                                        alpha: isDark ? 0.25 : 0.12)),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              isInflow
                                  ? Icons.arrow_downward_rounded
                                  : (isTransfer
                                      ? Icons.sync_alt_rounded
                                      : Icons.arrow_upward_rounded),
                              size: 12,
                              color: amountColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          amountStr,
                          style: TextStyle(
                            color: amountColor,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        break;

      case AppTransactionListStyle.modernStreamlined:
        cardBody = Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cardRadius),
            boxShadow: [
              ...studio.cardShadows(isDark
                  ? Colors.black
                  : const Color(0xFF64748B).withValues(alpha: 0.10)),
              ...studio.getGlowShadows(isDark),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cardRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: math.max(studio.glassBlur, 12.0),
                sigmaY: math.max(studio.glassBlur, 12.0),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: studio.getCardFillColor(isDark),
                  borderRadius: BorderRadius.circular(cardRadius),
                  border: studio.getCardBorder(isDark),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    TransactionIconWidget(
                      type: tx.type,
                      categoryIcon: resolvedCategoryIcon,
                      categoryName:
                          liveCategory?.name ?? tx.categoryName ?? tx.note,
                      categoryColor: resolvedCategoryColor,
                      merchantId: tx.merchantId,
                      merchantName: mName,
                      bankBrand: walletBrand,
                      showBankBadge: true,
                      size: 42,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              SpenderBadgeWidget(
                                tag: tx.creatorTag,
                                ownerName: tx.ownerName,
                                isDark: isDark,
                                compact: true,
                              ),
                              const SizedBox(width: 6),
                              if (mName != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        (isDark ? Colors.white : Colors.black)
                                            .withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    mName,
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFFCBD5E1)
                                          : const Color(0xFF475569),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isDark ? Colors.white : Colors.black)
                                      .withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  walletName,
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                  fontSize: 10.5,
                                ),
                              ),
                              if (isAi) ...[
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6)
                                        .withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'AI',
                                    style: TextStyle(
                                      color: Color(0xFFA78BFA),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: amountColor.withValues(
                                alpha: isDark ? 0.16 : 0.10),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: amountColor.withValues(
                                  alpha: isDark ? 0.30 : 0.20),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            amountStr,
                            style: TextStyle(
                              color: amountColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isHusband ? 'Chồng' : 'Vợ',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        break;

      case AppTransactionListStyle.magazineLedger:
        cardBody = Container(
          margin: const EdgeInsets.only(bottom: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : const Color(0xFF64748B))
                    .withValues(alpha: isDark ? 0.28 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: math.max(studio.glassBlur, 12.0),
                sigmaY: math.max(studio.glassBlur, 12.0),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: studio.getCardFillColor(isDark),
                  borderRadius: BorderRadius.circular(14),
                  border: studio.getCardBorder(isDark),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Vertical accent edge bar
                      Container(
                        width: 4.5,
                        decoration: BoxDecoration(
                          color: amountColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(14),
                            bottomLeft: Radius.circular(14),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
                          child: Row(
                            children: [
                              TransactionIconWidget(
                                type: tx.type,
                                categoryIcon: resolvedCategoryIcon,
                                categoryName: liveCategory?.name ??
                                    tx.categoryName ??
                                    tx.note,
                                categoryColor: resolvedCategoryColor,
                                merchantId: tx.merchantId,
                                merchantName: mName,
                                bankBrand: walletBrand,
                                showBankBadge: true,
                                size: 34,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        SpenderBadgeWidget(
                                          tag: tx.creatorTag,
                                          ownerName: tx.ownerName,
                                          isDark: isDark,
                                          compact: true,
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            '${mName != null ? '$mName · ' : ''}$walletName · $timeStr',
                                            style: TextStyle(
                                              color: isDark
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF64748B),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    amountStr,
                                    style: TextStyle(
                                      color: amountColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.3,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isHusband ? 'CHỒNG' : 'VỢ',
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFF64748B)
                                          : const Color(0xFF94A3B8),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        break;
    }

    return Dismissible(
      key: ValueKey('tx_${tx.id}'),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.amber.shade700,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit();
          return false;
        } else if (direction == DismissDirection.endToStart) {
          onDelete();
          return false;
        }
        return false;
      },
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TransactionDetailScreen(
                userId: widget.userId,
                transaction: tx,
              ),
            ),
          );
        },
        child: cardBody,
      ),
    );
  }
}

/// Filter Sheet Bottom Sheet
class _FilterSheet extends StatelessWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final provider = context.watch<TransactionProvider>();

    return GlassBottomSheet(
      radius: 32,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.md,
            bottom: AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bộ lọc nâng cao',
                      style: AppTypography.title2.copyWith(
                        color: primaryTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        provider.applyFilters(
                          type: 'all',
                          walletId: null,
                          memberTag: 'all',
                          date: DateFilterOption.thisMonth,
                        );
                      },
                      child: const Text(
                        'Đặt lại',
                        style: TextStyle(
                          color: Color(0xFF005FEA),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 1. Member Section (Chồng / Vợ / Tất cả)
                Text(
                  'Thành viên',
                  style: AppTypography.caption2.copyWith(
                    color: secondaryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilterChipX(
                      label: 'Tất cả',
                      icon: Icons.people_alt_rounded,
                      selected: provider.selectedMemberTag == null ||
                          provider.selectedMemberTag == 'all',
                      onTap: () => provider.setSelectedMemberTag(null),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    FilterChipX(
                      label: 'Chồng',
                      icon: Icons.male_rounded,
                      color: const Color(0xFF0284C7),
                      selected: provider.selectedMemberTag == 'husband',
                      onTap: () => provider.setSelectedMemberTag('husband'),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    FilterChipX(
                      label: 'Vợ',
                      icon: Icons.female_rounded,
                      color: const Color(0xFFDB2777),
                      selected: provider.selectedMemberTag == 'wife',
                      onTap: () => provider.setSelectedMemberTag('wife'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 2. Transaction Type Section (Tất cả, Thu, Chi, Chuyển, Đầu tư, Trả thẻ)
                Text(
                  'Phân loại giao dịch',
                  style: AppTypography.caption2.copyWith(
                    color: secondaryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      FilterChipX(
                        label: 'Tất cả',
                        color: const Color(0xFF005FEA),
                        selected: provider.selectedType == null,
                        onTap: () => provider.setSelectedType(null),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      FilterChipX(
                        label: 'Thu nhập',
                        color: const Color(0xFF059669),
                        selected: provider.selectedType == 'income',
                        onTap: () => provider.setSelectedType('income'),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      FilterChipX(
                        label: 'Chi tiêu',
                        color: const Color(0xFFDC2626),
                        selected: provider.selectedType == 'expense',
                        onTap: () => provider.setSelectedType('expense'),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      FilterChipX(
                        label: 'Chuyển tiền',
                        color: const Color(0xFF0284C7),
                        selected: provider.selectedType == 'transfer',
                        onTap: () => provider.setSelectedType('transfer'),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      FilterChipX(
                        label: 'Đầu tư',
                        color: const Color(0xFFD97706),
                        selected: provider.selectedType == 'investment',
                        onTap: () => provider.setSelectedType('investment'),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      FilterChipX(
                        label: 'Trả thẻ',
                        color: const Color(0xFF0891B2),
                        selected:
                            provider.selectedType == 'credit_card_payment',
                        onTap: () =>
                            provider.setSelectedType('credit_card_payment'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 3. Date Filter Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Khoảng thời gian',
                      style: AppTypography.caption2.copyWith(
                        color: secondaryTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      provider.activeDateFilterLabel,
                      style: const TextStyle(
                        color: Color(0xFF005FEA),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: [
                      DateFilterOption.today,
                      DateFilterOption.yesterday,
                      DateFilterOption.thisWeek,
                      DateFilterOption.lastWeek,
                      DateFilterOption.thisMonth,
                      DateFilterOption.lastMonth,
                      DateFilterOption.thisYear,
                      DateFilterOption.allTime,
                    ].length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.xs),
                    itemBuilder: (_, i) {
                      final option = [
                        DateFilterOption.today,
                        DateFilterOption.yesterday,
                        DateFilterOption.thisWeek,
                        DateFilterOption.lastWeek,
                        DateFilterOption.thisMonth,
                        DateFilterOption.lastMonth,
                        DateFilterOption.thisYear,
                        DateFilterOption.allTime,
                      ][i];
                      return FilterChipX(
                        label: option.label,
                        selected: provider.selectedDateFilter == option,
                        onTap: () => provider.setSelectedDateFilter(option),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Custom Single Date & Date Range Picker Actions
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showFinoraDatePicker(
                            context: context,
                            initialDate: provider.customDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                            helpText: 'CHỌN NGÀY CỤ THỂ',
                          );
                          if (picked != null) {
                            provider.setCustomDate(picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: provider.selectedDateFilter ==
                                    DateFilterOption.customDate
                                ? const Color(0xFF005FEA)
                                    .withValues(alpha: 0.12)
                                : (isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: provider.selectedDateFilter ==
                                      DateFilterOption.customDate
                                  ? const Color(0xFF005FEA)
                                  : (isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0)),
                              width: provider.selectedDateFilter ==
                                      DateFilterOption.customDate
                                  ? 1.5
                                  : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_rounded,
                                  size: 18, color: Color(0xFF005FEA)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Tùy chọn ngày',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: isDark
                                            ? Colors.white60
                                            : const Color(0xFF64748B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      provider.selectedDateFilter ==
                                                  DateFilterOption.customDate &&
                                              provider.customDate != null
                                          ? '${provider.customDate!.day.toString().padLeft(2, '0')}/${provider.customDate!.month.toString().padLeft(2, '0')}/${provider.customDate!.year}'
                                          : 'Chọn ngày...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
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
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final initialRange =
                              (provider.customStartDate != null &&
                                      provider.customEndDate != null)
                                  ? DateTimeRange(
                                      start: provider.customStartDate!,
                                      end: provider.customEndDate!)
                                  : DateTimeRange(
                                      start: DateTime.now()
                                          .subtract(const Duration(days: 7)),
                                      end: DateTime.now(),
                                    );
                          final range = await showFinoraDateRangePicker(
                            context: context,
                            initialDateRange: initialRange,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                            helpText: 'CHỌN TỪ NGÀY ĐẾN NGÀY',
                            saveText: 'CHỌN',
                          );
                          if (range != null) {
                            provider.setCustomRange(range.start, range.end);
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: provider.selectedDateFilter ==
                                    DateFilterOption.customRange
                                ? const Color(0xFF0284C7)
                                    .withValues(alpha: 0.12)
                                : (isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: provider.selectedDateFilter ==
                                      DateFilterOption.customRange
                                  ? const Color(0xFF0284C7)
                                  : (isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0)),
                              width: provider.selectedDateFilter ==
                                      DateFilterOption.customRange
                                  ? 1.5
                                  : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.date_range_rounded,
                                  size: 18, color: Color(0xFF0284C7)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Từ khoảng ngày',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: isDark
                                            ? Colors.white60
                                            : const Color(0xFF64748B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      provider.selectedDateFilter ==
                                                  DateFilterOption
                                                      .customRange &&
                                              provider.customStartDate != null
                                          ? '${provider.customStartDate!.day.toString().padLeft(2, '0')}/${provider.customStartDate!.month.toString().padLeft(2, '0')} - ${provider.customEndDate?.day.toString().padLeft(2, '0')}/${provider.customEndDate?.month.toString().padLeft(2, '0')}'
                                          : 'Từ - Đến...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
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
                const SizedBox(height: AppSpacing.md),

                // 4. Wallets / Accounts Section
                if (provider.wallets.isNotEmpty) ...[
                  Text(
                    'Tài khoản / Ví',
                    style: AppTypography.caption2.copyWith(
                      color: secondaryTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: provider.wallets.length + 1,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpacing.xs),
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          return FilterChipX(
                            label: 'Tất cả ví',
                            selected: provider.selectedWalletId == null,
                            onTap: () => provider.setSelectedWalletId(null),
                          );
                        }
                        final wallet = provider.wallets[i - 1];
                        return FilterChipX(
                          label: wallet.name,
                          selected: provider.selectedWalletId == wallet.id,
                          onTap: () => provider.setSelectedWalletId(wallet.id),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                PrimaryButton(
                  expand: true,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Áp dụng bộ lọc',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
