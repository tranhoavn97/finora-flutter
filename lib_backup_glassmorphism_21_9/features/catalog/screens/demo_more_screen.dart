import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../core/design_system/v8/finora_v8.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../widgets/catalog_glass_card.dart';

/// Screen 21: More (Menu mở rộng & tiện ích tài chính) in Glassmorphism 2.0
class DemoMoreScreen extends StatelessWidget {
  final bool isLiveMode;
  final VoidCallback? onBack;

  const DemoMoreScreen({
    super.key,
    this.isLiveMode = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final utilities = [
      {'title': 'Tính lãi suất', 'subtitle': 'Lãi kép & gửi tiết kiệm', 'icon': LucideIcons.percent, 'color': const Color(0xFF007AFF)},
      {'title': 'Ước tính khoản vay', 'subtitle': 'Lịch trả góp & lãi dư nợ', 'icon': LucideIcons.calculator, 'color': const Color(0xFF34C759)},
      {'title': 'Tỷ giá & Giá vàng', 'subtitle': 'Cập nhật thị trường 24/7', 'icon': LucideIcons.coins, 'color': const Color(0xFFFF9500)},
      {'title': 'Xuất báo cáo Excel', 'subtitle': 'Sao kê đầy đủ phục vụ thuế', 'icon': LucideIcons.file_spreadsheet, 'color': const Color(0xFF10B981)},
      {'title': 'Bảo mật dữ liệu', 'subtitle': 'Sao lưu Cloud & Mã hóa', 'icon': LucideIcons.cloud, 'color': const Color(0xFF5856D6)},
      {'title': 'Hỗ trợ & Góp ý', 'subtitle': 'Đội ngũ Finora phản hồi 2h', 'icon': LucideIcons.headphones, 'color': const Color(0xFFFF2D55)},
    ];

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
                  title: 'Tiện ích mở rộng',
                  onBack: onBack ?? () => Navigator.maybePop(context),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: CatalogGlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: GlassmorphismTokens.primary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(LucideIcons.sparkles, color: GlassmorphismTokens.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hệ sinh thái công cụ Finora',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Bộ tiện ích tính toán và phân tích tài chính toàn diện dành cho bạn và gia đình.',
                              style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.25,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, idx) {
                    final item = utilities[idx];
                    final color = item['color'] as Color;
                    return CatalogGlassCard(
                      padding: const EdgeInsets.all(16),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đang mở tiện ích: ${item['title']}')),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(item['icon'] as IconData, color: color, size: 20),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] as String,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['subtitle'] as String,
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: utilities.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
