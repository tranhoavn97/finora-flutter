import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/credit_card_palette.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/widgets/finora_mascot.dart';
import '../../core/widgets/finora_interactive_mascot.dart';
import '../../core/theme/finora_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../../state/dashboard_provider.dart';
import '../../state/budget_provider.dart';
import '../../state/more_provider.dart';
import '../../state/theme_studio_controller.dart';
import '../transaction/add_transaction_page.dart';
import '../transaction/transaction_detail_sheet.dart';
import '../transaction/transaction_theme_sheet.dart';
import '../wallet/wealth_hub_screen.dart';

/// Zenvest Glass Deck Card
/// Thiết kế chuẩn giao diện quản lý tài chính quốc tế theo phong cách Zenvest:
/// 1. Lời chào tài chính cá nhân hóa & Thẻ Kính Mờ Lơ Lửng (Frosted Glass Floating Card Deck) kích thước lớn
///    với hoa văn hào quang cực quang pastel (Iridescent bloom), huy hiệu cờ 🇻🇳 VND, số dư lớn, số tài khoản & hạn thẻ.
/// 2. Dãy phím tác vụ nhanh chuẩn Zenvest (Chuyển tiền ↗, Nhận tiền ✓, Tùy chọn ⋮ và Nút tròn nổi đen + 1 chạm).
/// 3. Khối AI Thông Minh tích hợp: Nhập nhanh AI & Sức khoẻ tài chính Finora AI nằm ngay trên khối giao dịch.
/// 4. Khối Giao Dịch bo tròn đáy (Transactions Surface Sheet) với thanh kéo, bộ lọc ≡, tiêu đề & tìm kiếm 🔍,
///    phân nhóm giao dịch theo ngày, avatar tròn đồng nhất danh mục không viền và nhãn phân loại màu sắc.
class ZenvestGlassDeckCard extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final DashboardProvider provider;
  final num totalBalance;
  final num income;
  final num expense;
  final num netFlow;
  final List<TransactionModel> txList;
  final bool isDark;
  final ThemeStudioController studio;
  final bool masked;
  final VoidCallback onToggleMask;
  final VoidCallback? onViewWallets;
  final VoidCallback? onViewLoans;
  final VoidCallback? onViewPlanning;
  final VoidCallback? onViewTransactions;
  final VoidCallback? onDateFilterTap;
  final VoidCallback? onAiQuickLogTap;
  final VoidCallback? onAiAdvisorTap;

  const ZenvestGlassDeckCard({
    super.key,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.provider,
    required this.totalBalance,
    required this.income,
    required this.expense,
    required this.netFlow,
    required this.txList,
    required this.isDark,
    required this.studio,
    required this.masked,
    required this.onToggleMask,
    this.onViewWallets,
    this.onViewLoans,
    this.onViewPlanning,
    this.onViewTransactions,
    this.onDateFilterTap,
    this.onAiQuickLogTap,
    this.onAiAdvisorTap,
  });

  @override
  State<ZenvestGlassDeckCard> createState() => _ZenvestGlassDeckCardState();
}

class _ZenvestGlassDeckCardState extends State<ZenvestGlassDeckCard> {
  late PageController _pageController;
  int _activeCardIndex = 0;
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'vi_VN');

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatAmount(num val) {
    return _currencyFormat.format(val.toInt());
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDate = DateTime(date.year, date.month, date.day);
    final diff = today.difference(txDate).inDays;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Hôm qua';
    return '${date.day} Thg ${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final wallets = widget.provider.data.wallets;
    final totalCards = 1 + wallets.length; // Card 0: Tổng tài sản; Card 1..N: Ví cụ thể

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Zenvest Floating Frosted Glass Card Deck
        _buildCardDeck(wallets, totalCards, isDark),

        const SizedBox(height: 14),

        // 2. Finora AI 3D Interactive Companion Lounge (Linh thú 3D sống động ngay trên đầu trang chủ)
        _buildFinora3DCompanionLounge(isDark),

        const SizedBox(height: 14),

        // 3. Widget Chi tiêu, Thu nhập, Số dư ở dưới card widget tổng quan
        _buildExpenseIncomeBalanceStats(isDark),

        const SizedBox(height: 16),

        // 4. Zenvest Fast Action Buttons Row (Chuyển tiền ↗, Nhận tiền ✓, ⋮, (+))
        _buildActionRow(isDark),

        const SizedBox(height: 18),

        // 5. Khối AI Thông Minh (Nhập nhanh AI, Sức khoẻ AI, Cho vay & Vay nợ)
        _buildZenvestAiSection(isDark),

        const SizedBox(height: 22),

        // 6. Zenvest Transactions Surface Container (Khối giao dịch bo tròn kiểu Sheet)
        _buildTransactionsSurface(isDark),
      ],
    );
  }

  // 2. Zenvest Card Carousel
  Widget _buildCardDeck(List<Wallet> wallets, int totalCards, bool isDark) {
    return Column(
      children: [
        SizedBox(
          height: 208,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
              },
            ),
            child: PageView.builder(
              controller: _pageController,
              physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
              itemCount: totalCards,
              onPageChanged: (idx) {
                setState(() => _activeCardIndex = idx);
                HapticFeedback.selectionClick();
              },
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Card 0: Tổng tài sản ròng (Master Net Worth Card)
                  return _buildMasterGlassCard(
                    title: 'Tổng số dư',
                    currency: 'VND',
                    balance: widget.totalBalance,
                    accountNumber: '${wallets.length} VÍ HOẠT ĐỘNG',
                    validDate: 'FINORA',
                    tierBadge: 'TỔNG TÀI SẢN',
                    isDark: isDark,
                    isMaster: true,
                  );
                } else {
                  // Card 1..N: Các ví chi tiết
                  final wallet = wallets[index - 1];
                  final brand = BankIconRegistry.resolve(
                    wallet.bankCode,
                    bankName: wallet.bankName ?? wallet.name,
                  );
                  final lowerName = wallet.name.toLowerCase();
                  final isCash = wallet.type == 'cash' ||
                      brand.code == 'cash' ||
                      lowerName.contains('tiền mặt') ||
                      lowerName.contains('cash');

                  final String displayAccount;
                  if (isCash) {
                    displayAccount = 'TIỀN MẶT';
                  } else {
                    final maskedId = wallet.accountNumber?.isNotEmpty == true
                        ? (wallet.accountNumber!.length > 4
                            ? wallet.accountNumber!.substring(wallet.accountNumber!.length - 4)
                            : wallet.accountNumber!)
                        : (wallet.id.length > 4 ? wallet.id.substring(wallet.id.length - 4) : '0000');
                    displayAccount = '•••• $maskedId';
                  }

                  final String tierBadge;
                  if (wallet.isCreditCard) {
                    tierBadge = 'THẺ TÍN DỤNG';
                  } else if (wallet.type == 'bank') {
                    tierBadge = 'TÀI KHOẢN';
                  } else if (isCash) {
                    tierBadge = 'VÍ TIỀN MẶT';
                  } else {
                    tierBadge = 'VÍ TÀI SẢN';
                  }

                  final String cardTierOrDate;
                  if (wallet.isCreditCard) {
                    if (lowerName.contains('gold') || lowerName.contains('vàng')) {
                      cardTierOrDate = 'FINORA GOLD';
                    } else if (lowerName.contains('sliver') || lowerName.contains('silver') || lowerName.contains('bạc')) {
                      cardTierOrDate = 'FINORA SILVER';
                    } else if (lowerName.contains('plat')) {
                      cardTierOrDate = 'FINORA PLATINUM';
                    } else {
                      cardTierOrDate = 'CREDIT CARD';
                    }
                  } else if (wallet.type == 'bank') {
                    cardTierOrDate = 'DEBIT CARD';
                  } else if (isCash) {
                    cardTierOrDate = 'TIỀN MẶT';
                  } else {
                    cardTierOrDate = 'FINORA PAY';
                  }

                  final num displayBalance = wallet.isCreditCard && wallet.creditLimit > 0
                      ? (wallet.creditLimit - wallet.currentDebt)
                      : wallet.balance;

                  final String displayCurrency = (brand.code != 'cash' && !isCash)
                      ? brand.name.toUpperCase()
                      : (isCash ? 'TIỀN MẶT' : 'VND');

                  return _buildMasterGlassCard(
                    title: wallet.name,
                    currency: displayCurrency,
                    balance: displayBalance,
                    accountNumber: displayAccount,
                    validDate: cardTierOrDate,
                    tierBadge: tierBadge,
                    isDark: isDark,
                    isMaster: false,
                    wallet: wallet,
                    brand: brand,
                  );
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Indicator Pills
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalCards, (idx) {
            final isCurrent = idx == _activeCardIndex;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                _pageController.animateToPage(
                  idx,
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: isCurrent ? 18 : 6,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF0F6E56))
                        : (isDark ? const Color(0xFF23322C) : const Color(0xFFD5E2DC)),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // Khối Thẻ Kính Mờ Lơ Lửng (Frosted Glass Card) - Chuẩn màu sang trọng như trong Ví Tiền, không pha trắng
  Widget _buildMasterGlassCard({
    required String title,
    required String currency,
    required num balance,
    required String accountNumber,
    required String validDate,
    required String tierBadge,
    required bool isDark,
    required bool isMaster,
    Wallet? wallet,
    BankBrand? brand,
  }) {
    final isMasked = widget.masked;
    final isCash = !isMaster &&
        (brand?.code == 'cash' ||
            wallet?.type == 'cash' ||
            title.toLowerCase().contains('tiền mặt') ||
            title.toLowerCase().contains('cash'));
    final isBankBrand = !isMaster && !isCash && brand != null && brand.code != 'cash';

    // Màu thẻ chuẩn mực từ CreditCardPalette ("màu đẹp như trong ví tiền") tuyệt đối KHÔNG pha trắng
    final List<Color> cardColors;
    final Color brandColor;

    if (isMaster) {
      // Thẻ Tổng tài sản: Ngọc lục bảo Finora Emerald thuần khiết chuẩn nhận diện thương hiệu
      cardColors = isDark
          ? const [Color(0xFF083A2C), Color(0xFF0F6E56), Color(0xFF147A60)]
          : const [Color(0xFF0B4F3E), Color(0xFF0F6E56), Color(0xFF158064)];
      brandColor = const Color(0xFF0F6E56);
    } else if (isCash) {
      // Ví tiền mặt: Ngọc bích đậm sang trọng như trong WebWalletCard (ví tiền)
      cardColors = const [Color(0xFF06281D), Color(0xFF093527), Color(0xFF041A13)];
      brandColor = const Color(0xFF10B981);
    } else {
      final walletName = (wallet?.name ?? title).toLowerCase();
      var skin = wallet?.themeColor ?? '';
      if (skin.isEmpty) {
        if (RegExp(r'gold|vàng').hasMatch(walletName)) {
          skin = 'gold';
        } else if (RegExp(r'silver|sliver|bạc|platinum').hasMatch(walletName)) {
          skin = 'silver';
        } else if (brand != null && ['mbbank', 'mb', 'bidv', 'acb', 'vtb', 'vietinbank', 'scb'].contains(brand.code)) {
          skin = 'blue';
        } else if (brand != null && ['vcb', 'vietcombank', 'vpb', 'vpbank', 'ocb'].contains(brand.code)) {
          skin = 'emerald';
        } else if (brand != null && ['tcb', 'techcombank', 'cake', 'hdb', 'hdbank', 'agri', 'agribank'].contains(brand.code)) {
          skin = 'rose';
        } else if (brand != null && ['tpb', 'tpbank', 'timo'].contains(brand.code)) {
          skin = 'purple';
        } else if (brand != null && ['shb', 'sea', 'seabank'].contains(brand.code)) {
          skin = 'orange';
        } else if (brand != null && ['vib', 'zalo', 'zalopay'].contains(brand.code)) {
          skin = 'cyan';
        } else if (brand != null && ['momo'].contains(brand.code)) {
          skin = 'pink';
        }
      }

      final resolvedColors = skin.isNotEmpty ? CreditCardPalette.skins[skin.toLowerCase()] : null;
      if (resolvedColors != null) {
        cardColors = resolvedColors;
        brandColor = resolvedColors.length >= 2 ? resolvedColors[1] : (brand?.color ?? const Color(0xFF0070F3));
      } else if (brand != null && brand.code != 'cash') {
        brandColor = brand.color;
        cardColors = [
          Color.lerp(const Color(0xFF080C14), brandColor, 0.55)!,
          Color.lerp(const Color(0xFF141A28), brandColor, 0.85)!,
          Color.lerp(const Color(0xFF04060A), brandColor, 0.40)!,
        ];
      } else {
        cardColors = CreditCardPalette.skins['black']!;
        brandColor = const Color(0xFF334155);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isMaster ? const Color(0xFF0F6E56) : brandColor)
                .withValues(alpha: isDark ? 0.42 : 0.30),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Layer 1: Nền thẻ màu sang trọng như trong ví tiền
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: cardColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            // Specular Sheen Overlay: Phản quang bóng kính tinh tế
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: const Alignment(-0.8, -1.0),
                      end: const Alignment(0.8, 1.0),
                      colors: [
                        Colors.white.withValues(alpha: 0.14),
                        Colors.white.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.22),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Layer 2: Hào quang ngọc lục bảo nhẹ nhàng tinh khiết
            Positioned.fill(
              child: CustomPaint(
                painter: isMaster
                    ? _IridescentBloomPainter(isDark: isDark)
                    : _BankBloomPainter(brandColor: brandColor, isDark: isDark),
              ),
            ),

            // Layer 3: Viền pha lê cao cấp
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1.1,
                  ),
                ),
              ),
            ),

            // Layer 4: Nội dung thông số thẻ chuẩn Zenvest với chữ trắng sắc nét
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Hàng trên: Quốc kỳ / Logo Ngân Hàng & Tên + Sóng thanh toán Contactless
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Flag & Currency / Bank Logo Pill
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Flag Icon or Bank Logo Avatar
                              if (isBankBrand && brand.assetPath != null)
                                Container(
                                  width: 19,
                                  height: 19,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.12),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      brand.assetPath!,
                                      width: 19,
                                      height: 19,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: brand.color,
                                        child: Center(
                                          child: Text(
                                            brand.name.isNotEmpty ? brand.name[0] : 'B',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              else if (isCash)
                                Container(
                                  width: 19,
                                  height: 19,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF10B981),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.payments_rounded,
                                      color: Colors.white,
                                      size: 11,
                                    ),
                                  ),
                                )
                              else
                                const FinoraMascotImage(
                                  pose: FinoraMascotPose.leafLogo,
                                  size: 18,
                                ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    currency,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Contactless Wave Icon & Tier Badge
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                tierBadge,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.contactless_rounded,
                                color: Colors.white.withValues(alpha: 0.85),
                                size: 19,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Hàng giữa: Nhãn số dư + Số tiền lớn + Nút con mắt ẩn số dư
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                isMasked ? '••••••••' : '₫ ${_formatAmount(balance)}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              widget.onToggleMask();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isMasked ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 18,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Hàng dưới: 2 cột (Số tài khoản & Hạn thẻ)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                isMaster
                                    ? 'Danh mục ví'
                                    : ((wallet?.isCreditCard == true)
                                        ? 'Số thẻ tín dụng'
                                        : (isCash ? 'Loại ví' : 'Số tài khoản')),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.70),
                                ),
                              ),
                            ),
                            const SizedBox(height: 1),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                accountNumber,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                isMaster ? 'Hệ sinh thái' : 'Hạn thẻ / Hạng',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.70),
                                ),
                              ),
                            ),
                            const SizedBox(height: 1),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                validDate,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Zenvest Action Row (Chuyển tiền ↗, Nhận tiền ✓ - 2 nút căn chỉnh cân đối)
  Widget _buildActionRow(bool isDark) {
    return Row(
      children: [
          // Nút 1: Chuyển tiền ↗
          Expanded(
            child: _buildActionPill(
              label: 'Chuyển tiền',
              icon: LucideIcons.arrow_up_right,
              isDark: isDark,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddTransactionPage(
                      userId: widget.userId,
                      initialType: 'expense',
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 12),

          // Nút 2: Nhận tiền ✓
          Expanded(
            child: _buildActionPill(
              label: 'Nhận tiền',
              icon: Icons.check_rounded,
              isDark: isDark,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddTransactionPage(
                      userId: widget.userId,
                      initialType: 'income',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
    );
  }

  Widget _buildActionPill({
    required String label,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121A17) : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE3EBE7),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F6E56).withValues(alpha: 0.25)
                        : const Color(0xFFE8F5F0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 13.5,
                    color: isDark
                        ? const Color(0xFF34D399)
                        : const Color(0xFF0F6E56),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0D1F1A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 2. Widget Chi tiêu, Thu nhập, Số dư (Ngay dưới Card Deck Tổng Quan)
  Widget _buildExpenseIncomeBalanceStats(bool isDark) {
    return Row(
      children: [
        // 1. Chi tiêu
        Expanded(
          child: _buildMetricMiniCard(
            label: 'Chi tiêu',
            amount: widget.expense,
            prefix: '-',
            color: const Color(0xFFEF4444), // Red
            icon: Icons.arrow_upward_rounded,
            isDark: isDark,
            onTap: widget.onViewTransactions,
          ),
        ),
        const SizedBox(width: 8),

        // 2. Thu nhập
        Expanded(
          child: _buildMetricMiniCard(
            label: 'Thu nhập',
            amount: widget.income,
            prefix: '+',
            color: const Color(0xFF10B981), // Emerald
            icon: Icons.arrow_downward_rounded,
            isDark: isDark,
            onTap: widget.onViewTransactions,
          ),
        ),
        const SizedBox(width: 8),

        // 3. Số dư
        Expanded(
          child: _buildMetricMiniCard(
            label: 'Số dư',
            amount: widget.totalBalance,
            prefix: '',
            color: const Color(0xFF0F6E56), // Finora Emerald
            icon: Icons.account_balance_wallet_rounded,
            isDark: isDark,
            onTap: widget.onViewWallets,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricMiniCard({
    required String label,
    required num amount,
    required String prefix,
    required Color color,
    required IconData icon,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    final formattedValue = widget.masked
        ? '••••••'
        : '$prefix${_formatAmount(amount)} đ';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: FinoraTokens.calmCardDecoration(
            isDark: isDark,
            radius: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.20 : 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(icon, color: color, size: 13),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FinoraTokens.footnote(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF52665E),
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formattedValue,
                  maxLines: 1,
                  style: FinoraTokens.headline(
                    color: isDark ? Colors.white : const Color(0xFF0D1F1A),
                    weight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. Khối AI Thông Minh Tích Hợp (Nhập Nhanh AI + Sức Khỏe AI + Cho Vay / Vay Nợ + Companion Banner)
  Widget _buildZenvestAiSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 4.1. Thanh Nhập Nhanh Với AI (Thiết kế Clean Minimal Finora Emerald)
        _buildZenvestAiQuickInputBar(isDark),

        const SizedBox(height: 12),

        // 4.2. Thẻ Bento Sức Khỏe Tài Chính Finora AI (Thiết kế Clean Minimal)
        _buildZenvestAiHealthCard(isDark),

        const SizedBox(height: 12),

        // 4.3. Widget Cho Vay và Vay Nợ
        _buildLendingAndDebtWidget(isDark),
      ],
    );
  }

  // 2. Finora AI Smart Ambient Island (Apple Intelligence Inspired Companion)
  Widget _buildFinora3DCompanionLounge(bool isDark) {
    return Builder(
      builder: (context) {
        final budgetProv = context.watch<BudgetProvider?>();
        final budgets = budgetProv?.budgetsWithSpent ?? [];
        final totalBudgetLimit = budgets.fold<int>(0, (s, b) => s + b.budget.limitAmount);
        final totalBudgetSpent = budgets.fold<int>(0, (s, b) => s + b.spentAmount);
        final budgetProgress = totalBudgetLimit > 0
            ? (totalBudgetSpent / totalBudgetLimit).clamp(0.0, 1.0)
            : 0.0;
        final isOver = budgetProgress > 0.85;

        final String speechText;
        if (totalBudgetLimit > 0) {
          if (isOver) {
            speechText = 'Cảnh báo! Đã dùng ${(budgetProgress * 100).toInt()}% hạn mức tháng.';
          } else {
            speechText = 'Tiến độ an toàn! Đã dùng ${(budgetProgress * 100).toInt()}% hạn mức.';
          }
        } else {
          speechText = 'Chào bạn! Chạm vào tớ để tương tác 3D và khám phá tài chính.';
        }

        final statusColor = isOver ? FinoraTokens.appleCoral : FinoraTokens.appleMint;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onViewPlanning,
            borderRadius: BorderRadius.circular(FinoraTokens.radiusCard),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: FinoraTokens.ambientIslandDecoration(isDark: isDark),
              child: Row(
                children: [
                  // 1. Linh thú Finora 3D tương tác mượt mà
                  SizedBox(
                    width: 58,
                    height: 58,
                    child: FinoraInteractive3DMascot(
                      size: 54,
                      showSpeechBubbleOnTap: false,
                      budgetSpentRatio: budgetProgress,
                      onTap: widget.onViewPlanning,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // 2. Cột thông tin Ambient AI
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: statusColor.withValues(alpha: 0.5),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOver ? 'CẢNH BÁO HẠN MỨC' : 'TRỢ LÝ FINORA AI',
                              style: FinoraTokens.microBadge(
                                color: statusColor,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: isDark ? Colors.white38 : Colors.black26,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          speechText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FinoraTokens.subhead(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            weight: FontWeight.w600,
                          ),
                        ),
                        if (totalBudgetLimit > 0) ...[
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: LinearProgressIndicator(
                              value: budgetProgress.clamp(0.0, 1.0),
                              minHeight: 3.5,
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : Colors.black.withValues(alpha: 0.06),
                              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildZenvestAiQuickInputBar(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onAiQuickLogTap?.call();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121A17) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE3EBE7),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // 3D Finora Cat AI Mascot Badge
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F6E56).withValues(alpha: 0.20)
                      : const Color(0xFFEFF7F4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const FinoraMascotImage(
                  pose: FinoraMascotPose.focused,
                  size: 38,
                ),
              ),
              const SizedBox(width: 12),

              // Placeholder Hint
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Nhập nhanh với AI',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: isDark ? Colors.white : const Color(0xFF0D1F1A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F6E56).withValues(alpha: isDark ? 0.24 : 0.10),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'FINORA AI',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textScaler: TextScaler.noScaling,
                              style: TextStyle(
                                fontSize: 9.0,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFF34D399) : const Color(0xFF0F6E56),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '"Ăn trưa 45k", "Đổ xăng 70k ví Momo"...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF52665E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Mic / Record action pill (Pure icon only)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F6E56).withValues(alpha: 0.24)
                      : const Color(0xFFE8F5F0),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.mic_none_rounded,
                    size: 16,
                    color: isDark ? const Color(0xFF34D399) : const Color(0xFF0F6E56),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZenvestAiHealthCard(bool isDark) {
    final d = widget.provider.data;
    final score = d.aiHealthScore > 0 ? d.aiHealthScore : 92;
    final runway = d.emergencyRunwayMonths > 0
        ? d.emergencyRunwayMonths.toStringAsFixed(1)
        : '4.8';
    final savings = d.savingsRatePercent > 0
        ? d.savingsRatePercent.toInt().toString()
        : '46';
    final debt = d.debtRatioPercent > 0 ? d.debtRatioPercent.toInt().toString() : '1';
    final tier = d.aiHealthTier.isNotEmpty ? d.aiHealthTier : 'Xuất sắc';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onAiAdvisorTap?.call();
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121A17) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE3EBE7),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header row: Clean Icon Badge + Title + Tier Badge
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F6E56).withValues(alpha: 0.24)
                          : const Color(0xFFE8F5F0),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 15,
                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF0F6E56),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sức khỏe tài chính Finora AI',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: isDark ? Colors.white : const Color(0xFF0D1F1A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 130),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F6E56).withValues(alpha: 0.22)
                            : const Color(0xFFE8F5F0),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              tier,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFF34D399) : const Color(0xFF0F6E56),
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 13,
                            color: isDark ? const Color(0xFF34D399) : const Color(0xFF0F6E56),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Gauge Score + 3 Financial Metrics
              Row(
                children: [
                  // Circular Score Ring
                  SizedBox(
                    width: 68,
                    height: 68,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 68,
                          height: 68,
                          child: CircularProgressIndicator(
                            value: (score / 100).clamp(0.0, 1.0),
                            strokeWidth: 5.5,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$score',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const Text(
                              '/100',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 14),

                  // 3 Key Metrics
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 68),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildZenvestAiMetricRow('Quỹ khẩn cấp', '$runway tháng', isDark),
                          const SizedBox(height: 4),
                          _buildZenvestAiMetricRow('Tỷ lệ tích lũy', '$savings%', isDark),
                          const SizedBox(height: 4),
                          _buildZenvestAiMetricRow('Tỷ lệ nợ/tài sản', '$debt%', isDark),
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
    );
  }

  Widget _buildZenvestAiMetricRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 110),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              maxLines: 1,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 4.3. Widget Cho Vay và Vay Nợ (Ngay Dưới Sức Khoẻ AI)
  Widget _buildLendingAndDebtWidget(bool isDark) {
    final moreProv = context.watch<MoreProvider>();
    final loans = moreProv.loans;
    final lentLoans = loans.where((l) => l.type == 'lent' && l.status == 'active').toList();
    final borrowedLoans = loans.where((l) => l.type == 'borrowed' && l.status == 'active').toList();

    final totalLent = lentLoans.fold<int>(
      0,
      (sum, l) => sum + (l.remainingPrincipal > 0 ? l.remainingPrincipal : (l.amount - l.paidAmount)),
    );
    final totalBorrowed = borrowedLoans.fold<int>(
      0,
      (sum, l) => sum + (l.remainingPrincipal > 0 ? l.remainingPrincipal : (l.amount - l.paidAmount)),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (widget.onViewLoans != null) {
            widget.onViewLoans!();
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WealthHubScreen(
                  userId: widget.userId,
                  initialTabIndex: 3,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121A17) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE3EBE7),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F6E56).withValues(alpha: 0.24)
                          : const Color(0xFFE8F5F0),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.handshake_outlined,
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF0F6E56),
                        size: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cho vay & Vay nợ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: isDark ? Colors.white : const Color(0xFF0D1F1A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 105),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Quản lý sổ nợ',
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF34D399) : const Color(0xFF0F6E56),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 11,
                            color: isDark ? const Color(0xFF34D399) : const Color(0xFF0F6E56),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Two Pods: Cho vay & Vay nợ
              Row(
                children: [
                  // Cho vay
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F6E56).withValues(alpha: 0.12)
                            : const Color(0xFFF6FAF8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF10B981).withValues(alpha: 0.20)
                              : const Color(0xFFE3EBE7),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0F6E56),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  'Cần thu về',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF52665E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.masked ? '••••••' : '${_formatAmount(totalLent)} đ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: isDark ? const Color(0xFF34D399) : const Color(0xFF0F6E56),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${lentLoans.length} khoản đang mở',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF83968E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Vay nợ
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFFD97706).withValues(alpha: 0.10)
                            : const Color(0xFFFDFBF7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.20)
                              : const Color(0xFFEDE8DF),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD97706),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  'Cần phải trả',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF52665E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.masked ? '••••••' : '${_formatAmount(totalBorrowed)} đ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${borrowedLoans.length} khoản đang mở',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF83968E),
                            ),
                          ),
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
    );
  }

  // 5. Zenvest Transactions Surface Container
  Widget _buildTransactionsSurface(bool isDark) {
    final txList = widget.txList;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121A17) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE3EBE7),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tay nắm kéo nhỏ ở đỉnh (Zenvest top handle)
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF23322C) : const Color(0xFFDDE7E2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Header: Filter ≡ | Title Giao dịch | Search 🔍
          Row(
            children: [
              // Filter Icon
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onDateFilterTap?.call();
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.sliders_horizontal,
                    size: 16,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF52665E),
                  ),
                ),
              ),

              // Title
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Giao dịch',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : const Color(0xFF0D1F1A),
                      ),
                    ),
                  ),
                ),
              ),

              // Theme Style Button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  showTransactionThemeModal(context);
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F6E56).withValues(alpha: 0.22)
                        : const Color(0xFFE8F5F0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.palette_outlined,
                    size: 16,
                    color: isDark ? const Color(0xFF34D399) : const Color(0xFF0F6E56),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Search Icon
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onViewTransactions?.call();
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.search,
                    size: 16,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF52665E),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Danh sách giao dịch phong cách Zenvest
          if (txList.isEmpty)
            _buildEmptyTransactionsPlaceholder(isDark)
          else ...[
            // Nhãn ngày tháng phân nhóm
            Text(
              'Gần đây',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF52665E),
              ),
            ),
            const SizedBox(height: 8),

            // Lấy tối đa 5 giao dịch gần nhất
            ...txList.take(5).map((tx) => _buildZenvestTransactionItem(tx, isDark)),

            const SizedBox(height: 8),

            // Nút "Xem tất cả giao dịch →"
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onViewTransactions?.call();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    'Xem tất cả giao dịch →',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF0F6E56),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyTransactionsPlaceholder(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const FinoraMascotImage(
            pose: FinoraMascotPose.relaxed,
            size: 68,
          ),
          const SizedBox(height: 10),
          Text(
            'Chưa có giao dịch gần đây',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddTransactionPage(userId: widget.userId),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : const Color(0xFF0F172A)).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '+ Tạo giao dịch đầu tiên',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Từng mục giao dịch chuẩn Zenvest: Avatar tròn đồng nhất danh mục, KHÔNG viền bao quanh
  Widget _buildZenvestTransactionItem(TransactionModel tx, bool isDark) {
    final isFlowIn = TransactionVisuals.isInflow(tx.type);
    final isTransfer = TransactionVisuals.isTransfer(tx.type);
    final isMasked = widget.masked;

    // Đồng nhất hoàn toàn icon và màu sắc với danh mục của người dùng
    final categories = Provider.of<MoreProvider?>(context, listen: false)?.categories ?? [];
    final txCatId = tx.categoryId?.trim().toLowerCase();
    final txCatName = tx.categoryName?.trim().toLowerCase();
    final matchingCategory = categories.cast<dynamic>().firstWhere(
      (c) {
        if (c == null) return false;
        final cId = c.id?.toString().trim().toLowerCase();
        final cName = c.name?.toString().trim().toLowerCase();
        if (txCatId != null && txCatId.isNotEmpty && cId == txCatId) return true;
        if (txCatName != null && txCatName.isNotEmpty && cName == txCatName) return true;
        return false;
      },
      orElse: () => null,
    );

    final resolvedIconStr = TransactionVisuals.iconFor(
      tx.type,
      matchingCategory?.icon ?? tx.categoryIcon,
      categoryName: matchingCategory?.name ?? tx.categoryName ?? tx.note,
      merchantId: tx.merchantId,
      merchantName: tx.merchantName,
    );
    final catColor = TransactionVisuals.iconColorFor(
      tx.type,
      categoryColor: matchingCategory?.color ?? tx.categoryColor,
    );
    final effectiveIconColor = isDark ? catColor : Color.lerp(catColor, Colors.black, 0.15)!;

    final catDisplayName = matchingCategory?.name ?? tx.categoryName ?? 'Giao dịch';
    final title = (tx.note != null && tx.note!.trim().isNotEmpty) ? tx.note!.trim() : catDisplayName;
    final txDate = DateTime.fromMillisecondsSinceEpoch(tx.date);
    final subtitle = '$catDisplayName • ↻ ${_formatRelativeDate(txDate)}';

    final statusColor = TransactionVisuals.colorFor(tx.type);
    final statusLabel = switch (tx.type.toLowerCase()) {
      'lending' || 'loan' || 'lent' => 'Cho vay',
      'borrowing' || 'borrow' || 'debt' => 'Đi vay',
      'debt_repayment' || 'repayment' || 'debt_repayment_paid' => 'Trả nợ',
      'loan_repayment_received' || 'debt_collection' => 'Thu nợ',
      'investment' || 'invest' => 'Đầu tư',
      'saving' || 'savings' => 'Tiết kiệm',
      'credit_card_payment' => 'Trả thẻ',
      'transfer' => 'Chuyển tiền',
      'income' => 'Thu nhập',
      _ => isFlowIn ? 'Thu nhập' : 'Chi tiêu',
    };

    final amountPrefix = isTransfer ? '' : (isFlowIn ? '+' : '-');
    final amountText = isMasked
        ? '••••••'
        : '$amountPrefix${_formatAmount(tx.amount)} ₫';

    final isPhoto = CategoryIconHelper.isPhoto(resolvedIconStr, catDisplayName) ||
        (BankIconRegistry.resolve(resolvedIconStr, bankName: catDisplayName).code != 'cash' &&
            BankIconRegistry.resolve(resolvedIconStr, bankName: catDisplayName).assetPath != null);

    final listStyle = widget.studio.transactionListStyle;
    final isCompact = listStyle == AppTransactionListStyle.compactTable;
    final isBento = listStyle == AppTransactionListStyle.bentoCards;
    final isTimeline = listStyle == AppTransactionListStyle.timelineRail;
    final isMinimal = listStyle == AppTransactionListStyle.minimalDivided;

    final rowContent = Row(
      children: [
        if (isTimeline) ...[
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
        ],
        // Circular Avatar Icon: Đồng nhất với danh mục, KHÔNG viền bao quanh, icon FULL hoàn toàn
        Container(
          width: isCompact ? 34 : 42,
          height: isCompact ? 34 : 42,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isPhoto ? Colors.transparent : catColor.withValues(alpha: isDark ? 0.22 : 0.14),
            shape: isBento ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: isBento ? BorderRadius.circular(12) : null,
          ),
          child: Center(
            child: CategoryIconWidget(
              icon: resolvedIconStr,
              categoryName: catDisplayName,
              size: isPhoto ? (isCompact ? 34 : 42) : (isCompact ? 18 : 22),
              color: effectiveIconColor,
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Title & Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isCompact ? 13.5 : 14.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(width: 10),

        // Amount & Status Badge (Always pinned flush right)
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 112),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  amountText,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: isCompact ? 13.5 : 14.5,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: isTransfer
                        ? (isDark
                            ? const Color(0xFF38BDF8)
                            : const Color(0xFF0284C7))
                        : (isFlowIn
                            ? (isDark
                                ? const Color(0xFF34D399)
                                : const Color(0xFF059669))
                            : (isDark
                                ? const Color(0xFFF87171)
                                : const Color(0xFFE11D48))),
                  ),
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        showTransactionDetailSheet(
          context,
          transaction: tx,
          userId: widget.userId,
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: isBento ? 4 : 0),
        padding: EdgeInsets.symmetric(
          vertical: isCompact ? 6 : 9,
          horizontal: isBento ? 10 : 2,
        ),
        decoration: isBento
            ? BoxDecoration(
                color: (isDark ? Colors.white : const Color(0xFF0F172A)).withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (isDark ? Colors.white : const Color(0xFF0F172A)).withValues(alpha: 0.07),
                ),
              )
            : isMinimal
                ? BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                        width: 0.6,
                      ),
                    ),
                  )
                : null,
        child: rowContent,
      ),
    );
  }
}

/// Iridescent Bloom Painter
/// Vẽ dải hào quang ngọc lục bảo Finora tinh khiết mượt mà bên phải thẻ
class _IridescentBloomPainter extends CustomPainter {
  final bool isDark;
  const _IridescentBloomPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.84, size.height * 0.42);

    // 1. Vầng sáng xanh ngọc mint mềm mại (Soft Emerald Mint Glow)
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF34D399).withValues(alpha: isDark ? 0.22 : 0.28),
          const Color(0xFF10B981).withValues(alpha: isDark ? 0.10 : 0.14),
          Colors.transparent,
        ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.height * 0.85));
    canvas.drawCircle(center, size.height * 0.85, paint1);

    // 2. Vầng phản quang trắng ngọc cực nhẹ ở góc trên phải
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.08 : 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.80],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.92, size.height * 0.18), radius: size.height * 0.55));
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.18), size.height * 0.55, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bank Card Bloom Painter
/// Vẽ dải hào quang màu thương hiệu ngân hàng mượt mà phát sáng bên phải thẻ
class _BankBloomPainter extends CustomPainter {
  final Color brandColor;
  final bool isDark;

  const _BankBloomPainter({
    required this.brandColor,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.82, size.height * 0.50);

    // 1. Vầng màu thương hiệu chính (Primary Bank Glow)
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          brandColor.withValues(alpha: isDark ? 0.40 : 0.42),
          brandColor.withValues(alpha: isDark ? 0.20 : 0.22),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(
        center: center.translate(-15, -10),
        radius: size.height * 0.75,
      ));
    canvas.drawCircle(center.translate(-15, -10), size.height * 0.75, paint1);

    // 2. Vầng điểm sáng pha trắng / pastel nhẹ (Luminous Tint Flare)
    final highlightColor = Color.lerp(brandColor, Colors.white, 0.45)!;
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          highlightColor.withValues(alpha: isDark ? 0.28 : 0.38),
          highlightColor.withValues(alpha: isDark ? 0.12 : 0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(Rect.fromCircle(
        center: center.translate(14, 16),
        radius: size.height * 0.65,
      ));
    canvas.drawCircle(center.translate(14, 16), size.height * 0.65, paint2);

    // 3. Vầng màu bổ trợ mềm mại (Soft Ambient Halo)
    final ambientColor = Color.lerp(brandColor, const Color(0xFFFFD1A9), 0.35)!;
    final paint3 = Paint()
      ..shader = RadialGradient(
        colors: [
          ambientColor.withValues(alpha: isDark ? 0.20 : 0.30),
          Colors.transparent,
        ],
        stops: const [0.0, 0.85],
      ).createShader(Rect.fromCircle(
        center: center.translate(-30, 22),
        radius: size.height * 0.55,
      ));
    canvas.drawCircle(center.translate(-30, 22), size.height * 0.55, paint3);
  }

  @override
  bool shouldRepaint(covariant _BankBloomPainter oldDelegate) {
    return oldDelegate.brandColor != brandColor || oldDelegate.isDark != isDark;
  }
}

