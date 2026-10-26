import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../core/design_system/v8/finora_v8.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../widgets/catalog_glass_card.dart';

/// Screen 20: Showcase (Trình diễn tính năng nổi bật & Glassmorphism 2.0 Engine)
class DemoShowcaseScreen extends StatefulWidget {
  final bool isLiveMode;
  final VoidCallback? onBack;

  const DemoShowcaseScreen({
    super.key,
    this.isLiveMode = false,
    this.onBack,
  });

  @override
  State<DemoShowcaseScreen> createState() => _DemoShowcaseScreenState();
}

class _DemoShowcaseScreenState extends State<DemoShowcaseScreen> {
  double _blurSigma = 24.0;
  double _surfaceAlpha = 0.70;
  double _borderRadius = 22.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  title: 'Showcase Glassmorphism 2.0',
                  onBack: widget.onBack ?? () => Navigator.maybePop(context),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: CatalogGlassCard(
                  radius: _borderRadius,
                  blurSigma: _blurSigma,
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Liquid Glass Live Preview',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: GlassmorphismTokens.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Sigma: ${_blurSigma.toInt()}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GlassmorphismTokens.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Hiệu ứng kính mờ thời gian thực kết hợp viền phản quang specular highlight hairline và khúc xạ cực quang Aurora đa tầng.',
                        style: TextStyle(fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Thu nhập ròng', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  SizedBox(height: 4),
                                  Text('+42,500,000 đ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: GlassmorphismTokens.income)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Tích lũy đạt', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  SizedBox(height: 4),
                                  Text('86.4%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: GlassmorphismTokens.primary)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'Bộ điều khiển thông số thời gian thực',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : Colors.black54),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CatalogGlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Độ mờ kính (Backdrop Blur Sigma)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('${_blurSigma.toInt()} px', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: _blurSigma,
                        min: 8.0,
                        max: 60.0,
                        activeColor: GlassmorphismTokens.primary,
                        onChanged: (val) {
                          setState(() => _blurSigma = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Độ trong suốt nền (Surface Alpha)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('${(_surfaceAlpha * 100).toInt()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: _surfaceAlpha,
                        min: 0.3,
                        max: 0.95,
                        activeColor: GlassmorphismTokens.primary,
                        onChanged: (val) {
                          setState(() => _surfaceAlpha = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Bán kính bo góc (Corner Radius)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('${_borderRadius.toInt()} px', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: _borderRadius,
                        min: 0.0,
                        max: 36.0,
                        activeColor: GlassmorphismTokens.primary,
                        onChanged: (val) {
                          setState(() => _borderRadius = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                child: Center(
                  child: TextButton.icon(
                    icon: const Icon(LucideIcons.rotate_ccw, size: 16),
                    label: const Text('Khôi phục chuẩn thiết kế mặc định'),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _blurSigma = 24.0;
                        _surfaceAlpha = 0.70;
                        _borderRadius = 22.0;
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
