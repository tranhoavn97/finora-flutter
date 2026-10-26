import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/design_system/v8/finora_v8.dart';
import '../../core/widgets/glass_widgets.dart';
import 'catalog_registry.dart';
import 'catalog_sandbox_screen.dart';
import 'widgets/catalog_glass_card.dart';

/// Screen Catalog Master Hub — 22-Screen Showcase Browser
class CatalogHubScreen extends StatefulWidget {
  const CatalogHubScreen({super.key});

  @override
  State<CatalogHubScreen> createState() => _CatalogHubScreenState();
}

class _CatalogHubScreenState extends State<CatalogHubScreen> {
  String _searchQuery = '';
  ScreenCluster? _selectedCluster;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allItems = CatalogRegistry.items;
    final filteredItems = allItems.where((item) {
      if (_selectedCluster != null && item.cluster != _selectedCluster) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = item.title.toLowerCase().contains(query);
        final matchVn = item.vietnameseTitle.toLowerCase().contains(query);
        final matchDesc = item.description.toLowerCase().contains(query);
        return matchTitle || matchVn || matchDesc;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Ambient Aurora Canvas
          AmbientFloatingBackground(
            isDark: isDark,
            child: const SizedBox.expand(),
          ),

          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: FinoraPageHeader(
                      title: 'Screen Catalog 2.0',
                      onBack: () => Navigator.maybePop(context),
                      actions: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: GlassmorphismTokens.primary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: GlassmorphismTokens.primary.withValues(alpha: 0.35)),
                          ),
                          child: const Text(
                            '22/22 Màn hình',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: GlassmorphismTokens.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Hero Statistics Banner
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: CatalogGlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: GlassmorphismTokens.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(LucideIcons.sparkles, color: GlassmorphismTokens.primary, size: 20),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Design System Glassmorphism 2.0',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Toàn bộ 22 màn hình chức năng của FINORA được thiết kế lại hoàn toàn mới với hiệu ứng kính mờ đa tầng, viền phản quang specular highlight và bảo toàn 100% dữ liệu thực.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.black87,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMetricCol('22', 'Màn hình demo', GlassmorphismTokens.primary),
                              _buildMetricCol('5', 'Cụm phân hệ', const Color(0xFF5856D6)),
                              _buildMetricCol('100%', 'Bảo toàn logic', GlassmorphismTokens.income),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Search Box - True Pill Shape
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      height: 46,
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                      ),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: const InputDecoration(
                          icon: Icon(LucideIcons.search, size: 18, color: Colors.grey),
                          hintText: 'Tìm kiếm màn hình chức năng...',
                          hintStyle: TextStyle(fontSize: 13),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),

                // Cluster Filter Pills - Seamless Pill Capsule Dock
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
                        ),
                        child: Row(
                          children: [
                            _buildClusterPill(null, 'Tất cả', LucideIcons.layout_grid, isDark),
                            ...ScreenCluster.values.map((c) => _buildClusterPill(c, c.label, c.icon, isDark)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 22 Screen Cards Grid
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, idx) {
                        final item = filteredItems[idx];
                        return _buildScreenCard(item, isDark);
                      },
                      childCount: filteredItems.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildClusterPill(ScreenCluster? cluster, String label, IconData icon, bool isDark) {
    final isSel = _selectedCluster == cluster;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedCluster = cluster);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSel ? GlassmorphismTokens.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: isSel
              ? [
                  BoxShadow(
                    color: GlassmorphismTokens.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSel ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                color: isSel ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenCard(ScreenCatalogItem item, bool isDark) {
    return CatalogGlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CatalogSandboxScreen(item: item),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: GlassmorphismTokens.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GlassmorphismTokens.primary.withValues(alpha: 0.3)),
            ),
            child: Icon(item.icon, color: GlassmorphismTokens.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.cluster.label,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54),
                      ),
                    ),
                    if (item.badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: GlassmorphismTokens.income.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.badge!,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: GlassmorphismTokens.income),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.vietnameseTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: GlassmorphismTokens.primary.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: GlassmorphismTokens.primary.withValues(alpha: 0.35)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Xem',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GlassmorphismTokens.primary),
                ),
                SizedBox(width: 3),
                Icon(LucideIcons.chevron_right, size: 12, color: GlassmorphismTokens.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
