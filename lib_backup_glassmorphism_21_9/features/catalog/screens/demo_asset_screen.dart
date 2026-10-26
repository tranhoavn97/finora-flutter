import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/v8/finora_v8.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../catalog_mock_data.dart';
import '../widgets/catalog_glass_card.dart';
import '../widgets/catalog_hero_card.dart';

final NumberFormat _vnd = NumberFormat('#,##0', 'vi_VN');

/// Screen 8: Asset (Quản lý tài sản & danh mục đầu tư) in Glassmorphism 2.0
class DemoAssetScreen extends StatefulWidget {
  final bool isLiveMode;
  final VoidCallback? onBack;

  const DemoAssetScreen({
    super.key,
    this.isLiveMode = false,
    this.onBack,
  });

  @override
  State<DemoAssetScreen> createState() => _DemoAssetScreenState();
}

class _DemoAssetScreenState extends State<DemoAssetScreen> {
  String _selectedType = 'Tất cả';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allAssets = CatalogMockData.assets;
    final assets = allAssets.where((a) {
      if (_selectedType == 'Tất cả') return true;
      return a.category == _selectedType;
    }).toList();

    final totalValue = allAssets.fold<int>(0, (s, a) => s + a.marketValue);
    final totalCost = allAssets.fold<int>(0, (s, a) => s + a.costPrice);
    final totalGain = totalValue - totalCost;

    final types = ['Tất cả', 'Vàng', 'Bất động sản', 'Cổ phiếu', 'Tiết kiệm'];

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
                  title: 'Danh mục tài sản',
                  onBack: widget.onBack ?? () => Navigator.maybePop(context),
                  actions: [
                    FinoraAddIconButton(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Thêm tài sản mới')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: CatalogHeroCard(
                title: 'Tổng định giá danh mục',
                amount: totalValue,
                subtitle: 'Lãi chưa chốt: +${_vnd.format(totalGain)} đ (+${(totalGain * 100 / totalCost).toStringAsFixed(1)}%)',
                gradientColors: const [
                  Color(0xFF312E81),
                  Color(0xFF4F46E5),
                ],
                metrics: [
                  HeroMetricItem(
                    label: 'Vốn gốc đầu tư',
                    value: _vnd.format(totalCost),
                    color: Colors.white70,
                  ),
                  HeroMetricItem(
                    label: 'Số tài sản',
                    value: '${allAssets.length} hạng mục',
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: types.map((t) {
                      final isSel = _selectedType == t;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedType = t);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSel
                                ? GlassmorphismTokens.primary.withValues(alpha: isDark ? 0.35 : 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSel
                                  ? GlassmorphismTokens.primary.withValues(alpha: 0.6)
                                  : (isDark ? Colors.white12 : Colors.black12),
                            ),
                          ),
                          child: Text(
                            t,
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
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, idx) {
                    final asset = assets[idx];
                    return _buildAssetCard(asset, isDark);
                  },
                  childCount: assets.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetCard(CatalogAssetItem asset, bool isDark) {
    final gain = asset.marketValue - asset.costPrice;
    final gainPct = (gain * 100 / asset.costPrice).toStringAsFixed(1);
    final isProfitable = gain >= 0;

    return CatalogGlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: GlassmorphismTokens.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GlassmorphismTokens.primary.withValues(alpha: 0.3)),
            ),
            child: Icon(asset.icon, color: GlassmorphismTokens.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      asset.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        asset.category,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Giá vốn: ${_vnd.format(asset.costPrice)} đ',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_vnd.format(asset.marketValue)} đ',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: -0.2),
              ),
              const SizedBox(height: 3),
              Text(
                '${isProfitable ? '+' : ''}$gainPct%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isProfitable ? GlassmorphismTokens.income : GlassmorphismTokens.expense,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
