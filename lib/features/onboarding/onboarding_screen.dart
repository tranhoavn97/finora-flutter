import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart'; // To navigate to AuthGate

/// Màn hình giới thiệu Onboarding chuẩn thiết kế từ Brand Board chính thức (source-board.png).
/// Gồm 3 bước cụ thể:
/// 1. Quản lý tài chính cùng Finora (Linh vật Onboarding 01 Chào mừng)
/// 2. Theo dõi chi tiêu mọi lúc mọi nơi (Thẻ tổng chi tiêu tháng 12.680.000 đ + Linh vật Onboarding 02 Ngân sách)
/// 3. Cùng gia đình kiến tạo tương lai (3 thẻ mục tiêu Mua nhà, Du lịch, Giáo dục con + Linh vật Onboarding 03 Gia đình)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

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

  void _onNext() {
    if (_currentPage == 2) {
      _finishOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const ivoryBg = Color(0xFFF9FBFA);
    const pinePrimary = Color(0xFF003D35);
    const emeraldPrimary = Color(0xFF00866A);
    const metaColor = Color(0xFF586B63);

    return Scaffold(
      backgroundColor: ivoryBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48), // balance
                  // App Brand text
                  const Text(
                    'Finora',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: pinePrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  TextButton(
                    onPressed: _finishOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: emeraldPrimary,
                      textStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Bỏ qua'),
                  ),
                ],
              ),
            ),

            // 3-Step PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                children: [
                  _buildStep1Welcome(pinePrimary, metaColor),
                  _buildStep2Tracking(pinePrimary, metaColor),
                  _buildStep3Family(pinePrimary, metaColor),
                ],
              ),
            ),

            // Pagination Dots Indicator
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (idx) {
                  final isActive = _currentPage == idx;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 26 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive ? emeraldPrimary : const Color(0xFFD4E2DC),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),

            // Primary Bottom Action Pill Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: emeraldPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: _onNext,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage == 0
                            ? 'Bắt đầu'
                            : (_currentPage == 1 ? 'Tiếp tục' : 'Bắt đầu ngay'),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(LucideIcons.arrow_right, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bước 1: Quản lý tài chính cùng Finora
  Widget _buildStep1Welcome(Color pinePrimary, Color metaColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Mascot 01: Welcome
          Image.asset(
            'assets/mascot/onboarding-01-welcome.png',
            height: 270,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          Text(
            'Quản lý tài chính\ncùng Finora',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: pinePrimary,
              height: 1.25,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Chi tiêu thông minh – Tích lũy vững vàng',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: metaColor,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Bước 2: Theo dõi chi tiêu mọi lúc, mọi nơi
  Widget _buildStep2Tracking(Color pinePrimary, Color metaColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            'Theo dõi chi tiêu\nmọi lúc, mọi nơi',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: pinePrimary,
              height: 1.25,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hiểu rõ dòng tiền của bạn qua biểu đồ trực quan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: metaColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),

          // The Signature Dark Pine Expense Card from source-board.png
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF003D35),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF003D35).withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng chi tiêu tháng',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xCCFFFFFF),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '12.680.000 đ',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                // 4 Category Quick Pills
                Row(
                  children: [
                    _buildCategoryPill(LucideIcons.utensils, 'Ăn uống'),
                    const SizedBox(width: 8),
                    _buildCategoryPill(LucideIcons.car, 'Đi lại'),
                    const SizedBox(width: 8),
                    _buildCategoryPill(LucideIcons.shopping_bag, 'Mua sắm'),
                    const SizedBox(width: 8),
                    _buildCategoryPill(LucideIcons.layout_grid, 'Khác'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Mascot 02: Budget & Saving
          Image.asset(
            'assets/mascot/onboarding-02-budget.png',
            height: 180,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF34D399)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Bước 3: Cùng gia đình kiến tạo tương lai
  Widget _buildStep3Family(Color pinePrimary, Color metaColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            'Cùng gia đình\nkiến tạo tương lai',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: pinePrimary,
              height: 1.25,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Lập kế hoạch tài chính cho những mục tiêu lớn hơn',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: metaColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // 3 Goal Cards from source-board.png
          _buildGoalCard(
            icon: LucideIcons.house,
            iconBg: const Color(0xFFE6F4EA),
            iconColor: const Color(0xFF00866A),
            title: 'Mua nhà',
            amount: '2.000.000.000 đ',
          ),
          const SizedBox(height: 10),
          _buildGoalCard(
            icon: LucideIcons.plane,
            iconBg: const Color(0xFFE0F2FE),
            iconColor: const Color(0xFF0284C7),
            title: 'Du lịch',
            amount: '500.000.000 đ',
          ),
          const SizedBox(height: 10),
          _buildGoalCard(
            icon: LucideIcons.graduation_cap,
            iconBg: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFD97706),
            title: 'Giáo dục con',
            amount: '1.000.000.000 đ',
          ),
          const SizedBox(height: 12),

          // Mascot 03: Family
          Image.asset(
            'assets/mascot/onboarding-03-family.png',
            height: 140,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildGoalCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String amount,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEEC), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF003D35),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevron_right, size: 16, color: Color(0xFFB0BEB8)),
        ],
      ),
    );
  }
}
