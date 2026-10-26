import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../data/services/trash_repository.dart';

class TrashScreen extends StatefulWidget {
  final String userId;
  final String? familyId;

  const TrashScreen({
    super.key,
    required this.userId,
    this.familyId,
  });

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final TrashRepository _repo = TrashRepository();
  List<TrashItemModel> _items = [];
  bool _isLoading = true;
  String _filter = 'all'; // 'all', 'transactions', 'wallets', 'assets', etc.

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  Future<void> _loadTrash() async {
    setState(() => _isLoading = true);
    try {
      final items = await _repo.getTrashItems(
        widget.userId,
        familyId: widget.familyId,
      );
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải thùng rác: $e')),
        );
      }
    }
  }

  Future<void> _restore(TrashItemModel item) async {
    HapticFeedback.mediumImpact();
    try {
      await _repo.restoreItem(
        widget.userId,
        item,
        familyId: widget.familyId,
      );
      setState(() {
        _items.removeWhere((i) => i.id == item.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã khôi phục "${item.label}" thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi khôi phục: $e')),
        );
      }
    }
  }

  Future<void> _deletePermanently(TrashItemModel item) async {
    HapticFeedback.heavyImpact();
    final confirm = await showConfirmDeleteDialog(
      context: context,
      title: 'Xóa vĩnh viễn?',
      content:
          'Bạn có chắc chắn muốn xóa vĩnh viễn "${item.label}" không? Thao tác này không thể hoàn tác.',
    );

    if (confirm && mounted) {
      try {
        await _repo.permanentlyDeleteItem(
          widget.userId,
          item,
          familyId: widget.familyId,
        );
        setState(() {
          _items.removeWhere((i) => i.id == item.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa vĩnh viễn mục này.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xóa vĩnh viễn: $e')),
          );
        }
      }
    }
  }

  List<TrashItemModel> get _filteredItems {
    if (_filter == 'all') return _items;
    return _items.where((i) => i.collectionName == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);

    final displayItems = _filteredItems;

    return GlassScaffold(
      appBar: GlassTopBar(
        title: 'Thùng rác 30 ngày',
        onBack: () => Navigator.of(context).pop(),
        actions: [
          IconButton(
            onPressed: _loadTrash,
            tooltip: 'Làm mới',
            icon: Icon(
              Icons.refresh_rounded,
              color: primaryTextColor,
              size: 22,
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Informational header banner
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16, GlassScaffold.topInset(context, 8), 16, 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withOpacity(0.7)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_delete_outlined,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tự động dọn dẹp sau 30 ngày',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Dữ liệu đã xóa có thể được khôi phục nguyên vẹn về vị trí ban đầu.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Category filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _filterChip('all', 'Tất cả (${_items.length})', isDark),
                  _filterChip(
                      'transactions',
                      'Giao dịch (${_items.where((i) => i.collectionName == 'transactions').length})',
                      isDark),
                  _filterChip(
                      'wallets',
                      'Ví (${_items.where((i) => i.collectionName == 'wallets').length})',
                      isDark),
                  _filterChip(
                      'assets',
                      'Tài sản (${_items.where((i) => i.collectionName == 'assets').length})',
                      isDark),
                  _filterChip(
                      'loans',
                      'Khoản nợ (${_items.where((i) => i.collectionName == 'loans').length})',
                      isDark),
                  _filterChip(
                      'goals',
                      'Mục tiêu (${_items.where((i) => i.collectionName == 'goals').length})',
                      isDark),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Items list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : displayItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_sweep_outlined,
                                size: 56,
                                color: secondaryTextColor.withOpacity(0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Thùng rác đang trống',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: secondaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Không có mục nào cần dọn dẹp',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryTextColor.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                          itemCount: displayItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = displayItems[index];
                            final delStr = item.deletedAt != null
                                ? DateFormat('dd/MM/yyyy HH:mm')
                                    .format(item.deletedAt!)
                                : 'Gần đây';

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withOpacity(isDark ? 0.2 : 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _iconForCollection(item.collectionName),
                                      size: 20,
                                      color: isDark
                                          ? Colors.white70
                                          : AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.label,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: primaryTextColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                item.collectionLabel,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              delStr,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: secondaryTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Days remaining tag
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: item.daysRemaining <= 5
                                          ? AppColors.error.withOpacity(0.12)
                                          : Colors.amber.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${item.daysRemaining} ngày',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: item.daysRemaining <= 5
                                            ? AppColors.error
                                            : Colors.amber.shade800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // Restore Button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.settings_backup_restore_rounded,
                                      color: AppColors.success,
                                      size: 22,
                                    ),
                                    tooltip: 'Khôi phục',
                                    onPressed: () => _restore(item),
                                  ),
                                  // Delete permanently Button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_forever_rounded,
                                      color: AppColors.error,
                                      size: 22,
                                    ),
                                    tooltip: 'Xóa vĩnh viễn',
                                    onPressed: () => _deletePermanently(item),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String key, String label, bool isDark) {
    final isSelected = _filter == key;
    final color = switch (key) {
      'transactions' => const Color(0xFFEF4444),
      'wallets' => const Color(0xFF8B5CF6),
      'budgets' => const Color(0xFFF59E0B),
      _ => AppColors.primary,
    };
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: LiquidFilterPill(
        selected: isSelected,
        label: label,
        color: color,
        onTap: () => setState(() => _filter = key),
      ),
    );
  }

  IconData _iconForCollection(String col) {
    switch (col) {
      case 'transactions':
        return Icons.receipt_long_rounded;
      case 'wallets':
        return Icons.account_balance_wallet_rounded;
      case 'assets':
        return Icons.trending_up_rounded;
      case 'loans':
        return Icons.handshake_rounded;
      case 'goals':
        return Icons.flag_rounded;
      case 'budgets':
        return Icons.pie_chart_outline_rounded;
      case 'categories':
        return Icons.category_rounded;
      default:
        return Icons.folder_outlined;
    }
  }
}
