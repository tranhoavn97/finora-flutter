import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/utils/date_filter.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/bank_icon.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../../state/more_provider.dart';
import '../../state/transaction_provider.dart';
import 'add_transaction_page.dart';
import 'transaction_detail_screen.dart';

/// Modal lịch sử giao dịch thiết kế chuẩn theo Hình 1:
/// - Header: Subtitle chữ in hoa + Tiêu đề lớn + Nút đóng tròn
/// - Hero card: Gradient xanh dương rực rỡ (số dư khả dụng + tag Vợ/Chồng)
/// - Bộ lọc 2 tầng: Tầng 1 (Tất cả / Thu / Chi), Tầng 2 (Tất cả / Chồng / Vợ + Nút chọn ngày)
/// - Danh sách thẻ giao dịch bo góc tinh tế nền pastel chuẩn Hình 1
class TransactionHistorySheet extends StatefulWidget {
  final String userId;
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
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
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
        context.read<TransactionProvider>().load(widget.userId);
        context.read<MoreProvider>().load(widget.userId);
      }
    });
  }

  void _openDatePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 28,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Chọn khoảng thời gian',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 14),
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
              ? const Color(0xFF2563EB).withOpacity(0.12)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
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
                    ? const Color(0xFF2563EB)
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF2563EB), size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        if (!matchNote && !matchCat && !matchAmount && !matchWallet) return false;
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

      // 2. Lọc theo Danh mục
      if (widget.categoryId != null) {
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
      heroLabel =
          widget.categoryGroup == 'income' ? 'Tổng thu nhập' : 'Tổng chi tiêu';
      ownerBadgeText = _memberFilter == 'wife'
          ? 'Vợ'
          : (_memberFilter == 'husband' ? 'Chồng' : 'Tất cả');
    }

    final titleText = widget.walletName ?? widget.categoryName ?? 'Tiền mặt';
    final subtitleText = widget.walletId != null
        ? 'LỊCH SỬ GIAO DỊCH VÍ'
        : 'LỊCH SỬ GIAO DỊCH DANH MỤC';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thanh kéo nhỏ trên cùng
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // HEADER: Subtitle + Title + Close Button (Chuẩn Hình 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subtitleText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          titleText,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Nút "Thêm giao dịch"
                  Material(
                    color: const Color(0xFF005FEA),
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _openAddTransaction(context),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded,
                                size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Thêm GD',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color:
                            isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // NỘI DUNG CUỘN CHÍNH
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                children: [
                  // 1. HERO CARD GRADIENT XANH DƯƠNG (Chuẩn Hình 1)
                  _buildHeroCard(
                    heroLabel: heroLabel,
                    heroAmount: heroAmount,
                    ownerBadge: ownerBadgeText,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),

                  // THANH TÌM KIẾM
                  _buildSearchBar(isDark),
                  const SizedBox(height: 14),

                  // 2. BỘ LỌC TẦNG 1: TẤT CẢ / THU / CHI
                  _buildTypeSegmentedFilter(isDark),
                  const SizedBox(height: 10),

                  // 3. BỘ LỌC TẦNG 2: TẤT CẢ / CHỒNG / VỢ + NÚT CHỌN NGÀY
                  _buildMemberAndDateRow(isDark),
                  const SizedBox(height: 18),

                  // 4. HEADER GIAO DỊCH GẦN ĐÂY
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Giao dịch gần đây',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${filteredTxs.length} giao dịch',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 5. DANH SÁCH GIAO DỊCH
                  if (filteredTxs.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty
                                ? Icons.search_off_rounded
                                : Icons.receipt_long_outlined,
                            size: 42,
                            color: isDark
                                ? const Color(0xFF475569)
                                : const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Không tìm thấy giao dịch nào khớp với "$_searchQuery"'
                                : 'Chưa có giao dịch phù hợp',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
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
                                foregroundColor: const Color(0xFF005FEA),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: () => _openAddTransaction(context),
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Thêm giao dịch ngay'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF005FEA),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    ...filteredTxs
                        .map((tx) => _buildTransactionCardItem(tx, isDark)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Thanh tìm kiếm giao dịch
  Widget _buildSearchBar(bool isDark) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val.trim().toLowerCase();
          });
        },
        style: TextStyle(
          fontSize: 13.5,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
          hintText: 'Tìm kiếm theo ghi chú, danh mục, số tiền...',
          hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: Color(0xFF94A3B8),
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
                    size: 18,
                    color: Color(0xFF94A3B8),
                  ),
                )
              : null,
          border: InputBorder.none,
        ),
      ),
    );
  }

  /// 1. Hero Card: Gradient xanh dương rực rỡ bo góc 22px
  Widget _buildHeroCard({
    required String heroLabel,
    required int heroAmount,
    required String ownerBadge,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2563EB), // Vivid royal blue
            Color(0xFF38BDF8), // Light sky blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Label + Owner Pill Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                heroLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  ownerBadge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Số tiền lớn nổi bật (30sp)
          Text(
            Formatters.formatCurrency(heroAmount),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Bộ lọc tầng 1: Tất cả / Thu / Chi
  Widget _buildTypeSegmentedFilter(bool isDark) {
    final tabs = [
      ('all', 'Tất cả'),
      ('income', 'Thu'),
      ('expense', 'Chi'),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
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
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  t.$2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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

  /// 3. Bộ lọc tầng 2: Tất cả / Chồng / Vợ + Nút Lịch
  Widget _buildMemberAndDateRow(bool isDark) {
    final members = [
      ('all', 'Tất cả'),
      ('husband', 'Chồng'),
      ('wife', 'Vợ'),
    ];

    return Row(
      children: [
        // Segmented Member tabs
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              children: members.map((m) {
                final isSelected = _memberFilter == m.$1;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _memberFilter = m.$1);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFF1E293B))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        m.$2,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
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
          ),
        ),
        const SizedBox(width: 10),

        // Nút Lịch màu tím nhạt bo góc 12px (Chuẩn Hình 1)
        GestureDetector(
          onTap: _openDatePicker,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFE0E7FF),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF4F46E5),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  /// 4. Thẻ giao dịch bo góc 18px độc lập chuẩn Hình 1
  Widget _buildTransactionCardItem(TransactionModel tx, bool isDark) {
    final isExpense = TransactionVisuals.isOutflow(tx.type) &&
        !TransactionVisuals.isTransfer(tx.type);
    final isIncome = TransactionVisuals.isInflow(tx.type);
    final amountText = isExpense
        ? '-${Formatters.formatCurrency(tx.amount)}'
        : (isIncome
            ? '+${Formatters.formatCurrency(tx.amount)}'
            : Formatters.formatCurrency(tx.amount));
    final amountColor =
        TransactionVisuals.colorFor(tx.type, categoryColor: tx.categoryColor);

    final txDate = DateTime.fromMillisecondsSinceEpoch(tx.date);
    final timeStr = DateFormat('HH:mm').format(txDate);
    final dateStr = DateFormat('dd/MM').format(txDate);
    final walletStr = tx.walletName ?? widget.walletName ?? 'Tiền mặt';

    final titleStr = tx.note?.isNotEmpty == true
        ? tx.note!
        : (tx.categoryName ?? 'Giao dịch');

    final categories = context.read<MoreProvider>().categories;
    final matchingCategory = categories.where((category) =>
        (tx.categoryId?.isNotEmpty == true && category.id == tx.categoryId) ||
        (tx.categoryId?.isNotEmpty != true &&
            category.name == tx.categoryName));
    final liveCategory =
        matchingCategory.isEmpty ? null : matchingCategory.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TransactionDetailScreen(
                  userId: widget.userId,
                  transaction: tx,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Icon tròn pastel chuẩn Hình 1
                TransactionIconWidget(
                  type: tx.type,
                  categoryIcon: liveCategory?.icon ?? tx.categoryIcon,
                  categoryName:
                      liveCategory?.name ?? tx.categoryName ?? tx.note,
                  categoryColor: liveCategory?.color ?? tx.categoryColor,
                  merchantId: tx.merchantId,
                  size: 44,
                ),
                const SizedBox(width: 12),

                // Thông tin: Tên giao dịch + Dòng phụ ví và giờ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleStr,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 6,
                        runSpacing: 3,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (walletStr.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5.5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF3B0764).withOpacity(0.5)
                                    : const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                walletStr,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF7C3AED),
                                ),
                              ),
                            ),
                          Text(
                            '$timeStr • $dateStr',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Số tiền (Đỏ nếu Chi, Xanh nếu Thu)
                Text(
                  amountText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: amountColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _resolvePastelColor(TransactionModel tx) {
    final name = (tx.categoryName ?? tx.note ?? '').toLowerCase();
    if (name.contains('rau') || name.contains('nhà'))
      return const Color(0xFFFEE2E2); // Light red/pink
    if (name.contains('chợ') || name.contains('ăn'))
      return const Color(0xFFFCE7F3); // Pink pastel
    if (name.contains('vay') || name.contains('mượn'))
      return const Color(0xFFFEF3C7); // Yellow pastel
    if (name.contains('xăng') || name.contains('xe'))
      return const Color(0xFFFFEDD5); // Peach pastel
    if (name.contains('shopee') || name.contains('sắm'))
      return const Color(0xFFEDE9FE); // Purple pastel
    return const Color(0xFFF1F5F9); // Slate pastel
  }
}
