import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/premium_widgets.dart';
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
            backgroundColor: const Color(0xFF138875),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF14273A) : const Color(0xFFF1F6FA),
      body: AmbientFloatingBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 1. Soft Header: head('Thùng rác', 'Có thể đổi ý, không sao cả.')
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.maybePop(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E3146) : Colors.white,
                              borderRadius: BorderRadius.circular(19),
                              border: Border.all(
                                color: isDark ? const Color(0xFF2E455C) : const Color(0xFFDCE7F0),
                              ),
                            ),
                            child: Icon(
                              LucideIcons.chevron_left,
                              size: 20,
                              color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thùng rác',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Có thể đổi ý, không sao cả.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFFABC0D3) : const Color(0xFF7A90A5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _loadTrash,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E3146) : Colors.white,
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2E455C) : const Color(0xFFDCE7F0),
                          ),
                        ),
                        child: Icon(
                          LucideIcons.rotate_cw,
                          size: 18,
                          color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Trash Content List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                        children: [
                          // Hero center message matching app.js
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Column(
                              children: [
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E3146) : Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF2E455C) : const Color(0xFFDCE7F0),
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      LucideIcons.archive_restore,
                                      size: 34,
                                      color: isDark ? const Color(0xFFABC0D3) : const Color(0xFF5B738B),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Một khoảng chờ an toàn',
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                    color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Các mục đã xóa được giữ trong 30 ngày.\nKhôi phục khi bạn cần.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: isDark ? const Color(0xFFABC0D3) : const Color(0xFF7A90A5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Real Trash items or demo item matching app.js
                          if (_items.isEmpty)
                            _buildTrashCard(
                              icon: LucideIcons.shopping_bag,
                              title: 'Mua sắm · Giao dịch trùng',
                              subtitle: 'Đã xóa hôm qua · Còn 29 ngày',
                              amount: '680.000 ₫',
                              onRestore: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã khôi phục mục mô phỏng!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              isDark: isDark,
                            )
                          else
                            ..._items.map((item) {
                              final deletedDate = item.deletedAt ?? DateTime.now();
                              final daysLeft = item.daysRemaining;
                              final dateStr = DateFormat('dd/MM').format(deletedDate);
                              return _buildTrashCard(
                                icon: _resolveTrashIcon(item.collectionName),
                                title: item.label,
                                subtitle: 'Đã xóa $dateStr · Còn $daysLeft ngày',
                                amount: item.collectionLabel,
                                onRestore: () => _restore(item),
                                isDark: isDark,
                              );
                            }),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _resolveTrashIcon(String collection) {
    switch (collection) {
      case 'transactions':
        return LucideIcons.receipt;
      case 'wallets':
        return LucideIcons.wallet;
      case 'assets':
        return LucideIcons.gem;
      case 'loans':
        return LucideIcons.hand_coins;
      case 'goals':
        return LucideIcons.flag;
      default:
        return LucideIcons.trash;
    }
  }

  Widget _buildTrashCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required VoidCallback onRestore,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2C3E) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF2B3F55) : const Color(0xFFE4EDF4),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF142434) : const Color(0xFFF1F6FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 20,
                    color: isDark ? const Color(0xFFABC0D3) : const Color(0xFF5B738B),
                  ),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFFABC0D3) : const Color(0xFF7A90A5),
                      ),
                    ),
                  ],
                ),
              ),
              if (amount.isNotEmpty)
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: onRestore,
              icon: const Icon(LucideIcons.rotate_ccw, size: 16),
              label: const Text('Khôi phục giao dịch'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF1C3654) : const Color(0xFFEAF1FF),
                foregroundColor: const Color(0xFF005FEA),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(21),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
