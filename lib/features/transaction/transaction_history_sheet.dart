import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/utils/date_filter.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/widgets/finora_member_filter.dart';
import '../../data/models/transaction.dart';
import '../../data/models/category.dart';
import '../../data/models/wallet.dart';
import '../../state/more_provider.dart';
import '../../state/transaction_provider.dart';
import 'add_transaction_page.dart';
import 'transaction_detail_sheet.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../state/theme_studio_controller.dart';

/// Modal lịch sử giao dịch thiết kế chuẩn theo Hình 1:
/// - Header: Subtitle chữ in hoa + Tiêu đề lớn + Nút đóng tròn
/// - Hero card: Gradient xanh dương rực rỡ (số dư khả dụng + tag Vợ/Chồng)
/// - Bộ lọc 2 tầng: Tầng 1 (Tất cả / Thu / Chi), Tầng 2 (Tất cả / Chồng / Vợ + Nút chọn ngày)
/// - Danh sách thẻ giao dịch bo góc tinh tế nền pastel chuẩn Hình 1
class TransactionHistorySheet extends StatefulWidget {
  final String userId;
  final String? familyId;
  final String? walletId;
  final String? walletName;
  final Wallet? wallet;
  final String? categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String? categoryGroup;
  final bool embedded;

  const TransactionHistorySheet({
    super.key,
    required this.userId,
    this.familyId,
    this.walletId,
    this.walletName,
    this.wallet,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.categoryGroup,
    this.embedded = false,
  });

  @override
  State<TransactionHistorySheet> createState() =>
      _TransactionHistorySheetState();
}

class _TransactionHistorySheetState extends State<TransactionHistorySheet> {
  // Bộ lọc loại giao dịch (Hàng 1): 'all', 'income', 'expense'
  String _typeFilter = 'all';

  // Bộ lọc thành viên (Hàng 2): 'all', 'husband', 'wife'
  String _memberFilter = 'all';

  // Bộ lọc thời gian: mặc định Tháng này
  DateFilterOption _period = DateFilterOption.thisMonth;
  DateTime? _customDate;

  // Tìm kiếm
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _isSearchExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openAddTransaction(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddTransactionPage(
          userId: widget.userId,
          initialType: widget.categoryGroup != null
              ? (widget.categoryGroup == 'income' ? 'income' : 'expense')
              : null,
          initialWalletId: widget.walletId,
          initialCategoryId: widget.categoryId ?? widget.categoryName,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context
            .read<TransactionProvider>()
            .load(widget.userId, familyId: widget.familyId);
        context
            .read<MoreProvider>()
            .load(widget.userId, familyId: widget.familyId);
      }
    });
  }

  void _openDatePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showFinoraGlassModalBottomSheet(
      context: context,
      title: 'Khoảng thời gian',
      subtitle: 'Lọc lịch sử giao dịch theo mốc thời gian',
      icon: Icons.calendar_today_rounded,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPeriodOption(ctx, 'Hôm nay', DateFilterOption.today, isDark),
            _buildPeriodOption(
                ctx, 'Tuần này', DateFilterOption.thisWeek, isDark),
            _buildPeriodOption(
                ctx, 'Tháng này', DateFilterOption.thisMonth, isDark),
            _buildPeriodOption(
                ctx, 'Năm nay', DateFilterOption.thisYear, isDark),
            _buildPeriodOption(
                ctx, 'Toàn bộ thời gian', DateFilterOption.allTime, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodOption(
    BuildContext ctx,
    String label,
    DateFilterOption option,
    bool isDark,
  ) {
    final studio = Provider.of<ThemeStudioController?>(ctx, listen: false);
    final primary = studio?.primaryColor ?? const Color(0xFF2563EB);
    final isSelected = _period == option;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _period = option);
        Navigator.pop(ctx);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: isDark ? 0.22 : 0.12)
              : (studio?.getCardFillColor(isDark) ??
                  (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC))),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? primary
                : (studio?.getBorderColor(isDark) ??
                    (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? primary
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: primary, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final txProv = context.watch<TransactionProvider>();
    final moreProv = context.watch<MoreProvider>();

    // Tìm ví tương ứng
    Wallet? currentWallet = widget.wallet;
    if (currentWallet == null && widget.walletId != null) {
      for (final w in moreProv.wallets) {
        if (w.id == widget.walletId) {
          currentWallet = w;
          break;
        }
      }
    }

    // Lọc giao dịch
    final allTxs = txProv.transactions;
    final filteredTxs = allTxs.where((t) {
      // 0. Lọc theo từ khóa tìm kiếm
      if (_searchQuery.isNotEmpty) {
        final matchNote = (t.note ?? '').toLowerCase().contains(_searchQuery);
        final matchCat =
            (t.categoryName ?? '').toLowerCase().contains(_searchQuery);
        final matchAmount = t.amount.toString().contains(_searchQuery);
        final matchWallet =
            (t.walletName ?? '').toLowerCase().contains(_searchQuery);
        if (!matchNote && !matchCat && !matchAmount && !matchWallet) {
          return false;
        }
      }

      // 1. Lọc theo Ví
      if (widget.walletId != null) {
        final matchWallet = [
          t.walletId,
          t.fromWalletId,
          t.toWalletId,
          t.creditCardId
        ].contains(widget.walletId);
        if (!matchWallet) return false;
      }

      // 2. Lọc theo Danh mục hoặc Nơi mua
      if (widget.categoryGroup == 'merchant') {
        final cId = widget.categoryId?.trim().toLowerCase();
        final cName = widget.categoryName?.trim().toLowerCase();
        final mId = t.merchantId?.trim().toLowerCase();
        final mName = t.merchantName?.trim().toLowerCase();
        final matchMerchant = (cId != null && (mId == cId || mName == cId)) ||
            (cName != null && (mId == cName || mName == cName));
        if (!matchMerchant) return false;
      } else if (widget.categoryId != null) {
        if (t.categoryId != widget.categoryId) return false;
      } else if (widget.categoryName != null) {
        if (t.categoryName != widget.categoryName) return false;
      }

      // 3. Lọc theo Loại (Tất cả / Thu / Chi)
      if (_typeFilter == 'income') {
        if (t.type != 'income') return false;
      } else if (_typeFilter == 'expense') {
        if (t.type != 'expense') return false;
      }

      // 4. Lọc theo Thành viên (Tất cả / Chồng / Vợ)
      final isWife = t.creatorTag == 'Vợ' ||
          t.creatorTag?.toLowerCase() == 'wife' ||
          t.ownerName?.toLowerCase() == 'vợ' ||
          t.ownerName?.toLowerCase() == 'wife' ||
          t.owner?.toLowerCase() == 'wife' ||
          t.fromOwner?.toLowerCase() == 'wife' ||
          t.paidByOwner?.toLowerCase() == 'wife' ||
          t.tags.any((tag) =>
              tag.toLowerCase() == 'vợ' || tag.toLowerCase() == 'wife');

      if (_memberFilter == 'wife' && !isWife) return false;
      if (_memberFilter == 'husband' && isWife) return false;

      // 5. Lọc theo Thời gian
      if (!isDateInFilterOption(t.date, _period, customDate: _customDate)) {
        return false;
      }

      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    // Tính toán số dư hoặc tổng chi tiêu cho Hero card
    final int heroAmount;
    final String heroLabel;
    final String ownerBadgeText;

    if (currentWallet != null) {
      heroAmount = currentWallet.balance;
      heroLabel = 'Số dư khả dụng';
      final isWife = currentWallet.owner == 'wife' ||
          currentWallet.ownerName.toLowerCase() == 'vợ' ||
          currentWallet.name.toLowerCase().contains('vợ');
      ownerBadgeText = isWife ? 'Vợ' : 'Chồng';
    } else {
      // Đối với Danh mục: Tính tổng tiền các giao dịch đã lọc
      int sum = 0;
      for (final tx in filteredTxs) {
        sum += tx.amount;
      }
      heroAmount = sum;
      heroLabel = widget.categoryGroup == 'income'
          ? 'Tổng thu nhập'
          : (widget.categoryGroup == 'merchant'
              ? 'Tổng chi tại nơi này'
              : 'Tổng chi tiêu');
      ownerBadgeText = _memberFilter == 'wife'
          ? 'Vợ'
          : (_memberFilter == 'husband' ? 'Chồng' : 'Tất cả');
    }

    final titleText = widget.walletName ?? widget.categoryName ?? 'Tiền mặt';
    final subtitleText = widget.walletId != null
        ? 'LỊCH SỬ GIAO DỊCH VÍ'
        : (widget.categoryGroup == 'merchant'
            ? 'LỊCH SỬ GIAO DỊCH NƠI MUA'
            : 'LỊCH SỬ GIAO DỊCH DANH MỤC');

    return GlassBottomSheet(
      radius: studio?.getCardRadius(CardDensity.spacious) ?? 28,
      showHandle: true,
      isExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER: Category icon + Subtitle + Title + Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (widget.categoryIcon != null || widget.categoryName != null) ...[
                        Container(
                          width: 38,
                          height: 38,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: (BankIconRegistry.parseThemeColor(
                              widget.categoryColor,
                              fallback: studio?.primaryColor ?? const Color(0xFF005FEA),
                            )).withValues(alpha: isDark ? 0.22 : 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CategoryIconWidget(
                              icon: widget.categoryIcon,
                              categoryName: widget.categoryName,
                              size: 38,
                              color: BankIconRegistry.parseThemeColor(
                                widget.categoryColor,
                                fallback: studio?.primaryColor ?? const Color(0xFF005FEA),
                              ),
                            ),
                          ),
                        ),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subtitleText,
                              style: TextStyle(
                                fontSize: 10.5 * (studio?.fontScale ?? 1.0),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                fontFamily: studio?.fontFamilyName,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              titleText,
                              style: TextStyle(
                                fontSize: 20 * (studio?.fontScale ?? 1.0),
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                                fontFamily: studio?.fontFamilyName,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                const SizedBox(width: 8),
                FinoraPillButton(
                  icon: Icons.add_rounded,
                  label: 'Thêm',
                  primary: true,
                  compact: true,
                  onPressed: () => _openAddTransaction(context),
                ),
                const SizedBox(width: 8),
                FinoraIconAction(
                  icon: Icons.close_rounded,
                  label: 'Đóng',
                  size: 34,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),

          // NỘI DUNG CUỘN CHÍNH
          Expanded(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // 1. HERO CARD GRADIENT DYNAMIC THEMED
                _buildHeroCard(
                  heroLabel: heroLabel,
                  heroAmount: heroAmount,
                  ownerBadge: ownerBadgeText,
                  isDark: isDark,
                  studio: studio,
                ),
                const SizedBox(height: 12),

                // 2. THANH CÔNG CỤ TÌM KIẾM & BỘ LỌC HỢP NHẤT 1 HÀNG DUY NHẤT
                _buildUnifiedToolbar(isDark, studio),
                if (_hasActiveFilters) ...[
                  const SizedBox(height: 8),
                  _buildActiveFilterChips(isDark, studio),
                ],
                const SizedBox(height: 12),

                // 5. DANH SÁCH LỊCH SỬ GIAO DỊCH THIẾT KẾ MỚI GỌN ĐẸP DỄ NHÌN
                if (filteredTxs.isEmpty)
                  _buildEmptyState(isDark, studio)
                else
                  _buildGroupedTransactionList(
                    txs: filteredTxs,
                    isDark: isDark,
                    studio: studio,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Hero Card: Dynamic gradient theo màu danh mục hoặc Theme Studio
  Widget _buildHeroCard({
    required String heroLabel,
    required int heroAmount,
    required String ownerBadge,
    required bool isDark,
    required ThemeStudioController? studio,
  }) {
    final cardRadius = studio?.getCardRadius(CardDensity.standard) ?? 20.0;

    final Gradient cardGradient;
    if (widget.categoryColor != null && widget.categoryColor!.isNotEmpty) {
      final baseColor = BankIconRegistry.parseThemeColor(
        widget.categoryColor,
        fallback: studio?.primaryColor ?? const Color(0xFF005FEA),
      );
      cardGradient = LinearGradient(
        colors: [
          Color.alphaBlend(Colors.black.withValues(alpha: isDark ? 0.40 : 0.20), baseColor),
          baseColor,
          Color.alphaBlend(Colors.white.withValues(alpha: isDark ? 0.15 : 0.25), baseColor),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      cardGradient = LinearGradient(
        colors: studio?.currentPaletteMeta.heroGradient ?? const [
          Color(0xFF1E3A8A),
          Color(0xFF2563EB),
          Color(0xFF38BDF8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: (studio?.primaryColor ?? const Color(0xFF2563EB))
                .withValues(alpha: isDark ? 0.35 : 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Label + Owner pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                heroLabel,
                style: TextStyle(
                  fontSize: 12.5 * (studio?.fontScale ?? 1.0),
                  fontWeight: FontWeight.w600,
                  fontFamily: studio?.fontFamilyName,
                  color: Colors.white.withValues(alpha: 0.88),
                  letterSpacing: 0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  ownerBadge,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5 * (studio?.fontScale ?? 1.0),
                    fontWeight: FontWeight.w800,
                    fontFamily: studio?.fontFamilyName,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Row 2: Số tiền lớn nổi bật
          Text(
            studio?.formatCurrency(heroAmount) ?? Formatters.formatCurrency(heroAmount),
            style: TextStyle(
              fontSize: 26 * (studio?.fontScale ?? 1.0),
              fontWeight: FontWeight.w900,
              fontFamily: studio?.fontFamilyName,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasActiveFilters =>
      _memberFilter != 'all' ||
      _period != DateFilterOption.allTime ||
      _searchQuery.isNotEmpty;

  /// 2. Thanh công cụ 1 hàng duy nhất: Tab Thu/Chi + Dropdown Vợ Chồng (icon) + Icon Tìm kiếm (nảy ra) + Icon Lịch
  Widget _buildUnifiedToolbar(bool isDark, ThemeStudioController? studio) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: _isSearchExpanded
          ? KeyedSubtree(
              key: const ValueKey('search_expanded'),
              child: _buildExpandedSearchBar(isDark, studio),
            )
          : KeyedSubtree(
              key: const ValueKey('toolbar_collapsed'),
              child: _buildCollapsedToolbar(isDark, studio),
            ),
    );
  }

  /// Trạng thái bình thường: [Tất cả | Thu | Chi] + [👥/👨/👩 Dropdown] + [🔍 Icon tìm kiếm] + [📅 Icon lịch]
  Widget _buildCollapsedToolbar(bool isDark, ThemeStudioController? studio) {
    final cardRadius = studio?.getCardRadius(CardDensity.compact) ?? 10.0;
    final primary = studio?.primaryColor ?? const Color(0xFF005FEA);
    final hasDate = _period != DateFilterOption.allTime;
    final hasSearch = _searchQuery.isNotEmpty;

    return Row(
      children: [
        // 1. Tab Thu Chi (Giữ nguyên dạng segmented pill trên hàng)
        Expanded(
          child: _buildTypeSegmentedFilter(isDark, studio),
        ),
        const SizedBox(width: 6),

        // 2. Dropdown Vợ Chồng (Chỉ hiển thị icon)
        _buildMemberDropdownButton(isDark, studio),
        const SizedBox(width: 6),

        // 3. Icon Tìm Kiếm (Nhấn vào sẽ nảy ra thanh tìm kiếm)
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _isSearchExpanded = true;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _searchFocusNode.requestFocus();
            });
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: hasSearch
                  ? primary.withValues(alpha: isDark ? 0.28 : 0.15)
                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
                      .withValues(alpha: studio?.glassOpacity ?? 0.85),
              borderRadius: BorderRadius.circular(cardRadius),
              border: Border.all(
                color: hasSearch
                    ? primary.withValues(alpha: 0.50)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06)),
                width: 0.8,
              ),
            ),
            alignment: Alignment.center,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.search_rounded,
                  color: hasSearch
                      ? primary
                      : (isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B)),
                  size: 18,
                ),
                if (hasSearch)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isDark ? const Color(0xFF0F172A) : Colors.white,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),

        // 4. Icon Lịch (Thời gian)
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openDatePicker,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: hasDate
                  ? primary.withValues(alpha: isDark ? 0.28 : 0.15)
                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
                      .withValues(alpha: studio?.glassOpacity ?? 0.85),
              borderRadius: BorderRadius.circular(cardRadius),
              border: Border.all(
                color: hasDate
                    ? primary.withValues(alpha: 0.50)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06)),
                width: 0.8,
              ),
            ),
            alignment: Alignment.center,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: hasDate
                      ? primary
                      : (isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B)),
                  size: 18,
                ),
                if (hasDate)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isDark ? const Color(0xFF0F172A) : Colors.white,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Trạng thái mở rộng: Thanh tìm kiếm chiếm toàn bộ hàng sau khi ấn icon tìm kiếm
  Widget _buildExpandedSearchBar(bool isDark, ThemeStudioController? studio) {
    final cardRadius = studio?.getCardRadius(CardDensity.compact) ?? 10.0;
    final primary = studio?.primaryColor ?? const Color(0xFF005FEA);

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
                  .withValues(alpha: isDark ? 0.85 : 0.95),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: isDark ? 0.12 : 0.08),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [FirstLetterUpperCaseFormatter()],
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              style: TextStyle(
                fontSize: 13.5 * (studio?.fontScale ?? 1.0),
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontFamily: studio?.fontFamilyName,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                filled: false,
                fillColor: Colors.transparent,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
                hintText: 'Tìm theo ghi chú, danh mục, số tiền...',
                hintStyle: TextStyle(
                  fontSize: 12.5 * (studio?.fontScale ?? 1.0),
                  fontFamily: studio?.fontFamilyName,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 19,
                  color: primary,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.lightImpact();
            _searchController.clear();
            _searchFocusNode.unfocus();
            setState(() {
              _searchQuery = '';
              _isSearchExpanded = false;
            });
          },
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
                  .withValues(alpha: studio?.glassOpacity ?? 0.85),
              borderRadius: BorderRadius.circular(cardRadius),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                width: 0.8,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              'Hủy',
              style: TextStyle(
                fontSize: 12.5 * (studio?.fontScale ?? 1.0),
                fontWeight: FontWeight.w700,
                fontFamily: studio?.fontFamilyName,
                color: primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Tab Thu Chi giữ nguyên chuẩn segmented pill
  Widget _buildTypeSegmentedFilter(bool isDark, ThemeStudioController? studio) {
    final tabs = [
      ('all', 'Tất cả'),
      ('income', 'Thu'),
      ('expense', 'Chi'),
    ];

    final primary = studio?.primaryColor ?? const Color(0xFF005FEA);

    return Container(
      height: 38,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
            .withValues(alpha: studio?.glassOpacity ?? 0.80),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: tabs.map((t) {
          final isSelected = _typeFilter == t.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _typeFilter = t.$1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isSelected ? primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.30),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  t.$2,
                  style: TextStyle(
                    fontSize: 12 * (studio?.fontScale ?? 1.0),
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontFamily: studio?.fontFamilyName,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Dropdown chọn thành viên: chỉ hiển thị icon (👥 / 👨 / 👩)
  Widget _buildMemberDropdownButton(
      bool isDark, ThemeStudioController? studio) {
    return FinoraUnifiedMemberPill(
      currentMember: _memberFilter == 'all' ? null : _memberFilter,
      onSelected: (val) {
        setState(() => _memberFilter = val ?? 'all');
      },
      isDark: isDark,
    );
  }

  /// Các chip hiển thị bộ lọc đang được kích hoạt
  Widget _buildActiveFilterChips(bool isDark, ThemeStudioController? studio) {
    final primary = studio?.primaryColor ?? const Color(0xFF005FEA);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          if (_memberFilter != 'all') ...[
            _buildDismissibleChip(
              label: _memberFilter == 'wife' ? 'Vợ' : 'Chồng',
              onDismiss: () => setState(() => _memberFilter = 'all'),
              isDark: isDark,
              primary: _memberFilter == 'wife'
                  ? const Color(0xFFEC4899)
                  : const Color(0xFF0284C7),
              studio: studio,
            ),
            const SizedBox(width: 6),
          ],
          if (_period != DateFilterOption.allTime) ...[
            _buildDismissibleChip(
              label: _getPeriodLabel(_period),
              onDismiss: () =>
                  setState(() => _period = DateFilterOption.allTime),
              isDark: isDark,
              primary: primary,
              studio: studio,
            ),
            const SizedBox(width: 6),
          ],
          if (_searchQuery.isNotEmpty) ...[
            _buildDismissibleChip(
              label: '"$_searchQuery"',
              onDismiss: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              isDark: isDark,
              primary: primary,
              studio: studio,
            ),
            const SizedBox(width: 6),
          ],
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _searchController.clear();
              setState(() {
                _memberFilter = 'all';
                _period = DateFilterOption.allTime;
                _searchQuery = '';
              });
            },
            child: Text(
              'Xóa bộ lọc',
              style: TextStyle(
                fontSize: 11 * (studio?.fontScale ?? 1.0),
                fontWeight: FontWeight.w700,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissibleChip({
    required String label,
    required VoidCallback onDismiss,
    required bool isDark,
    required Color primary,
    required ThemeStudioController? studio,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 3, 5, 3),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: primary.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11 * (studio?.fontScale ?? 1.0),
              fontWeight: FontWeight.w700,
              fontFamily: studio?.fontFamilyName,
              color: primary,
            ),
          ),
          const SizedBox(width: 3),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(
              Icons.close_rounded,
              size: 13,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel(DateFilterOption option) {
    switch (option) {
      case DateFilterOption.today:
        return 'Hôm nay';
      case DateFilterOption.thisWeek:
        return 'Tuần này';
      case DateFilterOption.thisMonth:
        return 'Tháng này';
      case DateFilterOption.thisYear:
        return 'Năm nay';
      case DateFilterOption.allTime:
        return 'Toàn bộ';
      default:
        return 'Thời gian';
    }
  }

  /// 5. Danh sách giao dịch được nhóm theo Ngày trong các Card hợp nhất gọn gàng, tinh tế
  Widget _buildGroupedTransactionList({
    required List<TransactionModel> txs,
    required bool isDark,
    required ThemeStudioController? studio,
  }) {
    final Map<DateTime, List<TransactionModel>> grouped = {};
    for (final tx in txs) {
      final dt = DateTime.fromMillisecondsSinceEpoch(tx.date);
      final dayKey = DateTime(dt.year, dt.month, dt.day);
      grouped.putIfAbsent(dayKey, () => []).add(tx);
    }
    final sortedDays = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final cardRadius = studio?.getCardRadius() ?? 18.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sortedDays.map((day) {
        final dayTxs = grouped[day]!;
        int dayExpense = 0;
        int dayIncome = 0;
        for (final t in dayTxs) {
          final isExpense = TransactionVisuals.isOutflow(t.type) &&
              !TransactionVisuals.isTransfer(t.type);
          if (isExpense) {
            dayExpense += t.amount;
          } else if (TransactionVisuals.isInflow(t.type)) {
            dayIncome += t.amount;
          }
        }

        final dayNetStr = dayExpense > 0
            ? '-${studio?.formatCurrency(dayExpense) ?? Formatters.formatCurrency(dayExpense)}'
            : (dayIncome > 0
                ? '+${studio?.formatCurrency(dayIncome) ?? Formatters.formatCurrency(dayIncome)}'
                : '${dayTxs.length} giao dịch');

        final dayNetColor = dayExpense > 0
            ? (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626))
            : (dayIncome > 0
                ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)));

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Ngày & Tổng tiền của ngày
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDateHeader(day),
                      style: TextStyle(
                        fontSize: 12 * (studio?.fontScale ?? 1.0),
                        fontWeight: FontWeight.w700,
                        fontFamily: studio?.fontFamilyName,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      dayNetStr,
                      style: TextStyle(
                        fontSize: 11.5 * (studio?.fontScale ?? 1.0),
                        fontWeight: FontWeight.w800,
                        fontFamily: studio?.fontFamilyName,
                        color: dayNetColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Kết xuất danh sách giao dịch phản hồi chính xác theo ThemeStudioController.transactionListStyle
              Builder(
                builder: (context) {
                  final txStyle = studio?.transactionListStyle ??
                      AppTransactionListStyle.modernStreamlined;

                  if (txStyle == AppTransactionListStyle.modernStreamlined ||
                      txStyle == AppTransactionListStyle.bentoCards) {
                    return Column(
                      children: [
                        for (final tx in dayTxs)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              decoration: studio?.getWidgetCardDecoration(
                                    isDark: isDark,
                                    customRadius: cardRadius,
                                  ) ??
                                  studio?.getCardDecoration(
                                    isDark: isDark,
                                    radius: cardRadius,
                                  ) ??
                                  BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(cardRadius),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : const Color(0xFFF1F5F9),
                                      width: 1.0,
                                    ),
                                  ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(cardRadius),
                                child: _buildTransactionRowItem(
                                  tx: tx,
                                  isDark: isDark,
                                  studio: studio,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  }

                  if (txStyle == AppTransactionListStyle.magazineLedger) {
                    return Column(
                      children: [
                        for (final tx in dayTxs)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              decoration: studio?.getCardDecoration(
                                    isDark: isDark,
                                    radius: 14,
                                  ) ??
                                  BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Container(
                                        width: 4.5,
                                        color: TransactionVisuals.isOutflow(tx.type)
                                            ? const Color(0xFFDC2626)
                                            : const Color(0xFF059669),
                                      ),
                                      Expanded(
                                        child: _buildTransactionRowItem(
                                          tx: tx,
                                          isDark: isDark,
                                          studio: studio,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  }

                  // Default / minimalDivided / compactTable: Thẻ gom nhóm ngày tinh gọn
                  return Container(
                    decoration: studio?.getCardDecoration(
                          isDark: isDark,
                          radius: cardRadius,
                        ) ??
                        BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(cardRadius),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFF1F5F9),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.2 : 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(cardRadius),
                      child: Column(
                        children: [
                          for (int i = 0; i < dayTxs.length; i++) ...[
                            if (i > 0)
                              Divider(
                                height: 1,
                                thickness: 0.7,
                                indent: 58,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.05),
                              ),
                            _buildTransactionRowItem(
                              tx: dayTxs[i],
                              isDark: isDark,
                              studio: studio,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 6. Hàng giao dịch gọn gàng, thanh lịch với thông tin phân cấp rõ ràng
  Widget _buildTransactionRowItem({
    required TransactionModel tx,
    required bool isDark,
    required ThemeStudioController? studio,
  }) {
    final isExpense = TransactionVisuals.isOutflow(tx.type) &&
        !TransactionVisuals.isTransfer(tx.type);
    final isIncome = TransactionVisuals.isInflow(tx.type);
    final isTransfer = TransactionVisuals.isTransfer(tx.type);

    final sign = isExpense ? '-' : (isIncome ? '+' : '');
    final amountText =
        '$sign${studio?.formatCurrency(tx.amount) ?? Formatters.formatCurrency(tx.amount)}';

    final amountColor = isTransfer
        ? const Color(0xFF0284C7)
        : (isExpense
            ? (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626))
            : (isDark ? const Color(0xFF34D399) : const Color(0xFF059669)));

    final txDate = DateTime.fromMillisecondsSinceEpoch(tx.date);
    final timeStr = DateFormat('HH:mm').format(txDate);
    final walletStr = tx.walletName ?? widget.walletName ?? '';

    final titleStr = (tx.note?.isNotEmpty == true)
        ? tx.note!
        : (tx.categoryName ?? 'Giao dịch');

    final categories = context.read<MoreProvider>().categories;
    final matchingCategory = categories.where((category) =>
        (tx.categoryId?.isNotEmpty == true && category.id == tx.categoryId) ||
        (tx.categoryId?.isNotEmpty != true &&
            category.name == tx.categoryName));
    final liveCategory =
        matchingCategory.isEmpty ? null : matchingCategory.first;

    Category? liveMerchant;
    if (tx.merchantId?.isNotEmpty == true || tx.merchantName?.isNotEmpty == true) {
      final mIdLower = tx.merchantId?.toLowerCase().trim();
      final mNameLower = tx.merchantName?.toLowerCase().trim();
      for (final c in categories) {
        final cIdLower = c.id.toLowerCase();
        final cNameLower = c.name.toLowerCase().trim();
        if ((mIdLower != null && (cIdLower == mIdLower || cNameLower == mIdLower)) ||
            (mNameLower != null && (cNameLower == mNameLower || cIdLower == mNameLower))) {
          liveMerchant = c;
          break;
        }
      }
    }

    final effectiveMerchant = liveMerchant?.name ??
        (tx.merchantName?.isNotEmpty == true ? tx.merchantName : null) ??
        (tx.merchantId?.isNotEmpty == true
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
                                    : (tx.merchantId!.startsWith('brand-')
                                        ? tx.merchantId!.replaceFirst('brand-', '')
                                        : tx.merchantId!))
            : null);

    final walletBrand = BankIconRegistry.resolve(
      tx.walletId ?? widget.wallet?.bankCode,
      bankName: walletStr.isNotEmpty ? walletStr : (tx.walletName ?? tx.fromWalletName),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showTransactionDetailSheet(
            context,
            userId: widget.userId,
            transaction: tx,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Icon danh mục gắn kèm Huy Hiệu Ngân Hàng / Ví nguồn chi tiêu
              TransactionIconWidget(
                type: tx.type,
                categoryIcon: liveCategory?.icon ?? tx.categoryIcon,
                categoryName:
                    liveCategory?.name ?? tx.categoryName ?? tx.note,
                categoryColor: liveCategory?.color ?? tx.categoryColor,
                merchantId: tx.merchantId,
                merchantName: effectiveMerchant,
                merchantIcon: liveMerchant?.icon,
                bankBrand: walletBrand,
                showBankBadge: true,
                size: 38,
              ),
              const SizedBox(width: 12),

              // Title + Dòng thông tin phụ (Giờ, thành viên, ví)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      titleStr,
                      style: TextStyle(
                        fontSize: 13.5 * (studio?.fontScale ?? 1.0),
                        fontWeight: FontWeight.w700,
                        fontFamily: studio?.fontFamilyName,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 11 * (studio?.fontScale ?? 1.0),
                            fontWeight: FontWeight.w500,
                            fontFamily: studio?.fontFamilyName,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Badge thành viên Chồng / Vợ tương phản cao, siêu sắc nét
                        SpenderBadgeWidget(
                          tag: tx.creatorTag,
                          ownerName: tx.ownerName ?? tx.owner ?? tx.fromOwner,
                          isDark: isDark,
                          fontScale: studio?.fontScale ?? 1.0,
                          fontFamily: studio?.fontFamilyName,
                          compact: true,
                        ),
                        if (walletStr.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: (isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFF1F5F9))
                                    .withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                walletStr,
                                style: TextStyle(
                                  fontSize: 9.5 * (studio?.fontScale ?? 1.0),
                                  fontWeight: FontWeight.w600,
                                  fontFamily: studio?.fontFamilyName,
                                  color: isDark
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        if (effectiveMerchant != null &&
                            widget.categoryGroup != 'merchant') ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3861FB)
                                  .withValues(alpha: isDark ? 0.22 : 0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF3861FB)
                                    .withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.storefront_rounded,
                                    size: 9, color: Color(0xFF3861FB)),
                                const SizedBox(width: 2.5),
                                Text(
                                  effectiveMerchant,
                                  style: TextStyle(
                                    fontSize: 9.5 * (studio?.fontScale ?? 1.0),
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF3861FB),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Số tiền nổi bật
              Text(
                amountText,
                style: TextStyle(
                  fontSize: 14.5 * (studio?.fontScale ?? 1.0),
                  fontWeight: FontWeight.w800,
                  fontFamily: studio?.fontFamilyName,
                  letterSpacing: -0.2,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 7. Trạng thái rỗng
  Widget _buildEmptyState(bool isDark, ThemeStudioController? studio) {
    final cardRadius = studio?.getCardRadius(CardDensity.standard) ?? 18.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      alignment: Alignment.center,
      decoration: studio?.getCardDecoration(
            isDark: isDark,
            radius: cardRadius,
          ) ??
          BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(cardRadius),
          ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _searchQuery.isNotEmpty
                ? Icons.search_off_rounded
                : Icons.receipt_long_outlined,
            size: 38,
            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Không tìm thấy giao dịch nào khớp với "$_searchQuery"'
                : 'Chưa có giao dịch phù hợp',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13 * (studio?.fontScale ?? 1.0),
              fontWeight: FontWeight.w600,
              fontFamily: studio?.fontFamilyName,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          if (_searchQuery.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              icon: const Icon(Icons.clear_rounded, size: 16),
              label: const Text('Xóa tìm kiếm'),
              style: TextButton.styleFrom(
                foregroundColor: studio?.primaryColor ?? const Color(0xFF005FEA),
                textStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5 * (studio?.fontScale ?? 1.0),
                  fontFamily: studio?.fontFamilyName,
                ),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () => _openAddTransaction(context),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Thêm giao dịch ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: studio?.primaryColor ?? const Color(0xFF005FEA),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5 * (studio?.fontScale ?? 1.0),
                  fontFamily: studio?.fontFamilyName,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Định dạng tiêu đề ngày chuẩn tiếng Việt
  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) {
      return 'Hôm nay, ${DateFormat('dd/MM').format(date)}';
    } else if (d == yesterday) {
      return 'Hôm qua, ${DateFormat('dd/MM').format(date)}';
    } else {
      const weekdaysVi = ['', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];
      final weekdayStr = weekdaysVi[date.weekday.clamp(1, 7)];
      return '$weekdayStr, ${DateFormat('dd/MM/yyyy').format(date)}';
    }
  }
}
