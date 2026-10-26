import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../core/design_system/v8/finora_v8.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../widgets/catalog_glass_card.dart';

/// Screen 17: Onboarding (Giới thiệu luồng khởi động người dùng mới) in Glassmorphism 2.0
class DemoOnboardingScreen extends StatefulWidget {
  final bool isLiveMode;
  final VoidCallback? onBack;

  const DemoOnboardingScreen({
    super.key,
    this.isLiveMode = false,
    this.onBack,
  });

  @override
  State<DemoOnboardingScreen> createState() => _DemoOnboardingScreenState();
}

class _DemoOnboardingScreenState extends State<DemoOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Quản lý dòng tiền thông minh',
      'subtitle': 'Kiểm soát thu chi đa tài khoản, ví ngân hàng và tiền mặt với giao diện kính mờ Glassmorphism 2.0 đỉnh cao.',
      'icon': LucideIcons.wallet,
      'color': const Color(0xFF007AFF),
    },
    {
      'title': 'Tài chính gia đình đồng bộ',
      'subtitle': 'Kết nối vợ chồng minh bạch, theo dõi tỷ lệ đóng góp chi tiêu và tích lũy mục tiêu dài hạn chung.',
      'icon': LucideIcons.users,
      'color': const Color(0xFFAF52DE),
    },
    {
      'title': 'Trợ lý ảo Finora AI Copilot',
      'subtitle': 'Ghi chép giao dịch siêu tốc bằng giọng nói tiếng Việt tự nhiên và nhận tư vấn ngân sách thông minh tức thì.',
      'icon': LucideIcons.sparkles,
      'color': const Color(0xFFFF9500),
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FinoraBackButton(
                    onTap: widget.onBack ?? () => Navigator.maybePop(context),
                  ),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _pageController.jumpToPage(_slides.length - 1);
                    },
                    child: Text('Bỏ qua', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, idx) {
                  final slide = _slides[idx];
                  final color = slide['color'] as Color;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CatalogGlassCard(
                          padding: const EdgeInsets.all(36),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: color.withValues(alpha: 0.4)),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.35),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(slide['icon'] as IconData, size: 48, color: color),
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          slide['title'] as String,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black54,
                            height: 1.45,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(_slides.length, (idx) {
                      final isSel = idx == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        width: isSel ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isSel ? GlassmorphismTokens.primary : (isDark ? Colors.white24 : Colors.black12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlassmorphismTokens.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (_currentPage < _slides.length - 1) {
                        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Khởi tạo hoàn tất! Chào mừng đến với FINORA.')),
                        );
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == _slides.length - 1 ? 'Bắt đầu ngay' : 'Tiếp theo',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        const Icon(LucideIcons.arrow_right, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
