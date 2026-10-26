import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../data/models/transaction.dart';
import '../../state/transaction_provider.dart';
import 'add_transaction_page.dart';
import 'transaction_detail_screen.dart';

/// FINORA Mobile 3.0 — Sổ Thu Chi & Giao Dịch
/// Bê nguyên thiết kế Web/Mobile 3.0: Bộ chuyển tháng, Dải chọn ngày theo tuần (Date Strip),
/// Thanh tìm kiếm kết hợp Mini Capsule Chồng/Vợ, Dải lọc loại tiền, Icon kính 3D
class TransactionScreen extends StatefulWidget {
  final String userId;
  final String? familyId;
  final VoidCallback? onBack;
  final bool isTab;

  const TransactionScreen({
    super.key,
    required this.userId,
    this.familyId,
    this.onBack,
    this.isTab = false,
  });

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  late final TextEditingController _searchController;
  StreamSubscription<String>? _eventsSub;

  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDate; // null = Toàn tháng
  String _ownerFilter = 'all'; // 'all', 'husband', 'wife'
  String _typeFilter = 'all'; // 'all', 'expense', 'income', 'transfer'

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() => setState(() {}));

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

  @override
  void dispose() {
    _searchController.dispose();
    _eventsSub?.cancel();
    super.dispose();
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  String _formatCompact(int amount) {
    if (amount.abs() >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount.abs() >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount.abs() >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return amount.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<TransactionProvider>();
    final allTransactions = provider.transactions;

    // Lọc theo tháng, ngày, search, type, và owner
    final filteredTransactions = allTransactions.where((tx) {
      final txDate = tx.date > 100000000000
          ? DateTime.fromMillisecondsSinceEpoch(tx.date)
          : DateTime.fromMillisecondsSinceEpoch(tx.date * 1000);

      // 1. Kiểm tra tháng
      if (txDate.year != _currentMonth.year || txDate.month != _currentMonth.month) {
        return false;
      }

      // 2. Kiểm tra ngày cụ thể (nếu có chọn)
      if (_selectedDate != null) {
        if (txDate.year != _selectedDate!.year ||
            txDate.month != _selectedDate!.month ||
            txDate.day != _selectedDate!.day) {
          return false;
        }
      }

      // 3. Kiểm tra loại giao dịch
      if (_typeFilter != 'all' && tx.type != _typeFilter) {
        return false;
      }

      // 4. Kiểm tra tìm kiếm
      final query = _searchController.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        final note = (tx.note ?? '').toLowerCase();
        final cat = (tx.categoryName ?? '').toLowerCase();
        final wallet = (tx.walletName ?? '').toLowerCase();
        if (!note.contains(query) && !cat.contains(query) && !wallet.contains(query)) {
          return false;
        }
      }

      // 5. Kiểm tra owner (Chồng / Vợ)
      if (_ownerFilter != 'all') {
        final nameLower = (tx.note ?? '').toLowerCase();
        final walletLower = (tx.walletName ?? '').toLowerCase();
        if (_ownerFilter == 'husband') {
          if (!nameLower.contains('chồng') &&
              !walletLower.contains('vcb') &&
              !walletLower.contains('vietcombank') &&
              !walletLower.contains('techcom') &&
              !walletLower.contains('visa')) {
            return false;
          }
        } else if (_ownerFilter == 'wife') {
          if (!nameLower.contains('vợ') &&
              !walletLower.contains('momo') &&
              !walletLower.contains('tiền mặt')) {
            return false;
          }
        }
      }

      return true;
    }).toList();

    // Tính toán tổng thu và tổng chi của tháng đang xem
    int monthIncome = 0;
    int monthExpense = 0;
    for (final tx in allTransactions) {
      final txDate = tx.date > 100000000000
          ? DateTime.fromMillisecondsSinceEpoch(tx.date)
          : DateTime.fromMillisecondsSinceEpoch(tx.date * 1000);
      if (txDate.year == _currentMonth.year && txDate.month == _currentMonth.month) {
        if (tx.type == 'income') {
          monthIncome += tx.amount;
        } else if (tx.type == 'expense') {
          monthExpense += tx.amount;
        }
      }
    }

    // Nhóm giao dịch đã lọc theo ngày
    final grouped = <String, List<TransactionModel>>{};
    for (final tx in filteredTransactions) {
      final txDate = tx.date > 100000000000
          ? DateTime.fromMillisecondsSinceEpoch(tx.date)
          : DateTime.fromMillisecondsSinceEpoch(tx.date * 1000);
      final dayKey = DateFormat('yyyy-MM-dd').format(txDate);
      grouped.putIfAbsent(dayKey, () => []).add(tx);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: const Color(0xFF4F46E5),
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          onRefresh: () async {
            provider.load(widget.userId, familyId: widget.familyId, force: true);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 120),
            children: [
              // 1. Header: SỔ THU CHI & GIAO DỊCH + NÚT GHI CHÉP GLOW INDIGO
              _buildHeader(isDark),
              const SizedBox(height: 12),

              // 2. Bộ Chuyển Tháng (Month Navigator)
              _buildMonthNavigator(
                monthIncome: monthIncome,
                monthExpense: monthExpense,
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              // 3. Dải Chọn Ngày Theo Tuần (Date Strip Carousel)
              _buildDateStrip(isDark),
              const SizedBox(height: 12),

              // 4. Thanh Tìm Kiếm Kết Hợp Mini Bộ Lọc Chồng / Vợ
              _buildSearchAndOwnerRow(isDark),
              const SizedBox(height: 12),

              // 5. Dải Lọc Loại Tiền (Pill Filter Chips)
              _buildTypeFilterRow(isDark, monthIncome, monthExpense),
              const SizedBox(height: 14),

              // 6. Danh Sách Giao Dịch Chi Tiết Theo Ngày (Icon Kính 3D)
              if (grouped.isEmpty)
                _buildEmptyState(isDark)
              else
                ...grouped.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildDayGroup(entry.key, entry.value, isDark),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. HEADER & NÚT GHI CHÉP GLOW INDIGO ---
  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (!widget.isTab &&
                (widget.onBack != null || Navigator.canPop(context)))
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: _handleBack,
                  icon: Icon(
                    LucideIcons.arrow_left,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    size: 20,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            Text(
              'SỔ THU CHI & GIAO DỊCH',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddTransactionPage(userId: widget.userId),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5),
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.plus, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Ghi chép',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 2. BỘ CHUYỂN THÁNG (MONTH NAVIGATOR) ---
  Widget _buildMonthNavigator({
    required int monthIncome,
    required int monthExpense,
    required bool isDark,
  }) {
    final now = DateTime.now();
    final isCurrentMonth = _currentMonth.year == now.year &&
        _currentMonth.month == now.month;

    return FinoraClayCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Nút tháng trước ‹
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _currentMonth = DateTime(
                    _currentMonth.year, _currentMonth.month - 1, 1);
                _selectedDate = null;
              });
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF243045) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  LucideIcons.chevron_left,
                  size: 18,
                  color: isDark ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ),
          ),

          // Trung tâm: Tháng, Năm + Badge Hiện Tại + Tóm tắt Thu/Chi
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tháng ${_currentMonth.month}, ${_currentMonth.year}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  if (isCurrentMonth) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'HIỆN TẠI',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF4F46E5),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Thu: +${_formatCompact(monthIncome)} • Chi: -${_formatCompact(monthExpense)}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),

          // Nút tháng sau ›
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _currentMonth = DateTime(
                    _currentMonth.year, _currentMonth.month + 1, 1);
                _selectedDate = null;
              });
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF243045) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  LucideIcons.chevron_right,
                  size: 18,
                  color: isDark ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. DẢI CHỌN NGÀY THEO TUẦN (DATE STRIP CAROUSEL) ---
  Widget _buildDateStrip(bool isDark) {
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final now = DateTime.now();

    final selectedLabel = _selectedDate == null
        ? 'Đang chọn: Toàn tháng ${_currentMonth.month}'
        : (_selectedDate!.year == now.year &&
                _selectedDate!.month == now.month &&
                _selectedDate!.day == now.day
            ? 'Đang chọn: Hôm nay (${DateFormat('dd/MM').format(_selectedDate!)})'
            : 'Đang chọn: Ngày ${DateFormat('dd/MM').format(_selectedDate!)}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CHỌN NGÀY ĐỂ XEM',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : const Color(0xFF94A3B8),
                ),
              ),
              Text(
                selectedLabel,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        SizedBox(
          height: 64,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: daysInMonth + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                // Nút "TẤT CẢ T.X"
                final isSelected = _selectedDate == null;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedDate = null);
                  },
                  child: Container(
                    width: 46,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4F46E5)
                          : (isDark ? const Color(0xFF162032) : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF4F46E5)
                            : (isDark
                                ? const Color(0xFF243045)
                                : const Color(0xFFE2E8F0)),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF4F46E5)
                                    .withValues(alpha: 0.45),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'TẤT CẢ',
                          style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? const Color(0xFFC7D2FE)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'T.${_currentMonth.month}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final dayNum = index;
              final date = DateTime(
                  _currentMonth.year, _currentMonth.month, dayNum);
              final isToday = date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;
              final isSelected = _selectedDate != null &&
                  _selectedDate!.year == date.year &&
                  _selectedDate!.month == date.month &&
                  _selectedDate!.day == date.day;

              const weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
              final weekdayLabel =
                  isToday ? 'H.NAY' : weekdays[date.weekday % 7];

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedDate = date);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 46,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF4F46E5)
                        : (isDark ? const Color(0xFF162032) : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : (isToday
                              ? const Color(0xFF4F46E5)
                              : (isDark
                                  ? const Color(0xFF243045)
                                  : const Color(0xFFE2E8F0))),
                      width: isSelected ? 2 : 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF4F46E5)
                                  .withValues(alpha: 0.50),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        weekdayLabel,
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                          color: isSelected
                              ? const Color(0xFFC7D2FE)
                              : (isToday
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFF94A3B8)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- 4. THANH TÌM KIẾM KẾT HỢP MINI BỘ LỌC CHỒNG / VỢ ---
  Widget _buildSearchAndOwnerRow(bool isDark) {
    return Row(
      children: [
        // Ô tìm kiếm
        Expanded(
          child: FinoraClayCard(
            radius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            subtle: true,
            child: Row(
              children: [
                const Icon(LucideIcons.search,
                    size: 15, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Tìm kiếm tên, số tiền...',
                      hintStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () => _searchController.clear(),
                    child: const Icon(LucideIcons.x,
                        size: 14, color: Color(0xFF94A3B8)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Mini capsule Chồng / Vợ
        FinoraClayCard(
          radius: 16,
          padding: const EdgeInsets.all(3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTxOwnerBtn('all', 'Tất cả'),
              _buildTxOwnerBtn('husband', '👨 Chồng'),
              _buildTxOwnerBtn('wife', '👩 Vợ'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTxOwnerBtn(String key, String label) {
    final isSelected = _ownerFilter == key;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _ownerFilter = key);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // --- 5. DẢI LỌC LOẠI TIỀN (PILL FILTER CHIPS) ---
  Widget _buildTypeFilterRow(bool isDark, int income, int expense) {
    final chips = [
      {'key': 'all', 'label': 'Tất cả loại'},
      {'key': 'expense', 'label': 'Chi Tiêu (-${_formatCompact(expense)})'},
      {'key': 'income', 'label': 'Thu Nhập (+${_formatCompact(income)})'},
    ];

    return Row(
      children: chips.map((c) {
        final key = c['key'] as String;
        final label = c['label'] as String;
        final isSelected = _typeFilter == key;

        Color textColor;
        if (isSelected) {
          textColor = Colors.white;
        } else if (key == 'expense') {
          textColor = const Color(0xFFF43F5E);
        } else if (key == 'income') {
          textColor = const Color(0xFF10B981);
        } else {
          textColor = isDark ? Colors.white70 : const Color(0xFF64748B);
        }

        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _typeFilter = key);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? const Color(0xFF4F46E5) : const Color(0xFF0F172A))
                    : (isDark ? const Color(0xFF162032) : Colors.white),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark
                          ? const Color(0xFF243045)
                          : const Color(0xFFE2E8F0)),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: (isDark
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFF0F172A))
                              .withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- 6. DANH SÁCH GIAO DỊCH THEO NGÀY (CÓ ICON KÍNH 3D & TAG CHỒNG/VỢ) ---
  Widget _buildDayGroup(
      String dayKey, List<TransactionModel> txList, bool isDark) {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayStr =
        DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    final dayDate = DateTime.tryParse(dayKey) ?? now;
    const weekdays = [
      'CHỦ NHẬT',
      'THỨ HAI',
      'THỨ BA',
      'THỨ TƯ',
      'THỨ NĂM',
      'THỨ SÁU',
      'THỨ BẢY'
    ];
    final weekdayStr = weekdays[dayDate.weekday % 7];

    String dayTitle;
    if (dayKey == todayStr) {
      dayTitle = 'HÔM NAY ($weekdayStr, ${DateFormat('dd/MM').format(dayDate)})';
    } else if (dayKey == yesterdayStr) {
      dayTitle = 'HÔM QUA ($weekdayStr, ${DateFormat('dd/MM').format(dayDate)})';
    } else {
      dayTitle = '$weekdayStr (${DateFormat('dd/MM').format(dayDate)})';
    }

    // Tính thặng dư/tổng chi ngày
    int dayIncome = 0;
    int dayExpense = 0;
    for (final tx in txList) {
      if (tx.type == 'income') {
        dayIncome += tx.amount;
      } else if (tx.type == 'expense') {
        dayExpense += tx.amount;
      }
    }
    final netDay = dayIncome - dayExpense;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dayTitle,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : const Color(0xFF94A3B8),
                ),
              ),
              Text(
                netDay >= 0
                    ? 'Thặng dư: +${formatVND(netDay)}'
                    : 'Tổng chi: -${formatVND(netDay.abs())}',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: netDay >= 0
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF43F5E),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Các hàng thẻ giao dịch
        ...txList.map((tx) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _buildTransactionCard(tx, isDark),
            )),
      ],
    );
  }

  Widget _buildTransactionCard(TransactionModel tx, bool isDark) {
    final isIncome = tx.type == 'income';
    final isTransfer = tx.type == 'transfer';
    final nameLower = (tx.note ?? '').toLowerCase();

    // Owner tag
    String owner = 'Chung';
    Color ownerBg = const Color(0xFFFEF3C7);
    Color ownerText = const Color(0xFF92400E);

    if (nameLower.contains('chồng') ||
        tx.walletName?.toLowerCase().contains('vcb') == true ||
        tx.walletName?.toLowerCase().contains('vietcombank') == true ||
        tx.walletName?.toLowerCase().contains('techcom') == true) {
      owner = '👨 Chồng';
      ownerBg = const Color(0xFFE0E7FF);
      ownerText = const Color(0xFF3730A3);
    } else if (nameLower.contains('vợ') ||
        tx.walletName?.toLowerCase().contains('momo') == true ||
        tx.walletName?.toLowerCase().contains('tiền mặt') == true) {
      owner = '👩 Vợ';
      ownerBg = const Color(0xFFFCE7F3);
      ownerText = const Color(0xFF9D174D);
    }

    final txDate = tx.date > 100000000000
        ? DateTime.fromMillisecondsSinceEpoch(tx.date)
        : DateTime.fromMillisecondsSinceEpoch(tx.date * 1000);
    final timeStr = DateFormat('HH:mm').format(txDate);

    final title = (tx.note != null && tx.note!.isNotEmpty)
        ? tx.note!
        : (tx.categoryName ?? 'Giao dịch');
    final walletName = tx.walletName ?? 'Ví';
    final categoryText = tx.categoryName ?? 'Chung';

    final amountColor = isIncome
        ? const Color(0xFF10B981)
        : (isTransfer ? const Color(0xFF4F46E5) : const Color(0xFFF43F5E));
    final prefix = isIncome ? '+' : (isTransfer ? '' : '-');

    return FinoraClayCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onTap: () {
        HapticFeedback.lightImpact();
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
      child: Row(
        children: [
          // 3D Glass Orb Icon
          Finora3DGlassOrb(
            size: 40,
            tint: amountColor,
            child: Icon(
              isIncome
                  ? LucideIcons.arrow_down_left
                  : (isTransfer
                      ? LucideIcons.arrow_right_left
                      : LucideIcons.arrow_up_right),
              size: 19,
              color: amountColor,
            ),
          ),
          const SizedBox(width: 10),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: ownerBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        owner,
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: ownerText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$walletName • $timeStr • $categoryText',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : const Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Amount
          Text(
            '$prefix${formatVND(tx.amount)}',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: amountColor,
              letterSpacing: -0.3,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(LucideIcons.receipt,
              size: 40, color: isDark ? Colors.white30 : Colors.black26),
          const SizedBox(height: 12),
          Text(
            'Không có giao dịch nào phù hợp',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hãy thử đổi ngày, tháng hoặc bỏ bớt các bộ lọc',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
