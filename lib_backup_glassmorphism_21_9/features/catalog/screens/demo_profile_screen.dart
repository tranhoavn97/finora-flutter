import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../core/design_system/v8/finora_v8.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../widgets/catalog_glass_card.dart';

/// Screen 14: Profile (Hồ sơ cá nhân & thông tin người dùng) in Glassmorphism 2.0
class DemoProfileScreen extends StatelessWidget {
  final bool isLiveMode;
  final VoidCallback? onBack;

  const DemoProfileScreen({
    super.key,
    this.isLiveMode = false,
    this.onBack,
  });

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
                  title: 'Hồ sơ cá nhân',
                  onBack: onBack ?? () => Navigator.maybePop(context),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: CatalogGlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: GlassmorphismTokens.primary.withValues(alpha: 0.2),
                        child: const Text(
                          'LT',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: GlassmorphismTokens.primary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Louis Trần',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
                                  ),
                                  child: const Text(
                                    'PRO VIP',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'louis.tran@finora.io',
                              style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '👨 Trưởng gia đình FINORA',
                              style: TextStyle(fontSize: 12, color: GlassmorphismTokens.primary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Quản lý tài chính',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : Colors.black54),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildMenuItem(LucideIcons.wallet, 'Ví & Thẻ liên kết', 'Quản lý 4 nguồn tiền', isDark),
                  _buildMenuItem(LucideIcons.chart_pie, 'Báo cáo thu chi', 'Phân tích dòng tiền tháng 9', isDark),
                  _buildMenuItem(LucideIcons.shield_check, 'Nhật ký kiểm toán', 'Lịch sử thay đổi số dư', isDark),
                  _buildMenuItem(LucideIcons.users, 'Tài chính gia đình', 'Liên kết sổ chi tiêu 2 vợ chồng', isDark),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  'Bảo mật & Ứng dụng',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : Colors.black54),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildMenuItem(LucideIcons.scan_face, 'Sinh trắc học & Khóa ứng dụng', 'Face ID / Vân tay', isDark),
                  _buildMenuItem(LucideIcons.palette, 'Cài đặt giao diện', 'Glassmorphism 2.0 & Aurora presets', isDark),
                  _buildMenuItem(LucideIcons.trash, 'Thùng rác & Khôi phục', 'Dữ liệu xóa trong 30 ngày', isDark),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                child: CatalogGlassCard(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã chọn Đăng xuất tài khoản')),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.log_out, color: GlassmorphismTokens.expense, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Đăng xuất tài khoản',
                        style: TextStyle(color: GlassmorphismTokens.expense, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
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

  Widget _buildMenuItem(IconData icon, String title, String subtitle, bool isDark) {
    return CatalogGlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: () {},
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: GlassmorphismTokens.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: GlassmorphismTokens.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45)),
              ],
            ),
          ),
          const Icon(LucideIcons.chevron_right, size: 18, color: Colors.grey),
        ],
      ),
    );
  }
}
