import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../../core/design_system/app_duration.dart';
import '../../main.dart'; // To navigate to AuthGate

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Quản lý Dòng tiền',
      description: 'Theo dõi chi tiết các tài khoản, thẻ tín dụng, khoản vay và nợ ở một nơi duy nhất với giao diện Material 3 mượt mà và trực quan.',
    ),
    _OnboardingPageData(
      icon: Icons.donut_large_outlined,
      title: 'Tự động hóa Ngân sách',
      description: 'Lập kế hoạch hạn mức chi tiêu hàng tháng dễ dàng. Hệ thống sẽ tự động đồng bộ hóa và cảnh báo khi chi tiêu sắp vượt ngưỡng.',
    ),
    _OnboardingPageData(
      icon: Icons.psychology_outlined,
      title: 'Trí tuệ nhân tạo Gemini',
      description: 'Hỏi cố vấn tài chính AI về thói quen tiêu dùng của bạn, nhận đề xuất hạn mức và trích xuất hóa đơn tự động qua ảnh chụp.',
    ),
  ];

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthGate(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return GradientBackground(
      child: FloatingBubblesBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        'Bỏ qua',
                        style: AppTypography.footnote.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      onPageChanged: (idx) {
                        setState(() {
                          _currentPage = idx;
                        });
                      },
                      itemBuilder: (context, idx) {
                        final data = _pages[idx];
                        return Center(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                              child: GlassCard(
                                radius: AppRadius.xl,
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxxl),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Soft floating icon
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDark ? AppColors.darkSurfaceElevated : Colors.white.withOpacity(0.5),
                                        border: Border.all(
                                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                        ),
                                      ),
                                      child: Icon(
                                        data.icon,
                                        size: 40,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xxl),
                                    Text(
                                      data.title,
                                      textAlign: TextAlign.center,
                                      style: AppTypography.title2.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      data.description,
                                      textAlign: TextAlign.center,
                                      style: AppTypography.body.copyWith(
                                        height: 1.5,
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Pagination dots & Next button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Dots
                      Row(
                        children: List.generate(
                          _pages.length,
                          (index) => AnimatedContainer(
                            duration: AppDuration.normal,
                            margin: const EdgeInsets.only(right: 6),
                            width: _currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: _currentPage == index
                                  ? AppColors.accent
                                  : (isDark ? Colors.white24 : Colors.black12),
                            ),
                          ),
                        ),
                      ),
                      // Action Button
                      SizedBox(
                        width: 140,
                        child: GradientButton(
                          onPressed: () {
                            if (_currentPage == _pages.length - 1) {
                              _finishOnboarding();
                            } else {
                              _pageController.nextPage(
                                duration: AppDuration.slow,
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          radius: AppRadius.sm,
                          colors: const [AppColors.accent, AppColors.accentLight],
                          child: Text(
                            _currentPage == _pages.length - 1 ? 'Bắt đầu' : 'Tiếp theo',
                            style: AppTypography.buttonLabel.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
  });
}
