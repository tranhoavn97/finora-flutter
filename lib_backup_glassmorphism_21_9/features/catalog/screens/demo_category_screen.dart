import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/v8/finora_v8.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../catalog_mock_data.dart';
import '../widgets/catalog_glass_card.dart';

final NumberFormat _vnd = NumberFormat('#,##0', 'vi_VN');

/// Screen 9: Category (Danh mục thu chi & tùy biến nhãn) in Glassmorphism 2.0
class DemoCategoryScreen extends StatefulWidget {
  final bool isLiveMode;
  final VoidCallback? onBack;

  const DemoCategoryScreen({
    super.key,
    this.isLiveMode = false,
    this.onBack,
  });

  @override
  State<DemoCategoryScreen> createState() => _DemoCategoryScreenState();
}

class _DemoCategoryScreenState extends State<DemoCategoryScreen> {
  String _selectedGroup = 'Chi';
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allCats = CatalogMockData.categories;
    final categories = allCats.where((c) => c.group == _selectedGroup).toList();

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
                  title: 'Danh mục tài chính',
                  onBack: widget.onBack ?? () => Navigator.maybePop(context),
                  actions: [
                    FinoraHeaderIconButton(
                      icon: _isGridView ? LucideIcons.list : LucideIcons.layout_grid,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _isGridView = !_isGridView);
                      },
                    ),
                    const SizedBox(width: 8),
                    FinoraAddIconButton(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Thêm danh mục mới')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(child: _buildGroupTab('Chi', 'Chi tiêu', LucideIcons.arrow_up_right, isDark)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildGroupTab('Thu', 'Thu nhập', LucideIcons.arrow_down_left, isDark)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildGroupTab('Đầu tư', 'Đầu tư', LucideIcons.trending_up, isDark)),
                  ],
                ),
              ),
            ),
            if (_isGridView)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.15,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, idx) {
                      final c = categories[idx];
                      return _buildGridCategoryCard(c, isDark);
                    },
                    childCount: categories.length,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, idx) {
                      final c = categories[idx];
                      return _buildListCategoryCard(c, isDark);
                    },
                    childCount: categories.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupTab(String key, String label, IconData icon, bool isDark) {
    final isSel = _selectedGroup == key;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedGroup = key);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSel ? GlassmorphismTokens.primary.withValues(alpha: isDark ? 0.35 : 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSel ? GlassmorphismTokens.primary.withValues(alpha: 0.6) : (isDark ? Colors.white12 : Colors.black12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSel ? GlassmorphismTokens.primary : (isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                color: isSel ? GlassmorphismTokens.primary : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCategoryCard(CatalogCategoryItem cat, bool isDark) {
    return CatalogGlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(cat.icon, color: cat.color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${cat.count} GD',
                  style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black54),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cat.name,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${_vnd.format(cat.spent)} đ',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: GlassmorphismTokens.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListCategoryCard(CatalogCategoryItem cat, bool isDark) {
    return CatalogGlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cat.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(cat.icon, color: cat.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  '${cat.count} giao dịch trong tháng',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45),
                ),
              ],
            ),
          ),
          Text(
            '${_vnd.format(cat.spent)} đ',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
