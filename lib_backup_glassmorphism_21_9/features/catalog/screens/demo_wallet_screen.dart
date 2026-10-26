import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/v8/finora_v8.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../catalog_mock_data.dart';
import '../widgets/catalog_bottom_sheets.dart';
import '../widgets/catalog_glass_card.dart';
import '../widgets/catalog_hero_card.dart';

final NumberFormat _vnd = NumberFormat('#,##0', 'vi_VN');

/// Screen 3: Wallet (Quản lý ví, thẻ & tài khoản) in Glassmorphism 2.0
class DemoWalletScreen extends StatefulWidget {
  final bool isLiveMode;
  final VoidCallback? onBack;

  const DemoWalletScreen({
    super.key,
    this.isLiveMode = false,
    this.onBack,
  });

  @override
  State<DemoWalletScreen> createState() => _DemoWalletScreenState();
}

class _DemoWalletScreenState extends State<DemoWalletScreen> {
  int _selectedCardIndex = 0;
  String _selectedFilter = 'Tất cả';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wallets = CatalogMockData.wallets;
    final totalBalance = wallets.fold<int>(0, (sum, w) => sum + w.balance);

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
                  title: 'Ví & Thẻ liên kết',
                  onBack: widget.onBack ?? () => Navigator.maybePop(context),
                  actions: [
                    FinoraAddIconButton(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        CatalogBottomSheets.showAddWalletSheet(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: CatalogHeroCard(
                title: 'Tổng số dư khả dụng',
                amount: totalBalance,
                subtitle: '${wallets.length} nguồn tiền hoạt động',
                gradientColors: const [
                  Color(0xFF0D253F),
                  Color(0xFF1B4965),
                ],
                metrics: [
                  HeroMetricItem(
                    label: 'Tài khoản bank',
                    value: _vnd.format(wallets.where((w) => w.type == WalletType.bank).fold<int>(0, (s, w) => s + w.balance)),
                    color: GlassmorphismTokens.balance,
                  ),
                  HeroMetricItem(
                    label: 'Tiền mặt & ví',
                    value: _vnd.format(wallets.where((w) => w.type != WalletType.bank).fold<int>(0, (s, w) => s + w.balance)),
                    color: GlassmorphismTokens.income,
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Thẻ & Tài khoản ngân hàng',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                    ),
                    Text(
                      '${_selectedCardIndex + 1}/${wallets.length}',
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black45),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 190,
                child: PageView.builder(
                  controller: PageController(viewportFraction: 0.88),
                  itemCount: wallets.length,
                  onPageChanged: (idx) => setState(() => _selectedCardIndex = idx),
                  itemBuilder: (context, idx) {
                    final wallet = wallets[idx];
                    return _buildCreditCardItem(wallet, idx == _selectedCardIndex, isDark);
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Danh sách ví chi tiết',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                    ),
                    Row(
                      children: ['Tất cả', 'Ngân hàng', 'Tiền mặt'].map((f) {
                        final isSel = _selectedFilter == f;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedFilter = f);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? GlassmorphismTokens.primary.withValues(alpha: isDark ? 0.35 : 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSel
                                    ? GlassmorphismTokens.primary.withValues(alpha: 0.6)
                                    : (isDark ? Colors.white12 : Colors.black12),
                              ),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                                color: isSel
                                    ? GlassmorphismTokens.primary
                                    : (isDark ? Colors.white60 : Colors.black54),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, idx) {
                    final filtered = wallets.where((w) {
                      if (_selectedFilter == 'Ngân hàng') return w.type == WalletType.bank;
                      if (_selectedFilter == 'Tiền mặt') return w.type == WalletType.cash || w.type == WalletType.eWallet;
                      return true;
                    }).toList();
                    if (idx >= filtered.length) return null;
                    final w = filtered[idx];
                    return _buildWalletRowCard(w, isDark);
                  },
                  childCount: wallets.where((w) {
                    if (_selectedFilter == 'Ngân hàng') return w.type == WalletType.bank;
                    if (_selectedFilter == 'Tiền mặt') return w.type == WalletType.cash || w.type == WalletType.eWallet;
                    return true;
                  }).length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCardItem(CatalogWalletItem wallet, bool isSelected, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            wallet.color,
            wallet.color.withValues(alpha: 0.75),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: wallet.color.withValues(alpha: isSelected ? 0.45 : 0.20),
            blurRadius: isSelected ? 18 : 8,
            offset: Offset(0, isSelected ? 8 : 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                wallet.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  wallet.accountNumber.isNotEmpty ? wallet.accountNumber : 'CASH',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Số dư thực tế',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 2),
              Text(
                '${_vnd.format(wallet.balance)} đ',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                wallet.owner,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  CatalogBottomSheets.showWalletReconciliationSheet(context, wallet);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.circle_check, size: 13, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Đối soát',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletRowCard(CatalogWalletItem wallet, bool isDark) {
    return CatalogGlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: () {
        CatalogBottomSheets.showWalletReconciliationSheet(context, wallet);
      },
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: wallet.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: wallet.color.withValues(alpha: 0.35)),
            ),
            child: Icon(
              wallet.type == WalletType.bank
                  ? LucideIcons.landmark
                  : (wallet.type == WalletType.credit ? LucideIcons.credit_card : LucideIcons.wallet),
              color: wallet.color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      wallet.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        wallet.owner,
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
                  'Số TK: ${wallet.accountNumber}',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_vnd.format(wallet.balance)} đ',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: -0.2),
              ),
              const SizedBox(height: 3),
              const Text(
                'Khớp số dư',
                style: TextStyle(fontSize: 11, color: GlassmorphismTokens.income, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
