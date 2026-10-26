import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../core/design_system/v8/finora_v8.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../widgets/catalog_glass_card.dart';

/// Screen 15: Settings (Cài đặt hệ thống, tiền tệ, bảo mật) in Glassmorphism 2.0
class DemoSettingsScreen extends StatefulWidget {
  final bool isLiveMode;
  final VoidCallback? onBack;

  const DemoSettingsScreen({
    super.key,
    this.isLiveMode = false,
    this.onBack,
  });

  @override
  State<DemoSettingsScreen> createState() => _DemoSettingsScreenState();
}

class _DemoSettingsScreenState extends State<DemoSettingsScreen> {
  String _selectedTheme = 'Tối (Dark Aurora)';
  Color _accentColor = GlassmorphismTokens.primary;
  bool _enableBiometrics = true;
  bool _enableSound = true;

  final List<Color> _accentColors = const [
    Color(0xFF007AFF), // Blue
    Color(0xFF34C759), // Green
    Color(0xFFFF9500), // Orange
    Color(0xFFAF52DE), // Purple
    Color(0xFFFF2D55), // Pink
  ];

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
                  title: 'Cài đặt hệ thống',
                  onBack: widget.onBack ?? () => Navigator.maybePop(context),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'Giao diện & Hiệu ứng kính mờ (Glassmorphism 2.0)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : Colors.black54),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CatalogGlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chế độ hiển thị',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: ['Sáng', 'Tối (Dark Aurora)', 'Hệ thống'].map((mode) {
                          final isSel = _selectedTheme == mode;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedTheme = mode);
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSel ? _accentColor.withValues(alpha: 0.2) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSel ? _accentColor : (isDark ? Colors.white12 : Colors.black12),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  mode,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                    color: isSel ? _accentColor : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Màu chủ đạo (Accent Palette)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: _accentColors.map((color) {
                          final isSel = _accentColor == color;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() => _accentColor = color);
                            },
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSel ? Colors.white : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: isSel ? 0.6 : 0.2),
                                    blurRadius: isSel ? 12 : 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: isSel ? const Icon(LucideIcons.check, size: 20, color: Colors.white) : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  'Bảo mật & Trải nghiệm',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : Colors.black54),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CatalogGlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Xác thực sinh trắc học (Face ID / Vân tay)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Khóa màn hình khi thoát ứng dụng', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        value: _enableBiometrics,
                        activeThumbColor: Colors.white,
                        activeTrackColor: _accentColor,
                        onChanged: (val) {
                          HapticFeedback.lightImpact();
                          setState(() => _enableBiometrics = val);
                        },
                      ),
                      Divider(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Phản hồi xúc giác & âm thanh', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Rung nhẹ khi thao tác trên các nút kính', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        value: _enableSound,
                        activeThumbColor: Colors.white,
                        activeTrackColor: _accentColor,
                        onChanged: (val) {
                          HapticFeedback.lightImpact();
                          setState(() => _enableSound = val);
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
                  child: Text(
                    'FINORA Flutter v2.0 • Design System Glassmorphism 2.0',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
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
