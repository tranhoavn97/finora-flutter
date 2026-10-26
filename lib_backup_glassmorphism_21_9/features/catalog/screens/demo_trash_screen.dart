import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/v8/finora_v8.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../widgets/catalog_glass_card.dart';

final NumberFormat _vnd = NumberFormat('#,##0', 'vi_VN');

/// Screen 19: Trash (Thùng rác & khôi phục dữ liệu đã xóa) in Glassmorphism 2.0
class DemoTrashScreen extends StatefulWidget {
  final bool isLiveMode;
  final VoidCallback? onBack;

  const DemoTrashScreen({
    super.key,
    this.isLiveMode = false,
    this.onBack,
  });

  @override
  State<DemoTrashScreen> createState() => _DemoTrashScreenState();
}

class _DemoTrashScreenState extends State<DemoTrashScreen> {
  String _selectedFilter = 'Tất cả';

  final List<Map<String, dynamic>> _trashItems = [
    {
      'id': 'tr1',
      'title': 'Chi mua sách Alpha Books',
      'amount': 450000,
      'category': 'Giáo dục',
      'type': 'Giao dịch',
      'deletedAt': '20/09/2026 14:10',
      'expiresIn': '29 ngày',
    },
    {
      'id': 'tr2',
      'title': 'Ví phụ ShopeePay',
      'amount': 240000,
      'category': 'Ví điện tử',
      'type': 'Ví tiền',
      'deletedAt': '18/09/2026 09:20',
      'expiresIn': '27 ngày',
    },
    {
      'id': 'tr3',
      'title': 'Quỹ du lịch Hàn Quốc',
      'amount': 15000000,
      'category': 'Mục tiêu',
      'type': 'Mục tiêu',
      'deletedAt': '15/09/2026 21:00',
      'expiresIn': '24 ngày',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _trashItems.where((i) {
      if (_selectedFilter == 'Tất cả') return true;
      return i['type'] == _selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: FinoraPageHeader(
                  title: 'Thùng rác & Lưu trữ',
                  onBack: widget.onBack ?? () => Navigator.maybePop(context),
                  actions: [
                    if (_trashItems.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          setState(() => _trashItems.clear());
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã dọn sạch thùng rác!')),
                          );
                        },
                        child: const Text(
                          'Dọn sạch',
                          style: TextStyle(color: GlassmorphismTokens.expense, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: CatalogGlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: GlassmorphismTokens.warning.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.clock, color: GlassmorphismTokens.warning, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tự động xóa vĩnh viễn sau 30 ngày',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Các mục trong thùng rác có thể khôi phục lại bất cứ lúc nào trước thời hạn.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: ['Tất cả', 'Giao dịch', 'Ví tiền', 'Mục tiêu'].map((f) {
                    final isSel = _selectedFilter == f;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedFilter = f);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? GlassmorphismTokens.primary.withValues(alpha: isDark ? 0.35 : 0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSel ? GlassmorphismTokens.primary.withValues(alpha: 0.6) : (isDark ? Colors.white12 : Colors.black12),
                          ),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                            color: isSel ? GlassmorphismTokens.primary : (isDark ? Colors.white60 : Colors.black54),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            if (items.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(LucideIcons.trash, size: 48, color: isDark ? Colors.white24 : Colors.black12),
                        const SizedBox(height: 12),
                        Text(
                          'Thùng rác trống',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.black45),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, idx) {
                      final item = items[idx];
                      return CatalogGlassCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: GlassmorphismTokens.expense.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(LucideIcons.trash, color: GlassmorphismTokens.expense, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'] as String,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${item['category']} • Xóa lúc ${item['deletedAt']}',
                                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Hết hạn sau: ${item['expiresIn']}',
                                    style: const TextStyle(fontSize: 11, color: GlassmorphismTokens.warning, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${_vnd.format(item['amount'])} đ',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      _trashItems.removeWhere((i) => i['id'] == item['id']);
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Đã khôi phục "${item['title']}"')),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: GlassmorphismTokens.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.rotate_ccw, size: 12, color: GlassmorphismTokens.primary),
                                        SizedBox(width: 4),
                                        Text('Khôi phục', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GlassmorphismTokens.primary)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
