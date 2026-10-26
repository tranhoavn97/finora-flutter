import 'package:flutter/material.dart';
import '../frosted_glass.dart';

/// Interactive Showcase Screen for Finora Frosted Neo-Glass Design System
class FrostedGlassShowcaseScreen extends StatefulWidget {
  const FrostedGlassShowcaseScreen({super.key});

  @override
  State<FrostedGlassShowcaseScreen> createState() =>
      _FrostedGlassShowcaseScreenState();
}

class _FrostedGlassShowcaseScreenState
    extends State<FrostedGlassShowcaseScreen> {
  int _selectedTabIndex = 0;
  bool _isBalanceVisible = true;
  bool _isDarkPreview = false;

  @override
  Widget build(BuildContext context) {
    // Dynamic theme wrapper for the showcase preview
    final themeData = _isDarkPreview
        ? ThemeData.dark().copyWith(
            scaffoldBackgroundColor: FrostedGlassTokens.darkScaffoldBg,
          )
        : ThemeData.light().copyWith(
            scaffoldBackgroundColor: FrostedGlassTokens.lightScaffoldBg,
          );

    return Theme(
      data: themeData,
      child: Scaffold(
        backgroundColor: _isDarkPreview
            ? FrostedGlassTokens.darkScaffoldBg
            : FrostedGlassTokens.lightScaffoldBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: _isDarkPreview ? Colors.white : const Color(0xFF0F172A),
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            'Frosted Neo-Glass',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: _isDarkPreview ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          actions: [
            // Dark / Light preview toggle
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: FrostedNeoButton.circle(
                icon: _isDarkPreview
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                size: 38,
                isPrimary: false,
                onPressed: () {
                  setState(() => _isDarkPreview = !_isDarkPreview);
                },
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Decorative background lights to showcase glass refraction
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF005FEA).withValues(
                    alpha: _isDarkPreview ? 0.35 : 0.18,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 260,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF059669).withValues(
                    alpha: _isDarkPreview ? 0.25 : 0.12,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              right: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6366F1).withValues(
                    alpha: _isDarkPreview ? 0.30 : 0.15,
                  ),
                ),
              ),
            ),

            // Main Content
            ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Header Badge
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF005FEA).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFF005FEA).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 14, color: Color(0xFF005FEA)),
                        SizedBox(width: 6),
                        Text(
                          'Apple VisionOS Financial Edition',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF005FEA),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 1. HERO BALANCE CARD
                _buildHeroBalanceCard(context, _isDarkPreview),
                const SizedBox(height: 20),

                // 2. SEGMENTED TABS
                _buildSectionHeader('Segmented Controls', _isDarkPreview),
                const SizedBox(height: 10),
                FrostedNeoTabs(
                  labels: const ['Hôm nay', 'Tuần này', 'Tháng này', 'Năm nay'],
                  selectedIndex: _selectedTabIndex,
                  onChanged: (idx) => setState(() => _selectedTabIndex = idx),
                ),
                const SizedBox(height: 20),

                // 3. FINANCIAL METRICS TILES
                _buildSectionHeader('Thẻ Phân tích Tài chính', _isDarkPreview),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FrostedNeoCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FrostedNeoBadge.income(text: 'Thu nhập'),
                            const SizedBox(height: 10),
                            Text(
                              '+35.000.000 đ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: _isDarkPreview
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Đạt 112% mục tiêu',
                              style: TextStyle(
                                fontSize: 11,
                                color: _isDarkPreview
                                    ? FrostedGlassTokens.darkTextSecondary
                                    : FrostedGlassTokens.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FrostedNeoCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FrostedNeoBadge.expense(text: 'Chi tiêu'),
                            const SizedBox(height: 10),
                            Text(
                              '-14.280.000 đ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: _isDarkPreview
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Còn 48% ngân sách',
                              style: TextStyle(
                                fontSize: 11,
                                color: _isDarkPreview
                                    ? FrostedGlassTokens.darkTextSecondary
                                    : FrostedGlassTokens.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 4. INTERACTIVE BUTTONS & MODAL TRIGGER
                _buildSectionHeader('Nút Bấm & Modal Kính mờ', _isDarkPreview),
                const SizedBox(height: 10),
                FrostedNeoCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: FrostedNeoButton.primary(
                              label: 'Thêm giao dịch',
                              icon: Icons.add_rounded,
                              onPressed: () {
                                _openDemoSheet(context);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FrostedNeoButton.glass(
                              label: 'Mở BottomSheet',
                              icon: Icons.layers_rounded,
                              onPressed: () {
                                _openDemoSheet(context);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildCircleAction(
                            icon: Icons.qr_code_scanner_rounded,
                            label: 'Quét HĐ',
                            isDark: _isDarkPreview,
                          ),
                          _buildCircleAction(
                            icon: Icons.send_rounded,
                            label: 'Chuyển tiền',
                            isDark: _isDarkPreview,
                          ),
                          _buildCircleAction(
                            icon: Icons.pie_chart_rounded,
                            label: 'Báo cáo',
                            isDark: _isDarkPreview,
                          ),
                          _buildCircleAction(
                            icon: Icons.auto_awesome_rounded,
                            label: 'Finora AI',
                            isDark: _isDarkPreview,
                            isHighlighted: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 5. RECENT TRANSACTIONS IN FROSTED TILES
                _buildSectionHeader('Danh sách Giao dịch Kính mờ', _isDarkPreview),
                const SizedBox(height: 10),
                FrostedNeoCard(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      _buildTransactionTile(
                        icon: Icons.shopping_bag_outlined,
                        iconBg: const Color(0xFFE11D48).withValues(alpha: 0.12),
                        iconColor: const Color(0xFFE11D48),
                        title: 'Siêu thị WinMart',
                        subtitle: 'Hôm nay, 14:30 • Thẻ VPBank',
                        amount: '-450.000 đ',
                        isNegative: true,
                        isDark: _isDarkPreview,
                      ),
                      Divider(
                        height: 1,
                        indent: 68,
                        endIndent: 20,
                        color: _isDarkPreview
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE2E8F0),
                      ),
                      _buildTransactionTile(
                        icon: Icons.account_balance_wallet_outlined,
                        iconBg: const Color(0xFF059669).withValues(alpha: 0.12),
                        iconColor: const Color(0xFF059669),
                        title: 'Lương Techcombank',
                        subtitle: 'Hôm nay, 09:15 • Tài khoản chính',
                        amount: '+32.500.000 đ',
                        isNegative: false,
                        isDark: _isDarkPreview,
                      ),
                      Divider(
                        height: 1,
                        indent: 68,
                        endIndent: 20,
                        color: _isDarkPreview
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE2E8F0),
                      ),
                      _buildTransactionTile(
                        icon: Icons.coffee_outlined,
                        iconBg: const Color(0xFFD97706).withValues(alpha: 0.12),
                        iconColor: const Color(0xFFD97706),
                        title: 'The Coffee House',
                        subtitle: 'Hôm qua • Ví MoMo',
                        amount: '-65.000 đ',
                        isNegative: true,
                        isDark: _isDarkPreview,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        color: isDark
            ? FrostedGlassTokens.darkTextPrimary
            : FrostedGlassTokens.lightTextPrimary,
      ),
    );
  }

  Widget _buildHeroBalanceCard(BuildContext context, bool isDark) {
    return FrostedNeoCard(
      borderRadius: FrostedGlassTokens.radiusHero,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TỔNG TÀI SẢN RÒNG',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark
                      ? FrostedGlassTokens.darkTextSecondary
                      : FrostedGlassTokens.lightTextSecondary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _isBalanceVisible = !_isBalanceVisible);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.04),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isBalanceVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    size: 16,
                    color: isDark
                        ? FrostedGlassTokens.darkTextSecondary
                        : FrostedGlassTokens.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _isBalanceVisible ? '41.985.000 đ' : '••••••••',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              color: isDark
                  ? FrostedGlassTokens.darkTextPrimary
                  : FrostedGlassTokens.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Progress or Sub-information bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF059669),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Tăng trưởng +18.4% so với tháng trước',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? FrostedGlassTokens.darkTextSecondary
                        : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleAction({
    required IconData icon,
    required String label,
    required bool isDark,
    bool isHighlighted = false,
  }) {
    return Column(
      children: [
        FrostedNeoButton.circle(
          icon: icon,
          size: 46,
          isPrimary: isHighlighted,
          onPressed: () {},
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark
                ? FrostedGlassTokens.darkTextSecondary
                : FrostedGlassTokens.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String amount,
    required bool isNegative,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: isDark
                        ? FrostedGlassTokens.darkTextPrimary
                        : FrostedGlassTokens.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? FrostedGlassTokens.darkTextSecondary
                        : FrostedGlassTokens.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: isNegative
                  ? (isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48))
                  : (isDark ? const Color(0xFF34D399) : const Color(0xFF059669)),
            ),
          ),
        ],
      ),
    );
  }

  void _openDemoSheet(BuildContext context) {
    showFrostedNeoSheet(
      context: context,
      title: 'Chi tiết Giao dịch Kính mờ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Đây là trải nghiệm Modal BottomSheet theo chuẩn Frosted Neo-Glass của Apple VisionOS.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 16),
          const FrostedNeoCard(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFF005FEA)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Dữ liệu mã hóa đầu-cuối an toàn tuyệt đối',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FrostedNeoButton.primary(
            label: 'Xác nhận & Đóng',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
